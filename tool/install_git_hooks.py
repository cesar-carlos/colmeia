#!/usr/bin/env python3
"""Install Colmeia git hooks into .git/hooks (local only, not committed)."""

from __future__ import annotations

import shutil
import stat
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent
HOOKS_SRC = PROJECT_ROOT / "tool" / "git-hooks"
GIT_HOOKS = PROJECT_ROOT / ".git" / "hooks"


def main() -> int:
    if not (PROJECT_ROOT / ".git").exists():
        print("Not a git repository.", file=sys.stderr)
        return 1
    if not HOOKS_SRC.is_dir():
        print(f"Missing hooks source: {HOOKS_SRC}", file=sys.stderr)
        return 1

    GIT_HOOKS.mkdir(parents=True, exist_ok=True)
    installed: list[str] = []
    for source in sorted(HOOKS_SRC.iterdir()):
        if not source.is_file() or source.name.startswith("."):
            continue
        destination = GIT_HOOKS / source.name
        shutil.copy2(source, destination)
        mode = destination.stat().st_mode
        destination.chmod(mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
        installed.append(source.name)

    if not installed:
        print("No hooks found to install.", file=sys.stderr)
        return 1

    print("Installed git hooks:")
    for name in installed:
        print(f"  - {name}")
    print("Pre-push now runs: python tool/ci_preflight.py --templates-only")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
