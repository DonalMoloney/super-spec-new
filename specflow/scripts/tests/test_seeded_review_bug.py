#!/usr/bin/env python3
"""Tests for the T591 seeded-review-bug example and its outside oracle.

specflow/examples/seeded-review-bug/ does not exist yet (it is a copy of
specflow/examples/link-audit/ with one planted spec violation the shipped
tests miss), and specflow/scripts/tests/planted_violation_oracle.py, the
pytest module the shipped suite never collects, does not exist yet either.
Every test here fails until both are written; writing them belongs to
implementation-engineer, not to this file.
"""

import difflib
import os
import re
import subprocess
import sys
from pathlib import Path

SPECFLOW_DIR = Path(__file__).resolve().parents[2]
REPO_ROOT = Path(__file__).resolve().parents[3]
SCRIPTS_TESTS_DIR = Path(__file__).resolve().parent

LINK_AUDIT_DIR = SPECFLOW_DIR / "examples" / "link-audit"
SEEDED_DIR = SPECFLOW_DIR / "examples" / "seeded-review-bug"
LINK_AUDIT_SRC = LINK_AUDIT_DIR / "src" / "link_audit"
SEEDED_SRC = SEEDED_DIR / "src" / "link_audit"

ORACLE = SCRIPTS_TESTS_DIR / "planted_violation_oracle.py"


def find_planted_hunks():
    """Return one (relative_path, first_changed_line) entry per differing hunk.

    Compares every *.py file link-audit/src/link_audit/ holds against the same
    relative path under seeded-review-bug/src/link_audit/, one difflib opcode
    group per hunk.
    """
    hunks = []
    for path in sorted(LINK_AUDIT_SRC.rglob("*.py")):
        relative = path.relative_to(LINK_AUDIT_SRC)
        original_lines = path.read_text(encoding="utf-8").splitlines()
        seeded_lines = (SEEDED_SRC / relative).read_text(encoding="utf-8").splitlines()
        matcher = difflib.SequenceMatcher(a=original_lines, b=seeded_lines, autojunk=False)
        for tag, i1, _i2, _j1, _j2 in matcher.get_opcodes():
            if tag != "equal":
                hunks.append((str(relative), i1 + 1))
    return hunks


def read_readme():
    """Return seeded-review-bug/README.md's text."""
    return (SEEDED_DIR / "README.md").read_text(encoding="utf-8")


def run_oracle(link_audit_src):
    """Run planted_violation_oracle.py under pytest with LINK_AUDIT_SRC set to link_audit_src."""
    environment = {**os.environ, "LINK_AUDIT_SRC": str(link_audit_src)}
    return subprocess.run(
        [sys.executable, "-m", "pytest", "-q", str(ORACLE)],
        capture_output=True,
        text=True,
        env=environment,
    )


def test_seeded_copys_own_pytest_suite_passes():
    assert SEEDED_DIR.is_dir(), f"{SEEDED_DIR} is missing"
    result = subprocess.run(
        [sys.executable, "-m", "pytest", "-q"],
        cwd=str(SEEDED_DIR),
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr


def test_plain_pytest_does_not_collect_the_oracle():
    assert ORACLE.exists(), f"{ORACLE} is missing"
    result = subprocess.run(
        [sys.executable, "-m", "pytest", "--collect-only", "-q", str(SCRIPTS_TESTS_DIR)],
        capture_output=True,
        text=True,
    )
    assert "planted_violation_oracle" not in result.stdout


def test_oracle_fails_against_the_seeded_copy():
    assert ORACLE.exists(), f"{ORACLE} is missing"
    assert SEEDED_SRC.is_dir(), f"{SEEDED_SRC} is missing"
    result = run_oracle(SEEDED_SRC)
    assert result.returncode != 0, result.stdout + result.stderr


def test_oracle_passes_against_the_original():
    assert ORACLE.exists(), f"{ORACLE} is missing"
    assert LINK_AUDIT_SRC.is_dir(), f"{LINK_AUDIT_SRC} is missing"
    result = run_oracle(LINK_AUDIT_SRC)
    assert result.returncode == 0, result.stdout + result.stderr


def test_seeded_copy_differs_from_the_original_by_one_hunk():
    assert SEEDED_SRC.is_dir(), f"{SEEDED_SRC} is missing"
    hunks = find_planted_hunks()
    assert len(hunks) == 1, f"expected exactly one differing hunk, found {hunks}"


def test_readme_names_the_planted_file():
    relative_path, _ = find_planted_hunks()[0]
    readme = read_readme()
    assert relative_path in readme or f"src/link_audit/{relative_path}" in readme, (
        f"README.md does not name {relative_path}"
    )


def test_readme_states_the_planted_line_number():
    _, line_number = find_planted_hunks()[0]
    readme = read_readme()
    assert re.search(rf"\bline\s+{line_number}\b", readme), (
        f"README.md does not state 'line {line_number}'"
    )


def test_readme_describes_the_planted_fault_in_one_sentence():
    readme = read_readme()
    sentences = [s.strip() for s in re.split(r"(?<=[.!?])\s+", readme) if s.strip()]
    fault_sentences = [s for s in sentences if re.search(r"\bfault\b", s, re.IGNORECASE)]
    assert fault_sentences, "no sentence in README.md mentions the planted fault"
    assert any(4 <= len(s.split()) <= 40 for s in fault_sentences), (
        "no fault sentence in README.md reads as one plain sentence"
    )


def test_readme_cites_the_broken_functional_requirement():
    spec = (SEEDED_DIR / "specs" / "001-link-audit" / "spec.md").read_text(encoding="utf-8")
    fr_ids = set(re.findall(r"\bFR-\d{3}\b", spec))
    assert fr_ids, "the copy's spec.md names no FR- id"
    readme = read_readme()
    cited = set(re.findall(r"\bFR-\d{3}\b", readme))
    assert cited & fr_ids, "README.md cites no FR- id that appears in the copy's spec.md"


def test_copied_hook_test_suite_still_reports_clean():
    progress = SEEDED_DIR / "specs" / "001-link-audit" / "progress.yml"
    assert progress.exists(), f"{progress} is missing; copy it from link-audit"
    result = subprocess.run(
        ["bash", ".claude/hooks/tests/run.sh"],
        cwd=str(REPO_ROOT),
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    assert re.search(r"\b0 failed\b", result.stdout), result.stdout
