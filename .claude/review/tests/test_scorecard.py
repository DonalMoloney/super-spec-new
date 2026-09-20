"""Behavior of .claude/review/scorecard.sh, exercised through its CLI."""

import json
import subprocess
from pathlib import Path

REVIEW_DIR = Path(__file__).resolve().parents[1]
SCORECARD = REVIEW_DIR / "scorecard.sh"

FOUR_FINDINGS = {
    "schema_version": "1.0",
    "reviewer": "correctness-reviewer",
    "model": "sonnet",
    "stage": "correctness",
    "verdict": "CONCERNS",
    "findings": [
        {
            "id": "F001",
            "severity": "Important",
            "category": "error-handling",
            "location": "specflow/scripts/e2e-smoke.sh:42",
            "evidence": "standards/code.md forbids swallowing an exception",
            "fix": "Re-raise with the failing path in the message.",
            "status": "fixed",
        },
        {
            "id": "F002",
            "severity": "Minor",
            "category": "naming",
            "location": "specflow/scripts/e2e-smoke.sh:50",
            "evidence": "standards/code.md rejects the name data",
            "fix": "Rename to changed_files.",
            "status": "fixed",
        },
        {
            "id": "F003",
            "severity": "Important",
            "category": "error-handling",
            "location": "specflow/scripts/e2e-smoke.sh:60",
            "evidence": "standards/code.md forbids a blanket except",
            "fix": "Catch the specific exception.",
            "status": "rejected",
        },
        {
            "id": "F004",
            "severity": "Minor",
            "category": "naming",
            "location": "specflow/scripts/e2e-smoke.sh:70",
            "evidence": "standards/code.md rejects the name temp",
            "fix": "Rename to staging_dir.",
            "status": "rejected",
        },
    ],
}


def run_scorecard(cwd):
    return subprocess.run(
        ["bash", str(SCORECARD)],
        cwd=cwd,
        capture_output=True,
        text=True,
    )


def test_prints_precision_for_a_single_reviewer(tmp_path):
    review_dir = tmp_path / ".claude" / "review"
    review_dir.mkdir(parents=True)
    (review_dir / "findings.json").write_text(json.dumps(FOUR_FINDINGS))

    result = run_scorecard(tmp_path)

    assert result.returncode == 0, result.stderr
    assert "correctness-reviewer 0.50 (2 fixed, 2 rejected, 0 rebutted)" in result.stdout
