#!/usr/bin/env python3
"""Compare Colmeia E2E runtime across REST and socket transports."""

from __future__ import annotations

import argparse
import dataclasses
import json
import math
import pathlib
import shutil
import statistics
import subprocess
import time
from collections.abc import Iterable


ROOT = pathlib.Path(__file__).resolve().parents[1]
E2E_DIR = ROOT / "test" / "integration" / "e2e"

TRANSPORT_DEFINES = {
    "rest": [
        "--dart-define=AGENT_BRIDGE_TRANSPORT=rest",
        "--dart-define=E2E_DISABLE_RELAY_DISPATCH=true",
    ],
    "socket": [
        "--dart-define=AGENT_BRIDGE_TRANSPORT=socket",
        "--dart-define=E2E_DISABLE_RELAY_DISPATCH=false",
    ],
}


@dataclasses.dataclass(frozen=True)
class RunTarget:
    label: str
    path: pathlib.Path


@dataclasses.dataclass(frozen=True)
class RunResult:
    status: str
    seconds: float | None
    output: str = ""


@dataclasses.dataclass(frozen=True)
class AggregatedResult:
    """Aggregated stats across N runs of the same target+transport.

    Reports the median wall-clock for the **passing** runs and surfaces
    pass/fail counts. Median is preferred over mean because a single
    cold-start outlier (e.g. a hub 503 retry) skews the average a lot.
    """

    seconds: float | None  # median over passing runs; None when no pass.
    minimum: float | None
    maximum: float | None
    pass_count: int
    fail_count: int
    timeout_count: int
    total_runs: int
    failure_outputs: list[str]

    @property
    def status(self) -> str:
        if self.total_runs == 0:
            return "no-runs"
        if self.timeout_count > 0:
            return f"timeout({self.timeout_count}/{self.total_runs})"
        if self.fail_count > 0:
            return f"fail({self.fail_count}/{self.total_runs})"
        return f"pass({self.pass_count}/{self.total_runs})"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run test/integration/e2e under REST and/or socket transport "
            "and print a Markdown timing table."
        ),
    )
    parser.add_argument(
        "--mode", choices=("process", "requests"), default="process",
        help="Measure whole test processes or SQL requests after bootstrap.",
    )
    parser.add_argument("--samples", type=int, default=100)
    parser.add_argument("--warmups", type=int, default=5)
    parser.add_argument("--scenarios", nargs="+", choices=("small", "large", "batch"),
                        default=["small", "large", "batch"])
    parser.add_argument("--output-json", type=pathlib.Path)
    parser.add_argument("--baseline-json", type=pathlib.Path)
    parser.add_argument(
        "--files",
        nargs="*",
        default=None,
        help=(
            "Optional E2E file names or paths. Defaults to every "
            "test/integration/e2e/*_test.dart file."
        ),
    )
    parser.add_argument(
        "--timeout-seconds",
        type=int,
        default=180,
        help="Per file/transport timeout in seconds. Default: 180.",
    )
    parser.add_argument(
        "--transport",
        choices=("rest", "socket", "legacy", "relay", "both", "all"),
        default="both",
        help="Transport(s) to run. Default: both.",
    )
    parser.add_argument(
        "--scope",
        choices=("files", "suite", "both"),
        default="files",
        help=(
            "Run each file separately, the whole e2e suite once, or both. "
            "Default: files."
        ),
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print commands without running them.",
    )
    parser.add_argument(
        "--tail-lines",
        type=int,
        default=80,
        help="Lines of Flutter output to print for failed/timeout runs. Default: 80.",
    )
    parser.add_argument(
        "--runs",
        type=int,
        default=1,
        help=(
            "Repeat each target/transport N times and report the median "
            "wall-clock of the passing runs. Use 3..5 to dampen single-run "
            "variance; CI defaults to 1. Default: 1."
        ),
    )
    return parser.parse_args()


