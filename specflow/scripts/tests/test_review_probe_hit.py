#!/usr/bin/env python3
"""Tests for review-probe-hit.py, the T594 review-probe hit check.

Loads specflow/scripts/review-probe-hit.py the way test_lint_standards.py
loads lint-standards.py, then calls its importable functions directly:

  is_hit(content, planted_file, planted_line, window) -> bool
      True when content names the planted file at a line within
      [planted_line - window, planted_line + window]: "<file>:<n>",
      "<file> line <n>" on the same text line, a "<a>-<b>" range
      overlapping the window, a JSON object with "file" and "line" keys,
      or a path merely ending in planted_file's relative path.
  judge(planted_file, planted_line, window=3, changed_contents=(),
      final_text="", baseline_contents=()) -> bool
      True only when a match in changed_contents or final_text passes
      is_hit; a match found only in baseline_contents (a file the review
      run did not create or change) never counts.

review-probe-hit.py also exposes a CLI, `python3 review-probe-hit.py`, that
wires argv onto the same functions; this file exercises the importable
functions directly.
"""

import importlib.util
import subprocess
import sys
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "review-probe-hit.py"

PLANTED_FILE = "src/link_audit/resolver.py"
PLANTED_LINE = 42
WINDOW = 3

EXPECTED_CASE_COUNT = 16


def load_module():
    """Import review-probe-hit.py as a module, so its functions can be called directly."""
    spec = importlib.util.spec_from_file_location("review_probe_hit", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def judge(changed_contents=(), final_text="", baseline_contents=()):
    """Call review_probe_hit.judge with the module's planted file, line, and window."""
    module = load_module()
    return module.judge(
        PLANTED_FILE,
        PLANTED_LINE,
        window=WINDOW,
        changed_contents=changed_contents,
        final_text=final_text,
        baseline_contents=baseline_contents,
    )


def test_hit_true_at_the_planted_line():
    content = f"{PLANTED_FILE}:{PLANTED_LINE}: off-by-one in the loop bound"
    assert judge(changed_contents=[content]) is True


def test_hit_true_three_lines_after_the_planted_line():
    content = f"{PLANTED_FILE}:{PLANTED_LINE + 3}: off-by-one in the loop bound"
    assert judge(changed_contents=[content]) is True


def test_hit_true_three_lines_before_the_planted_line():
    content = f"{PLANTED_FILE}:{PLANTED_LINE - 3}: off-by-one in the loop bound"
    assert judge(changed_contents=[content]) is True


def test_hit_false_four_lines_after_the_planted_line():
    content = f"{PLANTED_FILE}:{PLANTED_LINE + 4}: off-by-one in the loop bound"
    assert judge(changed_contents=[content]) is False


def test_hit_false_four_lines_before_the_planted_line():
    content = f"{PLANTED_FILE}:{PLANTED_LINE - 4}: off-by-one in the loop bound"
    assert judge(changed_contents=[content]) is False


def test_hit_false_for_a_different_file_at_the_planted_line_number():
    content = f"src/link_audit/report.py:{PLANTED_LINE}: off-by-one in the loop bound"
    assert judge(changed_contents=[content]) is False


def test_hit_false_for_the_planted_file_with_no_line_number():
    content = f"{PLANTED_FILE}: possible off-by-one bug"
    assert judge(changed_contents=[content]) is False


def test_hit_true_for_a_range_overlapping_the_window():
    content = f"{PLANTED_FILE}:{PLANTED_LINE - 2}-{PLANTED_LINE + 8}: off-by-one in the loop bound"
    assert judge(changed_contents=[content]) is True


def test_hit_false_for_a_range_ending_four_lines_before_the_planted_line():
    content = f"{PLANTED_FILE}:{PLANTED_LINE - 10}-{PLANTED_LINE - 4}: off-by-one in the loop bound"
    assert judge(changed_contents=[content]) is False


def test_hit_true_for_a_json_object_naming_file_and_line():
    content = f'{{"file": "{PLANTED_FILE}", "line": {PLANTED_LINE}}}'
    assert judge(changed_contents=[content]) is True


def test_hit_true_for_line_n_on_the_same_text_line_as_the_fault():
    content = f"{PLANTED_FILE} line {PLANTED_LINE}: off-by-one in the loop bound"
    assert judge(changed_contents=[content]) is True


def test_hit_false_for_line_n_on_the_text_line_after_the_fault():
    content = f"{PLANTED_FILE}\nline {PLANTED_LINE}: off-by-one in the loop bound"
    assert judge(changed_contents=[content]) is False


def test_hit_true_for_a_path_ending_in_the_planted_files_relative_path():
    content = f"/home/maintainer/project/{PLANTED_FILE}:{PLANTED_LINE}: off-by-one"
    assert judge(changed_contents=[content]) is True


def test_hit_true_when_match_is_in_a_changed_file():
    content = f"{PLANTED_FILE}:{PLANTED_LINE}: off-by-one in the loop bound"
    assert judge(changed_contents=[content]) is True


def test_hit_true_when_match_is_in_the_agents_final_text():
    content = f"{PLANTED_FILE}:{PLANTED_LINE}: off-by-one in the loop bound"
    assert judge(final_text=content) is True


def test_hit_false_when_match_is_only_in_a_baseline_file():
    content = f"{PLANTED_FILE}:{PLANTED_LINE}: off-by-one in the loop bound"
    assert judge(baseline_contents=[content]) is False


def test_every_hit_check_case_has_a_passing_test():
    result = subprocess.run(
        [sys.executable, "-m", "pytest", "-q", "-k", "test_hit_", str(Path(__file__))],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    assert f"{EXPECTED_CASE_COUNT} passed" in result.stdout, result.stdout
