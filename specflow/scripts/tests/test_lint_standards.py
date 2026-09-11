#!/usr/bin/env python3
"""Tests for lint-standards.py, the em-dash and banned-word check."""

import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "lint-standards.py"


def lint(*args: str, cwd: Path | None = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        capture_output=True,
        text=True,
        cwd=cwd,
    )


def write(path: Path, text: str) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
    return path


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
            write(root / "imporvements" / "plan.md", "A — dash.\n"),
            write(root / "standards" / "documentation.md", "A — dash.\n"),
        ]
        git_repo(root, *files)
        result = lint(".", cwd=root)
    assert result.returncode == 0, result.stdout


def test_explicit_file_under_an_excluded_directory_is_skipped():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        path = write(root / "imporvements" / "notes.md", "A \u2014 dash.\n")
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
