from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import textwrap
import unittest

REPO_ROOT = Path(__file__).resolve().parents[2]


def publish_step() -> str:
    workflow = (REPO_ROOT / ".github/workflows/windows_release.yml").read_text(encoding="utf-8")
    step = workflow.split("      - name: Publish GitHub release\n", 1)[1]
    step = step.split("\n      - name:", 1)[0]
    script = textwrap.dedent(step.split("        run: |\n", 1)[1])
    return script.replace(
        "${{ needs.prepare_release.outputs.release_tag }}", "v1.6.10"
    ).replace(
        "${{ needs.prepare_release.outputs.release_title }}", "Version 1.6.10"
    )


class ReleaseWorkflowTest(unittest.TestCase):
    def setUp(self) -> None:
        if os.name == "nt":
            git = shutil.which("git")
            self.bash = str(Path(git).resolve().parents[1] / "bin/bash.exe") if git else None
        else:
            self.bash = shutil.which("bash")
        if not self.bash or not Path(self.bash).is_file():
            self.skipTest("Bash is required to execute the release workflow step")
        self.workspace = Path(self.enterContext(tempfile.TemporaryDirectory()))
        assets = self.workspace / "release-assets"
        assets.mkdir()
        (assets / "installer.exe").write_bytes(b"test asset")
        (assets / "installer.exe.sha256").write_text("test digest", encoding="utf-8")

    def run_step(self, *, exists: bool, fail_upload: bool = False):
        fake_gh = textwrap.dedent("""\
            gh() {
              printf '%s\\n' "$*" >> gh-commands.txt
              case "$1 ${2:-}" in
                'release view') [ "$RELEASE_EXISTS" = 1 ] ;;
                'release upload') [ "$FAIL_UPLOAD" = 0 ] ;;
                *) return 0 ;;
              esac
            }
            """)
        result = subprocess.run(
            [self.bash, "--noprofile", "--norc", "-c", fake_gh + publish_step()],
            cwd=self.workspace,
            env={**os.environ, "RELEASE_EXISTS": str(int(exists)), "FAIL_UPLOAD": str(int(fail_upload))},
            capture_output=True,
            text=True,
            timeout=15,
        )
        commands = (self.workspace / "gh-commands.txt").read_text(encoding="utf-8").splitlines()
        return result, commands

    def test_should_publish_existing_draft_only_after_upload_succeeds(self) -> None:
        result, commands = self.run_step(exists=True)

        self.assertEqual(0, result.returncode, result.stderr)
        upload = next(i for i, cmd in enumerate(commands) if cmd.startswith("release upload"))
        edit = next(i for i, cmd in enumerate(commands) if cmd.startswith("release edit"))
        self.assertLess(upload, edit)
        self.assertIn("--draft=false", commands[edit])
        self.assertIn("installer.exe.sha256", commands[upload])
        self.assertFalse(any(cmd.startswith("release create") for cmd in commands))

    def test_should_leave_draft_unpublished_when_upload_fails(self) -> None:
        result, commands = self.run_step(exists=True, fail_upload=True)

        self.assertNotEqual(0, result.returncode)
        self.assertTrue(any(cmd.startswith("release upload") for cmd in commands))
        self.assertFalse(any(cmd.startswith("release edit") for cmd in commands))

    def test_should_create_missing_release_with_assets(self) -> None:
        result, commands = self.run_step(exists=False)

        self.assertEqual(0, result.returncode, result.stderr)
        create = next(cmd for cmd in commands if cmd.startswith("release create"))
        self.assertIn("v1.6.10", create)
        self.assertIn("installer.exe.sha256", create)
        self.assertIn("--generate-notes", create)
        self.assertFalse(any(cmd.startswith("release edit") for cmd in commands))


if __name__ == "__main__":
    unittest.main()
