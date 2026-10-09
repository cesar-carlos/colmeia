from __future__ import annotations

import importlib.util
import io
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

    def test_should_reject_cancelled_ci_with_exact_commit_recovery_instructions(self) -> None:
        with (
            mock.patch.object(self.module, "list_flutter_ci_runs", return_value=[
                {"conclusion": "cancelled", "status": "completed", "url": "https://example.test/run"},
            ]),
            mock.patch.object(sys, "argv", ["ci_require_flutter_ci.py", "--sha", "tag-sha"]),
            mock.patch.object(sys, "stderr", new_callable=io.StringIO) as stderr,
        ):
            self.assertEqual(1, self.module.main())

        self.assertIn("this exact commit", stderr.getvalue())
        self.assertIn("https://example.test/run", stderr.getvalue())

    def test_should_wait_for_rerun_instead_of_rejecting_previous_cancellation(self) -> None:
        cancelled = {"conclusion": "cancelled", "status": "completed"}
        with (
            mock.patch.object(self.module, "list_flutter_ci_runs", side_effect=[
                [cancelled, {"status": "queued", "conclusion": None}],
                [{"status": "completed", "conclusion": "success"}],
            ]),
            mock.patch.object(sys, "argv", ["ci_require_flutter_ci.py", "--sha", "tag-sha"]),
            mock.patch.object(self.module.time, "sleep"),
        ):
            self.assertEqual(0, self.module.main())

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
