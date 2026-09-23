#!/usr/bin/env python3
"""Tests for lint-standards.py, the em-dash, banned-word and word-choice check."""

from __future__ import annotations

import importlib.util
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import pytest

SCRIPT = Path(__file__).resolve().parents[1] / "lint-standards.py"


def load_script():
    """Import lint-standards.py as a module, so a parsing function can be called directly."""
    spec = importlib.util.spec_from_file_location("lint_standards", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def lint(
    *args: str,
    cwd: Path | None = None,
    python_path: Path | None = None,
) -> subprocess.CompletedProcess:
    environment = None
    if python_path is not None:
        environment = {**os.environ, "PYTHONPATH": str(python_path)}
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        capture_output=True,
        text=True,
        cwd=cwd,
        env=environment,
    )


def write(path: Path, text: str) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    return path


def write_manifest(
    path: Path,
    *,
    extension_id: str = "specflow",
    name: str = "Specflow",
    description: str = "Adds brainstorming to spec-kit.",
    command_name: str = "speckit.specflow.status",
    command_description: str = "Show current progress.",
    prompt: str = "Run task decomposition?",
) -> Path:
    return write(
        path,
        f"""schema_version: "1.0"
extension:
  id: "{extension_id}"
  name: "{name}"
  description: "{description}"
requires:
  optional_skills:
    - id: "test-driven-development"
      source: "obra/superpowers"
provides:
  commands:
    - name: "{command_name}"
      file: "commands/status.md"
      description: "{command_description}"
hooks:
  after_tasks:
    command: "speckit.specflow.tasks"
    prompt: "{prompt}"
    description: "Check task coverage."
""",
    )


def without_yaml(root: Path) -> Path:
    """Write a `yaml` module that refuses to import and return the directory holding it.

    Passed as PYTHONPATH it shadows PyYAML, so a run behaves as it would on a
    machine where PyYAML was never installed.
    """
    write(root / "stub" / "yaml.py", "raise ModuleNotFoundError(\"No module named 'yaml'\")\n")
    return root / "stub"


def git_repo(root: Path, *tracked: Path) -> None:
    subprocess.run(["git", "-C", str(root), "init", "-q"], check=True)
    for path in tracked:
        subprocess.run(["git", "-C", str(root), "add", str(path)], check=True)


def test_clean_file_exits_zero_and_prints_ok():
    with tempfile.TemporaryDirectory() as tmp:
        path = write(Path(tmp) / "clean.md", "The validator rejects a mismatched id.\n")
        result = lint(str(path))
    assert result.returncode == 0, result.stdout + result.stderr
    assert result.stdout.strip() == "OK: 1 file checked, 0 findings"


def test_em_dash_is_reported_with_path_and_line():
    with tempfile.TemporaryDirectory() as tmp:
        path = write(Path(tmp) / "dash.md", "First line.\nSecond — line.\n")
        result = lint(str(path))
    assert result.returncode == 1
    assert f"{path}:2: em-dash" in result.stdout


def test_banned_word_is_reported_case_insensitively():
    with tempfile.TemporaryDirectory() as tmp:
        path = write(Path(tmp) / "word.md", "Leverage the cache.\n")
        result = lint(str(path))
    assert result.returncode == 1
    assert f"{path}:1: banned word 'leverage'" in result.stdout


def test_banned_phrase_is_reported():
    with tempfile.TemporaryDirectory() as tmp:
        path = write(Path(tmp) / "phrase.md", "Note that the gate blocks.\n")
        result = lint(str(path))
    assert result.returncode == 1
    assert "banned word 'note that'" in result.stdout


def test_banned_word_matches_an_inflected_form():
    lint_standards = load_script()
    pattern = lint_standards.entry_pattern(["bridge"], match_inflections=True)

    assert pattern.search("The adapter is bridging two formats.")


def test_banned_word_inside_fenced_code_is_ignored():
    with tempfile.TemporaryDirectory() as tmp:
        path = write(Path(tmp) / "code.md", "```bash\n# leverage nothing\n```\n")
        result = lint(str(path))
    assert result.returncode == 0, result.stdout