def discover_files(raw_files: list[str] | None) -> list[pathlib.Path]:
    all_files = sorted(E2E_DIR.glob("*_test.dart"))
    if not raw_files:
        return all_files

    by_name = {path.name: path for path in all_files}
    selected: list[pathlib.Path] = []
    for raw in raw_files:
        path = pathlib.Path(raw)
        if path.is_absolute() and path.exists():
            selected.append(path)
            continue
        candidate = (ROOT / path).resolve()
        if candidate.exists():
            selected.append(candidate)
            continue
        if raw in by_name:
            selected.append(by_name[raw])
            continue
        raise SystemExit(f"E2E file not found: {raw}")
    return selected


def selected_transports(raw: str) -> tuple[str, ...]:
    if raw == "all":
        return ("rest", "legacy", "relay")
    if raw == "both":
        return ("rest", "socket")
    return (raw,)


def percentile(values: list[float], fraction: float) -> float:
    ordered = sorted(values)
    position = (len(ordered) - 1) * fraction
    low, high = math.floor(position), math.ceil(position)
    return ordered[low] + (ordered[high] - ordered[low]) * (position - low)


def request_measurements(output: str) -> list[dict]:
    """Ignore Flutter bootstrap and runner output; accept only structured records."""
    prefix = "REQUEST_BENCHMARK "
    records = []
    for line in output.splitlines():
        if prefix in line:
            records.append(json.loads(line.split(prefix, 1)[1]))
    return records


def summarize_requests(records: list[dict], samples: int) -> list[dict]:
    groups: dict[tuple, list[dict]] = {}
    digests: dict[str, str] = {}
    for record in records:
        if record.get("kind") != "request":
            continue
        if not record.get("success"):
            raise ValueError("Request failure: benchmark cannot approve performance")
        diagnostics = record["diagnostics"]
        if not diagnostics.get("cacheHit"):
            expected = "socket_legacy" if record["route"] == "legacy" else record["route"]
            actual = diagnostics.get("transport")
            actual = "relay" if actual == "relay_streaming" else actual
            if actual != expected or diagnostics.get("fallback"):
                raise ValueError("Fallback or missing transport cannot approve a requested route")
        scenario = record["scenario"]
        digest = record["digest"]
        if digests.setdefault(scenario, digest) != digest:
            raise ValueError(f"Data mismatch for {scenario}")
        if record["phase"] == "sample":
            key = record["route"], scenario, record["cache"]
            groups.setdefault(key, []).append(record)
    summaries = []
    for (route, scenario, cache), group in sorted(groups.items()):
        if len(group) != samples or {r["index"] for r in group} != set(range(samples)):
            raise ValueError("Missing or duplicate samples; skips never count as success")
        durations = [r["completionMs"] for r in group]
        first_rows = [r["diagnostics"]["phasesMs"]["first_rows"] for r in group
                      if "first_rows" in r["diagnostics"]["phasesMs"]]
        summaries.append({
            "route": route, "scenario": scenario, "cache": cache,
            "samples": samples, "digest": group[0]["digest"], "rows": group[0]["rows"],
            "p50Ms": percentile(durations, .5), "p95Ms": percentile(durations, .95),
            "p99Ms": percentile(durations, .99),
            "firstRowP95Ms": percentile(first_rows, .95) if first_rows else None,
            "throughput": 1000 * samples / sum(durations),
            "rssPeakBytes": max(r["rssBytes"] for r in group),
            "rssGrowthPeakBytes": max(r["rssGrowthBytes"] for r in group),
            "errors": 0, "timeouts": 0,
        })
    return summaries


def summarize_failures(records: list[dict]) -> list[dict]:
    groups: dict[tuple, list[dict]] = {}
    for record in records:
        if record.get("kind") == "request":
            key = record["route"], record["scenario"], record["cache"]
            groups.setdefault(key, []).append(record)
    return [{"route": route, "scenario": scenario, "cache": cache,
             "observedRequests": len(group),
             "errors": sum(record.get("success") is False for record in group),
             "timeouts": sum(record.get("success") is False and record.get("timeout") is True
                             for record in group)}
            for (route, scenario, cache), group in sorted(groups.items())]


