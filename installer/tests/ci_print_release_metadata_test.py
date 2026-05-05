from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]


def load_ci_module():
    module_path = REPO_ROOT / "installer" / "ci_print_release_metadata.py"
    spec = importlib.util.spec_from_file_location("installer_ci_meta", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class CiPrintReleaseMetadataTest(unittest.TestCase):
    def test_emit_release_metadata_writes_outputs(self) -> None:
        module = load_ci_module()
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        (root / "pubspec.yaml").write_text(
            'name: colmeia\nversion: 1.2.3+4\n',
            encoding="utf-8",
        )
        out = root / "out.txt"

        module.emit_release_metadata(
            repo_root=root,
            github_output=out,
            release_tag="v1.2.3",
            repository="org/colmeia",
        )

        text = out.read_text(encoding="utf-8")
        self.assertIn("full_version=1.2.3+4\n", text)
        self.assertIn("short_version=1.2.3\n", text)
        self.assertIn("windows_asset_name=Colmeia-Setup-1.2.3.exe\n", text)

    def test_emit_release_metadata_tag_mismatch_exits(self) -> None:
        module = load_ci_module()
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        root = Path(tmp.name)
        (root / "pubspec.yaml").write_text(
            'name: colmeia\nversion: 9.9.9+1\n',
            encoding="utf-8",
        )
        out = root / "out.txt"

        with self.assertRaises(SystemExit):
            module.emit_release_metadata(
                repo_root=root,
                github_output=out,
                release_tag="v1.0.0",
                repository="org/colmeia",
            )


if __name__ == "__main__":
    unittest.main()
