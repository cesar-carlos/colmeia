#!/usr/bin/env python3
"""Build a signed iOS App Store IPA and export it to installer/dist."""

from __future__ import annotations

import argparse
import hashlib
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
EXPORT_OPTIONS_PLIST = PROJECT_ROOT / "ios" / "ExportOptions-appstore.plist"
IPA_BUILD_OUTPUT = PROJECT_ROOT / "build" / "ios" / "ipa" / "colmeia.ipa"


def main() -> None:
    args = parse_args()
    short_version, _ = read_pubspec_versions(PUBSPEC_PATH)
    DIST_DIR.mkdir(parents=True, exist_ok=True)

    if not args.skip_build:
        run(
            [
                "flutter",
                "build",
                "ipa",
                f"--export-options-plist={EXPORT_OPTIONS_PLIST}",
            ],
        )

    if not IPA_BUILD_OUTPUT.exists():
        raise SystemExit(
            f"Expected iOS release artifact was not found: {IPA_BUILD_OUTPUT}",
        )

    destination_path = DIST_DIR / release_asset_name(short_version)
    export_artifact(IPA_BUILD_OUTPUT, destination_path)
    checksum_path = write_sha256_file(destination_path)
    print(destination_path)
    print(checksum_path)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Build a signed iOS App Store IPA and copy it to installer/dist."
        ),
    )
    parser.add_argument(
        "--skip-build",
        action="store_true",
        help="Reuse build/ios/ipa output and only export to installer/dist.",
    )
    return parser.parse_args()


def release_asset_name(short_version: str) -> str:
    return f"Colmeia-iOS-{short_version}.ipa"


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
