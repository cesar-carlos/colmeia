from __future__ import annotations

import importlib.util
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


REPO_ROOT = Path(__file__).resolve().parents[2]


def load_module():
    module_path = REPO_ROOT / "tool" / "build_android_release.py"
    spec = importlib.util.spec_from_file_location(
        "tool_build_android_release",
        module_path,
    )
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class BuildAndroidReleaseTest(unittest.TestCase):
    def setUp(self) -> None:
        self.module = load_module()
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.workspace = Path(self.temp_dir.name)

    def test_resolve_requested_formats_defaults_to_both_artifacts(self) -> None:
        args = self.module.parse_args.__globals__["argparse"].Namespace(
            apk=False,
            aab=False,
            skip_build=False,
        )

        self.assertEqual(["apk", "aab"], self.module.resolve_requested_formats(args))

    def test_release_asset_name_uses_versioned_android_names(self) -> None:
        self.assertEqual(
            "Colmeia-Android-1.2.3.apk",
            self.module.release_asset_name("apk", "1.2.3"),
        )
        self.assertEqual(
            "Colmeia-Android-1.2.3.aab",
            self.module.release_asset_name("aab", "1.2.3"),
        )

    def test_release_dart_defines_injects_sentry_dsn_when_env_set(self) -> None:
        with mock.patch.dict(
            os.environ,
            {"SENTRY_DSN": "https://example.ingest.sentry.io/1"},
            clear=False,
        ):
            self.assertEqual(
                [
                    "--dart-define",
                    "SENTRY_DSN=https://example.ingest.sentry.io/1",
                ],
                self.module.release_dart_defines(),
            )

    def test_release_dart_defines_omits_empty_sentry_dsn(self) -> None:
        with mock.patch.dict(os.environ, {}, clear=True):
            self.assertEqual([], self.module.release_dart_defines())

    def test_build_command_appends_release_dart_defines(self) -> None:
        with mock.patch.dict(
            os.environ,
            {"SENTRY_DSN": "https://example.ingest.sentry.io/1"},
            clear=False,
        ):
            self.assertEqual(
                [
                    "flutter",
                    "build",
                    "apk",
                    "--release",
                    "--dart-define",
                    "SENTRY_DSN=https://example.ingest.sentry.io/1",
                ],
                self.module.build_command("apk"),
            )

    def test_export_artifact_and_checksum_copy_to_destination(self) -> None:
        source = self.workspace / "app-release.apk"
        destination = self.workspace / "installer" / "dist" / "Colmeia-Android-1.2.3.apk"
        destination.parent.mkdir(parents=True, exist_ok=True)
        source.write_bytes(b"apk-bytes")

        self.module.export_artifact(source, destination)
        checksum_path = self.module.write_sha256_file(destination)

        self.assertEqual(b"apk-bytes", destination.read_bytes())
        self.assertEqual(
            "1e10ba560383b17472b4cf72fef8f9e76c66815a3e6ae8c5a9b0c5e696b0bdf8",
            checksum_path.read_text(encoding="utf-8"),
        )


if __name__ == "__main__":
    unittest.main()
