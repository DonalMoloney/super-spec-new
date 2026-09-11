#!/usr/bin/env bash
# PostToolUse hook (matcher: Edit|Write). If an edit just ticked a task
# ([x]) in a tasks.md, the project's test command must pass; otherwise exit 2
# so Claude has to un-tick it or fix the tests. Override the command with
# SPECFLOW_TEST_CMD (default: this repo's extension-metadata validator).
set -euo pipefail
input="$(cat)"
path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')"
TEST_CMD="${SPECFLOW_TEST_CMD:-cd specflow && python3 scripts/validate-extension-metadata.py}"
case "$path" in
  *tasks.md)
    if git diff -- "$path" 2>/dev/null | grep -Eq '^\+.*\[[xX]\]'; then
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
