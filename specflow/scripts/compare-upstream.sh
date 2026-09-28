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
#   E2E_MODEL                   model passed to claude --model (default: the
#                                CLI's own)
#   E2E_MAX_BUDGET_USD           per-invocation budget cap, default 0.50
#   E2E_MAX_TURNS                per-invocation turn cap, default 30
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

MAX_BUDGET="${E2E_MAX_BUDGET_USD:-0.50}"
MAX_TURNS="${E2E_MAX_TURNS:-30}"
MODEL="${E2E_MODEL:-}"

# ADR-0033's allowlist, one shell command per line a probe runs without
# approval. Each pipeline's own gate path names that pipeline's own
# extension id; scripts/e2e-agent-claude.sh's ALLOWED_TOOLS array is the
# shape both lists follow.
ALLOWED_TOOLS_SPECFLOW="Bash(.specify/scripts/bash/*) Bash(.specify/extensions/specflow/gates/bash/*) Bash(bash .specify/extensions/specflow/gates/bash/*) Bash(cd *) Bash(git *) Bash(python3 *)"
ALLOWED_TOOLS_SUPERSPEC="Bash(.specify/scripts/bash/*) Bash(.specify/extensions/superspec/gates/bash/*) Bash(bash .specify/extensions/superspec/gates/bash/*) Bash(cd *) Bash(git *) Bash(python3 *)"

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

# Prints one `claude -p` invocation line: the ADR-0033 allowlist, the
# budget and turn caps, --output-format json so a probe can read
# total_cost_usd and model back out of claude's own JSON, --model only when
# E2E_MODEL is set, and never --permission-mode bypassPermissions.
print_claude_invocation() {
  local allowed_tools="$1"
  local prompt="$2"
  local model_flag=""
  if [ -n "$MODEL" ]; then
    model_flag=" --model $MODEL"
  fi
  printf 'claude -p --permission-mode acceptEdits --allowedTools %s --max-budget-usd %s --max-turns %s --output-format json%s -- %s\n' \
    "$allowed_tools" "$MAX_BUDGET" "$MAX_TURNS" "$model_flag" "$prompt"
}

# Placeholder prompt for the specflow pipeline's probe. Items 7 and 9
# replace this with the real spec and review probe prompts.
specflow_probe_prompt() {
  printf 'Run /speckit.specflow.brainstorm against the seeded feature. No user will answer, so answer every question the command would otherwise ask.'
}

# Placeholder prompt for the superspec pipeline's probe, naming only
# upstream's own command namespace.
superspec_probe_prompt() {
  printf 'Run /speckit.superspec.brainstorm against the seeded feature. No user will answer, so answer every question the command would otherwise ask.'
}

if [ "$DRY_RUN" = "1" ]; then
  print_fork_install_command
  print_claude_invocation "$ALLOWED_TOOLS_SPECFLOW" "$(specflow_probe_prompt)"
  print_upstream_install_command
  print_claude_invocation "$ALLOWED_TOOLS_SUPERSPEC" "$(superspec_probe_prompt)"
  exit 0
fi

exit 0
