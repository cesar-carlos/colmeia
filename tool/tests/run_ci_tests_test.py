from __future__ import annotations

import importlib.util
import sys
import subprocess
import tempfile
import unittest
from pathlib import Path


TOOL_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOL_DIR))
spec = importlib.util.spec_from_file_location("run_ci_tests", TOOL_DIR / "run_ci_tests.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class RunCiTestsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for directory in module.TEST_DIRECTORIES:
            target = self.root / directory
            target.mkdir(parents=True)
            for index in range(3):
                (target / f"sample_{index}_test.dart").touch()
        contract = self.root / module.CONTRACT_TEST
        contract.parent.mkdir(parents=True)
        contract.touch()
        (self.root / "test/root_test.dart").touch()
        e2e = self.root / "test/integration/e2e/remote_test.dart"
        e2e.parent.mkdir()
        e2e.touch()

    def test_shards_cover_every_file_once_and_exclude_remote_tests(self) -> None:
        all_files = module.shard_files(self.root, shards=1, shard=0)
        partitions = [module.shard_files(self.root, shards=4, shard=index) for index in range(4)]
        flattened = [file for partition in partitions for file in partition]
        self.assertEqual(all_files, sorted(flattened))
        self.assertEqual(len(flattened), len(set(flattened)))
        self.assertEqual(17, len(flattened))
        self.assertIn("test/root_test.dart", flattened)
        self.assertIn(module.CONTRACT_TEST, flattened)
        self.assertFalse(any("/e2e/" in file for file in flattened))

    def test_partition_is_deterministic(self) -> None:
        self.assertEqual(
            module.shard_files(self.root, shards=4, shard=2),
            module.shard_files(self.root, shards=4, shard=2),
        )

    def test_invalid_or_empty_shards_fail(self) -> None:
        for shards, shard in [(0, 0), (4, -1), (4, 4), (30, 29)]:
            with self.subTest(shards=shards, shard=shard), self.assertRaises(ValueError):
                module.shard_files(self.root, shards=shards, shard=shard)

    def test_long_windows_commands_are_split_without_losing_targets(self) -> None:
        targets = [f"test/directory with spaces/{index}_test.dart" for index in range(30)]
        commands = module.test_commands("C:/Flutter SDK/flutter.bat", targets, max_length=250)
        self.assertGreater(len(commands), 1)
        self.assertEqual(targets, [target for command in commands for target in command[7:]])
        self.assertTrue(all(len(subprocess.list2cmdline(command)) <= 250 for command in commands))

    def test_a_single_overlong_path_fails(self) -> None:
        with self.assertRaises(ValueError):
            module.test_commands("flutter", ["x" * 300], max_length=200)

    def test_missing_required_target_fails_instead_of_reducing_coverage(self) -> None:
        (self.root / module.CONTRACT_TEST).unlink()
        with self.assertRaisesRegex(ValueError, "Missing test target"):
            module.shard_files(self.root, shards=1, shard=0)


if __name__ == "__main__":
    unittest.main()
