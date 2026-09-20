#!/usr/bin/env bash
# Blocks a merge while a Critical or Important finding is unresolved. A finding
# counts as resolved only when its status is "fixed" or "rebutted"; the critic
# stage judges a rebuttal and files its own finding when the rebuttal fails.
# Minor findings never block. By default it reads the reviewer agents' documents
# and the one /speckit.specflow.review writes per feature. Pass one or more globs
# to read findings elsewhere instead.
set -euo pipefail
if [ "$#" -gt 0 ]; then
  findings_globs=("$@")
else
  findings_globs=(".claude/review/*.json" "specs/*/review-findings.json")
fi
MARKER=".claude/review/.merge-approved"
SCHEMA_FILE="schema.json" # a project that copies the contract beside its reports
# The gate runs from the consuming project's root, so the validator is found
# beside this script rather than under the working directory.
VALIDATOR="$(cd "$(dirname "$0")/../python" && pwd)/validate-findings.py"
count_unresolved() { # severity file -> number of findings that still block
  jq --arg severity "$1" '
    [ .findings[]
      | select(.severity == $severity)
      | select((.status // "open") != "fixed" and (.status // "open") != "rebutted")
    ] | length' "$2"
}
# A marker left by an earlier run would outlive the findings that earned it.
rm -f "$MARKER"
unresolved_critical=0
unresolved_important=0
for findings_glob in "${findings_globs[@]}"; do
  for file in $findings_glob; do
    [ -e "$file" ] || continue
    if [ "$(basename "$file")" = "$SCHEMA_FILE" ]; then continue; fi
    if ! critical_in_file="$(count_unresolved Critical "$file")"; then
      echo "merge-gate: $file does not parse as a findings document; expected an object with a findings array matching references/findings-schema.json. Fix the file or move it out of the review directory." >&2
      exit 1
    fi
    if ! schema_violation="$(python3 "$VALIDATOR" "$file" 2>&1 >/dev/null)"; then
      echo "merge-gate: $schema_violation; expected a document matching references/findings-schema.json. Fix the finding, then rerun the gate." >&2
      exit 1
    fi
    important_in_file="$(count_unresolved Important "$file")"
    unresolved_critical=$((unresolved_critical + critical_in_file))
    unresolved_important=$((unresolved_important + important_in_file))
  done
done
if [ "$unresolved_critical" -gt 0 ]; then
  echo "MERGE BLOCKED: Critical findings unresolved: $unresolved_critical. Expected 0. Fix or rebut each finding, then rerun." >&2
  exit 1
fi
if [ "$unresolved_important" -gt 0 ]; then
  echo "MERGE BLOCKED: Important findings unresolved: $unresolved_important. Expected 0. Fix or rebut each finding, then rerun." >&2
  exit 1
fi
mkdir -p "$(dirname "$MARKER")"
touch "$MARKER"
echo "MERGE GATE PASSED."