def approve_against_baseline(summaries: list[dict], baseline: list[dict]) -> bool:
    if not summaries or not baseline:
        return False
    by_key = {(r["route"], r["scenario"], r["cache"]): r for r in baseline}
    for row in summaries:
        previous = by_key.get((row["route"], row["scenario"], row["cache"]))
        if previous is None or row["digest"] != previous["digest"] or row["rows"] != previous["rows"]:
            return False
        if row["errors"] or row["timeouts"] or row["p95Ms"] > 1.05 * previous["p95Ms"]:
            return False
        if row["throughput"] < .85 * previous["throughput"]:
            return False
    return len(summaries) == len(baseline)


def run_requests(args: argparse.Namespace) -> int:
    if args.samples < 1 or args.warmups < 0:
        raise SystemExit("samples must be positive and warmups non-negative")
    routes = ("rest", "legacy", "relay") if args.transport in ("both", "all") else (
        "legacy" if args.transport == "socket" else args.transport,
    )
    records = []
    failed_routes = []
    for route in routes:
        command = [flutter_executable(), "test",
                   "test/integration/e2e/agent_queries_transport_benchmark_e2e_test.dart",
                   "--tags=e2e", "--concurrency=1", "--reporter=expanded",
                   *TRANSPORT_DEFINES["rest" if route == "rest" else "socket"],
                   "--dart-define=AGENT_QUERY_TRANSPORT_POLICY=legacy",
                   "--dart-define=SOCKET_WARM_UP_AFTER_LOGIN=false",
                   "--dart-define=SOCKET_REQUEST_SERVER_TIMINGS_ENABLED=true",
                   "--dart-define=E2E_REQUEST_BENCHMARK=true",
                   f"--dart-define=E2E_BENCH_ROUTE={route}",
                   f"--dart-define=E2E_BENCH_SAMPLES={args.samples}",
                   f"--dart-define=E2E_BENCH_WARMUPS={args.warmups}",
                   f"--dart-define=E2E_BENCH_SCENARIOS={','.join(args.scenarios)}"]
        result = run_command(command, timeout_seconds=args.timeout_seconds, dry_run=args.dry_run)
        if args.dry_run:
            continue
        route_records = request_measurements(result.output)
        records.append({"kind": "process", "route": route, "status": result.status,
                        "ms": None if result.seconds is None else result.seconds * 1000})
        records.extend(route_records)
        if result.status != "pass":
            print(f"{route}: {result.status}; strict benchmark failed")
            print(_redact_output("\n".join(result.output.splitlines()[-args.tail_lines:])))
            failed_routes.append(route)
            continue
        if len([r for r in route_records if r.get("phase") == "sample"]) != args.samples * len(args.scenarios) * 2:
            print(f"{route}: incomplete benchmark; skips are not approved samples")
            failed_routes.append(route)
    if args.dry_run:
        return 0
    if failed_routes:
        if args.output_json:
            args.output_json.write_text(json.dumps({"schemaVersion": 1, "approved": False,
                "failedRoutes": failed_routes, "failures": summarize_failures(records),
                "measurements": records}, indent=2), encoding="utf-8")
        return 1
    try:
        summaries = summarize_requests(records, args.samples)
    except ValueError as error:
        print(str(error))
        return 1
    report = {"schemaVersion": 1, "approved": False, "warmups": args.warmups, "samples": args.samples, "scenarios": args.scenarios,
              "summaries": summaries, "measurements": records}
    if args.output_json:
        args.output_json.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print("| route | scenario | cache | p50 ms | p95 ms | p99 ms | first row p95 ms | requests/s | RSS MiB |")
    print("|---|---|---|---:|---:|---:|---:|---:|---:|")
    for row in summaries:
        first = row["firstRowP95Ms"]
        print(f"| {row['route']} | {row['scenario']} | {row['cache']} | {row['p50Ms']:.2f} | "
              f"{row['p95Ms']:.2f} | {row['p99Ms']:.2f} | {first if first is not None else '-'} | "
              f"{row['throughput']:.2f} | {row['rssPeakBytes'] / 1048576:.1f} |")
    if args.baseline_json:
        if args.samples < 100 or args.warmups < 5 or set(args.scenarios) != {"small", "large", "batch"}:
            print("Performance gate rejected: all scenarios, five warmups and 100 samples are required")
            return 1
        baseline = json.loads(args.baseline_json.read_text(encoding="utf-8"))["summaries"]
        approved = approve_against_baseline(summaries, baseline)
        report["approved"] = approved
        if args.output_json:
            args.output_json.write_text(json.dumps(report, indent=2), encoding="utf-8")
        print("Performance gate:", "approved" if approved else "rejected")
        return 0 if approved else 1
    print("No baseline supplied; this run establishes measurements, not performance approval.")
    return 0


