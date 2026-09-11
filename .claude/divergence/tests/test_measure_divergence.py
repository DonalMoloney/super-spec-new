"""Behavior of .claude/divergence/measure-divergence.py, exercised through its CLI."""

import subprocess
import sys
from pathlib import Path

MEASURE = Path(__file__).resolve().parents[1] / "measure-divergence.py"

UPSTREAM_TEXT = "\n".join(
    [
        "# superspec.status",
        "",
        "Show SuperSpec progress.",
        "",
        "1. Scan the directory",
        "2. Check the constitution",
        "3. Print the summary",
        "4. Suggest the next step",
        "",
    ]
)


def write_pair(tmp_path, local_text, upstream_text=UPSTREAM_TEXT):
    local = tmp_path / "specflow"
    upstream = tmp_path / "upstream"
    (local / "commands").mkdir(parents=True)
    (upstream / "commands").mkdir(parents=True)
    (local / "commands" / "status.md").write_text(local_text)
    (upstream / "commands" / "status.md").write_text(upstream_text)
    return local, upstream


def run(local, upstream, *paths):
    return subprocess.run(
        [sys.executable, str(MEASURE), "--local", str(local), "--upstream", str(upstream), *paths],
        capture_output=True,
        text=True,
    )


def test_reports_zero_for_a_byte_identical_file(tmp_path):
    local, upstream = write_pair(tmp_path, UPSTREAM_TEXT)
    result = run(local, upstream, "commands/status.md")
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "commands/status.md raw=0% real=0%"


def test_rebrand_tokens_count_as_raw_but_not_real(tmp_path):
    rebranded = UPSTREAM_TEXT.replace("superspec", "specflow").replace("SuperSpec", "SpecFlow")
    local, upstream = write_pair(tmp_path, rebranded)
    result = run(local, upstream, "commands/status.md")
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "commands/status.md raw=25% real=0%"


def test_rewritten_prose_raises_real_divergence(tmp_path):
    rewritten = UPSTREAM_TEXT.replace("Show SuperSpec progress.", "Print each feature's phase and open questions.")
    local, upstream = write_pair(tmp_path, rewritten)
    result = run(local, upstream, "commands/status.md")
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "commands/status.md raw=12% real=12%"


def test_missing_upstream_counterpart_fails_naming_the_path(tmp_path):
    local, upstream = write_pair(tmp_path, UPSTREAM_TEXT)
    (local / "commands" / "extra.md").write_text("Only here.\n")
    result = run(local, upstream, "commands/extra.md")
    assert result.returncode == 2
    assert "commands/extra.md" in result.stderr
    assert "no upstream counterpart" in result.stderr


def test_missing_local_file_fails_naming_the_path(tmp_path):
    local, upstream = write_pair(tmp_path, UPSTREAM_TEXT)
    result = run(local, upstream, "commands/gone.md")
    assert result.returncode == 2
    assert "commands/gone.md" in result.stderr
