from __future__ import annotations

import importlib.util
import struct
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]


def load_module():
    module_path = REPO_ROOT / "tool" / "check_apk_native_alignment.py"
    spec = importlib.util.spec_from_file_location(
        "tool_check_apk_native_alignment",
        module_path,
    )
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load module from {module_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def _minimal_elf64(align: int) -> bytes:
    e_ident = b"\x7fELF" + bytes([2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0])
    e_type, e_machine, e_version = 3, 183, 1
    e_entry, e_phoff = 0, 64
    e_shoff, e_flags = 0, 0
    e_ehsize, e_phentsize, e_phnum = 64, 56, 1
    e_shentsize, e_shnum, e_shstrndx = 0, 0, 0
    header = struct.pack(
        "<HHIQQQIHHHHHH",
        e_type,
        e_machine,
        e_version,
        e_entry,
        e_phoff,
        e_shoff,
        e_flags,
        e_ehsize,
        e_phentsize,
        e_phnum,
        e_shentsize,
        e_shnum,
        e_shstrndx,
    )
    ph = struct.pack(
        "<IIQQQQQQ",
        1,
        5,
        0,
        0,
        0,
        0x1000,
        0x1000,
        align,
    )
    return e_ident + header + ph


class CheckApkNativeAlignmentTest(unittest.TestCase):
    def setUp(self) -> None:
        self.module = load_module()

    def test_find_misaligned_members_flags_low_alignment(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            apk_path = Path(tmp) / "test.apk"
            so_ok = _minimal_elf64(16384)
            so_bad = _minimal_elf64(4096)
            with zipfile.ZipFile(apk_path, "w") as archive:
                archive.writestr("lib/arm64-v8a/libok.so", so_ok)
                archive.writestr("lib/arm64-v8a/libbad.so", so_bad)

            errors = self.module.find_misaligned_members(apk_path, 16384)
            self.assertEqual(1, len(errors))
            self.assertIn("libbad.so", errors[0])

    def test_find_misaligned_members_accepts_aligned_library(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            apk_path = Path(tmp) / "test.apk"
            with zipfile.ZipFile(apk_path, "w") as archive:
                archive.writestr(
                    "lib/arm64-v8a/libflutter.so",
                    _minimal_elf64(65536),
                )

            self.assertEqual([], self.module.find_misaligned_members(apk_path, 16384))


if __name__ == "__main__":
    unittest.main()