#!/usr/bin/env python3
"""CLI-level tests for review-probe-hit.py: arguments, exit codes, and stdout.

test_review_probe_hit.py exercises is_hit and judge directly, as importable
functions. This file exercises the same script through its command line
instead, the surface compare-upstream.sh's review_probe_entry actually
calls: a missing or malformed argument, and the hit/miss exit codes and
stdout lines main() produces.
"""

import subprocess
import sys
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "review-probe-hit.py"

PLANTED_FILE = "src/link_audit/resolver.py"
PLANTED_LINE = "42"


def run_cli(args):
    """Run review-probe-hit.py with args and return the completed process."""
    return subprocess.run(
        [sys.executable, str(SCRIPT), *args],
        capture_output=True,
        text=True,
    )


def test_missing_planted_file_exits_2_and_names_the_flag_on_stderr():
    result = run_cli(["--planted-line", PLANTED_LINE])
    assert result.returncode == 2, result.stdout + result.stderr
    assert "--planted-file" in result.stderr


def test_missing_planted_line_exits_2_and_names_the_flag_on_stderr():
    result = run_cli(["--planted-file", PLANTED_FILE])
    assert result.returncode == 2, result.stdout + result.stderr
    assert "--planted-line" in result.stderr


def test_planted_line_given_as_non_integer_exits_2():
    result = run_cli(["--planted-file", PLANTED_FILE, "--planted-line", "abc"])
    assert result.returncode == 2, result.stdout + result.stderr
    assert "--planted-line" in result.stderr


def test_a_hit_prints_hit_and_exits_0(tmp_path):
    changed = tmp_path / "changed.txt"
    changed.write_text(f"{PLANTED_FILE}:{PLANTED_LINE}: off-by-one\n")
    result = run_cli(
        [
            "--planted-file", PLANTED_FILE,
            "--planted-line", PLANTED_LINE,
            "--changed-file", str(changed),
        ]
    )
    assert result.returncode == 0, result.stdout + result.stderr
    assert result.stdout.strip() == "hit"


def test_a_miss_prints_miss_and_exits_1(tmp_path):
    changed = tmp_path / "changed.txt"
    changed.write_text("no mention of the planted file here\n")
    result = run_cli(
        [
            "--planted-file", PLANTED_FILE,
            "--planted-line", PLANTED_LINE,
            "--changed-file", str(changed),
        ]
    )
    assert result.returncode == 1, result.stdout + result.stderr
    assert result.stdout.strip() == "miss"


def test_a_miss_with_no_changed_or_final_text_file_still_prints_miss():
    result = run_cli(["--planted-file", PLANTED_FILE, "--planted-line", PLANTED_LINE])
    assert result.returncode == 1, result.stdout + result.stderr
    assert result.stdout.strip() == "miss"


def test_window_is_not_a_recognized_argument(tmp_path):
    changed = tmp_path / "changed.txt"
    changed.write_text(f"{PLANTED_FILE}:50: off-by-one\n")
    result = run_cli(
        [
            "--planted-file", PLANTED_FILE,
            "--planted-line", PLANTED_LINE,
            "--window", "8",
            "--changed-file", str(changed),
        ]
    )
    assert result.returncode == 2, result.stdout + result.stderr
    assert "--window" in result.stderr


def test_final_text_file_alone_can_produce_a_hit(tmp_path):
    final_text = tmp_path / "final.txt"
    final_text.write_text(f"{PLANTED_FILE}:{PLANTED_LINE}: off-by-one\n")
    result = run_cli(
        [
            "--planted-file", PLANTED_FILE,
            "--planted-line", PLANTED_LINE,
            "--final-text-file", str(final_text),
        ]
    )
    assert result.returncode == 0, result.stdout + result.stderr
    assert result.stdout.strip() == "hit"
