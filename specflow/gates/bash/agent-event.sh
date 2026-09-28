#!/usr/bin/env bash
# spec-kit events: handler for pre_tool_use, post_tool_use, and session_start on
# Claude Code and the Copilot CLI. Reads the hook payload on stdin, names the
# event from the payload's own shape, and runs the sibling gates against a
# payload carrying `.tool_input.command` and `.tool_input.file_path`. Exit 2
# blocks: stderr carries the reason for Claude Code, and stdout carries the
# JSON the Copilot CLI parses. Any other nonzero exit is a gate error and
# propagates with the gate's own code and stderr.
set -euo pipefail
# ADR-0027: jq is an install-time dependency no manifest field declares. The
# check uses only builtins, so it runs before any external command.
if ! command -v jq >/dev/null 2>&1; then
  echo "agent-event: jq is not installed; the handler reads each hook payload with it. Install jq (brew install jq, apt-get install jq), then rerun." >&2
  exit 1
fi

BLOCK_EXIT=2
PRE_TOOL_USE_GATE="block-main-commit.sh"
POST_TOOL_USE_GATES=("test-gate.sh" "artifact-lint.sh")
SESSION_START_GATE="session-start.sh"
# Gates resolve beside this script; the working directory is the consuming project.
GATES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Claude Code names the event in `hook_event_name`. The Copilot CLI does not:
# only its postToolUse payload carries a `toolResult`, and only a tool call
# carries `toolName`. A present but null `toolResult` reads as pre_tool_use,
# because a payload the handler misreads as post_tool_use skips the commit gate.
CLASSIFY_EVENT='
  if has("hook_event_name") then
    if .hook_event_name == "PreToolUse" then "pre_tool_use"
    elif .hook_event_name == "PostToolUse" then "post_tool_use"
    elif .hook_event_name == "SessionStart" then "session_start"
    else "unmatched" end
  elif .toolResult != null then "post_tool_use"
  elif has("toolName") then "pre_tool_use"
  else "session_start" end'

# `toolArgs` parsed from a JSON string when it arrives as one; null when the
# string does not parse.
RESOLVE_TOOL_ARGS='def tool_args: .toolArgs | if type == "string" then (try fromjson catch null) else . end;'

# docs/agent-event-mapping.md maps `toolArgs.command` and `toolArgs.path` to the
# Claude Code fields. `toolArgs` arrives as an object or as a JSON string; any
# other value carries no field a gate reads. `file_path` carries through only
# when `$args` also holds `file_text`, `old_str`, or `new_str`: those are the
# write-shaped arguments of Copilot's create and edit tools and of
# str_replace_editor's create, str_replace, and insert commands, so a read
# tool such as `view` never triggers a post_tool_use gate meant for a write.
# `$args` is a jq variable.
# shellcheck disable=SC2016
NORMALIZE_PAYLOAD='
  if has("hook_event_name") then . else
    (tool_args | if type == "object" then . else {} end) as $args
    | {tool_input: ({command: $args.command,
        file_path: (if ($args.file_text != null or $args.old_str != null or $args.new_str != null)
          then $args.path else null end)}
        | with_entries(select(.value != null)))}
  end'

# An unreadable `toolArgs` normalizes to no command, which block-main-commit.sh
# allows, so every Copilot tool call needs one that resolves to an object
# (ADR-0038). Only `bash` is recorded in docs/agent-event-mapping.md, so a shell
# under another name is indistinguishable from a tool that runs nothing.
UNREADABLE_TOOL_ARGS='(has("hook_event_name") | not) and (tool_args | type) != "object"'
UNREADABLE_TOOL_ARGS_REASON="BLOCKED: toolArgs is missing or does not parse as a JSON object, so block-main-commit.sh cannot read the command. Expected toolArgs as an object or a JSON string holding one; check the payload the agent sends."

print_stderr() { # text -> the text on stderr, newline-terminated, nothing when empty
  [ -z "$1" ] || printf '%s\n' "$1" >&2
}

# Sets gate_status and gate_stderr; the gate's stdout is discarded because the
# stdout contract belongs to this handler.
run_gate() { # gate-file-name payload
  gate_status=0
  gate_stderr="$(printf '%s' "$2" | bash "$GATES_DIR/$1" 2>&1 >/dev/null)" || gate_status=$?
}

deny_tool_use() { # reason
  print_stderr "$1"
  jq -n --arg reason "$1" '{permissionDecision: "deny", permissionDecisionReason: $reason}'
  exit "$BLOCK_EXIT"
}

run_pre_tool_use() { # payload
  run_gate "$PRE_TOOL_USE_GATE" "$1"
  [ "$gate_status" -ne "$BLOCK_EXIT" ] || deny_tool_use "$gate_stderr"
  print_stderr "$gate_stderr"
  exit "$gate_status"
}

# Every gate runs so one block does not hide another gate's reason. A block
# outranks a gate error; the first gate error sets the exit code otherwise.
run_post_tool_use() { # payload
  local gate block_reasons="" error_status=0
  for gate in "${POST_TOOL_USE_GATES[@]}"; do
    run_gate "$gate" "$1"
    print_stderr "$gate_stderr"
    if [ "$gate_status" -eq "$BLOCK_EXIT" ]; then
      block_reasons="${block_reasons:+$block_reasons$'\n'}$gate_stderr"
    elif [ "$gate_status" -ne 0 ] && [ "$error_status" -eq 0 ]; then
      error_status="$gate_status"
    fi
  done
  if [ -n "$block_reasons" ]; then
    jq -n --arg reason "$block_reasons" '{additionalContext: $reason}'
    exit "$BLOCK_EXIT"
  fi
  exit "$error_status"
}

# The spec-kit dispatcher wraps session_start stdout for the Copilot CLI, so the
# gate's stdout passes through unwrapped.
run_session_start() { # payload
  printf '%s' "$1" | bash "$GATES_DIR/$SESSION_START_GATE"
}

payload="$(cat)"
if ! printf '%s' "$payload" | jq -e 'type == "object"' >/dev/null 2>&1; then
  echo "agent-event: stdin is not a JSON object; expected the hook payload Claude Code or the Copilot CLI sends. Check the events: registration that runs this script." >&2
  exit 1
fi
event="$(printf '%s' "$payload" | jq -r "$CLASSIFY_EVENT")"
gate_payload="$(printf '%s' "$payload" | jq -c "$RESOLVE_TOOL_ARGS $NORMALIZE_PAYLOAD")"

case "$event" in
  pre_tool_use)
    # A jq error prints nothing, so it denies too.
    if [ "$(printf '%s' "$payload" | jq -r "$RESOLVE_TOOL_ARGS $UNREADABLE_TOOL_ARGS" 2>/dev/null || true)" != "false" ]; then
      deny_tool_use "$UNREADABLE_TOOL_ARGS_REASON"
    fi
    run_pre_tool_use "$gate_payload"
    ;;
  post_tool_use) run_post_tool_use "$gate_payload" ;;
  session_start) run_session_start "$gate_payload" ;;
esac
exit 0
