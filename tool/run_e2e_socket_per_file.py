#!/usr/bin/env python3
"""Run each E2E file alone on socket and classify hub vs app failures."""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys
import time

ROOT = pathlib.Path(__file__).resolve().parents[1]
E2E_DIR = ROOT / "test" / "integration" / "e2e"
TIMEOUT_S = 90
DEFINES = [
    "--dart-define=AGENT_BRIDGE_TRANSPORT=socket",
    "--dart-define=SOCKET_RELAY_ENABLED=true",
    "--dart-define=SOCKET_PRESENCE_LISTENER_ENABLED=true",
    "--dart-define=E2E_DISABLE_RELAY_DISPATCH=false",
]

HUB_HINTS = (
    "transportCode: timeout",
    "transportTimeout",
    "No response for clientRequestId",
    "TimeoutException",
    "HTTP 503",
    "HTTP 502",
    "HTTP 504",
    "rate_limited",
    "concurrent_handlers_exceeded",
    "queue_wait_timeout",
    "agent_disconnected",
    "RelayConversationLost",
    "RelayRequestRejected",
    "database_connection_failed",
    "circuitBreakerState",
    "isTransient=true",
)

APP_HINTS = (
    "Expected:",
    "TestFailure",
    "type 'Null' is not",
    "NoSuchMethodError",
    "Bad state:",
    "AssertionError",
    "FormatException",
    "StateError",
    "isA<",
)


def flutter_bin() -> str:
    return shutil_which("flutter") or "flutter"


def shutil_which(cmd: str) -> str | None:
    import shutil

    return shutil.which(cmd)


def classify(output: str, status: str) -> str:
    if status == "pass":
        return "ok"
    if status == "timeout":
        return "hub-likely (process timeout — relay/SQL hung)"
    low = output
    hub_hits = [h for h in HUB_HINTS if h in low]
    app_hits = [h for h in APP_HINTS if h in low]
    if hub_hits and not app_hits:
        return f"hub-likely ({', '.join(hub_hits[:2])})"
    if app_hits and not hub_hits:
        return f"app-likely ({', '.join(app_hits[:2])})"
    if hub_hits and app_hits:
        return f"mixed (hub={hub_hits[0]}; app={app_hits[0]})"
    # Soft e2e acceptance paths still count as pass for suite; hard fail here.
    if "All tests passed" in output:
        return "ok"
    return "unknown (inspect tail)"


def main() -> int:
    files = sorted(E2E_DIR.glob("*_e2e_test.dart"))
    # Also include support unit-style under e2e if tagged — stick to *_e2e_test.dart
    flutter = flutter_bin()
    rows: list[tuple[str, str, float, str]] = []
    print(f"Running {len(files)} E2E files on socket (timeout={TIMEOUT_S}s each)\n")
    for index, path in enumerate(files, start=1):
        label = path.name
        cmd = [
            flutter,
            "test",
            str(path),
            "--concurrency=1",
            *DEFINES,
        ]
        started = time.perf_counter()
        status = "pass"
        output = ""
        try:
            completed = subprocess.run(
                cmd,
                cwd=ROOT,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=TIMEOUT_S,
                check=False,
            )
            output = completed.stdout or ""
            status = "pass" if completed.returncode == 0 else "fail"
        except subprocess.TimeoutExpired as exc:
            status = "timeout"
            raw = exc.output
            if isinstance(raw, bytes):
                output = raw.decode("utf-8", errors="replace")
            else:
                output = raw or ""
        elapsed = time.perf_counter() - started
        kind = classify(output, status)
        rows.append((label, status, elapsed, kind))
        print(f"[{index:02d}/{len(files)}] {elapsed:6.1f}s  {status:7}  {kind}  {label}")
        sys.stdout.flush()

    print("\n## Summary\n")
    passed = [r for r in rows if r[1] == "pass"]
    failed = [r for r in rows if r[1] == "fail"]
    timed = [r for r in rows if r[1] == "timeout"]
    print(f"pass={len(passed)} fail={len(failed)} timeout={len(timed)} total={len(rows)}")
    if failed or timed:
        print("\n## Problems\n")
        print("| file | status | s | classification |")
        print("|---|---|---:|---|")
        for label, status, elapsed, kind in rows:
            if status == "pass":
                continue
            print(f"| `{label}` | {status} | {elapsed:.1f} | {kind} |")
    return 0 if not failed and not timed else 1


if __name__ == "__main__":
    raise SystemExit(main())
