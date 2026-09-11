#!/usr/bin/env bash
# Marks every finding in one document "rebutted" so merge-gate.sh stops blocking
# on it. CI calls it when the pull request carries the findings-rebutted label;
# the label is the reviewer-of-record's signature and the argument is the
# rebuttal's provenance. The headless findings file is never committed, so the
# label is the only way a status change reaches it. ADR-0012.
set -euo pipefail
findings_file="${1:-}"
reason="${2:-}"
if [ -z "$findings_file" ] || [ ! -f "$findings_file" ]; then
  echo "rebut-findings: findings document '$findings_file' not found; expected the path of a file matching .claude/review/schema.json. Pass the file as the first argument." >&2
  exit 2
fi
if [ -z "$reason" ]; then
  echo "rebut-findings: reason is empty; expected text naming where the rebuttal is recorded. Pass it as the second argument." >&2
  exit 2
fi
rebutted="$(jq --arg reason "$reason" '.findings |= map(.status = "rebutted" | .rebuttal = $reason)' "$findings_file")"
printf '%s\n' "$rebutted" > "$findings_file"
echo "rebut-findings: marked $(jq '.findings | length' "$findings_file") finding(s) in $findings_file rebutted."
