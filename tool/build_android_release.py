#!/usr/bin/env python3
"""Build signed Android release artifacts and export them to installer/dist."""

from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Sequence

_INSTALLER_DIR = Path(__file__).resolve().parent.parent / "installer"
if str(_INSTALLER_DIR) not in sys.path:
    sys.path.insert(0, str(_INSTALLER_DIR))

from pubspec_version import read_pubspec_versions


PROJECT_ROOT = Path(__file__).resolve().parent.parent
PUBSPEC_PATH = PROJECT_ROOT / "pubspec.yaml"
DIST_DIR = PROJECT_ROOT / "installer" / "dist"
APK_BUILD_OUTPUT = PROJECT_ROOT / "build" / "app" / "outputs" / "flutter-apk" / "app-release.apk"
AAB_BUILD_OUTPUT = PROJECT_ROOT / "build" / "app" / "outputs" / "bundle" / "release" / "app-release.aab"


def main() -> None:
    args = parse_args()
    short_version, _ = read_pubspec_versions(PUBSPEC_PATH)
    formats = resolve_requested_formats(args)
    DIST_DIR.mkdir(parents=True, exist_ok=True)

    exported_paths: list[Path] = []
    for artifact_format in formats:
        if not args.skip_build:
            run(build_command(artifact_format))

        source_path = build_output_path(artifact_format)
        if not source_path.exists():
            raise SystemExit(
                f"Expected Android release artifact was not found: {source_path}",
            )

        destination_path = DIST_DIR / release_asset_name(
            artifact_format,
            short_version,
        )
        export_artifact(source_path, destination_path)
        checksum_path = write_sha256_file(destination_path)
        exported_paths.extend([destination_path, checksum_path])

    for path in exported_paths:
        print(path)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Build signed Android release artifacts and copy them to installer/dist."
        ),
    )
    parser.add_argument(
        "--apk",
        action="store_true",
        help="Build/export the APK artifact.",
    )
    parser.add_argument(
        "--aab",
        action="store_true",
        help="Build/export the App Bundle artifact.",
    )
    parser.add_argument(
        "--skip-build",
        action="store_true",
        help="Reuse existing build/app outputs and only export to installer/dist.",
    )
    return parser.parse_args()


def resolve_requested_formats(args: argparse.Namespace) -> list[str]:
    formats: list[str] = []
    if args.apk:
        formats.append("apk")
    if args.aab:
        formats.append("aab")
    return formats or ["apk", "aab"]


def release_dart_defines() -> list[str]:
    """Forward CI secrets as compile-time defines.

    CI example (GitHub Actions)::

        env:
          SENTRY_DSN: ${{ secrets.SENTRY_DSN }}
        run: python tool/build_android_release.py --apk

    When ``SENTRY_DSN`` is set in the environment, this script passes
    ``--dart-define=SENTRY_DSN=<value>`` to ``flutter build`` so release
    artifacts ship with Sentry enabled without storing the DSN in the repo.
  """
    defines: list[str] = []
    sentry_dsn = os.environ.get("SENTRY_DSN", "").strip()
    if sentry_dsn:
        defines.extend(["--dart-define", f"SENTRY_DSN={sentry_dsn}"])
    return defines


def build_command(artifact_format: str) -> list[str]:
    if artifact_format == "apk":
        command = ["flutter", "build", "apk", "--release"]
    elif artifact_format == "aab":
        command = ["flutter", "build", "appbundle", "--release"]
    else:
        raise SystemExit(f"Unsupported Android artifact format: {artifact_format}")
    return command + release_dart_defines()


def build_output_path(artifact_format: str) -> Path:
    if artifact_format == "apk":
        return APK_BUILD_OUTPUT
    if artifact_format == "aab":
        return AAB_BUILD_OUTPUT
    raise SystemExit(f"Unsupported Android artifact format: {artifact_format}")


def release_asset_name(artifact_format: str, short_version: str) -> str:
    if artifact_format == "apk":
        return f"Colmeia-Android-{short_version}.apk"
    if artifact_format == "aab":
        return f"Colmeia-Android-{short_version}.aab"
    raise SystemExit(f"Unsupported Android artifact format: {artifact_format}")


def export_artifact(source_path: Path, destination_path: Path) -> None:
    shutil.copy2(source_path, destination_path)


def write_sha256_file(asset_path: Path) -> Path:
    digest = hashlib.sha256(asset_path.read_bytes()).hexdigest()
    checksum_path = asset_path.with_name(f"{asset_path.name}.sha256")
    checksum_path.write_text(digest, encoding="utf-8")
    return checksum_path


def run(command: Sequence[str]) -> None:
    try:
        subprocess.run(
            list(command),
            cwd=PROJECT_ROOT,
            check=True,
        )
    except FileNotFoundError as error:
        raise SystemExit(f"Command not found: {command[0]}") from error
    except subprocess.CalledProcessError as error:
        raise SystemExit(error.returncode) from error


if __name__ == "__main__":
    main()
