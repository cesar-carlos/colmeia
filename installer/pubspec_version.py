"""Shared `pubspec.yaml` version parsing for installer tooling."""

from __future__ import annotations

import re
from pathlib import Path

_VERSION_LINE_RE = re.compile(
    r'^version:\s*["\']?(\d+\.\d+\.\d+(?:\+\d+)?)["\']?\s*(?:#|$)',
    re.MULTILINE,
)


def read_pubspec_versions(pubspec_path: Path) -> tuple[str, str]:
    """Return `(short_version, full_version)` e.g. ``('1.2.3', '1.2.3+4')``."""
    if not pubspec_path.exists():
        raise SystemExit(f"pubspec.yaml not found: {pubspec_path}")

    content = pubspec_path.read_text(encoding="utf-8")
    match = _VERSION_LINE_RE.search(content)
    if match is None:
        raise SystemExit("version was not found in pubspec.yaml")

    full_version = match.group(1).strip()
    short_version = full_version.split("+", maxsplit=1)[0]
    return short_version, full_version
