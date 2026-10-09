#!/usr/bin/env python3
"""Merge a Windows release into the current remote appcast and publish it."""

from __future__ import annotations

import base64
import json
import os
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET

from update_appcast import (
    ReleaseMetadata,
    create_document,
    parse_args,
    update_document,
)

MAX_PUBLISH_ATTEMPTS = 3
REQUEST_TIMEOUT_SECONDS = 30


def publish_appcast(*, repository: str, token: str, release: ReleaseMetadata) -> bytes:
    url = f"https://api.github.com/repos/{repository}/contents/appcast.xml"
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "colmeia-tagged-release",
    }

    for attempt in range(MAX_PUBLISH_ATTEMPTS):
        request = urllib.request.Request(f"{url}?ref=main", headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT_SECONDS) as response:
                remote_document = json.load(response)
        except urllib.error.HTTPError as error:
            if error.code != 404:
                raise
            remote_document = None

        remote_content = (
            base64.b64decode(remote_document["content"])
            if remote_document is not None
            else None
        )
        root = (
            ET.fromstring(remote_content)
            if remote_content is not None
            else create_document(release)
        )
        content = update_document(root, release)
        if content == remote_content:
            print("appcast.xml already up to date.")
            return content

        body = {
            "message": f"chore: update appcast for {release.short_version}",
            "content": base64.b64encode(content).decode("ascii"),
            "branch": "main",
        }
        if remote_document is not None:
            body["sha"] = remote_document["sha"]

        request = urllib.request.Request(
            url,
            data=json.dumps(body).encode("utf-8"),
            headers={**headers, "Content-Type": "application/json"},
            method="PUT",
        )
        try:
            with urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT_SECONDS):
                pass
            return content
        except urllib.error.HTTPError as error:
            conflict = error.code == 409 or (
                error.code == 422 and remote_document is None
            )
            if not conflict:
                raise
            if attempt + 1 == MAX_PUBLISH_ATTEMPTS:
                raise SystemExit(
                    "appcast.xml changed during every publish attempt. "
                    "Rerun the update_windows_appcast job to retry."
                ) from error
            print("appcast.xml changed remotely; merging again before retrying.")

    raise AssertionError("No appcast publish attempt was made")


def main() -> None:
    args = parse_args()
    token = (os.environ.get("APPCAST_PUSH_TOKEN") or "").strip() or (
        os.environ.get("GITHUB_TOKEN") or ""
    ).strip()
    if not token:
        raise SystemExit("No token available to publish appcast.xml.")
    content = publish_appcast(
        repository=os.environ["GITHUB_REPOSITORY"],
        token=token,
        release=args.release,
    )
    args.output.write_bytes(content)


if __name__ == "__main__":
    main()
