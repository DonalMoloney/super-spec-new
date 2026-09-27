#!/usr/bin/env bash
# scripts/e2e-agent-claude.sh
#
# Full agent-driven end-to-end test for the specflow extension, run through
# Claude Code in headless (-p) mode. scripts/e2e-smoke.sh covers the other
# e2e test: structural assertions with no LLM, ~60s.
#
# Drives a deterministic feature ("link-audit", a CLI that reports broken
# Markdown links) through every stage of specflow's workflow and asserts, at each
# stage, that the expected artifact and section structure exist. Each stage
# is a separate `claude -p` invocation; the first failed assertion stops the
# run. scripts/e2e-stages.sh holds the stages, the assertions, and the
# dry-run seed, and scripts/e2e-agent-copilot.sh drives the same seven stages
# through the GitHub Copilot CLI.
#
# Environment
#   ANTHROPIC_API_KEY     required (unless E2E_DRY_RUN=1)
#   E2E_DRY_RUN=1         print the prompts, skip the claude call (free)
#   E2E_MAX_BUDGET_USD    per-stage budget cap, default 0.50
#   E2E_MAX_TURNS         per-stage turn cap, default 30
#   E2E_MODEL             model passed to claude --model (default: the CLI's own)
#   KEEP_WORKDIR=1        keep the tmp project at exit (default: keep it only
#                         when the run fails, or when E2E_RESUME_WORKDIR named it)
#   E2E_RESUME_WORKDIR    reuse this workdir (skip prep stage)
#   E2E_RESUME_FROM=N     skip stages 1..N-1 (default: 1, run all)
#
# Usage
#   ANTHROPIC_API_KEY=sk-ant-... bash scripts/e2e-agent-claude.sh
#   E2E_DRY_RUN=1            bash scripts/e2e-agent-claude.sh    # logic test only
#
# Exit code
#   0 if every stage's assertions pass, otherwise 1.

set -uo pipefail

AGENT_NAME="claude"
MAX_BUDGET="${E2E_MAX_BUDGET_USD:-0.50}"
MAX_TURNS="${E2E_MAX_TURNS:-30}"
MODEL="${E2E_MODEL:-}"

# shellcheck source=specflow/scripts/e2e-stages.sh
. "$(dirname "${BASH_SOURCE[0]}")/e2e-stages.sh"

# preflight: required binaries and auth
if [ "$DRY_RUN" != "1" ]; then
  if ! command -v claude >/dev/null 2>&1; then
    printf '%sFAIL%s claude CLI not in PATH. Install: npm i -g @anthropic-ai/claude-code\n' "$C_RED" "$C_RST"; exit 1
  fi
  # claude accepts ANTHROPIC_API_KEY, OAuth (claude login -> keychain), or
  # apiKeyHelper; claude itself errors when no auth is available. CI has no
  # keychain, so the missing env var is fatal only there.
  if [ -z "${ANTHROPIC_API_KEY:-}" ] && [ -n "${CI:-}" ]; then
    printf '%sFAIL%s ANTHROPIC_API_KEY not set in CI environment.\n' "$C_RED" "$C_RST"; exit 1
  fi
fi
require_uvx

open_workdir "specflow-agent-$AGENT_NAME"
trap cleanup EXIT

# acceptEdits approves file writes only, and a headless stage has nobody to
# approve a shell command, so the stages' own commands are listed here.
WORK_REAL="$(cd "$WORK" && pwd -P)"
ALLOWED_TOOLS=(
  "Bash(.specify/scripts/bash/*)"
  "Bash($WORK/.specify/scripts/bash/*)"
  "Bash($WORK_REAL/.specify/scripts/bash/*)"
  "Bash(bash .specify/scripts/bash/*)"
  "Bash(cd *)"
  "Bash(git *)"
  "Bash(mkdir *)"
  "Bash(touch *)"
  "Bash(rm -f specs/*)"
  "Bash(python3 *)"
  "Bash(python *)"
  "Bash(pytest *)"
)

# Runs one workflow stage's prompt through claude -p.
# Args: <prompt> <log path>. Requires cwd == $WORK so claude picks up
# .claude/ and .specify/.
invoke_agent() {
  local prompt="$1" log="$2"
  local model_args=()
  [ -n "$MODEL" ] && model_args=(--model "$MODEL")

  # --permission-mode acceptEdits: no interactive prompt for file writes
  # --allowedTools: the shell commands a stage runs without approval
  # --max-turns: caps agent loops
  # --max-budget-usd: caps per-stage spend
  # --output-format text: response format; the caller does not parse it
  # claude reads the project dir (.claude/, .specify/, AGENTS.md auto-discovery)
  # to find the spec-kit and specflow slash commands. claude exits non-zero on
  # max-turns or budget after writing artifacts, so the on-disk assertions
  # in each stage decide whether the stage delivered.
  if claude -p \
        --permission-mode acceptEdits \
        --allowedTools "${ALLOWED_TOOLS[@]}" \
        --max-turns "$MAX_TURNS" \
        --max-budget-usd "$MAX_BUDGET" \
        --output-format text \
        "${model_args[@]+"${model_args[@]}"}" \
        "$prompt" >"$log" 2>&1; then
    note "claude transcript: ${log#$WORK/}"
  else
    local rc=$?
    note "claude exited non-zero (rc=$rc), likely max-turns or budget. Checking artifacts."
    note "claude transcript: ${log#$WORK/}"
  fi
}

prep_project claude .claude
seed_dry_run_snapshot

stage_1_constitution invoke_agent
stage_2_specify invoke_agent
stage_3_brainstorm invoke_agent
stage_4_plan invoke_agent
stage_5_tasks invoke_agent
stage_6_execute invoke_agent
stage_7_review invoke_agent

report_summary "Set ANTHROPIC_API_KEY and re-run without E2E_DRY_RUN=1 to run the agent stages."
[ "$FAIL" -gt 0 ] && exit 1
exit 0
