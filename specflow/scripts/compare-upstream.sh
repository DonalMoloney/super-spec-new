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
#   COMPARE_PROBES               spec, review, or all (default: all)
#   COMPARE_RUNS                 runs per probe per pipeline (default: 3)
#   COMPARE_RESULTS              results file path (default: a temp file in
#                                a dry run; refuses to write to the committed
#                                examples/upstream-comparison/results.json
#                                during a dry run)
#
# Usage
#   E2E_DRY_RUN=1 bash scripts/compare-upstream.sh   # logic test only
#   bash scripts/compare-upstream.sh --spec-hit-for-score <score|error>
#                                     # prints true, false, or null for the
#                                     # spec-probe score-to-hit rule and exits
#
# Exit code
#   0 on a clean dry run.
#   1 when COMPARE_RESULTS points a dry run at the committed results.json, or
#     when COMPARE_PROBES names anything other than spec, review, or all.

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

COMPARE_RUNS="${COMPARE_RUNS:-3}"
COMMITTED_RESULTS="$FORK_ROOT/specflow/examples/upstream-comparison/results.json"

# Prints true, false, or null for a spec-probe score: 100 is a hit, `error`
# stands for an entry with status error and no score, anything else is a miss.
spec_hit_for_score() {
  local score="$1"
  if [ "$score" = "error" ]; then
    printf 'null'
  elif [ "$score" = "100" ]; then
    printf 'true'
  else
    printf 'false'
  fi
}

if [ "${1:-}" = "--spec-hit-for-score" ]; then
  spec_hit_for_score "${2:-}"
  printf '\n'
  exit 0
fi

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

