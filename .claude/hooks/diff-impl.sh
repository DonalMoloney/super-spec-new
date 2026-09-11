#!/usr/bin/env bash
# Sets up the two worktrees a differential implementation run needs: one per
# executor, both branched from HEAD, both tested with the same command. The
# protocol that consumes them is "Differential implementation" in
# specflow/references/workflow-guide.md.
#   bash .claude/hooks/diff-impl.sh <spec-dir>
# The shared test command comes from SPECFLOW_TEST_CMD, then from the first
# line of <spec-dir>/plan.md shaped "**Test command**: `<command>`", then from
# DEFAULT_TEST_CMD.
set -euo pipefail
DEFAULT_TEST_CMD='cd specflow && python3 scripts/validate-extension-metadata.py'
plan_test_cmd() { # plan-path -> the command the plan names, or nothing
  [ -f "$1" ] || return 0
  sed -n 's/^\*\*Test command\*\*: `\(.*\)`[[:space:]]*$/\1/p' "$1" | head -1
}
spec_dir="${1:-}"
if [ -z "$spec_dir" ]; then
  echo "diff-impl: no spec directory given; expected one argument such as specs/001-user-login. Pass the feature's spec directory." >&2
  exit 2
fi
if [ ! -d "$spec_dir" ]; then
  echo "diff-impl: spec directory '$spec_dir' does not exist; expected a directory holding spec.md. Create the feature with /speckit.specify first." >&2
  exit 2
fi
if ! root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
  echo "diff-impl: '$PWD' is not inside a git repository; expected a checkout with a HEAD commit. Run from the project root." >&2
  exit 2
fi
feature="$(basename "$spec_dir")"
test_cmd="${SPECFLOW_TEST_CMD:-}"
if [ -z "$test_cmd" ]; then test_cmd="$(plan_test_cmd "$spec_dir/plan.md")"; fi
if [ -z "$test_cmd" ]; then test_cmd="$DEFAULT_TEST_CMD"; fi
for side in a b; do
  path="$root/worktrees/$feature-$side"
  branch="$feature-$side"
  if [ -e "$path" ]; then
    echo "diff-impl: '$path' already exists; expected a free path for worktree $side. Remove the previous run with git worktree remove." >&2
    exit 2
  fi
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    echo "diff-impl: branch '$branch' already exists; expected a free branch name for worktree $side. Delete it with git branch -D." >&2
    exit 2
  fi
done
path_a="$root/worktrees/$feature-a"
path_b="$root/worktrees/$feature-b"
git worktree add -q -b "$feature-a" "$path_a" HEAD
if ! git worktree add -q -b "$feature-b" "$path_b" HEAD; then
  git worktree remove --force "$path_a"
  git branch -D "$feature-a" >/dev/null
  echo "diff-impl: could not create worktree b; expected git worktree add to succeed. Worktree a was removed, so the run left nothing behind." >&2
  exit 2
fi
echo "worktree-a: $path_a"
echo "worktree-b: $path_b"
echo "test-command: $test_cmd"
