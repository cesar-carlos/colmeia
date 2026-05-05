#!/usr/bin/env python3
"""Emit GitHub Actions step outputs for `prepare_release` (tagged release workflow)."""

from __future__ import annotations

import os
import sys
from pathlib import Path

_INSTALLER_DIR = Path(__file__).resolve().parent
if str(_INSTALLER_DIR) not in sys.path:
    sys.path.insert(0, str(_INSTALLER_DIR))

from pubspec_version import read_pubspec_versions


def emit_release_metadata(
    *,
    repo_root: Path,
    github_output: Path,
    release_tag: str,
    repository: str,
) -> None:
    pubspec_path = repo_root / "pubspec.yaml"
    short_version, full_version = read_pubspec_versions(pubspec_path)

    expected_tag = f"v{short_version}"
    if release_tag != expected_tag:
        raise SystemExit(
            f"Tag {release_tag} does not match pubspec.yaml version {short_version}",
        )

    windows_asset_name = f"Colmeia-Setup-{short_version}.exe"
    android_apk_asset_name = f"Colmeia-Android-{short_version}.apk"
    android_aab_asset_name = f"Colmeia-Android-{short_version}.aab"
    release_title = f"Version {short_version}"
    release_url = f"https://github.com/{repository}/releases/tag/{release_tag}"
    windows_asset_url = (
        f"https://github.com/{repository}/releases/download/"
        f"{release_tag}/{windows_asset_name}"
    )

    with github_output.open("a", encoding="utf-8") as output:
        output.write(f"full_version={full_version}\n")
        output.write(f"short_version={short_version}\n")
        output.write(f"release_title={release_title}\n")
        output.write(f"release_tag={release_tag}\n")
        output.write(f"windows_asset_name={windows_asset_name}\n")
        output.write(f"android_apk_asset_name={android_apk_asset_name}\n")
        output.write(f"android_aab_asset_name={android_aab_asset_name}\n")
        output.write(f"release_url={release_url}\n")
        output.write(f"windows_asset_url={windows_asset_url}\n")


def main() -> None:
    repo_root = Path(__file__).resolve().parent.parent
    emit_release_metadata(
        repo_root=repo_root,
        github_output=Path(os.environ["GITHUB_OUTPUT"]),
        release_tag=os.environ["GITHUB_REF_NAME"],
        repository=os.environ["GITHUB_REPOSITORY"],
    )


if __name__ == "__main__":
    main()
