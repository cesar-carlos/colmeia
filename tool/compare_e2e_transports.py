#!/usr/bin/env python3
"""Compare Colmeia E2E runtime across REST and socket transports."""

from __future__ import annotations

import argparse
import dataclasses
import pathlib
import shutil
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


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Run test/integration/e2e under REST and/or socket transport "
            "and print a Markdown timing table."
        ),
    )
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
        choices=("rest", "socket", "both"),
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
    if raw == "both":
        return ("rest", "socket")
    return (raw,)


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
    except subprocess.TimeoutExpired:
        return RunResult(status="timeout", seconds=timeout_seconds)

    elapsed = time.perf_counter() - started
    status = "pass" if completed.returncode == 0 else f"fail({completed.returncode})"
    return RunResult(status=status, seconds=elapsed)


def format_result(result: RunResult | None) -> str:
    if result is None:
        return "-"
    if result.seconds is None:
        return result.status
    return f"{result.status} {result.seconds:.3f}s"


def format_delta(rest: RunResult | None, socket: RunResult | None) -> str:
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
) -> list[tuple[RunTarget, dict[str, RunResult]]]:
    rows: list[tuple[RunTarget, dict[str, RunResult]]] = []
    for target in targets:
        results: dict[str, RunResult] = {}
        for transport in transports:
            results[transport] = run_command(
                command_for(target, transport, flutter_bin=flutter_bin),
                timeout_seconds=timeout_seconds,
                dry_run=dry_run,
            )
        rows.append((target, results))
    return rows


def print_table(rows: list[tuple[RunTarget, dict[str, RunResult]]]) -> None:
    print("| target | rest | socket | delta(socket-rest) |")
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


def main() -> int:
    args = parse_args()
    files = discover_files(args.files)
    targets = build_targets(files, args.scope)
    rows = rows_for(
        targets,
        selected_transports(args.transport),
        flutter_bin=flutter_executable(),
        timeout_seconds=args.timeout_seconds,
        dry_run=args.dry_run,
    )
    print_table(rows)
    failed = any(
        result.status.startswith("fail") or result.status == "timeout"
        for _, results in rows
        for result in results.values()
    )
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
