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


if __name__ == "__main__":
    unittest.main()
