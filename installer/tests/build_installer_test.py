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
    module_path = REPO_ROOT / "installer" / "build_installer.py"
    spec = importlib.util.spec_from_file_location("installer_build_installer", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class BuildInstallerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.module = load_module()
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.workspace = Path(self.temp_dir.name)
        self.module.PROJECT_ROOT = self.workspace
        self.module.RELEASE_ENV_FILE = self.workspace / ".env.release"
        self.module.DIST_DIR = self.workspace / "installer" / "dist"
        self.module.BUNDLED_LOCAL_ENV = self.workspace / "assets" / "env" / "local.env"

    def test_read_env_value_should_prefer_process_environment(self) -> None:
        self.module.RELEASE_ENV_FILE.write_text(
            "AUTO_UPDATE_FEED_URL=https://release.example/appcast.xml\n",
            encoding="utf-8",
        )
        with mock.patch.dict(
            os.environ,
            {"AUTO_UPDATE_FEED_URL": "https://process.example/appcast.xml"},
            clear=True,
        ):
            value = self.module.read_env_value("AUTO_UPDATE_FEED_URL")

        self.assertEqual("https://process.example/appcast.xml", value)

    def test_read_env_value_reads_release_env_only_not_plain_dotenv(self) -> None:
        """Only `.env.release` is used; a plain `.env` at the repo root is ignored."""
        legacy_dotenv = self.workspace / ".env"
        legacy_dotenv.write_text(
            "AUTO_UPDATE_FEED_URL=https://legacy.example/appcast.xml\n",
            encoding="utf-8",
        )
        self.module.RELEASE_ENV_FILE.write_text(
            "AUTO_UPDATE_FEED_URL=https://release.example/appcast.xml\n",
            encoding="utf-8",
        )

        with mock.patch.dict(os.environ, {}, clear=True):
            value = self.module.read_env_value("AUTO_UPDATE_FEED_URL")

        self.assertEqual("https://release.example/appcast.xml", value)

    def test_read_env_value_plain_dotenv_only_returns_none(self) -> None:
        plain = self.workspace / ".env"
        plain.write_text(
            "AUTO_UPDATE_FEED_URL=https://ignored.example/appcast.xml\n",
            encoding="utf-8",
        )

        with mock.patch.dict(os.environ, {}, clear=True):
            value = self.module.read_env_value("AUTO_UPDATE_FEED_URL")

        self.assertIsNone(value)

    def test_read_env_value_empty_override_falls_through_to_release_file(self) -> None:
        override = self.workspace / "custom.release.env"
        override.write_text(
            "AUTO_UPDATE_FEED_URL=\n",
            encoding="utf-8",
        )
        self.module.RELEASE_ENV_FILE.write_text(
            "AUTO_UPDATE_FEED_URL=https://release.example/appcast.xml\n",
            encoding="utf-8",
        )

        with mock.patch.dict(
            os.environ,
            {self.module.RELEASE_ENV_OVERRIDE_VAR: str(override)},
            clear=True,
        ):
            value = self.module.read_env_value("AUTO_UPDATE_FEED_URL")

        self.assertEqual("https://release.example/appcast.xml", value)

    def test_read_env_value_should_support_explicit_override_file(self) -> None:
        override = self.workspace / "custom.release.env"
        override.write_text(
            "AUTO_UPDATE_FEED_URL=https://override.example/appcast.xml\n",
            encoding="utf-8",
        )
        self.module.RELEASE_ENV_FILE.write_text(
            "AUTO_UPDATE_FEED_URL=https://release.example/appcast.xml\n",
            encoding="utf-8",
        )

        with mock.patch.dict(
            os.environ,
            {self.module.RELEASE_ENV_OVERRIDE_VAR: str(override)},
            clear=True,
        ):
            value = self.module.read_env_value("AUTO_UPDATE_FEED_URL")

        self.assertEqual("https://override.example/appcast.xml", value)

    def test_read_env_value_override_without_key_falls_through_to_release(self) -> None:
        override = self.workspace / "custom.release.env"
        override.write_text(
            "# no AUTO_UPDATE_FEED_URL here\nOTHER=1\n",
            encoding="utf-8",
        )
        self.module.RELEASE_ENV_FILE.write_text(
            "AUTO_UPDATE_FEED_URL=https://release.example/appcast.xml\n",
            encoding="utf-8",
        )

        with mock.patch.dict(
            os.environ,
            {self.module.RELEASE_ENV_OVERRIDE_VAR: str(override)},
            clear=True,
        ):
            value = self.module.read_env_value("AUTO_UPDATE_FEED_URL")

        self.assertEqual("https://release.example/appcast.xml", value)

    def test_resolve_env_files_should_fail_when_override_file_is_missing(self) -> None:
        with mock.patch.dict(
            os.environ,
            {self.module.RELEASE_ENV_OVERRIDE_VAR: str(self.workspace / "missing.env")},
            clear=True,
        ):
            with self.assertRaises(SystemExit) as ctx:
                self.module.resolve_env_files()

        self.assertIn("missing file", str(ctx.exception))

    def test_clear_previous_installer_outputs_removes_matching_artifacts(self) -> None:
        self.module.DIST_DIR.mkdir(parents=True)
        keep = self.module.DIST_DIR / "notes.txt"
        keep.write_text("x", encoding="utf-8")
        old = self.module.DIST_DIR / "Colmeia-Setup-0.0.1.exe"
        old.write_text("exe", encoding="utf-8")
        checksum = self.module.DIST_DIR / "Colmeia-Setup-0.0.1.exe.sha256"
        checksum.write_text("abc", encoding="utf-8")

        self.module.clear_previous_installer_outputs()

        self.assertFalse(old.exists())
        self.assertFalse(checksum.exists())
        self.assertTrue(keep.exists())

    def test_find_dart_prefers_flutter_root_sdk_executable(self) -> None:
        flutter_root = self.workspace / "flutter"
        dart_exe = flutter_root / self.module.DART_RELATIVE_TO_FLUTTER_ROOT
        dart_exe.parent.mkdir(parents=True, exist_ok=True)
        dart_exe.write_text("", encoding="utf-8")

        with mock.patch.dict(
            os.environ,
            {"FLUTTER_ROOT": str(flutter_root)},
            clear=True,
        ):
            resolved = self.module.find_dart()

        self.assertEqual(str(dart_exe), resolved)

    def test_find_dart_converts_dart_bat_into_sdk_dart_exe(self) -> None:
        flutter_bin = self.workspace / "flutter" / "bin"
        flutter_bin.mkdir(parents=True, exist_ok=True)
        dart_bat = flutter_bin / "dart.bat"
        dart_bat.write_text("", encoding="utf-8")
        dart_exe = flutter_bin / "cache" / "dart-sdk" / "bin" / "dart.exe"
        dart_exe.parent.mkdir(parents=True, exist_ok=True)
        dart_exe.write_text("", encoding="utf-8")

        with mock.patch("shutil.which", side_effect=lambda name: str(dart_bat) if name == "dart" else None):
            resolved = self.module.find_dart()

        self.assertEqual(str(dart_exe), resolved)

    def test_guard_against_bundled_local_env_allows_missing_file(self) -> None:
        self.module.guard_against_bundled_local_env()

    def test_guard_against_bundled_local_env_allows_comment_only_file(self) -> None:
        self.module.BUNDLED_LOCAL_ENV.parent.mkdir(parents=True, exist_ok=True)
        self.module.BUNDLED_LOCAL_ENV.write_text(
            "# comment only\n\n   # still ignored\n",
            encoding="utf-8",
        )

        self.module.guard_against_bundled_local_env()

    def test_has_meaningful_local_env_entries_ignores_utf8_bom_comment_lines(self) -> None:
        self.module.BUNDLED_LOCAL_ENV.parent.mkdir(parents=True, exist_ok=True)
        self.module.BUNDLED_LOCAL_ENV.write_text(
            "# comment only\n# still ignored\n",
            encoding="utf-8-sig",
        )

        self.assertFalse(self.module.has_meaningful_local_env_entries())

    def test_guard_against_bundled_local_env_fails_when_entries_exist(self) -> None:
        self.module.BUNDLED_LOCAL_ENV.parent.mkdir(parents=True, exist_ok=True)
        self.module.BUNDLED_LOCAL_ENV.write_text(
            "SECRET=value\n",
            encoding="utf-8",
        )

        with self.assertRaises(SystemExit) as ctx:
            self.module.guard_against_bundled_local_env()

        self.assertIn("would be bundled", str(ctx.exception))

    def test_guard_against_bundled_local_env_can_be_overridden_explicitly(self) -> None:
        self.module.BUNDLED_LOCAL_ENV.parent.mkdir(parents=True, exist_ok=True)
        self.module.BUNDLED_LOCAL_ENV.write_text(
            "SECRET=value\n",
            encoding="utf-8",
        )

        with mock.patch.dict(
            os.environ,
            {self.module.ALLOW_BUNDLED_LOCAL_ENV_VAR: "1"},
            clear=True,
        ):
            self.module.guard_against_bundled_local_env()

    def test_prepared_local_env_for_release_sanitizes_and_restores_sensitive_file(self) -> None:
        self.module.BUNDLED_LOCAL_ENV.parent.mkdir(parents=True, exist_ok=True)
        original_content = "SECRET=value\n"
        self.module.BUNDLED_LOCAL_ENV.write_text(original_content, encoding="utf-8")

        with self.module.prepared_local_env_for_release():
            sanitized_content = self.module.BUNDLED_LOCAL_ENV.read_text(
                encoding="utf-8",
            )
            self.assertNotIn("SECRET=value", sanitized_content)
            self.assertIn("Sanitized automatically", sanitized_content)

        restored_content = self.module.BUNDLED_LOCAL_ENV.read_text(encoding="utf-8")
        self.assertEqual(original_content, restored_content)

    def test_prepared_local_env_for_release_keeps_file_when_explicitly_allowed(self) -> None:
        self.module.BUNDLED_LOCAL_ENV.parent.mkdir(parents=True, exist_ok=True)
        original_content = "SECRET=value\n"
        self.module.BUNDLED_LOCAL_ENV.write_text(original_content, encoding="utf-8")

        with mock.patch.dict(
            os.environ,
            {self.module.ALLOW_BUNDLED_LOCAL_ENV_VAR: "1"},
            clear=True,
        ):
            with self.module.prepared_local_env_for_release():
                current_content = self.module.BUNDLED_LOCAL_ENV.read_text(
                    encoding="utf-8",
                )
                self.assertEqual(original_content, current_content)

    def test_write_sha256_file_creates_checksum_sidecar(self) -> None:
        asset_path = self.workspace / "installer" / "dist" / "Colmeia-Setup-9.9.9.exe"
        asset_path.parent.mkdir(parents=True, exist_ok=True)
        asset_path.write_text("binary-content", encoding="utf-8")

        checksum_path = self.module.write_sha256_file(asset_path)

        self.assertEqual(
            asset_path.with_name("Colmeia-Setup-9.9.9.exe.sha256"),
            checksum_path,
        )
        self.assertEqual(
            "37456ce54a2ef39b6c9c1d96ddc978f2edc730744bd2c9872dc1cc9ac886b00e",
            checksum_path.read_text(encoding="utf-8"),
        )


if __name__ == "__main__":
    unittest.main()
