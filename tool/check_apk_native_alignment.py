#!/usr/bin/env python3
"""Verify native .so libraries inside an APK meet 16 KB ELF page alignment.

Android 15+ devices with 16 KB memory pages require PT_LOAD segment alignment
of at least 16384 bytes. See:
https://developer.android.com/guide/practices/page-sizes

Usage:
  python tool/check_apk_native_alignment.py build/app/outputs/flutter-apk/app-release.apk

On failure, update Flutter/NDK/plugins and rebuild. Manual inspection:
  unzip -l app-release.apk 'lib/*/*.so'
  readelf -l lib/arm64-v8a/libflutter.so | rg LOAD
"""

from __future__ import annotations

import argparse
import struct
import sys
import zipfile
from dataclasses import dataclass
from pathlib import Path

PT_LOAD = 1
REQUIRED_ALIGN = 16 * 1024


@dataclass(frozen=True)
class LoadSegment:
    alignment: int


def _parse_elf_load_alignments(data: bytes, member_name: str) -> list[LoadSegment]:
    if len(data) < 64:
        raise ValueError(f"{member_name}: truncated ELF header")

    if data[:4] != b"\x7fELF":
        raise ValueError(f"{member_name}: not an ELF file")

    elf_class = data[4]
    endian = "<" if data[5] == 1 else ">"

    if elf_class == 1:
        # ELF32
        e_phoff = struct.unpack_from(endian + "I", data, 28)[0]
        e_phentsize, e_phnum = struct.unpack_from(endian + "HH", data, 42)
        ph_fmt = endian + "IIIIIIII"
        ph_size = 32
    elif elf_class == 2:
        # ELF64
        e_phoff = struct.unpack_from(endian + "Q", data, 32)[0]
        e_phentsize, e_phnum = struct.unpack_from(endian + "HH", data, 54)
        ph_fmt = endian + "IIQQQQQQ"
        ph_size = 56
    else:
        raise ValueError(f"{member_name}: unknown ELF class {elf_class}")

    if e_phentsize != ph_size:
        raise ValueError(
            f"{member_name}: unexpected program header entry size {e_phentsize}",
        )

    segments: list[LoadSegment] = []
    for index in range(e_phnum):
        offset = e_phoff + index * e_phentsize
        if offset + ph_size > len(data):
            raise ValueError(f"{member_name}: program header {index} out of range")
        fields = struct.unpack_from(ph_fmt, data, offset)
        p_type = fields[0]
        if p_type != PT_LOAD:
            continue
        p_align = fields[-1]
        segments.append(LoadSegment(alignment=int(p_align)))

    return segments


def find_misaligned_members(apk_path: Path, required_align: int) -> list[str]:
    errors: list[str] = []
    with zipfile.ZipFile(apk_path) as archive:
        for member in archive.namelist():
            if not member.startswith("lib/") or not member.endswith(".so"):
                continue
            data = archive.read(member)
            try:
                load_segments = _parse_elf_load_alignments(data, member)
            except ValueError as exc:
                errors.append(str(exc))
                continue
            if not load_segments:
                errors.append(f"{member}: no PT_LOAD segments found")
                continue
            for segment in load_segments:
                if segment.alignment < required_align:
                    errors.append(
                        f"{member}: PT_LOAD align {segment.alignment} < {required_align}",
                    )
                    break
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "apk",
        type=Path,
        help="Path to a release APK (e.g. build/app/outputs/flutter-apk/app-release.apk)",
    )
    parser.add_argument(
        "--min-align",
        type=int,
        default=REQUIRED_ALIGN,
        help=f"Minimum PT_LOAD alignment in bytes (default: {REQUIRED_ALIGN})",
    )
    args = parser.parse_args(argv)

    apk_path: Path = args.apk
    if not apk_path.is_file():
        print(f"APK not found: {apk_path}", file=sys.stderr)
        return 2

    errors = find_misaligned_members(apk_path, args.min_align)
    if errors:
        print(f"16 KB alignment check failed for {apk_path}:", file=sys.stderr)
        for line in errors:
            print(f"  - {line}", file=sys.stderr)
        return 1

    print(f"OK: all native libraries in {apk_path} have PT_LOAD align >= {args.min_align}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())