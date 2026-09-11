#!/usr/bin/env bash
# Stop hook. Appends one telemetry line per turn to .claude/telemetry.jsonl, for
# the jq queries in README.md beside this file. The phase comes from
# .claude/.current-phase; no command writes that file yet, so every line reads
# "unknown" until one does. Never blocks a turn: always exits 0.
set -u
input="$(cat)"
[ -d .claude ] || exit 0
phase="$(head -1 .claude/.current-phase 2>/dev/null || true)"
# Stdin that does not parse costs the session id, not the whole line.
session="$(printf '%s' "$input" | jq -r '.session_id // ""' 2>/dev/null || true)"
jq -cn \
  --arg ts "$(date -u +%FT%TZ)" \
  --arg phase "${phase:-unknown}" \
  --arg session "$session" \
  '{ts: $ts, event: "stop", phase: $phase, session: $session}' \
  >> .claude/telemetry.jsonl
exit 0
