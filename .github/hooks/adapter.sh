#!/usr/bin/env bash
# Bridges a Copilot CLI hook payload to a .claude/hooks/*.sh gate script.
# .github/hooks/hooks.json calls this as "adapter.sh <event> <gate>" and
# pipes the Copilot payload to it on stdin. The gate script itself stays on
# the Claude Code payload schema (ADR-0001); this script translates on the
# way in and translates the exit code back to Copilot's response envelope on
# the way out.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "adapter.sh: jq is not installed; the adapter reads the hook payload with it. Install jq (brew install jq, apt-get install jq), then rerun the hook." >&2
  exit 1
fi

event="${1:?adapter.sh: missing event (preToolUse, postToolUse, or sessionStart)}"
gate="${2:?adapter.sh: missing gate script name}"
script_dir="$(cd "$(dirname "$0")" && pwd)"
gate_path="$script_dir/../../.claude/hooks/$gate"

if [ ! -f "$gate_path" ]; then
  echo "adapter.sh: gate script not found at $gate_path" >&2
  exit 1
fi

payload="$(cat)"

if [ "$event" = "sessionStart" ]; then
  context="$(printf '%s' "$payload" | bash "$gate_path")"
  [ -n "$context" ] && jq -nc --arg ctx "$context" '{additionalContext: $ctx}'
  exit 0
fi

# docs/agent-event-mapping.md's field-mapping table: Copilot's toolArgs.command
# and toolArgs.path become tool_input.command and tool_input.file_path, the
# names every .claude/hooks/*.sh gate reads. A field absent from the Copilot
# payload becomes an empty string, which each gate already treats as "no
# match" rather than an error.
claude_payload="$(printf '%s' "$payload" | jq -c '{
  tool_input: {
    command: (.toolArgs.command // ""),
    file_path: (.toolArgs.path // "")
  }
}')"

set +e
reason="$(printf '%s' "$claude_payload" | bash "$gate_path" 2>&1 >/dev/null)"
status=$?
set -e

[ "$status" -eq 2 ] || exit 0

case "$event" in
preToolUse)
  # docs.github.com/en/copilot/reference/hooks-reference: a preToolUse hook
  # denies the call with permissionDecision "deny" and a required
  # permissionDecisionReason.
  jq -nc --arg reason "$reason" '{permissionDecision: "deny", permissionDecisionReason: $reason}'
  ;;
postToolUse)
  # The tool already ran by postToolUse, so Copilot's response has no deny
  # field there; additionalContext is the only way to surface the gate's
  # finding to the model.
  jq -nc --arg ctx "$reason" '{additionalContext: $ctx}'
  ;;
*)
  echo "adapter.sh: unknown event '$event'; expected preToolUse, postToolUse, or sessionStart" >&2
  exit 1
  ;;
esac
