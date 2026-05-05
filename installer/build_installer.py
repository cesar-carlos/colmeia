#!/usr/bin/env python3
"""
Build the Windows installer for Colmeia.

Flow:
1. Synchronize versioned files from pubspec.yaml (unless COLMEIA_SKIP_VERSION_SYNC=1)
2. Generate multi-resolution ICO files (`app_icon.ico` + `installer/setup_icon.ico`)
3. Build `flutter build windows --release`
4. Regenerate ICO files (Flutter may overwrite `windows/runner/.../app_icon.ico`; Inno uses `setup_icon.ico`)
5. Compile the Inno Setup installer (clears previous `Colmeia-Setup-*.exe` in dist first)

Output:
    installer/dist/Colmeia-Setup-{MAJOR.MINOR.PATCH}.exe
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Optional, Sequence

PROJECT_ROOT = Path(__file__).resolve().parent.parent
INSTALLER_DIR = PROJECT_ROOT / "installer"
BUILD_DIR = PROJECT_ROOT / "build" / "windows" / "x64" / "runner" / "Release"
DIST_DIR = INSTALLER_DIR / "dist"
SETUP_ISS = INSTALLER_DIR / "setup.iss"
RELEASE_ENV_FILE = PROJECT_ROOT / ".env.release"
RELEASE_ENV_OVERRIDE_VAR = "COLMEIA_RELEASE_ENV_FILE"
SKIP_VERSION_SYNC_VAR = "COLMEIA_SKIP_VERSION_SYNC"
BUNDLED_LOCAL_ENV = PROJECT_ROOT / "assets" / "env" / "local.env"
WINDOWS_BINARY_NAME = "colmeia.exe"
INSTALLER_GLOB = "Colmeia-Setup-*.exe"

ISCC_PATHS = (
    "ISCC",
    r"C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    r"C:\Program Files\Inno Setup 6\ISCC.exe",
)


def main() -> None:
    if _skip_version_sync():
        print(
            "1. Skipping version sync (COLMEIA_SKIP_VERSION_SYNC=1)...",
            flush=True,
        )
    else:
        print("1. Synchronizing installer/version files...", flush=True)
        run([sys.executable, str(INSTALLER_DIR / "update_version.py")])

    print("\n2. Windows multi-resolution ICO (runner + Inno)...", flush=True)
    run(["dart", "run", "tool/generate_windows_app_icon.dart"])

    print("\n3. Building Flutter Windows release...", flush=True)
    warn_if_bundled_local_env_has_entries()

    flutter_command = ["flutter", "build", "windows", "--release"]
    if feed_url := resolve_auto_update_feed_url():
        flutter_command.append(f"--dart-define=AUTO_UPDATE_FEED_URL={feed_url}")
        print(f"   AUTO_UPDATE_FEED_URL={feed_url}", flush=True)
    else:
        print(
            "   AUTO_UPDATE_FEED_URL not configured. "
            "Windows auto-update will stay disabled in this build.",
            flush=True,
        )
    run(flutter_command)

    binary_path = BUILD_DIR / WINDOWS_BINARY_NAME
    if not BUILD_DIR.exists():
        raise SystemExit(f"Build output folder not found: {BUILD_DIR}")
    if not binary_path.exists():
        raise SystemExit(f"Windows binary not found: {binary_path}")

    print(
        "\n4. Refresh ICO files (Flutter may overwrite runner/app_icon.ico; "
        "Inno uses installer/setup_icon.ico)...",
        flush=True,
    )
    run(["dart", "run", "tool/generate_windows_app_icon.dart"])

    print("\n5. Compiling Inno Setup installer...", flush=True)
    DIST_DIR.mkdir(parents=True, exist_ok=True)
    clear_previous_installer_outputs()
    run([find_iscc(), str(SETUP_ISS)], cwd=INSTALLER_DIR)

    installer_path = find_generated_installer()
    print(f"\nInstaller generated at: {installer_path}", flush=True)


def _skip_version_sync() -> bool:
    return os.environ.get(SKIP_VERSION_SYNC_VAR, "").strip() == "1"


def warn_if_bundled_local_env_has_entries() -> None:
    if not BUNDLED_LOCAL_ENV.is_file():
        return
    has_entry = any(
        line.strip() and not line.strip().startswith("#")
        for line in BUNDLED_LOCAL_ENV.read_text(encoding="utf-8").splitlines()
    )
    if not has_entry:
        return
    print(
        "   WARNING: assets/env/local.env contains entries and may be bundled "
        "(pubspec assets). Review secrets before distributing this build.",
        flush=True,
    )


def clear_previous_installer_outputs() -> None:
    if not DIST_DIR.is_dir():
        return
    for pattern in (INSTALLER_GLOB, "Colmeia-Setup-*.exe.sha256"):
        for path in DIST_DIR.glob(pattern):
            path.unlink()


def resolve_auto_update_feed_url() -> Optional[str]:
    return read_env_value("AUTO_UPDATE_FEED_URL")


def read_env_value(key: str) -> Optional[str]:
    process_value = normalize_env_value(os.environ.get(key))
    if process_value:
        return process_value

    for env_file in resolve_env_files():
        for raw_line in env_file.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            env_key, value = line.split("=", 1)
            if env_key.strip() != key:
                continue
            normalized = normalize_env_value(value)
            if normalized:
                return normalized
    return None


def resolve_env_files() -> list[Path]:
    candidates: list[Path] = []

    override = normalize_env_value(os.environ.get(RELEASE_ENV_OVERRIDE_VAR))
    if override:
        override_path = Path(override)
        if not override_path.is_absolute():
            override_path = PROJECT_ROOT / override_path
        if not override_path.exists():
            raise SystemExit(
                f"{RELEASE_ENV_OVERRIDE_VAR} points to a missing file: {override_path}",
            )
        candidates.append(override_path)

    if RELEASE_ENV_FILE.exists() and RELEASE_ENV_FILE not in candidates:
        candidates.append(RELEASE_ENV_FILE)

    return candidates


def normalize_env_value(raw: Optional[str]) -> Optional[str]:
    if raw is None:
        return None
    normalized = raw.strip().strip('"').strip("'")
    return normalized or None


def find_iscc() -> str:
    for candidate in ISCC_PATHS:
        if candidate == "ISCC":
            if shutil.which("ISCC"):
                return "ISCC"
            continue
        if Path(candidate).exists():
            return candidate
    raise SystemExit(
        "Inno Setup (ISCC) was not found. "
        "Install Inno Setup 6 and ensure ISCC is on PATH."
    )


def find_generated_installer() -> Path:
    candidates = sorted(
        DIST_DIR.glob(INSTALLER_GLOB),
        key=lambda path: path.stat().st_mtime,
        reverse=True,
    )
    if not candidates:
        raise SystemExit(f"No installer matching {INSTALLER_GLOB} was found.")
    return candidates[0]


def resolve_command(command: Sequence[str]) -> list[str]:
    args = list(command)
    if not args:
        raise SystemExit("Empty command")

    executable = args[0]
    if Path(executable).parent == Path("."):
        executable = shutil.which(executable) or executable

    if Path(executable).suffix.lower() in {".bat", ".cmd"}:
        return ["cmd.exe", "/d", "/c", executable, *args[1:]]

    return [executable, *args[1:]]


def run(command: Sequence[str], cwd: Optional[Path] = None) -> None:
    resolved = resolve_command(command)
    try:
        subprocess.run(
            resolved,
            cwd=cwd or PROJECT_ROOT,
            check=True,
        )
    except FileNotFoundError as error:
        raise SystemExit(f"Command not found: {resolved[0]}") from error
    except subprocess.CalledProcessError as error:
        raise SystemExit(error.returncode) from error


if __name__ == "__main__":
    main()
