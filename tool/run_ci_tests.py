"""Run the same local Flutter suite on development machines and CI shards."""

from __future__ import annotations

import argparse
import os
import subprocess
from pathlib import Path

import ci_preflight


PROJECT_ROOT = Path(__file__).resolve().parent.parent
TEST_DIRECTORIES = ("test/app", "test/core", "test/features", "test/shared", "test/docs")
CONTRACT_TEST = "test/integration/dart_test_config_contract_test.dart"


def test_targets(root: Path) -> list[str]:
    return [
        *(path.relative_to(root).as_posix() for path in sorted((root / "test").glob("*_test.dart"))),
        *TEST_DIRECTORIES,
        CONTRACT_TEST,
    ]


def shard_files(root: Path, *, shards: int, shard: int) -> list[str]:
    if shards < 1 or not 0 <= shard < shards:
        raise ValueError("Require shards >= 1 and 0 <= shard < shards")
    files: set[str] = set()
    for target in test_targets(root):
        path = root / target
        if not path.exists():
            raise ValueError(f"Missing test target: {target}")
        if path.is_dir():
            files.update(file.relative_to(root).as_posix() for file in path.rglob("*_test.dart"))
        else:
            files.add(target)
    selected = sorted(files)[shard::shards]
    if not selected:
        raise ValueError("The selected shard contains no tests")
    return selected


def test_commands(flutter: str, targets: list[str], *, max_length: int) -> list[list[str]]:
    prefix = [flutter, "test", "--no-pub", "--exclude-tags", "e2e", "--reporter", "expanded"]
    commands: list[list[str]] = []
    current = list(prefix)
    for target in targets:
        if len(subprocess.list2cmdline([*prefix, target])) > max_length:
            raise ValueError(f"Test path exceeds the command length limit: {target}")
        if len(subprocess.list2cmdline([*current, target])) > max_length:
            commands.append(current)
            current = list(prefix)
        current.append(target)
    if len(current) > len(prefix):
        commands.append(current)
    return commands


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--shards", type=int, default=1)
    parser.add_argument("--shard", type=int, default=0)
    parser.add_argument("--list", action="store_true", help="List selected files without running Flutter")
    args = parser.parse_args()
    try:
        selected = shard_files(PROJECT_ROOT, shards=args.shards, shard=args.shard)
    except ValueError as error:
        parser.error(str(error))
    print(f"Flutter test shard {args.shard + 1}/{args.shards}: {len(selected)} files", flush=True)
    if args.list:
        print("\n".join(selected))
        return
    targets = test_targets(PROJECT_ROOT) if args.shards == 1 else selected
    for command in test_commands(
        ci_preflight.resolve_flutter_command(), targets,
        max_length=7000 if os.name == "nt" else 100000,
    ):
        ci_preflight.run(command)


if __name__ == "__main__":
    main()
