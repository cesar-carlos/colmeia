from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]


def load_module():
    module_path = REPO_ROOT / "tool" / "update_appcast.py"
    spec = importlib.util.spec_from_file_location("tool_update_appcast", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class UpdateAppcastTest(unittest.TestCase):
    def setUp(self) -> None:
        self.module = load_module()
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.output = Path(self.temp_dir.name) / "appcast.xml"

    def test_should_create_new_appcast_document(self) -> None:
        release = self._release(version="1.2.3+4", short_version="1.2.3")

        root = self.module.ensure_document(self.output, release)
        channel = root.find("channel")
        self.assertIsNotNone(channel)

        self.module.upsert_release_item(channel, release)
        self.module.trim_release_items(channel, release.max_items)
        self.module.indent_xml(root)
        ET.ElementTree(root).write(self.output, encoding="utf-8", xml_declaration=True)

        tree = ET.parse(self.output)
        enclosure = tree.find("./channel/item/enclosure")
        self.assertIsNotNone(enclosure)
        self.assertEqual(
            release.asset_url,
            enclosure.attrib["url"],
        )
        self.assertEqual(
            release.version,
            enclosure.attrib[f"{{{self.module.SPARKLE_NS}}}version"],
        )

    def test_should_replace_existing_item_for_same_version_without_duplicates(self) -> None:
        release = self._release(version="2.0.0+1", short_version="2.0.0")
        updated_release = self._release(
            version="2.0.0+1",
            short_version="2.0.0",
            asset_url="https://example.com/new.exe",
        )

        root = self.module.ensure_document(self.output, release)
        channel = root.find("channel")
        self.assertIsNotNone(channel)

        self.module.upsert_release_item(channel, release)
        self.module.upsert_release_item(channel, updated_release)

        items = channel.findall("item")
        self.assertEqual(1, len(items))
        enclosure = items[0].find("enclosure")
        self.assertIsNotNone(enclosure)
        self.assertEqual("https://example.com/new.exe", enclosure.attrib["url"])

    def test_should_trim_feed_to_max_items(self) -> None:
        releases = [
            self._release(version="1.0.0+1", short_version="1.0.0"),
            self._release(version="1.0.1+1", short_version="1.0.1"),
            self._release(version="1.0.2+1", short_version="1.0.2"),
        ]
        root = self.module.ensure_document(self.output, releases[0])
        channel = root.find("channel")
        self.assertIsNotNone(channel)

        for release in releases:
            self.module.upsert_release_item(channel, release)

        self.module.trim_release_items(channel, 2)

        versions = [
            item.find("enclosure").attrib[f"{{{self.module.SPARKLE_NS}}}version"]
            for item in channel.findall("item")
        ]
        self.assertEqual(["1.0.2+1", "1.0.1+1"], versions)

    def _release(
        self,
        *,
        version: str,
        short_version: str,
        asset_url: str | None = None,
    ):
        return self.module.ReleaseMetadata(
            version=version,
            short_version=short_version,
            asset_url=asset_url or f"https://example.com/{short_version}.exe",
            release_notes_url=f"https://example.com/releases/{short_version}",
            published_at="Mon, 01 Jan 2024 00:00:00 GMT",
            content_length=12345,
            title="Colmeia",
            description="Most recent Windows releases for Colmeia",
            language="pt-BR",
            max_items=5,
            signature=None,
        )


if __name__ == "__main__":
    unittest.main()
