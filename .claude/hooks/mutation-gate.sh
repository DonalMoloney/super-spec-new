#!/usr/bin/env bash
# Runs mutmut 3 on a project directory and blocks when the share of mutants the
# tests kill falls below MUTATION_THRESHOLD (default 80). Exit 1 means the score
# is too low; exit 2 means the score could not be measured. Counts and the
# threshold are whole numbers, so bash arithmetic replaces bc (ADR-0005).
set -euo pipefail
DEFAULT_THRESHOLD=80
STATS_FILE="mutants/mutmut-cicd-stats.json"
project_dir="${1:-}"
threshold="${MUTATION_THRESHOLD:-$DEFAULT_THRESHOLD}"
if [ -z "$project_dir" ]; then
  echo "mutation-gate: no project directory given; expected the path to a project holding a pyproject.toml with a [tool.mutmut] section. Usage: mutation-gate.sh <project-dir>." >&2
  exit 2
fi
if [ ! -d "$project_dir" ]; then
  echo "mutation-gate: '$project_dir' is not a directory; expected the path to a project holding a pyproject.toml with a [tool.mutmut] section." >&2
  exit 2
fi
if [ ! -f "$project_dir/pyproject.toml" ]; then
  echo "mutation-gate: '$project_dir' has no pyproject.toml; expected one with a [tool.mutmut] section naming source_paths. See specflow/examples/mutation-gate-sample." >&2
  exit 2
fi
case "$threshold" in
  ''|*[!0-9]*)
    echo "mutation-gate: MUTATION_THRESHOLD is '$threshold'; expected a whole number from 0 to 100." >&2
    exit 2 ;;
esac
if [ "$threshold" -gt 100 ]; then
  echo "mutation-gate: MUTATION_THRESHOLD is $threshold; expected a whole number from 0 to 100." >&2
  exit 2
fi
if ! command -v mutmut >/dev/null 2>&1; then
  echo "mutation-gate: mutmut is not on PATH; expected mutmut 3. Run: python3 -m pip install -r requirements-dev.txt." >&2
  exit 2
fi
cd "$project_dir"
# mutmut reuses cached verdicts from mutants/, which would hide a test removed since the last run.
rm -rf mutants
log="$(mktemp)"
if ! mutmut run >"$log" 2>&1; then
  echo "mutation-gate: mutmut run failed in $project_dir; expected the test suite to pass before mutation. Tail:" >&2
  tail -n 20 "$log" >&2
  rm -f "$log"
  exit 2
fi
rm -f "$log"
mutmut export-cicd-stats >/dev/null
killed="$(jq '.killed' "$STATS_FILE")"
survived="$(jq '.survived' "$STATS_FILE")"
total="$(jq '.total' "$STATS_FILE")"
if [ "$total" -eq 0 ]; then
  echo "mutation-gate: mutmut generated 0 mutants in $project_dir; expected at least one. Check source_paths in pyproject.toml." >&2
  exit 2
fi
score=$((killed * 100 / total))
if [ "$score" -lt "$threshold" ]; then
  echo "MUTATION GATE FAILED: mutation score ${score}%; expected >= ${threshold}%. $survived of $total mutants survived. Run 'mutmut results' in $project_dir to list them." >&2
  exit 1
fi
echo "MUTATION GATE PASSED: mutation score ${score}%; expected >= ${threshold}%. $killed of $total mutants killed."
