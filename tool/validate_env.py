#!/usr/bin/env python3
"""Validate Colmeia env templates and local-env safety."""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
ENV_KEYS_FILE = REPO_ROOT / "lib" / "core" / "config" / "env_keys.dart"
ASSETS_ENV_EXAMPLE = REPO_ROOT / "assets" / "env" / ".env.example"
ASSETS_DEFAULT_ENV = REPO_ROOT / "assets" / "env" / "default.env"
ASSETS_LOCAL_ENV = REPO_ROOT / "assets" / "env" / "local.env"
PUBSPEC = REPO_ROOT / "pubspec.yaml"

ENV_KEY_PATTERN = re.compile(r"'([A-Z][A-Z0-9_]+)'")
ENV_LINE_PATTERN = re.compile(r"^([A-Z][A-Z0-9_]*)\s*=(.*)$")
SENSITIVE_KEY_PATTERN = re.compile(
    r"(TOKEN|PASSWORD|SECRET|SIGNING_KEY|PRIVATE_KEY|DSN)",
)


@dataclass(frozen=True)
class EnvLine:
    key: str
    value: str
    line_number: int


def main() -> int:
    errors = validate_repo()
    if errors:
        for error in errors:
            print(f"env validation error: {error}", file=sys.stderr)
        return 1
    print("Env validation passed.")
    return 0


def validate_repo(root: Path = REPO_ROOT) -> list[str]:
    env_keys_file = root / ENV_KEYS_FILE.relative_to(REPO_ROOT)
    assets_env_example = root / ASSETS_ENV_EXAMPLE.relative_to(REPO_ROOT)
    assets_default_env = root / ASSETS_DEFAULT_ENV.relative_to(REPO_ROOT)
    assets_local_env = root / ASSETS_LOCAL_ENV.relative_to(REPO_ROOT)
    pubspec = root / PUBSPEC.relative_to(REPO_ROOT)

    errors: list[str] = []
    declared_keys = parse_declared_env_keys(env_keys_file)
    if not declared_keys:
        errors.append(f"no EnvKeys constants found in {env_keys_file}")
        return errors

    for env_file in (assets_env_example, assets_default_env):
        template_keys = {line.key for line in parse_env_lines(env_file, include_comments=True)}
        missing = sorted(declared_keys - template_keys)
        if missing:
            errors.append(
                f"{env_file.relative_to(root)} is missing template keys: "
                + ", ".join(missing),
            )

    for env_file in (
        assets_env_example,
        assets_default_env,
        assets_local_env,
        root / ".env.example",
        root / ".env.release",
        root / ".env",
    ):
        if env_file.exists():
            errors.extend(validate_env_file_shape(env_file, root=root))

    if pubspec.exists() and "assets/env/local.env" in pubspec.read_text(
        encoding="utf-8",
    ):
        errors.append(
            "pubspec.yaml must not register assets/env/local.env; "
            "it can bundle local secrets into release builds",
        )

    if assets_local_env.exists():
        for line in parse_env_lines(assets_local_env, include_comments=False):
            if line.value and SENSITIVE_KEY_PATTERN.search(line.key):
                errors.append(
                    f"{assets_local_env.relative_to(root)}:{line.line_number} "
                    f"has active sensitive key {line.key}; use process env "
                    "or --dart-define instead",
                )

    return errors


def parse_declared_env_keys(path: Path) -> set[str]:
    if not path.exists():
        return set()
    return set(ENV_KEY_PATTERN.findall(path.read_text(encoding="utf-8")))


def parse_env_lines(path: Path, *, include_comments: bool) -> list[EnvLine]:
    if not path.exists():
        return []

    lines: list[EnvLine] = []
    for index, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("#"):
            if not include_comments:
                continue
            line = line.lstrip("#").strip()
        match = ENV_LINE_PATTERN.match(line)
        if match is None:
            continue
        lines.append(
            EnvLine(
                key=match.group(1).strip(),
                value=match.group(2).strip(),
                line_number=index,
            ),
        )
    return lines


def validate_env_file_shape(path: Path, *, root: Path) -> list[str]:
    errors: list[str] = []
    seen: dict[str, int] = {}
    for index, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        match = ENV_LINE_PATTERN.match(line)
        if match is None:
            errors.append(f"{path.relative_to(root)}:{index} is not KEY=value")
            continue
        key = match.group(1).strip()
        previous = seen.get(key)
        if previous is not None:
            errors.append(
                f"{path.relative_to(root)}:{index} duplicates {key} "
                f"from line {previous}",
            )
        seen[key] = index
    return errors


if __name__ == "__main__":
    raise SystemExit(main())
