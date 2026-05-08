#!/usr/bin/env python3
"""Copy assets/env/.env.example to local.env if missing.

The file is intentionally not registered as a Flutter asset by default. Prefer
--dart-define or process env for local overrides, and only add local.env to
pubspec.yaml in an uncommitted local-only change if you need bundled overrides.
"""

from __future__ import annotations

import sys
from pathlib import Path


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    example = repo_root / "assets" / "env" / ".env.example"
    target = repo_root / "assets" / "env" / "local.env"

    if not example.is_file():
        print(f"Missing {example}", file=sys.stderr)
        return 1

    if target.is_file():
        print("assets/env/local.env already exists; left unchanged.")
        return 0

    target.write_text(example.read_text(encoding="utf-8"), encoding="utf-8")
    print("Created assets/env/local.env from .env.example.")
    print("Note: local.env is not bundled unless you add it to pubspec.yaml.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
