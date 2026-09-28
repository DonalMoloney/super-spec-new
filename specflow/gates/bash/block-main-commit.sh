#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash). Blocks `git commit` when the commit would
# land on main or master. Exit 2 is the only code that blocks the tool call and
# feeds stderr back to Claude; exit 1 merely warns, so every gate here exits 2.
set -euo pipefail
input="$(cat)"
cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"
# symbolic-ref names an unborn branch, where rev-parse prints HEAD and exits
# 128. rev-parse covers a detached HEAD, which symbolic-ref cannot name.
branch="$(git symbolic-ref --short -q HEAD 2>/dev/null ||
  git rev-parse --abbrev-ref HEAD 2>/dev/null ||
  echo '')"
set -f

# The git subcommand a segment runs, or nothing when the segment does not start
# by running git. Anchoring on the first token separates a command from prose
# about a command, so a commit message quoting git does not steer the gate. A
# global option sits before the subcommand; -C and -c each take a separate
# value, which is skipped with the option. A quoted value holding a space
# splits into two tokens, so the second reads as the subcommand and the
# segment is skipped.
git_subcommand() { # segment
  local tok first=1 skip=0
  for tok in $1; do
    if [ "$first" -eq 1 ]; then
      first=0
      [ "$tok" = "git" ] || return 0
      continue
    fi
    if [ "$skip" -eq 1 ]; then
      skip=0
      continue
    fi
    case "$tok" in
    -C | -c) skip=1 ;;
    -*) ;;
    *)
      printf '%s' "$tok"
      return 0
      ;;
    esac
  done
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
# sequence a shell command gives the segments in execution order. A grouping
# character becomes a space first, so a subshell's contents split the same way.
segments="$(printf '%s' "$cmd" | tr '(){}' '    ' | awk '{gsub(/&&|\|\||;|\|/, "\n"); print}')"

effective="$branch"
while IFS= read -r seg; do
  case "$(git_subcommand "$seg")" in
  switch | checkout)
    target="$(switch_target "$seg")"
    [ "$target" = "NONE" ] || effective="$target"
    continue
    ;;
  commit) ;;
  *) continue ;;
  esac
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
