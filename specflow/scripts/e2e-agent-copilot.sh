#!/usr/bin/env bash
# scripts/e2e-agent-copilot.sh
#
# Full agent-driven end-to-end test for the specflow extension, run through
# the GitHub Copilot CLI in non-interactive (-p) mode. It drives the same
# seven stages scripts/e2e-agent-claude.sh drives, from the same file,
# scripts/e2e-stages.sh, against a project spec-kit initialised with
# `--integration copilot`.
#
# The Copilot CLI has no per-stage budget cap, so E2E_MAX_BUDGET_USD has no
# counterpart here. Tools are granted one at a time; see invoke_agent.
#
# Environment
#   GH_TOKEN              required in CI (unless E2E_DRY_RUN=1); a local
#                         `copilot login` credential works outside CI
#   E2E_DRY_RUN=1         print the prompts, skip the copilot call (free)
#   KEEP_WORKDIR=1        keep the tmp project at exit (default: keep it only
#                         when the run fails, or when E2E_RESUME_WORKDIR named it)
#   E2E_RESUME_WORKDIR    reuse this workdir (skip prep stage)
#   E2E_RESUME_FROM=N     skip stages 1..N-1 (default: 1, run all)
#
# Usage
#   GH_TOKEN=ghp_...  bash scripts/e2e-agent-copilot.sh
#   E2E_DRY_RUN=1     bash scripts/e2e-agent-copilot.sh    # logic test only
#
# Exit code
#   0 if every stage's assertions pass, otherwise 1.

set -uo pipefail

AGENT_NAME="copilot"

# shellcheck source=specflow/scripts/e2e-stages.sh
. "$(dirname "${BASH_SOURCE[0]}")/e2e-stages.sh"

# preflight: required binaries and auth
if [ "$DRY_RUN" != "1" ]; then
  if ! command -v copilot >/dev/null 2>&1; then
    printf '%sFAIL%s copilot CLI not in PATH. Install: npm i -g @github/copilot\n' "$C_RED" "$C_RST"; exit 1
  fi
  # copilot accepts COPILOT_GITHUB_TOKEN, GH_TOKEN, GITHUB_TOKEN, or a stored
  # `copilot login` credential. CI has no stored credential, so a missing
  # token is fatal only there.
  if [ -z "${COPILOT_GITHUB_TOKEN:-}${GH_TOKEN:-}${GITHUB_TOKEN:-}" ] && [ -n "${CI:-}" ]; then
    printf '%sFAIL%s No GitHub token set in CI environment. Export GH_TOKEN.\n' "$C_RED" "$C_RST"; exit 1
  fi
fi
require_uvx

open_workdir "specflow-agent-$AGENT_NAME"
trap cleanup EXIT

# Runs one workflow stage's prompt through copilot -p.
# Args: <prompt> <log path>. Requires cwd == $WORK so copilot picks up
# .github/ and .specify/.
invoke_agent() {
  local prompt="$1" log="$2"

  # --allow-tool grants one tool at a time. --allow-all-tools, --allow-all and
  # --yolo are never passed: a CI runner holds a token that can push, and a
  # blanket grant hands that token to whatever the model decides to run.
  # `write` covers the artifacts each stage produces, `shell(bash)` covers the
  # spec-kit scripts the slash commands call, and --deny-tool takes precedence
  # over every grant, so no path reaches `git push`.
  # --no-auto-update keeps the CLI at the version the runner installed.
  # --silent drops the stats block; the caller does not parse the response.
  if copilot -p "$prompt" \
        --allow-tool "write" \
        --allow-tool "shell(bash)" \
        --deny-tool "shell(git push)" \
        --no-auto-update \
        --silent >"$log" 2>&1; then
    note "copilot transcript: ${log#$WORK/}"
  else
    local rc=$?
    note "copilot exited non-zero (rc=$rc), likely a denied tool. Checking artifacts."
    note "copilot transcript: ${log#$WORK/}"
  fi
}

prep_project copilot .github
seed_dry_run_snapshot

stage_1_constitution invoke_agent
stage_2_specify invoke_agent
stage_3_brainstorm invoke_agent
stage_4_plan invoke_agent
stage_5_tasks invoke_agent
stage_6_execute invoke_agent
stage_7_review invoke_agent

report_summary "Set GH_TOKEN and re-run without E2E_DRY_RUN=1 to run the agent stages."
[ "$FAIL" -gt 0 ] && exit 1
exit 0
