from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]


def load_module():
    module_path = REPO_ROOT / "tool" / "validate_env.py"
    spec = importlib.util.spec_from_file_location("tool_validate_env", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class ValidateEnvTest(unittest.TestCase):
    def setUp(self) -> None:
        self.module = load_module()
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.root = Path(self.temp_dir.name)
        self._write("lib/core/config/env_keys.dart", "static const String foo = 'FOO';\n")
        self._write("assets/env/.env.example", "FOO=value\n")
        self._write("assets/env/default.env", "FOO=value\n")
        self._write("assets/env/local.env", "# TOKEN=\n")
        self._write("pubspec.yaml", "flutter:\n  assets:\n    - assets/env/default.env\n")

    def test_valid_repo_passes(self) -> None:
        self.assertEqual([], self.module.validate_repo(self.root))

    def test_missing_template_key_fails(self) -> None:
        self._write("assets/env/default.env", "# no foo here\n")

        errors = self.module.validate_repo(self.root)

        self.assertTrue(any("missing template keys: FOO" in error for error in errors))

    def test_pubspec_local_env_asset_fails(self) -> None:
        self._write(
            "pubspec.yaml",
            "flutter:\n  assets:\n    - assets/env/default.env\n    - assets/env/local.env\n",
        )

        errors = self.module.validate_repo(self.root)

        self.assertTrue(any("must not register assets/env/local.env" in error for error in errors))

    def test_active_sensitive_local_env_fails(self) -> None:
        self._write("assets/env/local.env", "E2E_CLIENT_TOKEN=secret\n")

        errors = self.module.validate_repo(self.root)

        self.assertTrue(any("active sensitive key E2E_CLIENT_TOKEN" in error for error in errors))

    def test_malformed_active_line_fails(self) -> None:
        self._write(".env", "[Window Title]\n")

        errors = self.module.validate_repo(self.root)

        self.assertTrue(any(".env:1 is not KEY=value" in error for error in errors))

    def _write(self, relative_path: str, content: str) -> None:
        path = self.root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")


if __name__ == "__main__":
    unittest.main()
