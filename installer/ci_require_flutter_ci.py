#!/usr/bin/env python3
"""Wait for / require a successful Flutter CI run for a given commit SHA."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
import time
from typing import Any


def main() -> int:
    args = parse_args()
    deadline = time.monotonic() + args.timeout_seconds

    while True:
        runs = list_flutter_ci_runs(args.sha, limit=args.limit)
        if any(run.get("conclusion") == "success" for run in runs):
            print(f"Flutter CI succeeded for {args.sha}.")
            return 0

        in_progress = [
            run
            for run in runs
            if run.get("status") in {"queued", "in_progress", "waiting", "pending"}
        ]
        failed = [
            run
            for run in runs
            if run.get("status") == "completed"
            and run.get("conclusion") not in {None, "success", "skipped", "neutral"}
        ]

        if failed and not in_progress:
            print(
                f"Flutter CI failed for {args.sha}. "
                "Fix CI on main before publishing this tag.",
                file=sys.stderr,
            )
            for run in failed[:3]:
                print(
                    f"  - conclusion={run.get('conclusion')} url={run.get('url')}",
                    file=sys.stderr,
                )
            return 1

        if time.monotonic() >= deadline:
            print(
                f"Timed out waiting for Flutter CI on {args.sha} "
                f"after {args.timeout_seconds}s.",
                file=sys.stderr,
            )
            if not runs:
                print(
                    "No Flutter CI runs found for this commit yet.",
                    file=sys.stderr,
                )
            return 1

        print(
            f"Waiting for Flutter CI on {args.sha} "
            f"({len(in_progress)} in progress, {len(runs)} total)...",
        )
        time.sleep(args.poll_seconds)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Require a successful Flutter CI run for a commit SHA.",
    )
    parser.add_argument("--sha", required=True)
    parser.add_argument("--timeout-seconds", type=int, default=900)
    parser.add_argument("--poll-seconds", type=int, default=20)
    parser.add_argument("--limit", type=int, default=10)
    return parser.parse_args()


def list_flutter_ci_runs(sha: str, *, limit: int) -> list[dict[str, Any]]:
    completed = subprocess.run(
        [
            "gh",
            "run",
            "list",
            "--workflow=flutter_ci.yml",
            f"--commit={sha}",
            f"--limit={limit}",
            "--json",
            "conclusion,status,url,databaseId,displayTitle",
        ],
        check=False,
        capture_output=True,
        text=True,
    )
    if completed.returncode != 0:
        raise SystemExit(
            "Failed to query Flutter CI runs via gh: "
            + (completed.stderr or completed.stdout or "unknown error"),
        )
    payload = json.loads(completed.stdout or "[]")
    if not isinstance(payload, list):
        raise SystemExit("Unexpected gh run list payload")
    return payload


if __name__ == "__main__":
    raise SystemExit(main())
