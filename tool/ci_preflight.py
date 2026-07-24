#!/usr/bin/env python3
"""Run the local checks that Flutter CI analyze fails on most often.

Mirrors the cheap gates from `.github/workflows/flutter_ci.yml`:
- env template sync (`tool/validate_env.py`)
- dart format
- versioned Windows release file sync
- optional `flutter analyze`

Use before push/release:

    python tool/ci_preflight.py
    python tool/ci_preflight.py --analyze
    python tool/ci_preflight.py --templates-only
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Callable, Sequence


PROJECT_ROOT = Path(__file__).resolve().parent.parent


def main() -> int:
    args = parse_args()
    failures: list[str] = []

    if not args.skip_env:
        failures.extend(
            _run_step(
                "env templates",
                lambda: _validate_env(templates_only=args.templates_only),
            ),
        )
    if not args.skip_format:
        failures.extend(_run_step("dart format", _check_dart_format))
    if not args.skip_version_sync:
        failures.extend(_run_step("version sync", _check_version_sync))
    if args.analyze:
        failures.extend(_run_step("flutter analyze", _flutter_analyze))

    if failures:
        print("\nCI preflight failed:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        print(
            "\nFix the issues above, or run the suggested commands, then retry.",
            file=sys.stderr,
        )
        return 1

    print("CI preflight passed.")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Local mirror of Flutter CI analyze gates "
            "(env templates, dart format, version sync)."
        ),
    )
    parser.add_argument(
        "--analyze",
        action="store_true",
        help="Also run flutter analyze --fatal-warnings --no-fatal-infos.",
    )
    parser.add_argument(
        "--templates-only",
        action="store_true",
        help=(
            "Skip active-secret checks in assets/env/local.env. "
            "Still validates EnvKeys vs default.env / .env.example."
        ),
    )
    parser.add_argument("--skip-env", action="store_true")
    parser.add_argument("--skip-format", action="store_true")
    parser.add_argument("--skip-version-sync", action="store_true")
    return parser.parse_args()


def _run_step(name: str, fn: Callable[[], None]) -> list[str]:
    print(f"==> {name}")
    try:
        fn()
    except SystemExit as error:
        code = error.code if isinstance(error.code, int) else 1
        if code == 0:
            return []
        return [f"{name} failed (exit {code})"]
    except Exception as error:  # noqa: BLE001 - surface any step failure
        return [f"{name} failed: {error}"]
    return []


def _validate_env(*, templates_only: bool) -> None:
    command = [sys.executable, "tool/validate_env.py"]
    if templates_only:
        command.append("--templates-only")
    run(command)


def _check_dart_format() -> None:
    dart = resolve_dart_command()
    completed = run(
        [
            dart,
            "format",
            "--output=none",
            "--set-exit-if-changed",
            "lib",
            "test",
        ],
        check=False,
    )
    if completed.returncode != 0:
        print(
            "Format drift detected. Run: dart format lib test",
            file=sys.stderr,
        )
        raise SystemExit(completed.returncode)


def _check_version_sync() -> None:
    run([sys.executable, "installer/update_version.py"])
    completed = run(
        [
            "git",
            "diff",
            "--exit-code",
            "--",
            "installer/setup.iss",
            "lib/core/constants/app_version.g.dart",
        ],
        check=False,
    )
    if completed.returncode != 0:
        print(
            "Versioned release files are out of sync with pubspec.yaml. "
            "Run: python installer/update_version.py",
            file=sys.stderr,
        )
        raise SystemExit(completed.returncode)


def _flutter_analyze() -> None:
    flutter = resolve_flutter_command()
    run(
        [
            flutter,
            "analyze",
            "--fatal-warnings",
            "--no-fatal-infos",
        ],
    )


def resolve_flutter_command() -> str:
    return _resolve_sdk_command("flutter")


def resolve_dart_command() -> str:
    return _resolve_sdk_command("dart")


def _resolve_sdk_command(name: str) -> str:
    found = shutil.which(name)
    if found is not None:
        return found

    if os.name == "nt":
        bat = shutil.which(f"{name}.bat")
        if bat is not None:
            return bat
        for candidate in _windows_flutter_candidates(name):
            if candidate.is_file():
                return str(candidate)

    raise SystemExit(
        f"Command not found: {name}. On Windows, run "
        "`tool/env_windows.ps1` in the shell first, or add Flutter to PATH.",
    )


def _windows_flutter_candidates(name: str) -> list[Path]:
    home = Path.home()
    return [
        home / "dev" / "flutter" / "bin" / f"{name}.bat",
        home / "flutter" / "bin" / f"{name}.bat",
        Path(r"C:\flutter\bin") / f"{name}.bat",
        Path(os.environ.get("LOCALAPPDATA", "")) / "flutter" / "bin" / f"{name}.bat",
    ]


def run(
    command: Sequence[str],
    *,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            list(command),
            cwd=PROJECT_ROOT,
            check=check,
            text=True,
        )
    except FileNotFoundError as error:
        raise SystemExit(f"Command not found: {command[0]}") from error
    except subprocess.CalledProcessError as error:
        raise SystemExit(error.returncode) from error


if __name__ == "__main__":
    raise SystemExit(main())
