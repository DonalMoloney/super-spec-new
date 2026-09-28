#!/usr/bin/env bash
# scripts/compare-upstream.sh
#
# Runs the same seeded input through this fork's specflow pipeline and
# through upstream's superspec pipeline, and records which one reports the
# planted flaw. scripts/e2e-stages.sh hardcodes /speckit.specflow.* and
# asserts this fork's artifacts, so upstream's /speckit.superspec.* commands
# need a script of their own rather than a shared stage.
#
# Run from specflow/ (the paths below are relative to that directory).
#
# Environment
#   E2E_DRY_RUN=1               print the install and probe commands, skip
#                                every claude/uvx/git call (free)
#   COMPARE_UPSTREAM_CHECKOUT    path to an existing upstream checkout; when
#                                unset, the script names the pinned commit it
#                                would clone into a scratch directory instead
#
# Usage
#   E2E_DRY_RUN=1 bash scripts/compare-upstream.sh   # logic test only
#
# Exit code
#   0 on a clean dry run.

set -uo pipefail

FORK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DRY_RUN="${E2E_DRY_RUN:-0}"
UPSTREAM_CHECKOUT="${COMPARE_UPSTREAM_CHECKOUT:-}"

UPSTREAM_URL="https://github.com/WangX0111/superspec"
UPSTREAM_COMMIT="c20ac6c1ba069cc9a72dacb8044b7b193d3dde81"
UPSTREAM_SCRATCH_DIR="$(mktemp -u -d -t compare-upstream)/superspec"

# Prints the bracket label a pipeline's block of output opens with, matching
# the [Stage N] convention scripts/e2e-stages.sh already uses.
print_pipeline_label() {
  printf '[%s]\n' "$1"
}

# Prints the fork's own install line. Names FORK_ROOT directly: the fork
# never needs a clone, since compare-upstream.sh already runs inside it.
print_fork_install_command() {
  print_pipeline_label "specflow"
  printf 'specify extension add %s --dev\n' "$FORK_ROOT"
}

# Prints the git clone and checkout lines for the pinned upstream commit.
# Live cloning into UPSTREAM_SCRATCH_DIR is wired by a later item; this dry
# run only names the command it would run.
print_upstream_clone_commands() {
  printf 'git clone %s %s\n' "$UPSTREAM_URL" "$UPSTREAM_SCRATCH_DIR"
  printf 'git -C %s checkout %s\n' "$UPSTREAM_SCRATCH_DIR" "$UPSTREAM_COMMIT"
}

# Prints upstream's install line. Names UPSTREAM_CHECKOUT directly when set;
# otherwise prints the clone this line depends on first, then installs from
# the scratch directory that clone would leave behind.
print_upstream_install_command() {
  print_pipeline_label "superspec"
  local upstream_path="$UPSTREAM_CHECKOUT"
  if [ -z "$upstream_path" ]; then
    print_upstream_clone_commands
    upstream_path="$UPSTREAM_SCRATCH_DIR"
  fi
  printf 'specify extension add %s --dev\n' "$upstream_path"
}

if [ "$DRY_RUN" = "1" ]; then
  print_fork_install_command
  print_upstream_install_command
  exit 0
fi

exit 0
