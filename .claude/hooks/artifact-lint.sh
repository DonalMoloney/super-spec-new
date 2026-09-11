#!/usr/bin/env bash
# PostToolUse hook (matcher: Edit|Write). Validates the structure of a just
# edited spec.md / plan.md / tasks.md / checklist-*.md against specflow's templates. Exit 2
# feeds the findings back to Claude so it fixes them before moving on.
# Required sections mirror the *(mandatory)* headings in specflow/templates/.
set -euo pipefail
input="$(cat)"
path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')"
[ -n "$path" ] && [ -f "$path" ] || exit 0
fail=0
err(){ echo "ARTIFACT LINT ($(basename "$path")): $1" >&2; fail=1; }
require_sections(){ for s in "$@"; do grep -qF "$s" "$path" || err "missing section: $s"; done; }
case "$(basename "$path")" in
  spec.md)
    require_sections "## User Scenarios & Testing" "## Requirements" "## Success Criteria"
    if [ -f "$(dirname "$path")/.clarified" ] && grep -q 'NEEDS CLARIFICATION' "$path"; then
      err "still has NEEDS CLARIFICATION markers after the clarify gate"
    fi
    ;;
  plan.md)
    require_sections "## Summary" "## Technical Context" "## Constitution Check"
    ;;
  checklist-*.md)
    grep -Eq '^[[:space:]]*[-*+][[:space:]]+\[[ xX]\]([[:space:]]|$)' "$path" || err "no checkbox lines (expected '- [ ] ...' or '- [x] ...')"
    ;;
  tasks.md)
    grep -Eq '^- \[[ xX]\] T[0-9]{3}' "$path" || err "no task lines with stable IDs (expected '- [ ] T001 ...')"
    # [P] in prose (the task-format legend) is fine; on a checkbox line it must follow a T-id.
    if grep -E '^- \[[ xX]\].*\[P\]' "$path" | grep -vqE '^- \[[ xX]\] T[0-9]{3}'; then
      err "malformed [P] marker: a checkbox line with [P] must start with '- [ ] TNNN'"
    fi
    ;;
esac
[ "$fail" -eq 0 ] || exit 2
exit 0
