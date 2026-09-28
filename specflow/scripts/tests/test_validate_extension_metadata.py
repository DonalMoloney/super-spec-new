#!/usr/bin/env python3
"""Tests for validate-extension-metadata.py."""

import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "validate-extension-metadata.py"
EXTENSION_DIR = Path(__file__).resolve().parents[2]

CATALOG_INSTALL_LINE = "specify extension add specflow"
DEV_INSTALL_LINE = "specify extension add ./specflow --dev"

# The validator reads no file under examples/, so the copy leaves it out.
SKIPPED_DIRECTORIES = {
    EXTENSION_DIR / "assets",
    EXTENSION_DIR / "examples",
    EXTENSION_DIR / "scripts" / "tests",
}


def skip_heavy_directories(directory: str, names: list[str]) -> set[str]:
    return {
        name
        for name in names
        if Path(directory) / name in SKIPPED_DIRECTORIES or name == "__pycache__"
    }


def copy_extension(tmp: str) -> Path:
    """Copy the extension tree minus media and snapshots and return the copy root."""
    root = Path(tmp) / "specflow"
    shutil.copytree(EXTENSION_DIR, root, ignore=skip_heavy_directories)
    return root


def validate(root: Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(root / "scripts" / SCRIPT.name)],
        capture_output=True,
        text=True,
    )


