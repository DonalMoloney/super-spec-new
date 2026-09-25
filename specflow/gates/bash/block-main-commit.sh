#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). Blocks `git commit` when the commit would
# land on main or master. Exit 2 is the only code that blocks the tool call and
# feeds stderr back to Claude; exit 1 merely warns, so every gate here exits 2.
set -euo pipefail
input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '')"

# True when the segment starts by running the named git subcommand. Anchoring
# separates a command from prose about a command, so a commit message quoting
# git does not steer the gate.
runs_git() { # segment subcommand-pattern
  printf '%s' "$1" | grep -Eq "^[[:space:]]*git[[:space:]]+$2([[:space:]]|\$)"
}

# First non-flag argument after `switch` or `checkout`. Prints NONE when the
# segment restores paths rather than moving HEAD, and UNKNOWN when it moves HEAD
# somewhere this hook cannot name, such as `git switch -`.
switch_target() { # segment
  local seg="$1" tok seen=0
  case "$seg" in *" -- "*)
    printf 'NONE'
    return
    ;;
  esac
  for tok in $seg; do
    if [ "$seen" -eq 0 ]; then
      case "$tok" in switch | checkout) seen=1 ;; esac
      continue
    fi
    case "$tok" in
    -*) continue ;;
    .* | /*)
      printf 'NONE'
      return
      ;;
    esac
    printf '%s' "$tok"
    return
  done
  printf 'UNKNOWN'
}

# A compound command may move HEAD before it commits, so the branch at hook time
# is not always the branch the commit lands on. Splitting on the operators that
# sequence a shell command gives the segments in execution order.
segments="$(printf '%s' "$cmd" | awk '{gsub(/&&|\|\||;|\|/, "\n"); print}')"

effective="$branch"
set -f
while IFS= read -r seg; do
  if runs_git "$seg" '(switch|checkout)'; then
    target="$(switch_target "$seg")"
    [ "$target" = "NONE" ] || effective="$target"
    continue
  fi
  runs_git "$seg" 'commit' || continue
  case "$effective" in
  main | master)
    echo "BLOCKED: the commit would land on $effective; a commit belongs on a feature branch. Run git switch -c <name> before committing." >&2
    exit 2
    ;;
  UNKNOWN)
    echo "BLOCKED: this command moves HEAD to a branch the gate cannot name, so the commit may land on main. Name the branch: git switch -c <name>." >&2
    exit 2
    ;;
  esac
done <<<"$segments"
exit 0
