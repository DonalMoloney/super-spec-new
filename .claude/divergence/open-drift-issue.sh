#!/usr/bin/env bash
# .claude/divergence/open-drift-issue.sh
#
# Files the upstream-drift report as an issue, and files nothing when an issue
# with the same title is already open. The weekly workflow runs every Monday,
# so without this check a single unresynced week would reopen the same report
# indefinitely.
#
# Usage: bash .claude/divergence/open-drift-issue.sh <report-file>
# Exit code: 0 when the drift issue is open afterwards, 2 on a bad argument or
# a failed gh call.
set -uo pipefail

# The de-duplication key. Changing it opens a second issue alongside any open
# one, so change it only when the old issue is closed.
DRIFT_TITLE="Upstream superspec has moved past the vendored commit"
ERROR_EXIT=2
# gh pages at 30 issues by default, which can hide an older open drift issue.
ISSUE_PAGE_LIMIT=200

report="${1:-}"
if [ -z "$report" ] || [ ! -f "$report" ]; then
  echo "open-drift-issue.sh needs a readable report file; got '${report:-no argument}'. Pass the file check-upstream.sh wrote." >&2
  exit "$ERROR_EXIT"
fi

if ! open_issues="$(gh issue list --state open --limit "$ISSUE_PAGE_LIMIT" --json title)"; then
  echo "gh issue list failed. Check that GH_TOKEN carries issue read access, then rerun." >&2
  exit "$ERROR_EXIT"
fi

# Titles are matched exactly rather than searched, because GitHub's search
# index lags a fresh issue and a lagging search opens a duplicate.
if printf '%s' "$open_issues" | python3 -c '
import json
import sys

titles = [issue["title"] for issue in json.load(sys.stdin)]
sys.exit(0 if sys.argv[1] in titles else 1)
' "$DRIFT_TITLE"; then
  echo "An issue titled \"$DRIFT_TITLE\" is already open. Filing nothing."
  exit 0
fi

if ! gh issue create --title "$DRIFT_TITLE" --body-file "$report"; then
  echo "gh issue create failed. Check that GH_TOKEN carries issue write access, then rerun." >&2
  exit "$ERROR_EXIT"
fi
