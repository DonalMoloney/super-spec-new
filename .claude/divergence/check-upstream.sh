#!/usr/bin/env bash
# .claude/divergence/check-upstream.sh
#
# Compares the upstream commit specflow/ was vendored from to upstream HEAD, so
# a resync lands as a decision rather than as a surprise during a rewrite.
#
# Usage: bash .claude/divergence/check-upstream.sh
# Exit code: 0 when upstream HEAD is the vendored commit, 1 when it moved,
# 2 when the remote could not be read.
set -uo pipefail

UPSTREAM_REMOTE="https://github.com/WangX0111/superspec.git"
# The commit improvements/roadmap.md measures every divergence percentage
# against. Move it only together with a fresh measurement run.
VENDORED_COMMIT="c20ac6c"
REMOTE_ERROR=2
REMOTE_ERROR_LINES=3

remote_stderr="$(mktemp)"
trap 'rm -f "$remote_stderr"' EXIT
ls_remote_answer="$(git ls-remote "$UPSTREAM_REMOTE" HEAD 2>"$remote_stderr")"
upstream_head="$(printf '%s\n' "$ls_remote_answer" | awk 'NR==1{print $1}')"
if [ -z "$upstream_head" ]; then
  # git names the reason on stderr. Dropping it leaves a CI failure with no cause.
  detail="$(tail -n "$REMOTE_ERROR_LINES" "$remote_stderr" | tr '\n' ' ')"
  echo "git ls-remote read no HEAD from $UPSTREAM_REMOTE: ${detail:-no stderr output}. Check network access to the remote, then rerun." >&2
  exit "$REMOTE_ERROR"
fi

echo "vendored $VENDORED_COMMIT"
echo "upstream $upstream_head"

case "$upstream_head" in
  "$VENDORED_COMMIT"*)
    echo "Upstream HEAD is the vendored commit. Nothing to resync."
    exit 0
    ;;
esac

echo "Upstream HEAD moved past the vendored commit. Clone $UPSTREAM_REMOTE, rerun measure-divergence.py against it, then repin VENDORED_COMMIT in this script."
exit 1
