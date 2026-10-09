#!/usr/bin/env python3
"""
Create or update the Colmeia Windows appcast feed.
"""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
import xml.etree.ElementTree as ET

SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"
ET.register_namespace("sparkle", SPARKLE_NS)


@dataclass(frozen=True)
class ReleaseMetadata:
    version: str
    short_version: str
    asset_url: str
    release_notes_url: str
    published_at: str
    content_length: int
    title: str
    description: str
    language: str
    max_items: int
    signature: str | None


def main() -> None:
    metadata = parse_args()
    output_path = metadata.output
    root = ensure_document(output_path, metadata.release)
    output_path.write_bytes(update_document(root, metadata.release))


def update_document(root: ET.Element, release: ReleaseMetadata) -> bytes:
    channel = root.find("channel")
    if channel is None:
        raise SystemExit("Invalid appcast.xml: missing channel node")

    upsert_release_item(channel, release)
    sort_release_items(channel)
    trim_release_items(channel, release.max_items)
    indent_xml(root)
    return ET.tostring(root, encoding="utf-8", xml_declaration=True)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--version", required=True)
    parser.add_argument("--short-version", required=True)
    parser.add_argument("--asset-url", required=True)
    parser.add_argument("--release-notes-url", required=True)
    parser.add_argument("--published-at", default=http_date_now())
    parser.add_argument("--content-length", required=True, type=int)
    parser.add_argument("--title", default="Colmeia")
    parser.add_argument(
        "--description",
        default="Most recent Windows releases for Colmeia",
    )
    parser.add_argument("--language", default="pt-BR")
    parser.add_argument("--max-items", default=5, type=int)
    parser.add_argument("--dsa-signature")
    args = parser.parse_args()
    args.release = ReleaseMetadata(
        version=args.version,
        short_version=args.short_version,
        asset_url=args.asset_url,
        release_notes_url=args.release_notes_url,
        published_at=args.published_at,
        content_length=args.content_length,
        title=args.title,
        description=args.description,
        language=args.language,
        max_items=args.max_items,
        signature=args.dsa_signature,
    )
    return args


def ensure_document(path: Path, release: ReleaseMetadata) -> ET.Element:
    if path.exists():
        return ET.parse(path).getroot()
    return create_document(release)


def create_document(release: ReleaseMetadata) -> ET.Element:
    rss = ET.Element(
        "rss",
        attrib={
            "version": "2.0",
        },
    )
    channel = ET.SubElement(rss, "channel")
    ET.SubElement(channel, "title").text = release.title
    ET.SubElement(channel, "description").text = release.description
    ET.SubElement(channel, "language").text = release.language
    return rss


def upsert_release_item(channel: ET.Element, release: ReleaseMetadata) -> None:
    existing_item = None
    for item in channel.findall("item"):
        enclosure = item.find("enclosure")
        version = None
        if enclosure is not None:
            version = enclosure.attrib.get(f"{{{SPARKLE_NS}}}version")
        if version == release.version:
            existing_item = item
            break

    if existing_item is not None:
        channel.remove(existing_item)

    item = ET.Element("item")
    ET.SubElement(item, "title").text = f"Version {release.short_version}"
    ET.SubElement(item, "pubDate").text = release.published_at
    ET.SubElement(item, "link").text = release.release_notes_url
    ET.SubElement(item, f"{{{SPARKLE_NS}}}releaseNotesLink").text = (
        release.release_notes_url
    )

    enclosure_attributes = {
        "url": release.asset_url,
        f"{{{SPARKLE_NS}}}version": release.version,
        f"{{{SPARKLE_NS}}}os": "windows",
        "length": str(release.content_length),
        "type": "application/octet-stream",
    }
    if release.signature:
        enclosure_attributes[f"{{{SPARKLE_NS}}}dsaSignature"] = release.signature
    ET.SubElement(item, "enclosure", attrib=enclosure_attributes)

    items = channel.findall("item")
    if items:
        first_item_index = list(channel).index(items[0])
        channel.insert(first_item_index, item)
    else:
        channel.append(item)


def trim_release_items(channel: ET.Element, max_items: int) -> None:
    items = channel.findall("item")
    for item in items[max_items:]:
        channel.remove(item)


def sort_release_items(channel: ET.Element) -> None:
    def version_key(item: ET.Element) -> tuple[int, ...]:
        enclosure = item.find("enclosure")
        version = (
            enclosure.get(f"{{{SPARKLE_NS}}}version", "")
            if enclosure is not None
            else ""
        )
        match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?", version)
        if match is None:
            raise SystemExit(f"Invalid appcast release version: {version!r}")
        return tuple(int(part or 0) for part in match.groups())

    items = sorted(channel.findall("item"), key=version_key, reverse=True)
    for item in items:
        channel.remove(item)
    channel.extend(items)


def http_date_now() -> str:
    return datetime.now(timezone.utc).strftime("%a, %d %b %Y %H:%M:%S GMT")


def indent_xml(element: ET.Element, level: int = 0) -> None:
    indent = "\n" + level * "  "
    if len(element):
        if not element.text or not element.text.strip():
            element.text = indent + "  "
        for child in element:
            indent_xml(child, level + 1)
        if not child.tail or not child.tail.strip():
            child.tail = indent
    elif level and (not element.tail or not element.tail.strip()):
        element.tail = indent


if __name__ == "__main__":
    main()
