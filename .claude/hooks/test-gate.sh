#!/usr/bin/env bash
# PostToolUse hook (matcher: Edit|Write). If an edit just ticked a task
# ([x]) in a tasks.md, the project's test command must pass; otherwise exit 2
# so Claude has to un-tick it or fix the tests. SPECFLOW_TEST_CMD names the
# command when set. Otherwise the "Test command:" line in
# .specify/memory/constitution.md names it. Neither present skips the gate.
set -euo pipefail
input="$(cat)"
path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')"
CONSTITUTION=".specify/memory/constitution.md"
case "$path" in
  *tasks.md)
    if git diff -- "$path" 2>/dev/null | grep -Eq '^\+.*\[[xX]\]'; then
      if [ -n "${SPECFLOW_TEST_CMD:-}" ]; then
        TEST_CMD="$SPECFLOW_TEST_CMD"
      elif [ -f "$CONSTITUTION" ] && grep -q 'Test command:' "$CONSTITUTION"; then
        TEST_CMD="$(sed -n 's/.*Test command: *//p' "$CONSTITUTION" | head -n1)"
      else
        echo 'test-gate: no test command found (SPECFLOW_TEST_CMD unset, no "Test command:" line in .specify/memory/constitution.md); skipping' >&2
        exit 0
      fi
      echo "Task marked complete; running gate: $TEST_CMD" >&2
      log="$(mktemp)"
      if ! bash -c "$TEST_CMD" >"$log" 2>&1; then
        echo "TEST GATE FAILED: a task was marked [x] but the test command failed. Do not mark tasks complete on red. Tail:" >&2
        tail -n 20 "$log" >&2
        rm -f "$log"
        exit 2
      fi
      rm -f "$log"
    fi
    ;;
esac
exit 0
