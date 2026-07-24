#!/usr/bin/env python3
"""Automate the local Windows release flow for Colmeia."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Sequence

_TOOL_DIR = Path(__file__).resolve().parent
_INSTALLER_DIR = Path(__file__).resolve().parent.parent / "installer"
if str(_INSTALLER_DIR) not in sys.path:
    sys.path.insert(0, str(_INSTALLER_DIR))
if str(_TOOL_DIR) not in sys.path:
    sys.path.insert(0, str(_TOOL_DIR))

from pubspec_version import read_pubspec_versions

import ci_preflight as ci_preflight_tool

PROJECT_ROOT = Path(__file__).resolve().parent.parent
PUBSPEC_PATH = PROJECT_ROOT / "pubspec.yaml"
VERSION_RE = re.compile(
    r'^(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)\+(?P<build>\d+)$',
)
TAG_RE = re.compile(r"^v(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)$")


@dataclass(frozen=True, order=True)
class ReleaseVersion:
    major: int
    minor: int
    patch: int
    build: int

    @property
    def short(self) -> str:
        return f"{self.major}.{self.minor}.{self.patch}"

    @property
    def full(self) -> str:
        return f"{self.short}+{self.build}"

    @property
    def tag(self) -> str:
        return f"v{self.short}"

    @classmethod
    def parse(cls, raw: str) -> ReleaseVersion:
        match = VERSION_RE.fullmatch(raw.strip())
        if match is None:
            raise SystemExit(
                "Expected version in MAJOR.MINOR.PATCH+BUILD format, "
                f"got: {raw}",
            )
        return cls(
            major=int(match.group("major")),
            minor=int(match.group("minor")),
            patch=int(match.group("patch")),
            build=int(match.group("build")),
        )


def main() -> None:
    args = parse_args()
    current_version = read_current_version()
    target_version = (
        ReleaseVersion.parse(args.version)
        if args.version
        else suggest_next_patch_version(current_version, list_release_tags())
    )

    print(f"Current version: {current_version.full}")
    print(f"Target version:  {target_version.full}")
    print(f"Target tag:      {target_version.tag}")

    if args.dry_run:
        print_dry_run_checklist(args, target_version)
        return

    if args.allow_dirty:
        print(
            "WARNING: --allow-dirty is discouraged. Prefer a clean worktree "
            "so release commits only contain the version bump.",
            file=sys.stderr,
        )
    else:
        ensure_clean_worktree()

    ensure_tag_does_not_exist(target_version.tag)
    update_pubspec_version(PUBSPEC_PATH, target_version.full)
    run([sys.executable, "installer/update_version.py"])

    if not args.skip_preflight:
        # Full env validation (including local.env secrets) before tagging.
        run([sys.executable, "tool/ci_preflight.py"])

    if not args.skip_tests:
        flutter = ci_preflight_tool.resolve_flutter_command()
        run(
            [
                flutter,
                "test",
                "test/app",
                "test/core",
                "test/features",
                "test/shared",
                "test/integration/dart_test_config_contract_test.dart",
                "--exclude-tags",
                "e2e",
                "--reporter",
                "expanded",
            ],
        )

    if not args.skip_installer:
        run([sys.executable, "installer/build_installer.py"])

    short_version, _ = read_pubspec_versions(PUBSPEC_PATH)
    release_tag = f"v{short_version}"
    run(
        [
            "git",
            "add",
            "pubspec.yaml",
            "installer/setup.iss",
            "lib/core/constants/app_version.g.dart",
        ],
    )
    run(["git", "commit", "-m", f"chore: bump version to {short_version}"])

    if not args.skip_push:
        run(["git", "push", args.remote, args.branch])

    run(["git", "tag", release_tag])
    if not args.skip_push:
        run(["git", "push", args.remote, release_tag])

    print(f"Release flow completed for {release_tag}.")


def print_dry_run_checklist(
    args: argparse.Namespace,
    target_version: ReleaseVersion,
) -> None:
    dirty = run(["git", "status", "--short"], capture_output=True).strip()
    tag_exists = bool(
        run(["git", "tag", "--list", target_version.tag], capture_output=True).strip(),
    )

    print("")
    print("Dry-run checklist (no changes will be made):")
    print(f"  [ ] Bump pubspec + sync setup.iss / app_version.g.dart -> {target_version.full}")
    print(
        "  [ ] Run tool/ci_preflight.py"
        if not args.skip_preflight
        else "  [x] Skip preflight (--skip-preflight)",
    )
    print(
        "  [ ] Run flutter test (non-e2e)"
        if not args.skip_tests
        else "  [x] Skip tests (--skip-tests)",
    )
    print(
        "  [ ] Build Windows installer"
        if not args.skip_installer
        else "  [x] Skip installer (--skip-installer)",
    )
    print(f"  [ ] Commit chore: bump version to {target_version.short}")
    if args.skip_push:
        print("  [x] Skip push (--skip-push)")
    else:
        print(f"  [ ] Push {args.branch} to {args.remote}")
        print(f"  [ ] Create and push tag {target_version.tag}")

    print("")
    print("Guards:")
    if dirty:
        status = "DIRTY (blocked unless --allow-dirty)"
        if args.allow_dirty:
            status = "DIRTY (--allow-dirty set; discouraged)"
        print(f"  worktree: {status}")
        for line in dirty.splitlines()[:12]:
            print(f"    {line}")
    else:
        print("  worktree: clean")
    print(
        f"  tag {target_version.tag}: "
        f"{'ALREADY EXISTS (will fail)' if tag_exists else 'available'}",
    )
    print("")
    print("Re-run without --dry-run to execute.")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Prepare, validate, build, commit, and tag a Windows release.",
    )
    parser.add_argument(
        "--version",
        help=(
            "Override the target version in MAJOR.MINOR.PATCH+BUILD format. "
            "When omitted, the script suggests the next patch after the latest tag "
            "and increments the current build number."
        ),
    )
    parser.add_argument("--remote", default="origin")
    parser.add_argument("--branch", default="main")
    parser.add_argument(
        "--allow-dirty",
        action="store_true",
        help=(
            "Allow releasing with a dirty worktree. Discouraged; prefer "
            "committing or stashing unrelated changes first."
        ),
    )
    parser.add_argument("--skip-tests", action="store_true")
    parser.add_argument(
        "--skip-preflight",
        action="store_true",
        help="Skip env/format/version-sync gates (tool/ci_preflight.py).",
    )
    parser.add_argument("--skip-installer", action="store_true")
    parser.add_argument("--skip-push", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def read_current_version() -> ReleaseVersion:
    _, full_version = read_pubspec_versions(PUBSPEC_PATH)
    return ReleaseVersion.parse(full_version)


def list_release_tags() -> list[str]:
    output = run(["git", "tag", "--list", "v*.*.*"], capture_output=True)
    return [line.strip() for line in output.splitlines() if line.strip()]


def suggest_next_patch_version(
    current_version: ReleaseVersion,
    release_tags: Sequence[str],
) -> ReleaseVersion:
    latest_tag = latest_release_tag(release_tags)
    if latest_tag is None:
        return ReleaseVersion(
            current_version.major,
            current_version.minor,
            current_version.patch,
            current_version.build + 1,
        )

    return ReleaseVersion(
        latest_tag.major,
        latest_tag.minor,
        latest_tag.patch + 1,
        current_version.build + 1,
    )


def latest_release_tag(release_tags: Sequence[str]) -> ReleaseVersion | None:
    parsed_tags: list[ReleaseVersion] = []
    for tag in release_tags:
        match = TAG_RE.fullmatch(tag.strip())
        if match is None:
            continue
        parsed_tags.append(
            ReleaseVersion(
                major=int(match.group("major")),
                minor=int(match.group("minor")),
                patch=int(match.group("patch")),
                build=0,
            ),
        )
    if not parsed_tags:
        return None
    return max(parsed_tags)


def ensure_clean_worktree() -> None:
    output = run(["git", "status", "--short"], capture_output=True)
    if output.strip():
        raise SystemExit(
            "Working tree is not clean. Commit or stash changes, or rerun with "
            "--allow-dirty if that is intentional (discouraged).",
        )


def ensure_tag_does_not_exist(tag: str) -> None:
    existing = run(["git", "tag", "--list", tag], capture_output=True).strip()
    if existing:
        raise SystemExit(f"Tag already exists: {tag}")


def update_pubspec_version(pubspec_path: Path, full_version: str) -> None:
    content = pubspec_path.read_text(encoding="utf-8")
    new_content, replacements = re.subn(
        r'(^version:\s*["\']?)(\d+\.\d+\.\d+(?:\+\d+)?)(["\']?\s*(?:#.*)?$)',
        rf"\g<1>{full_version}\g<3>",
        content,
        count=1,
        flags=re.MULTILINE,
    )
    if replacements != 1:
        raise SystemExit("Could not update the version line in pubspec.yaml")
    pubspec_path.write_text(new_content, encoding="utf-8")


def run(command: Sequence[str], *, capture_output: bool = False) -> str:
    kwargs = {
        "cwd": PROJECT_ROOT,
        "check": True,
        "text": True,
    }
    if capture_output:
        kwargs["capture_output"] = True

    try:
        completed = subprocess.run(list(command), **kwargs)
    except FileNotFoundError as error:
        raise SystemExit(f"Command not found: {command[0]}") from error
    except subprocess.CalledProcessError as error:
        raise SystemExit(error.returncode) from error

    return completed.stdout if capture_output else ""


if __name__ == "__main__":
    main()