def test_em_dash_inside_fenced_code_is_still_reported():
    with tempfile.TemporaryDirectory() as tmp:
        path = write(Path(tmp) / "code.md", "```\nphase 5 — done\n```\n")
        result = lint(str(path))
    assert result.returncode == 1


def test_qualified_table_entry_is_not_banned():
    with tempfile.TemporaryDirectory() as tmp:
        path = write(Path(tmp) / "key.md", "Set the API key to ensure access.\n")
        result = lint(str(path))
    assert result.returncode == 0, result.stdout


def test_hyphenated_compound_is_not_a_banned_word():
    with tempfile.TemporaryDirectory() as tmp:
        path = write(Path(tmp) / "hyphen.md", "The file is harness-neutral.\n")
        result = lint(str(path))
    assert result.returncode == 0, result.stdout


def test_directory_argument_checks_tracked_markdown_only():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        tracked = write(root / "docs" / "tracked.md", "Bad — dash.\n")
        write(root / "docs" / "untracked.md", "Also bad — dash.\n")
        git_repo(root, tracked)
        result = lint("docs", cwd=root)
    assert result.returncode == 1
    assert "tracked.md:1" in result.stdout
    assert "untracked.md" not in result.stdout


def test_excluded_directories_are_skipped_on_a_directory_walk():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        files = [
            write(root / "specflow" / "examples" / "run.md", "A — dash.\n"),
            write(root / "improvements" / "plan.md", "A — dash.\n"),
            write(root / "standards" / "documentation.md", "A — dash.\n"),
        ]
        git_repo(root, *files)
        result = lint(".", cwd=root)
    assert result.returncode == 0, result.stdout


def test_explicit_file_under_an_excluded_directory_is_skipped():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        path = write(root / "improvements" / "notes.md", "A \u2014 dash.\n")
        git_repo(root)
        result = lint(str(path), cwd=root)
    assert result.returncode == 0, result.stdout
    assert result.stdout.strip() == "OK: 0 files checked, 0 findings"


def test_no_argument_walks_the_current_directory():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        tracked = write(root / "README.md", "A — dash.\n")
        git_repo(root, tracked)
        result = lint(cwd=root)
    assert result.returncode == 1
    assert "README.md:1: em-dash" in result.stdout


def test_missing_repository_path_is_reported_with_file_and_line():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        path = write(root / "README.md", "Read `specflow/nope.md` before editing.\n")
        write(root / "specflow" / "README.md", "Existing directory anchor.\n")
        git_repo(root, path)
        result = lint(str(path), cwd=root)

    assert result.returncode == 1
    assert f"{path}:1: missing repository path 'specflow/nope.md'" in result.stdout


def test_missing_repository_path_drops_a_trailing_period():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        target = write(root / "specflow" / "README.md", "Existing file.\n")
        path = write(root / "doc.md", "Read `specflow/README.md`.\n")
        git_repo(root, path, target)
        result = lint(str(path), cwd=root)
    assert result.returncode == 0, result.stdout


def test_relative_parent_citation_is_not_checked_as_a_repository_path():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        path = write(root / "doc.md", "Resolves `../../../.claude/hooks/` in this checkout.\n")
        git_repo(root, path)
        result = lint(str(path), cwd=root)
    assert result.returncode == 0, result.stdout


def test_gitignored_citation_is_not_reported_as_missing():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        write(root / ".gitignore", ".claude/telemetry.jsonl\n")
        write(root / ".claude" / "hooks.md", "Anchor so `.claude` resolves.\n")
        path = write(root / "doc.md", "Query `.claude/telemetry.jsonl` after a run.\n")
        git_repo(root, path)
        result = lint(str(path), cwd=root)
    assert result.returncode == 0, result.stdout


