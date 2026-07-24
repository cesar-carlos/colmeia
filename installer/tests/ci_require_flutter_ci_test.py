from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path
from unittest import mock


REPO_ROOT = Path(__file__).resolve().parents[2]


def load_module():
    module_path = REPO_ROOT / "installer" / "ci_require_flutter_ci.py"
    spec = importlib.util.spec_from_file_location(
        "installer_ci_require_flutter_ci",
        module_path,
    )
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class RequireFlutterCiTest(unittest.TestCase):
    def setUp(self) -> None:
        self.module = load_module()

    def test_success_when_run_succeeded(self) -> None:
        with mock.patch.object(
            self.module,
            "list_flutter_ci_runs",
            return_value=[{"conclusion": "success", "status": "completed"}],
        ):
            with mock.patch.object(
                sys,
                "argv",
                [
                    "ci_require_flutter_ci.py",
                    "--sha",
                    "abc",
                    "--timeout-seconds",
                    "1",
                ],
            ):
                self.assertEqual(0, self.module.main())

    def test_fail_when_completed_failure(self) -> None:
        with mock.patch.object(
            self.module,
            "list_flutter_ci_runs",
            return_value=[
                {
                    "conclusion": "failure",
                    "status": "completed",
                    "url": "https://example.test/run",
                },
            ],
        ):
            with mock.patch.object(
                sys,
                "argv",
                [
                    "ci_require_flutter_ci.py",
                    "--sha",
                    "abc",
                    "--timeout-seconds",
                    "1",
                ],
            ):
                self.assertEqual(1, self.module.main())


if __name__ == "__main__":
    unittest.main()
