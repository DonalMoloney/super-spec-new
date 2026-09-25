#!/usr/bin/env bash
# Prints per-reviewer finding precision, fixed divided by fixed, rejected, and
# rebutted, then writes the same lines to .claude/review/scorecard.md. Reads
# the findings globs merge-gate.sh reads, from the consuming project's root,
# and skips a file that fails validation against findings-schema.json.
set -euo pipefail
findings_globs=(".claude/review/*.json" "specs/*/review-findings.json")
# scorecard.sh is invoked from the consuming project's root, so the validator
# is found beside this script rather than under the working directory.
VALIDATOR="$(cd "$(dirname "$0")" && pwd)/validate-findings.py"
OUTPUT_FILE=".claude/review/scorecard.md"

status_log="$(mktemp)"
trap 'rm -f "$status_log"' EXIT

for findings_glob in "${findings_globs[@]}"; do
  for file in $findings_glob; do
    [ -e "$file" ] || continue
    if ! python3 "$VALIDATOR" "$file" >/dev/null 2>&1; then
      echo "scorecard: $file does not validate against findings-schema.json; skipped." >&2
      continue
    fi
    jq -r '.reviewer as $persona | .findings[] | [$persona, (.status // "open")] | @tsv' "$file" >> "$status_log"
  done
done

report="$(awk -F'\t' '
  {
    key = $1 SUBSEP $2
    counts[key]++
    if (!($1 in seen)) { seen[$1] = 1; order[++n] = $1 }
  }
  END {
    for (i = 1; i <= n; i++) {
      persona = order[i]
      fixed = counts[persona SUBSEP "fixed"] + 0
      rejected = counts[persona SUBSEP "rejected"] + 0
      rebutted = counts[persona SUBSEP "rebutted"] + 0
      denominator = fixed + rejected + rebutted
      precision = (denominator > 0) ? fixed / denominator : 0
      printf "%s %.2f (%d fixed, %d rejected, %d rebutted)\n", persona, precision, fixed, rejected, rebutted
    }
  }
' "$status_log")"

mkdir -p "$(dirname "$OUTPUT_FILE")"
if [ -n "$report" ]; then
  printf '%s\n' "$report" | tee "$OUTPUT_FILE"
else
  : > "$OUTPUT_FILE"
fi
