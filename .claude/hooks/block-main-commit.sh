#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). Blocks `git commit` while on main/master.
# Exit 2 is the only code that blocks the tool call and feeds stderr back to
# Claude; exit 1 merely warns, so every gate here exits 2.
set -euo pipefail
input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"
if printf '%s' "$cmd" | grep -Eq 'git\s+commit'; then
  if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
    echo "BLOCKED: direct commit to $branch is forbidden. Create a feature branch first (git switch -c <name>)." >&2
    exit 2
  fi
fi
exit 0