def build_targets(files: list[pathlib.Path], scope: str) -> list[RunTarget]:
    targets: list[RunTarget] = []
    if scope in ("files", "both"):
        targets.extend(
            RunTarget(
                label=path.relative_to(ROOT).as_posix(),
                path=path,
            )
            for path in files
        )
    if scope in ("suite", "both"):
        targets.append(
            RunTarget(
                label=f"{E2E_DIR.relative_to(ROOT).as_posix()}/",
                path=E2E_DIR,
            ),
        )
    return targets


def flutter_executable() -> str:
    executable = shutil.which("flutter")
    if executable is None:
        raise SystemExit("flutter executable not found in PATH")
    return executable


def command_for(
    target: RunTarget,
    transport: str,
    *,
    flutter_bin: str,
) -> list[str]:
    return [
        flutter_bin,
        "test",
        str(target.path.relative_to(ROOT)),
        "--tags",
        "e2e",
        "--concurrency=1",
        *TRANSPORT_DEFINES[transport],
    ]


def run_command(
    command: list[str],
    *,
    timeout_seconds: int,
    dry_run: bool,
) -> RunResult:
    if dry_run:
        print("DRY-RUN:", " ".join(command))
        return RunResult(status="dry-run", seconds=None)

    started = time.perf_counter()
    try:
        completed = subprocess.run(
            command,
            cwd=ROOT,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=timeout_seconds,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        return RunResult(
            status="timeout",
            seconds=timeout_seconds,
            output=_coerce_output(exc.output),
        )

    elapsed = time.perf_counter() - started
    status = "pass" if completed.returncode == 0 else f"fail({completed.returncode})"
    return RunResult(status=status, seconds=elapsed, output=completed.stdout)


def aggregate(results: list[RunResult]) -> AggregatedResult:
    """Reduce a list of single-run [RunResult]s into a median + stats."""
    pass_seconds: list[float] = []
    pass_count = 0
    fail_count = 0
    timeout_count = 0
    failure_outputs: list[str] = []

    for result in results:
        if result.status == "pass" and result.seconds is not None:
            pass_seconds.append(result.seconds)
            pass_count += 1
        elif result.status == "timeout":
            timeout_count += 1
            failure_outputs.append(result.output)
        elif result.status.startswith("fail"):
            fail_count += 1
            failure_outputs.append(result.output)

    median = statistics.median(pass_seconds) if pass_seconds else None
    return AggregatedResult(
        seconds=median,
        minimum=min(pass_seconds) if pass_seconds else None,
        maximum=max(pass_seconds) if pass_seconds else None,
        pass_count=pass_count,
        fail_count=fail_count,
        timeout_count=timeout_count,
        total_runs=len(results),
        failure_outputs=failure_outputs,
    )


def format_result(result: AggregatedResult | None) -> str:
    if result is None or result.total_runs == 0:
        return "-"
    if result.seconds is None:
        return result.status
    if result.total_runs == 1:
        return f"{result.status} {result.seconds:.3f}s"
    span = ""
    if result.minimum is not None and result.maximum is not None:
        span = f" [{result.minimum:.3f}..{result.maximum:.3f}]"
    return f"{result.status} {result.seconds:.3f}s{span}"


def format_delta(
    rest: AggregatedResult | None,
    socket: AggregatedResult | None,
) -> str:
    if rest is None or socket is None:
        return "-"
    if rest.seconds is None or socket.seconds is None:
        return "-"
    return f"{socket.seconds - rest.seconds:+.3f}s"


def rows_for(
    targets: Iterable[RunTarget],
    transports: tuple[str, ...],
    *,
    flutter_bin: str,
    timeout_seconds: int,
    dry_run: bool,
    runs: int,
) -> list[tuple[RunTarget, dict[str, AggregatedResult]]]:
    rows: list[tuple[RunTarget, dict[str, AggregatedResult]]] = []
    for target in targets:
        results: dict[str, AggregatedResult] = {}
        for transport in transports:
            command = command_for(target, transport, flutter_bin=flutter_bin)
            single_runs: list[RunResult] = []
            for _ in range(max(1, runs)):
                single_runs.append(
                    run_command(
                        command,
                        timeout_seconds=timeout_seconds,
                        dry_run=dry_run,
                    ),
                )
            results[transport] = aggregate(single_runs)
        rows.append((target, results))
    return rows


def print_table(
    rows: list[tuple[RunTarget, dict[str, AggregatedResult]]],
    *,
    runs: int,
) -> None:
    suffix = " (median)" if runs > 1 else ""
    print(f"| target | rest{suffix} | socket{suffix} | delta(socket-rest) |")
    print("|---|---:|---:|---:|")
    for target, results in rows:
        rest = results.get("rest")
        socket = results.get("socket")
        print(
            "| "
            f"{target.label} | "
            f"{format_result(rest)} | "
            f"{format_result(socket)} | "
            f"{format_delta(rest, socket)} |"
        )


def print_failure_tails(
    rows: list[tuple[RunTarget, dict[str, AggregatedResult]]],
    *,
    tail_lines: int,
) -> None:
    if tail_lines <= 0:
        return

    blocks: list[tuple[str, str, AggregatedResult]] = []
    for target, results in rows:
        for transport, result in results.items():
            if result.fail_count > 0 or result.timeout_count > 0:
                blocks.append((target.label, transport, result))

    if not blocks:
        return

    print()
    print("## Failure output tails")
    for target, transport, result in blocks:
        for index, output in enumerate(result.failure_outputs, start=1):
            print()
            label = f"{target} [{transport}] {result.status}"
            if len(result.failure_outputs) > 1:
                label += f" run#{index}"
            print(f"### {label}")
            redacted = _redact_output(output)
            lines = redacted.splitlines()
            tail = lines[-tail_lines:] if lines else ["<no output captured>"]
            print("```text")
            for line in tail:
                print(line)
            print("```")


def _coerce_output(value: object) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode(errors="replace")
    return str(value)


def _redact_output(output: str) -> str:
    redacted_lines: list[str] = []
    for line in output.splitlines():
        lower = line.lower()
        if (
            "password" in lower
            or "client_token" in lower
            or "token" in lower
            or "secret" in lower
            or "authorization" in lower
        ):
            redacted_lines.append("<redacted sensitive output line>")
        else:
            redacted_lines.append(line)
    return "\n".join(redacted_lines)


def main() -> int:
    args = parse_args()
    if args.mode == "requests":
        return run_requests(args)
    if args.transport in ("legacy", "relay", "all"):
        raise SystemExit("legacy/relay/all require --mode=requests")
    files = discover_files(args.files)
    targets = build_targets(files, args.scope)
    rows = rows_for(
        targets,
        selected_transports(args.transport),
        flutter_bin=flutter_executable(),
        timeout_seconds=args.timeout_seconds,
        dry_run=args.dry_run,
        runs=args.runs,
    )
    print_table(rows, runs=args.runs)
    print_failure_tails(rows, tail_lines=args.tail_lines)
    failed = any(
        result.fail_count > 0 or result.timeout_count > 0
        for _, results in rows
        for result in results.values()
    )
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