def replace_in(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    assert old in text, f"{path} does not contain {old!r}"
    path.write_text(text.replace(old, new), encoding="utf-8")


def test_fixed_regex_only_matches_commands():
    """After the fix, the regex should only match commands in provides.commands."""
    manifest = """schema_version: "1.0"
extension:
  id: "specflow"
  name: "Superpowers Bridge"
  version: "1.0.0"
provides:
  commands:
    - name: "speckit.specflow.status"
      file: "commands/status.md"
      description: "Show status"
    - name: "speckit.specflow.brainstorm"
      file: "commands/brainstorm.md"
      description: "Brainstorm"
  templates:
    - name: "constitution-template"
      file: "templates/constitution-template.md"
      description: "Constitution template"
    - name: "spec-template"
      file: "templates/spec-template.md"
      description: "Spec template"
hooks:
  after_tasks:
    command: "speckit.specflow.status"
    optional: true
    description: "Test hook"
"""

    # Fixed approach: extract the commands section first, then find names within it
    # Match from "  commands:" until we hit "  templates:" or another top-level key
    commands_section_match = re.search(
        r"^  commands:\n((?:    .+\n)*?)(?=^  \w+:|^hooks:|^$)",
        manifest,
        re.MULTILINE,
    )
    assert commands_section_match, "Should find provides.commands section"

    commands_section = commands_section_match.group(1)
    fixed_command_names = re.findall(
        r"- name:[ \t]*[\"']?([^\"'\n]+)[\"']?",
        commands_section,
    )
    # After fix, should match all commands
    assert "speckit.specflow.status" in fixed_command_names
    assert "speckit.specflow.brainstorm" in fixed_command_names
    # Should NOT match template names
    assert "constitution-template" not in fixed_command_names
    assert "spec-template" not in fixed_command_names


def test_unmodified_copy_exits_zero_with_ok_line():
    with tempfile.TemporaryDirectory() as tmp:
        result = validate(copy_extension(tmp))
    assert result.returncode == 0, result.stdout + result.stderr
    assert "OK: extension metadata and docs are aligned (id='specflow')" in result.stdout


def test_extension_id_drift_fails_naming_the_command():
    with tempfile.TemporaryDirectory() as tmp:
        root = copy_extension(tmp)
        replace_in(root / "extension.yml", 'id: "specflow"', 'id: "flow"')
        result = validate(root)
    assert result.returncode == 1
    assert (
        "FAIL: command 'speckit.specflow.status' must use namespace 'speckit.flow.*'"
        in result.stdout
    )


def test_command_outside_namespace_fails_naming_the_command():
    with tempfile.TemporaryDirectory() as tmp:
        root = copy_extension(tmp)
        replace_in(
            root / "extension.yml",
            'name: "speckit.specflow.status"',
            'name: "speckit.other.status"',
        )
        result = validate(root)
    assert result.returncode == 1
    assert (
        "FAIL: command 'speckit.other.status' must use namespace 'speckit.specflow.*'"
        in result.stdout
    )


def test_hook_outside_namespace_fails_naming_the_hook():
    with tempfile.TemporaryDirectory() as tmp:
        root = copy_extension(tmp)
        replace_in(
            root / "extension.yml",
            'command: "speckit.specflow.tasks"',
            'command: "speckit.other.tasks"',
        )
        result = validate(root)
    assert result.returncode == 1
    assert (
        "FAIL: extension.yml hook 'after_tasks' must map to a 'speckit.specflow.*' command"
        in result.stdout
    )


def test_readme_catalog_slug_drift_fails_naming_the_slug():
    with tempfile.TemporaryDirectory() as tmp:
        root = copy_extension(tmp)
        replace_in(root / "README.md", CATALOG_INSTALL_LINE, "specify extension add other")
        result = validate(root)
    assert result.returncode == 1
    assert (
        "FAIL: README.md install command 'specify extension add other' "
        "must match extension.id='specflow'"
    ) in result.stdout


def test_readme_stale_command_reference_fails():
    with tempfile.TemporaryDirectory() as tmp:
        root = copy_extension(tmp)
        readme = root / "README.md"
        readme.write_text(
            readme.read_text(encoding="utf-8") + "\nRun /specflow.status first.\n",
            encoding="utf-8",
        )
        result = validate(root)
    assert result.returncode == 1
    assert "FAIL: found 1 stale command reference(s)" in result.stdout


def test_readme_without_dev_install_line_fails():
    with tempfile.TemporaryDirectory() as tmp:
        root = copy_extension(tmp)
        replace_in(root / "README.md", DEV_INSTALL_LINE, "")
        result = validate(root)
    assert result.returncode == 1
    assert "FAIL: README.md must document local --dev install command" in result.stdout


def write_catalog(root: Path, commands: int, hooks: int) -> Path:
    """Write a catalog.json beside the extension copy and return its path."""
    catalog = root.parent / "catalog.json"
    catalog.write_text(
        json.dumps(
            {
                "schema_version": "1.0",
                "extensions": {
                    "specflow": {
                        "id": "specflow",
                        "provides": {"commands": commands, "hooks": hooks},
                    }
                },
            }
        ),
        encoding="utf-8",
    )
    return catalog


def test_catalog_counts_matching_the_manifest_pass():
    with tempfile.TemporaryDirectory() as tmp:
        root = copy_extension(tmp)
        write_catalog(root, commands=7, hooks=6)
        result = validate(root)
        assert result.returncode == 0, result.stdout + result.stderr


def test_catalog_command_count_drift_fails_naming_both_numbers():
    with tempfile.TemporaryDirectory() as tmp:
        root = copy_extension(tmp)
        write_catalog(root, commands=6, hooks=6)
        result = validate(root)
    assert result.returncode == 1
    assert (
        "FAIL: catalog.json provides.commands is 6; extension.yml declares 7."
        in result.stdout
    )


def test_catalog_hook_count_drift_fails_naming_both_numbers():
    with tempfile.TemporaryDirectory() as tmp:
        root = copy_extension(tmp)
        write_catalog(root, commands=7, hooks=5)
        result = validate(root)
    assert result.returncode == 1
    assert (
        "FAIL: catalog.json provides.hooks is 5; extension.yml declares 6."
        in result.stdout
    )


def test_absent_catalog_is_not_an_error():
    with tempfile.TemporaryDirectory() as tmp:
        root = copy_extension(tmp)
        result = validate(root)
        assert result.returncode == 0, result.stdout + result.stderr
