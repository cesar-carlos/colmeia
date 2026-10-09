from __future__ import annotations

import base64
from dataclasses import replace
import io
import json
from pathlib import Path
import sys
import unittest
from unittest import mock
from urllib.error import HTTPError
import xml.etree.ElementTree as ET

TOOL_DIR = Path(__file__).resolve().parents[1]
if str(TOOL_DIR) not in sys.path:
    sys.path.insert(0, str(TOOL_DIR))

import publish_appcast
from update_appcast import ReleaseMetadata, SPARKLE_NS, create_document, update_document


class PublishAppcastTest(unittest.TestCase):
    def setUp(self) -> None:
        self.release = ReleaseMetadata(
            version="1.6.10+10",
            short_version="1.6.10",
            asset_url="https://example.test/1.6.10.exe",
            release_notes_url="https://example.test/releases/v1.6.10",
            published_at="Fri, 09 Oct 2026 17:00:00 GMT",
            content_length=123,
            title="Colmeia",
            description="Windows releases",
            language="pt-BR",
            max_items=5,
            signature=None,
        )
        self.urlopen = self.enterContext(
            mock.patch.object(publish_appcast.urllib.request, "urlopen")
        )

    def publish(self) -> bytes:
        return publish_appcast.publish_appcast(
            repository="example/colmeia", token="test-token", release=self.release
        )

    def feed(self, version: str) -> bytes:
        release = replace(self.release, version=version, short_version=version.split("+")[0])
        return update_document(create_document(release), release)

    def response(self, content: bytes, sha: str = "snapshot-sha") -> io.BytesIO:
        return io.BytesIO(json.dumps({
            "sha": sha,
            "content": base64.b64encode(content).decode("ascii"),
        }).encode("utf-8"))

    def error(self, status: int) -> HTTPError:
        return HTTPError("https://example.test", status, "API error", {}, None)

    def put_body(self, index: int = -1) -> dict:
        return json.loads(self.urlopen.call_args_list[index].args[0].data)

    def versions(self, content: bytes) -> list[str]:
        return [
            enclosure.attrib[f"{{{SPARKLE_NS}}}version"]
            for enclosure in ET.fromstring(content).findall("./channel/item/enclosure")
        ]

    def test_should_create_feed_when_remote_file_is_missing(self) -> None:
        self.urlopen.side_effect = [self.error(404), io.BytesIO(b"{}")]

        content = self.publish()

        self.assertEqual(["1.6.10+10"], self.versions(content))
        self.assertNotIn("sha", self.put_body())
        self.assertEqual("main", self.put_body()["branch"])

    def test_should_preserve_remote_releases_and_use_their_snapshot_sha(self) -> None:
        self.urlopen.side_effect = [self.response(self.feed("1.6.9+9")), io.BytesIO(b"{}")]

        content = self.publish()

        self.assertEqual(["1.6.10+10", "1.6.9+9"], self.versions(content))
        self.assertEqual("snapshot-sha", self.put_body()["sha"])
        self.assertEqual(content, base64.b64decode(self.put_body()["content"]))

    def test_should_merge_concurrent_release_again_after_conflict(self) -> None:
        original = self.feed("1.6.9+9")
        newer = replace(self.release, version="1.6.11+11", short_version="1.6.11")
        concurrent = update_document(ET.fromstring(original), newer)
        self.urlopen.side_effect = [
            self.response(original), self.error(409),
            self.response(concurrent, "new-sha"), io.BytesIO(b"{}"),
        ]

        content = self.publish()

        self.assertEqual(["1.6.11+11", "1.6.10+10", "1.6.9+9"], self.versions(content))
        self.assertEqual("new-sha", self.put_body()["sha"])

    def test_should_retry_when_another_run_creates_the_missing_feed(self) -> None:
        self.urlopen.side_effect = [
            self.error(404), self.error(422),
            self.response(self.feed("1.6.11+11")), io.BytesIO(b"{}"),
        ]

        self.assertEqual(["1.6.11+11", "1.6.10+10"], self.versions(self.publish()))

    def test_should_skip_write_when_release_is_already_current(self) -> None:
        content = self.feed(self.release.version)
        self.urlopen.return_value = self.response(content)

        self.assertEqual(content, self.publish())
        self.assertEqual(1, self.urlopen.call_count)

    def test_should_stop_with_actionable_error_after_repeated_conflicts(self) -> None:
        self.urlopen.side_effect = [
            result
            for _ in range(publish_appcast.MAX_PUBLISH_ATTEMPTS)
            for result in (self.response(self.feed("1.6.9+9")), self.error(409))
        ]

        with self.assertRaisesRegex(SystemExit, "Rerun the update_windows_appcast job"):
            self.publish()

    def test_should_propagate_permission_and_validation_errors_without_retry(self) -> None:
        for status in (403, 422):
            with self.subTest(status=status):
                self.urlopen.reset_mock()
                self.urlopen.side_effect = [self.response(self.feed("1.6.9+9")), self.error(status)]

                with self.assertRaises(HTTPError) as raised:
                    self.publish()

                self.assertEqual(status, raised.exception.code)
                self.assertEqual(2, self.urlopen.call_count)

    def test_should_not_replace_unreadable_or_invalid_remote_feed(self) -> None:
        for response, error_type in (
            (self.error(403), HTTPError),
            (self.response(b"not xml"), ET.ParseError),
            (self.response(b"<rss/>"), SystemExit),
        ):
            with self.subTest(error_type=error_type):
                self.urlopen.reset_mock()
                self.urlopen.side_effect = [response]

                with self.assertRaises(error_type):
                    self.publish()

                self.assertEqual(1, self.urlopen.call_count)

    def test_should_keep_newer_release_when_republishing_older_version(self) -> None:
        self.release = replace(self.release, max_items=1)
        self.urlopen.side_effect = [self.response(self.feed("1.6.11+11")), io.BytesIO(b"{}")]

        self.assertEqual(["1.6.11+11"], self.versions(self.publish()))


if __name__ == "__main__":
    unittest.main()
