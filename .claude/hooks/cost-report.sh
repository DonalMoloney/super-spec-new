#!/usr/bin/env bash
# Stop hook. Sums the dollars each feature recorded in .claude/telemetry.jsonl
# and reports every feature past SPECFLOW_BUDGET_USD, the ceiling the headless
# example in workflow-guide.md passes to --max-budget-usd. Only a headless run
# writes total_cost_usd, so a line the Stop hook wrote adds nothing to a sum.
# Exit 1 means a feature is over the ceiling; exit 3 means no sum was read.
# A Stop hook that exits 2 blocks the turn and feeds stderr back to the agent,
# so no path here uses that code.
set -uo pipefail
DEFAULT_BUDGET_USD="1.00"
UNREADABLE=3
TELEMETRY=".claude/telemetry.jsonl"
ceiling="${SPECFLOW_BUDGET_USD:-$DEFAULT_BUDGET_USD}"
if ! [[ "$ceiling" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
  echo "cost-report: SPECFLOW_BUDGET_USD is '$ceiling'; expected a dollar amount such as 1.00." >&2
  exit "$UNREADABLE"
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "cost-report: jq is not on PATH; expected jq to read $TELEMETRY. Install jq." >&2
  exit "$UNREADABLE"
fi
[ -f "$TELEMETRY" ] || exit 0

if ! rollup="$(jq -s -r --argjson ceiling "$ceiling" '
      map(select(.total_cost_usd))
      | group_by(.feature)
      | map({feature: .[0].feature, spend: (map(.total_cost_usd) | add)})
      | .[] | "\(.feature) \(.spend) \(.spend > $ceiling)"' "$TELEMETRY" 2>&1)"; then
  echo "cost-report: jq could not read $TELEMETRY; expected one JSON object per line. jq reported: $rollup" >&2
  exit "$UNREADABLE"
fi
[ -n "$rollup" ] || exit 0

over=0
while read -r feature spend past_ceiling; do
  echo "$feature $spend / $ceiling"
  if [ "$past_ceiling" = "true" ]; then
    over=$((over + 1))
    echo "BUDGET EXCEEDED: $feature spent $spend USD; expected at most $ceiling USD. Raise SPECFLOW_BUDGET_USD or split the feature." >&2
  fi
done <<< "$rollup"

[ "$over" -eq 0 ] || exit 1
exit 0