def test_excluded_citation_is_not_reported_as_missing():
    module = load_script()
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        document = write(root / "doc.md", "")
        findings = list(
            module.missing_path_findings(
                "Save nothing to `docs/superpowers/`.",
                document,
                1,
                root,
                frozenset({"docs/superpowers"}),
            )
        )
    assert findings == []


def test_a_missing_path_exclusion_without_a_reason_is_rejected():
    module = load_script()
    with pytest.raises(module.StaleExclusionError) as error:
        module.missing_path_exclusions("docs/superpowers\n")
    assert "docs/superpowers" in str(error.value)


def test_missing_path_exits_two_with_a_message():
    result = lint("/nonexistent/path.md")
    assert result.returncode == 2
    assert "/nonexistent/path.md" in result.stderr
    assert result.stdout == ""


def test_summary_counts_files_and_findings():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        files = [
            write(root / "a.md", "One — two.\n"),
            write(root / "b.md", "Really clean.\n"),
        ]
        git_repo(root, *files)
        result = lint(".", cwd=root)
    assert result.stdout.strip().endswith("2 files checked, 2 findings")


def test_quoting_file_is_skipped_but_its_siblings_are_not():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        files = [
            write(root / "docs" / "review-research.md", "Quoted — source.\n"),
            write(root / "docs" / "guide.md", "A — dash.\n"),
        ]
        git_repo(root, *files)
        result = lint(".", cwd=root)
    assert result.returncode == 1, result.stdout
    assert "review-research.md" not in result.stdout
    assert "guide.md:1" in result.stdout


def test_explicit_quoting_file_is_skipped():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        path = write(root / "docs" / "review-research.md", "A — dash.\n")
        git_repo(root)
        result = lint(str(path), cwd=root)
    assert result.returncode == 0, result.stdout
    assert result.stdout.strip() == "OK: 0 files checked, 0 findings"


def test_clean_manifest_passes():
    with tempfile.TemporaryDirectory() as tmp:
        path = write_manifest(Path(tmp) / "extension.yml")
        result = lint(str(path))
    assert result.returncode == 0, result.stdout + result.stderr
    assert result.stdout.strip() == "OK: 1 file checked, 0 findings"


def test_banned_word_in_the_manifest_description_names_its_key_path():
    with tempfile.TemporaryDirectory() as tmp:
        path = write_manifest(
            Path(tmp) / "extension.yml",
            description="Leverage spec-kit.",
        )
        result = lint(str(path))
    assert result.returncode == 1, result.stdout
    assert f"{path}:extension.description: banned word 'leverage'" in result.stdout


def test_banned_word_in_the_manifest_id_is_not_reported():
    with tempfile.TemporaryDirectory() as tmp:
        path = write_manifest(Path(tmp) / "extension.yml", extension_id="leverage")
        result = lint(str(path))
    assert result.returncode == 0, result.stdout


def test_banned_word_in_a_command_name_is_not_reported():
    with tempfile.TemporaryDirectory() as tmp:
        path = write_manifest(
            Path(tmp) / "extension.yml",
            command_name="speckit.specflow.robust",
        )
        result = lint(str(path))
    assert result.returncode == 0, result.stdout


def test_banned_word_in_the_manifest_display_name_is_reported():
    with tempfile.TemporaryDirectory() as tmp:
        path = write_manifest(Path(tmp) / "extension.yml", name="Seamless Specflow")
        result = lint(str(path))
    assert result.returncode == 1, result.stdout
    assert f"{path}:extension.name: banned word 'seamless'" in result.stdout


def test_em_dash_in_a_command_description_names_its_list_position():
    with tempfile.TemporaryDirectory() as tmp:
        path = write_manifest(
            Path(tmp) / "extension.yml",
            command_description="Show progress — and detection status.",
        )
        result = lint(str(path))
    assert result.returncode == 1, result.stdout
    assert f"{path}:provides.commands[0].description: em-dash" in result.stdout