# Prints the lexically normalized form of a path, without touching the
# filesystem, so a path that does not exist yet still normalizes.
normalize_path() {
  local candidate="$1"
  case "$candidate" in
    /*) : ;;
    *) candidate="$PWD/$candidate" ;;
  esac
  python3 -c 'import os, sys; print(os.path.normpath(sys.argv[1]))' "$candidate"
}

# Resolves COMPARE_PROBES into PROBES_TO_RUN, the probe names this run
# covers. Exits 1 on anything other than the fixed spec/review/all enum.
resolve_probes_to_run() {
  case "$1" in
    spec) PROBES_TO_RUN=(spec) ;;
    review) PROBES_TO_RUN=(review) ;;
    all) PROBES_TO_RUN=(spec review) ;;
    *)
      printf 'COMPARE_PROBES is %s; expected spec, review, or all.\n' "$1" >&2
      exit 1
      ;;
  esac
}

# Prints one compact-JSON dry-run entry per line: every pipeline and run
# index of each probe in PROBES_TO_RUN. `hit` stays null because a dry run
# never scores anything; a later, non-dry-run probe reuses
# spec_hit_for_score once it has a real score to score.
dry_run_entries() {
  local probe pipeline run
  for probe in "${PROBES_TO_RUN[@]}"; do
    for pipeline in specflow superspec; do
      for ((run = 1; run <= COMPARE_RUNS; run++)); do
        jq -nc --arg pipeline "$pipeline" --arg probe "$probe" --argjson run "$run" \
          '{pipeline: $pipeline, probe: $probe, run: $run, status: "dry-run", hit: null}'
      done
    done
  done
}

# Defaults COMPARE_RESULTS to a scratch path when unset, and exits 1 when it
# resolves to the committed examples/upstream-comparison/results.json, so
# neither run mode overwrites the checked-in file by accident.
resolve_compare_results_path() {
  if [ -z "${COMPARE_RESULTS:-}" ]; then
    local results_dir
    results_dir="$(mktemp -d -t compare-upstream-results)"
    COMPARE_RESULTS="$results_dir/results.json"
  fi

  if [ "$(normalize_path "$COMPARE_RESULTS")" = "$(normalize_path "$COMMITTED_RESULTS")" ]; then
    printf 'COMPARE_RESULTS resolves to the committed %s; refusing to write there. Point COMPARE_RESULTS elsewhere.\n' "$COMMITTED_RESULTS" >&2
    exit 1
  fi
}

# Reads compact-JSON entries from stdin and wraps them with the three keys
# every results.json carries once per file: the model a run used, the
# fork commit under test, and the pinned upstream commit.
assemble_results_json() {
  local fork_commit
  fork_commit="$(git -C "$FORK_ROOT" rev-parse HEAD)"
  if [ -n "$MODEL" ]; then
    jq -s --arg model "$MODEL" --arg fork_commit "$fork_commit" --arg upstream_commit "$UPSTREAM_COMMIT" \
      '{model: $model, fork_commit: $fork_commit, upstream_commit: $upstream_commit, entries: .}'
  else
    jq -s --arg fork_commit "$fork_commit" --arg upstream_commit "$UPSTREAM_COMMIT" \
      '{model: null, fork_commit: $fork_commit, upstream_commit: $upstream_commit, entries: .}'
  fi
}

if [ "$DRY_RUN" = "1" ]; then
  if ! command -v jq >/dev/null 2>&1; then
    printf 'compare-upstream.sh: jq is not installed; a dry run writes results.json with it. Install jq (brew install jq, apt-get install jq), then rerun.\n' >&2
    exit 1
  fi

  COMPARE_PROBES="${COMPARE_PROBES:-all}"
  resolve_probes_to_run "$COMPARE_PROBES"

  resolve_compare_results_path

  printf 'Dry run results file: %s\n' "$COMPARE_RESULTS" >&2

  print_fork_install_command
  print_claude_invocation "$ALLOWED_TOOLS_SPECFLOW" "$(specflow_probe_prompt)"
  print_upstream_install_command
  print_claude_invocation "$ALLOWED_TOOLS_SUPERSPEC" "$(superspec_probe_prompt)"

  mkdir -p "$(dirname "$COMPARE_RESULTS")"
  dry_run_entries | assemble_results_json > "$COMPARE_RESULTS"

  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  printf 'compare-upstream.sh: jq is not installed; a run writes results.json with it. Install jq (brew install jq, apt-get install jq), then rerun.\n' >&2
  exit 1
fi

COMPARE_PROBES="${COMPARE_PROBES:-all}"
resolve_probes_to_run "$COMPARE_PROBES"

resolve_compare_results_path

if [ -z "$UPSTREAM_CHECKOUT" ]; then
  printf 'compare-upstream.sh: COMPARE_UPSTREAM_CHECKOUT is unset. Live cloning of the pinned upstream commit is not wired yet; set COMPARE_UPSTREAM_CHECKOUT to an existing checkout.\n' >&2
  exit 1
fi

SPECFLOW_INSTALL_OK=0
SPECFLOW_INSTALL_ERROR=""
SUPERSPEC_INSTALL_OK=0
SUPERSPEC_INSTALL_ERROR=""

# Installs one pipeline via uvx, once per script run, and records the
# outcome in that pipeline's SPECFLOW_/SUPERSPEC_-prefixed globals. A
# pipeline whose install fails never reaches a claude call (item 14).
install_pipeline() {
  local pipeline="$1" path="$2" stderr_file
  stderr_file="$(mktemp -t compare-upstream-install)"
  if uvx --from git+https://github.com/github/spec-kit.git specify extension add "$path" --dev >/dev/null 2>"$stderr_file"; then
    case "$pipeline" in
      specflow) SPECFLOW_INSTALL_OK=1 ;;
      superspec) SUPERSPEC_INSTALL_OK=1 ;;
    esac
  else
    case "$pipeline" in
      specflow) SPECFLOW_INSTALL_ERROR="$(cat "$stderr_file")" ;;
      superspec) SUPERSPEC_INSTALL_ERROR="$(cat "$stderr_file")" ;;
    esac
  fi
  rm -f "$stderr_file"
}

# UPSTREAM_CHECKOUT is only ever read here, passed through as an argument to
# uvx; the script never cds into it or runs a mutating command against it
# (item 16).
install_pipeline specflow "$FORK_ROOT"
install_pipeline superspec "$UPSTREAM_CHECKOUT"

RESULTS_ENTRIES_FILE="$(mktemp -t compare-upstream-entries)"

# Appends one compact-JSON entry to RESULTS_ENTRIES_FILE for one pipeline,
# probe, and run index: an error entry when that pipeline's install failed
# (item 14) or claude exited nonzero (item 15), otherwise an ok entry
# carrying claude's reported cost (item 19).
run_probe_entry() {
  local pipeline="$1" probe="$2" run="$3" allowed_tools="$4" prompt="$5"
  local install_ok install_error
  case "$pipeline" in
    specflow) install_ok="$SPECFLOW_INSTALL_OK"; install_error="$SPECFLOW_INSTALL_ERROR" ;;
    superspec) install_ok="$SUPERSPEC_INSTALL_OK"; install_error="$SUPERSPEC_INSTALL_ERROR" ;;
  esac

  if [ "$install_ok" != "1" ]; then
    jq -nc --arg pipeline "$pipeline" --arg probe "$probe" --argjson run "$run" \
      --arg error "$install_error" \
      '{pipeline: $pipeline, probe: $probe, run: $run, status: "error", hit: null, error: $error, cost_usd: null}' \
      >> "$RESULTS_ENTRIES_FILE"
    return
  fi

  local stdout_file stderr_file exit_code claude_args
  stdout_file="$(mktemp -t compare-upstream-probe-out)"
  stderr_file="$(mktemp -t compare-upstream-probe-err)"
  claude_args=(-p --permission-mode acceptEdits --allowedTools "$allowed_tools"
    --max-budget-usd "$MAX_BUDGET" --max-turns "$MAX_TURNS" --output-format json)
  if [ -n "$MODEL" ]; then
    claude_args+=(--model "$MODEL")
  fi
  claude_args+=(-- "$prompt")

  claude "${claude_args[@]}" >"$stdout_file" 2>"$stderr_file"
  exit_code=$?

  if [ "$exit_code" -ne 0 ]; then
    jq -nc --arg pipeline "$pipeline" --arg probe "$probe" --argjson run "$run" \
      --arg error "$(cat "$stderr_file")" \
      '{pipeline: $pipeline, probe: $probe, run: $run, status: "error", hit: null, error: $error, cost_usd: null}' \
      >> "$RESULTS_ENTRIES_FILE"
  else
    local cost
    cost="$(jq -r 'if (type == "object") and has("total_cost_usd") then (.total_cost_usd | tostring) else "null" end' "$stdout_file" 2>/dev/null)"
    if [ -z "$cost" ]; then
      cost="null"
    fi
    jq -nc --arg pipeline "$pipeline" --arg probe "$probe" --argjson run "$run" --argjson cost "$cost" \
      '{pipeline: $pipeline, probe: $probe, run: $run, status: "ok", hit: null, error: null, cost_usd: $cost}' \
      >> "$RESULTS_ENTRIES_FILE"
  fi

  rm -f "$stdout_file" "$stderr_file"
}

for pipeline in specflow superspec; do
  case "$pipeline" in
    specflow) allowed_tools="$ALLOWED_TOOLS_SPECFLOW"; prompt="$(specflow_probe_prompt)" ;;
    superspec) allowed_tools="$ALLOWED_TOOLS_SUPERSPEC"; prompt="$(superspec_probe_prompt)" ;;
  esac
  for probe in "${PROBES_TO_RUN[@]}"; do
    for ((run = 1; run <= COMPARE_RUNS; run++)); do
      run_probe_entry "$pipeline" "$probe" "$run" "$allowed_tools" "$prompt"
    done
  done
done

mkdir -p "$(dirname "$COMPARE_RESULTS")"
assemble_results_json < "$RESULTS_ENTRIES_FILE" > "$COMPARE_RESULTS"
rm -f "$RESULTS_ENTRIES_FILE"

exit 0
