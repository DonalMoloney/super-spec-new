#!/usr/bin/env bash
# Stop hook. Appends one telemetry line per turn to .claude/telemetry.jsonl, for
# the jq queries in README.md beside this file. The phase and the feature come
# from the newest specs/*/progress.yml, the only file a command writes them to.
# Never blocks a turn: always exits 0.
set -u
shopt -s nullglob
input="$(cat)"
[ -d .claude ] || exit 0

phase=""
feature=""
candidates=(specs/*/progress.yml)
if [ "${#candidates[@]}" -gt 0 ]; then
  newest="$(ls -t "${candidates[@]}" | head -1)"
  phase="$(grep '^current_phase:' "$newest" | head -1 | cut -d: -f2 | tr -d '[:space:]')"
  feature="$(grep '^spec:' "$newest" | head -1 | cut -d: -f2 | tr -d '[:space:]')"
fi

# Stdin that does not parse costs the session id, not the whole line.
session="$(printf '%s' "$input" | jq -r '.session_id // ""' 2>/dev/null || true)"
jq -cn \
  --arg ts "$(date -u +%FT%TZ)" \
  --arg phase "${phase:-unknown}" \
  --arg feature "${feature:-unknown}" \
  --arg session "$session" \
  '{ts: $ts, event: "stop", phase: $phase, feature: $feature, session: $session}' \
  >> .claude/telemetry.jsonl
exit 0
