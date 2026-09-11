#!/usr/bin/env python3
"""Tests for validate-extension-metadata.py."""

import re


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
    print(f"Fixed regex matches: {fixed_command_names}")

    # After fix, should match all commands
    assert "speckit.specflow.status" in fixed_command_names
    assert "speckit.specflow.brainstorm" in fixed_command_names
    # Should NOT match template names
    assert "constitution-template" not in fixed_command_names
    assert "spec-template" not in fixed_command_names


if __name__ == "__main__":
    try:
        test_regex_only_matches_commands_not_templates()
        print("FAIL: Expected test to fail with current regex")
    except AssertionError as e:
        print(f"OK: Buggy regex test fails as expected: {e}")

    test_fixed_regex_only_matches_commands()
    print("OK: Fixed regex passes validation")
