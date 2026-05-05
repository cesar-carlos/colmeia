from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]


def load_pubspec_version():
    module_path = REPO_ROOT / "installer" / "pubspec_version.py"
    spec = importlib.util.spec_from_file_location("installer_pubspec_version", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class PubspecVersionTest(unittest.TestCase):
    def test_read_pubspec_versions(self) -> None:
        module = load_pubspec_version()
        with tempfile.TemporaryDirectory() as tmp:
            pubspec = Path(tmp) / "pubspec.yaml"
            pubspec.write_text('name: colmeia\nversion: 2.3.4+7\n', encoding="utf-8")
            short_version, full_version = module.read_pubspec_versions(pubspec)
        self.assertEqual("2.3.4", short_version)
        self.assertEqual("2.3.4+7", full_version)


if __name__ == "__main__":
    unittest.main()
