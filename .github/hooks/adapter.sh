#!/usr/bin/env bash
# Runs specflow/gates/bash/agent-event.sh for a Copilot CLI native hook.
# .github/hooks/hooks.json calls this as "adapter.sh <event>" with the Copilot
# payload on stdin. agent-event.sh reads toolArgs as an object or a JSON
# string, picks the gates, and prints Copilot's response JSON (ADR-0034); this
# script adds the event the native loader names, the exit code on a block, and
# the sessionStart wrap (ADR-0035).
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "adapter.sh: jq is not installed; the adapter reads the hook payload with it. Install jq (brew install jq, apt-get install jq), then rerun the hook." >&2
  exit 1
fi

BLOCK_EXIT=2
event="${1:?adapter.sh: missing event (preToolUse, postToolUse, or sessionStart)}"
agent_event="$(cd "$(dirname "$0")" && pwd)/../../specflow/gates/bash/agent-event.sh"

if [ ! -f "$agent_event" ]; then
  echo "adapter.sh: agent-event.sh not found at $agent_event; expected the specflow/ directory beside .github/. Restore specflow/gates/bash/agent-event.sh." >&2
  exit 1
fi

# agent-event.sh names the event from the payload's shape: toolResult means
# postToolUse, toolName alone means preToolUse, neither means sessionStart.
case "$event" in
preToolUse) shape='del(.toolResult) | .toolName //= ""' ;;
postToolUse) shape='.toolResult //= {} | .toolName //= ""' ;;
sessionStart) shape='del(.toolName, .toolResult)' ;;
*)
  echo "adapter.sh: unknown event '$event'; expected preToolUse, postToolUse, or sessionStart" >&2
  exit 1
  ;;
esac

payload="$(cat)"
# A payload that is not a JSON object passes through unshaped, so agent-event.sh
# rejects it with its own message.
shaped="$(printf '%s' "$payload" | jq -c "if type == \"object\" then $shape else . end" 2>/dev/null)" || shaped="$payload"

if [ "$event" = "sessionStart" ]; then
  # The events: dispatcher wraps session_start stdout for Copilot; the native
  # loader passes stdout through, so the wrap happens here.
  context="$(printf '%s' "$shaped" | bash "$agent_event")"
  [ -z "$context" ] || jq -nc --arg ctx "$context" '{additionalContext: $ctx}'
  exit 0
fi

status=0
response="$(printf '%s' "$shaped" | bash "$agent_event")" || status=$?
[ -z "$response" ] || printf '%s' "$response" | jq -c .
# docs.github.com/en/copilot/reference/hooks-reference: Copilot reads a deny or
# additionalContext from stdout, so a block exits 0 with the JSON.
[ "$status" -eq "$BLOCK_EXIT" ] && exit 0
exit "$status"
