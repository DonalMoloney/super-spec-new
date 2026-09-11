#!/usr/bin/env python3
"""Tests for validate-release-archive.py, the spec-kit install-limit check."""

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "validate-release-archive.py"

MIB = 1024 * 1024
MAX_ZIP_MEMBER_BYTES = 10 * MIB
MAX_ZIP_ENTRIES = 512

MANIFEST = """schema_version: "1.0"
extension:
  id: "specflow"
  name: "Superpowers Bridge"
  version: "1.0.0"
provides:
  commands:
    - name: "speckit.specflow.status"
      file: "commands/status.md"
      description: "Show status"
  templates:
    - name: "spec-template"
      file: "templates/spec-template.md"
      description: "Spec template"
hooks:
  after_tasks:
    command: "speckit.specflow.status"
    optional: true
"""

GITATTRIBUTES_EXCLUDING_ASSETS = """assets/ export-ignore
examples/ export-ignore
scripts/ export-ignore
.github/ export-ignore
.gitattributes export-ignore
.gitignore export-ignore
"""

GITATTRIBUTES_SHIPPING_ASSETS = """examples/ export-ignore
scripts/ export-ignore
.github/ export-ignore
.gitattributes export-ignore
.gitignore export-ignore
"""

MINIMAL_LAYOUT = {
    "extension.yml": MANIFEST,
    "README.md": "# specflow\n",
    "LICENSE": "MIT\n",
    "CHANGELOG.md": "# Changelog\n",
    "SKILL.md": "# Skill\n",
    "references/superpowers-bridge.md": "# Bridge\n",
    "references/workflow-guide.md": "# Guide\n",
    "commands/status.md": "# status\n",
    "templates/spec-template.md": "# spec\n",
    ".gitattributes": GITATTRIBUTES_EXCLUDING_ASSETS,
}

GIT_IDENTITY = {
    "GIT_AUTHOR_NAME": "test",
    "GIT_AUTHOR_EMAIL": "test@example.com",
    "GIT_COMMITTER_NAME": "test",
    "GIT_COMMITTER_EMAIL": "test@example.com",
}


def git(root: Path, *args: str) -> None:
    subprocess.run(
        ["git", "-C", str(root), *args],
        check=True,
        capture_output=True,
        env={**os.environ, **GIT_IDENTITY},
    )


def write_repo(root: Path, layout: dict[str, str | bytes]) -> Path:
    """Write layout under root, copy the validator into scripts/, and commit."""
    for relative, content in layout.items():
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        if isinstance(content, bytes):
            path.write_bytes(content)
        else:
            path.write_text(content, encoding="utf-8")
    scripts = root / "scripts"
    scripts.mkdir(exist_ok=True)
    copied = scripts / SCRIPT.name
    shutil.copy(SCRIPT, copied)
    git(root, "init", "-q")
    git(root, "add", "-A")
    git(root, "commit", "-q", "-m", "layout")
    return copied


def validate(root: Path, layout: dict[str, str | bytes], *args: str) -> subprocess.CompletedProcess:
    copied = write_repo(root, layout)
    return subprocess.run(
        [sys.executable, str(copied), *args],
        capture_output=True,
        text=True,
    )


def test_minimal_valid_layout_exits_zero():
    with tempfile.TemporaryDirectory() as tmp:
        result = validate(Path(tmp), MINIMAL_LAYOUT)
    assert result.returncode == 0, result.stdout + result.stderr
    assert "Release archive is within every spec-kit install limit." in result.stdout


def test_member_above_ten_mib_fails_naming_the_member():
    layout = {**MINIMAL_LAYOUT, "commands/big.bin": os.urandom(MAX_ZIP_MEMBER_BYTES + 1)}
    with tempfile.TemporaryDirectory() as tmp:
        result = validate(Path(tmp), layout)
    assert result.returncode == 1
    assert "FAIL  member commands/big.bin is 10.00 MiB" in result.stdout


def test_more_than_512_entries_fails_the_entries_check():
    layout = dict(MINIMAL_LAYOUT)
    for index in range(MAX_ZIP_ENTRIES + 8):
        layout[f"commands/extra-{index:03d}.md"] = "# extra\n"
    with tempfile.TemporaryDirectory() as tmp:
        result = validate(Path(tmp), layout)
    assert result.returncode == 1
    assert "FAIL  entries:" in result.stdout
    assert f"/ {MAX_ZIP_ENTRIES}" in result.stdout


def test_assets_file_not_export_ignored_fails_the_assets_check():
    layout = {
        **MINIMAL_LAYOUT,
        ".gitattributes": GITATTRIBUTES_SHIPPING_ASSETS,
        "assets/diagram.png": b"png",
    }
    with tempfile.TemporaryDirectory() as tmp:
        result = validate(Path(tmp), layout)
    assert result.returncode == 1
    assert "FAIL  assets/ should be export-ignored but ships" in result.stdout


def test_assets_file_export_ignored_passes_the_assets_check():
    layout = {**MINIMAL_LAYOUT, "assets/diagram.png": b"png"}
    with tempfile.TemporaryDirectory() as tmp:
        result = validate(Path(tmp), layout)
    assert result.returncode == 0, result.stdout + result.stderr
    assert "ok    assets/ excluded" in result.stdout


def test_missing_required_member_fails_naming_it():
    layout = {k: v for k, v in MINIMAL_LAYOUT.items() if k != "references/workflow-guide.md"}
    with tempfile.TemporaryDirectory() as tmp:
        result = validate(Path(tmp), layout)
    assert result.returncode == 1
    assert "FAIL  missing required member: references/workflow-guide.md" in result.stdout


def test_declared_file_absent_from_tree_fails_naming_it():
    layout = {k: v for k, v in MINIMAL_LAYOUT.items() if k != "templates/spec-template.md"}
    with tempfile.TemporaryDirectory() as tmp:
        result = validate(Path(tmp), layout)
    assert result.returncode == 1
    assert (
        "FAIL  extension.yml declares 'templates/spec-template.md' but it is not in the archive"
        in result.stdout
    )


def test_nonexistent_ref_exits_nonzero():
    with tempfile.TemporaryDirectory() as tmp:
        result = validate(Path(tmp), MINIMAL_LAYOUT, "no-such-ref")
    assert result.returncode != 0
    assert "Release archive is within every spec-kit install limit." not in result.stdout
