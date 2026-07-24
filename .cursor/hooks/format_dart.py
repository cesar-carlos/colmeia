#!/usr/bin/env python3
"""Cursor afterFileEdit hook: dart format touched .dart files."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 0

    file_path = payload.get("file_path") or payload.get("filePath") or ""
    if not isinstance(file_path, str) or not file_path.endswith(".dart"):
        return 0

    path = Path(file_path)
    if not path.is_file():
        return 0

    dart = _resolve_dart()
    if dart is None:
        return 0

    try:
        subprocess.run(
            [dart, "format", str(path)],
            check=False,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except OSError:
        return 0
    return 0


def _resolve_dart() -> str | None:
    found = shutil.which("dart")
    if found:
        return found
    if os.name == "nt":
        bat = shutil.which("dart.bat")
        if bat:
            return bat
        candidate = Path.home() / "dev" / "flutter" / "bin" / "dart.bat"
        if candidate.is_file():
            return str(candidate)
    return None


if __name__ == "__main__":
    raise SystemExit(main())
