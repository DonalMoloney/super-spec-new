"""Behavior of .claude/review/validate-findings.py, exercised through its CLI."""

import json
import subprocess
import sys
from pathlib import Path

REVIEW_DIR = Path(__file__).resolve().parents[1]
VALIDATOR = REVIEW_DIR / "validate-findings.py"

VALID_FINDINGS = {
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
            "status": "open",
        }
    ],
}


def run_validator(tmp_path, document):
    path = tmp_path / "findings.json"
    path.write_text(json.dumps(document))
    return subprocess.run(
        [sys.executable, str(VALIDATOR), str(path)],
        capture_output=True,
        text=True,
    )


def test_accepts_a_valid_findings_document(tmp_path):
    result = run_validator(tmp_path, VALID_FINDINGS)
    assert result.returncode == 0, result.stderr


def test_rejects_document_missing_verdict(tmp_path):
    document = {k: v for k, v in VALID_FINDINGS.items() if k != "verdict"}
    result = run_validator(tmp_path, document)
    assert result.returncode == 1
    assert "verdict" in result.stderr


def test_rejects_finding_with_unknown_severity(tmp_path):
    document = json.loads(json.dumps(VALID_FINDINGS))
    document["findings"][0]["severity"] = "Blocker"
    result = run_validator(tmp_path, document)
    assert result.returncode == 1
    assert "findings[0].severity" in result.stderr