def test_banned_word_in_a_hook_prompt_is_reported():
    with tempfile.TemporaryDirectory() as tmp:
        path = write_manifest(
            Path(tmp) / "extension.yml",
            prompt="Run a comprehensive decomposition?",
        )
        result = lint(str(path))
    assert result.returncode == 1, result.stdout
    assert f"{path}:hooks.after_tasks.prompt: banned word 'comprehensive'" in result.stdout


def test_markdown_is_checked_without_a_yaml_parser():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        path = write(root / "clean.md", "The validator rejects a mismatched id.\n")
        result = lint(str(path), python_path=without_yaml(root))
    assert result.returncode == 0, result.stdout + result.stderr
    assert result.stdout.strip() == "OK: 1 file checked, 0 findings"


def test_manifest_without_a_yaml_parser_asks_for_pyyaml():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        path = write_manifest(root / "extension.yml")
        result = lint(str(path), python_path=without_yaml(root))
    assert result.returncode != 0
    assert "PyYAML, which is not installed" in result.stderr


def test_word_choice_word_in_a_command_file_names_its_replacement():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        path = write(
            root / "specflow" / "commands" / "status.md",
            "Verify that the constitution exists.\n",
        )
        git_repo(root, path)
        result = lint(".", cwd=root)
    assert result.returncode == 1, result.stdout
    assert "status.md:1: word choice 'verify that'; write 'check, test'" in result.stdout


def test_word_choice_outside_the_shipped_contracts_is_not_reported():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        path = write(root / "docs" / "guide.md", "Verify that the constitution exists.\n")
        git_repo(root, path)
        result = lint(".", cwd=root)
    assert result.returncode == 0, result.stdout


def test_qualified_word_choice_entry_is_not_reported():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        path = write(root / "specflow" / "commands" / "tasks.md", "Update the stamp.\n")
        git_repo(root, path)
        result = lint(".", cwd=root)
    assert result.returncode == 0, result.stdout


def test_excluded_word_choice_entry_is_not_reported():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        path = write(root / "specflow" / "commands" / "review.md", "Name the target surface.\n")
        git_repo(root, path)
        result = lint(".", cwd=root)
    assert result.returncode == 0, result.stdout


def test_word_choice_inside_fenced_code_is_ignored():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        path = write(
            root / "specflow" / "commands" / "execute.md",
            "```bash\n# verify that the gate holds\n```\n",
        )
        git_repo(root, path)
        result = lint(".", cwd=root)
    assert result.returncode == 0, result.stdout


def test_word_choice_in_the_manifest_description_names_its_key_path():
    with tempfile.TemporaryDirectory() as tmp:
        path = write_manifest(
            Path(tmp) / "extension.yml",
            description="Verify that every task is covered.",
        )
        result = lint(str(path))
    assert result.returncode == 1, result.stdout
    assert (
        f"{path}:extension.description: word choice 'verify that'; write 'check, test'"
        in result.stdout
    )


def test_a_stale_exclusion_names_the_entry_the_table_no_longer_carries():
    module = load_script()
    standard = "## Word choice\n\n| Write | Not |\n|---|---|\n| use | employ |\n\n## Next\n"
    with pytest.raises(module.StaleExclusionError) as error:
        module.word_choice_rule(standard, "surface: a noun in this repository\n")
    assert "surface" in str(error.value)


def test_an_exclusion_without_a_reason_is_rejected():
    module = load_script()
    standard = "## Word choice\n\n| Write | Not |\n|---|---|\n| use | employ |\n\n## Next\n"
    with pytest.raises(module.StaleExclusionError) as error:
        module.word_choice_rule(standard, "employ\n")
    assert "employ" in str(error.value)


def test_directory_walk_checks_the_tracked_manifest():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        manifest = write_manifest(
            root / "specflow" / "extension.yml",
            description="Leverage spec-kit.",
        )
        git_repo(root, manifest)
        result = lint(".", cwd=root)
    assert result.returncode == 1, result.stdout
    assert "extension.yml:extension.description: banned word 'leverage'" in result.stdout
    assert result.stdout.strip().endswith("1 file checked, 1 findings")
