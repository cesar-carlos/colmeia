from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]


def load_module():
    module_path = REPO_ROOT / "tool" / "build_ios_release.py"
    spec = importlib.util.spec_from_file_location(
        "tool_build_ios_release",
        module_path,
    )
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class BuildIosReleaseTest(unittest.TestCase):
    def setUp(self) -> None:
        self.module = load_module()
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.workspace = Path(self.temp_dir.name)

    def test_release_asset_name_uses_versioned_ios_name(self) -> None:
        self.assertEqual(
            "Colmeia-iOS-1.2.3.ipa",
            self.module.release_asset_name("1.2.3"),
        )

    def test_export_artifact_and_checksum_copy_to_destination(self) -> None:
        source = self.workspace / "colmeia.ipa"
        destination = self.workspace / "installer" / "dist" / "Colmeia-iOS-1.2.3.ipa"
        destination.parent.mkdir(parents=True, exist_ok=True)
        source.write_bytes(b"ipa-bytes")

        self.module.export_artifact(source, destination)
        checksum_path = self.module.write_sha256_file(destination)

        self.assertEqual(b"ipa-bytes", destination.read_bytes())
        self.assertEqual(
            "7034dfbfb014e325a8e2fbddbdfa02e2b2cb892583cb50ce54f11aa66ddfcf5d",
            checksum_path.read_text(encoding="utf-8"),
        )


if __name__ == "__main__":
    unittest.main()
