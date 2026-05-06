from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]


def load_module():
    module_path = REPO_ROOT / "tool" / "release_windows.py"
    spec = importlib.util.spec_from_file_location("tool_release_windows", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class ReleaseWindowsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.module = load_module()
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.workspace = Path(self.temp_dir.name)
        self.module.PROJECT_ROOT = self.workspace
        self.module.PUBSPEC_PATH = self.workspace / "pubspec.yaml"

    def test_latest_release_tag_should_ignore_non_semver_tags(self) -> None:
        latest = self.module.latest_release_tag(
            ["v1.1.7", "scratch", "v1.1.8", "v1.1.6"],
        )

        self.assertIsNotNone(latest)
        self.assertEqual("1.1.8", latest.short)

    def test_suggest_next_patch_version_should_increment_latest_tag_and_build(self) -> None:
        current = self.module.ReleaseVersion.parse("1.1.8+9")

        suggested = self.module.suggest_next_patch_version(
            current,
            ["v1.1.6", "v1.1.7", "v1.1.8"],
        )

        self.assertEqual("1.1.9+10", suggested.full)

    def test_suggest_next_patch_version_without_tags_keeps_short_and_bumps_build(self) -> None:
        current = self.module.ReleaseVersion.parse("2.0.0+4")

        suggested = self.module.suggest_next_patch_version(current, [])

        self.assertEqual("2.0.0+5", suggested.full)

    def test_update_pubspec_version_should_replace_single_version_line(self) -> None:
        self.module.PUBSPEC_PATH.write_text(
            'name: colmeia\nversion: 1.1.8+9\ndescription: demo\n',
            encoding="utf-8",
        )

        self.module.update_pubspec_version(self.module.PUBSPEC_PATH, "1.1.9+10")

        self.assertIn(
            "version: 1.1.9+10",
            self.module.PUBSPEC_PATH.read_text(encoding="utf-8"),
        )


if __name__ == "__main__":
    unittest.main()
