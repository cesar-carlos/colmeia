from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


REPO_ROOT = Path(__file__).resolve().parents[2]


def load_module():
    module_path = REPO_ROOT / "tool" / "ci_preflight.py"
    spec = importlib.util.spec_from_file_location("tool_ci_preflight", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class CiPreflightTest(unittest.TestCase):
    def setUp(self) -> None:
        self.module = load_module()

    def test_parse_args_defaults_skip_analyze(self) -> None:
        with mock.patch.object(sys, "argv", ["ci_preflight.py"]):
            args = self.module.parse_args()

        self.assertFalse(args.analyze)
        self.assertFalse(args.templates_only)
        self.assertFalse(args.skip_env)
        self.assertFalse(args.skip_format)
        self.assertFalse(args.skip_version_sync)

    def test_templates_only_flag(self) -> None:
        with mock.patch.object(
            sys,
            "argv",
            ["ci_preflight.py", "--templates-only"],
        ):
            args = self.module.parse_args()

        self.assertTrue(args.templates_only)

    def test_tests_flag_runs_the_shared_suite(self) -> None:
        with (
            mock.patch.object(sys, "argv", ["ci_preflight.py", "--tests", "--skip-env", "--skip-format", "--skip-version-sync"]),
            mock.patch.object(self.module, "run") as run,
        ):
            self.assertEqual(0, self.module.main())
        run.assert_called_once_with([sys.executable, "tool/run_ci_tests.py"])

    def test_version_sync_accepts_matching_uncommitted_release_files(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            setup = root / "installer/setup.iss"
            dart = root / "lib/core/constants/app_version.g.dart"
            for path in (setup, dart):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("already synchronized\n")
            with mock.patch.object(self.module, "PROJECT_ROOT", root), mock.patch.object(self.module, "run"):
                self.module._check_version_sync()

    def test_version_sync_detects_generated_content_changes(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            setup = root / "installer/setup.iss"
            dart = root / "lib/core/constants/app_version.g.dart"
            for path in (setup, dart):
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("old\n")
            with (
                mock.patch.object(self.module, "PROJECT_ROOT", root),
                mock.patch.object(self.module, "run", side_effect=lambda _: dart.write_text("new\n")),
                self.assertRaises(SystemExit),
            ):
                self.module._check_version_sync()

    def test_resolve_sdk_command_prefers_which(self) -> None:
        with mock.patch.object(
            self.module.shutil,
            "which",
            side_effect=lambda name: f"/bin/{name}" if name == "dart" else None,
        ):
            self.assertEqual("/bin/dart", self.module.resolve_dart_command())

    def test_main_aggregates_failures(self) -> None:
        with (
            mock.patch.object(sys, "argv", ["ci_preflight.py", "--skip-version-sync"]),
            mock.patch.object(
                self.module,
                "_validate_env",
                side_effect=SystemExit(1),
            ),
            mock.patch.object(
                self.module,
                "_check_dart_format",
                side_effect=SystemExit(1),
            ),
        ):
            code = self.module.main()

        self.assertEqual(1, code)


if __name__ == "__main__":
    unittest.main()
