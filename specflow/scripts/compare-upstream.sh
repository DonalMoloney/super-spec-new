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
#                                unset, the script clones the pinned commit
#                                into a scratch directory instead
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
SPECFLOW_ROOT="$FORK_ROOT/specflow"
DRY_RUN="${E2E_DRY_RUN:-0}"
UPSTREAM_CHECKOUT="${COMPARE_UPSTREAM_CHECKOUT:-}"

UPSTREAM_URL="https://github.com/WangX0111/superspec"
UPSTREAM_COMMIT="c20ac6c1ba069cc9a72dacb8044b7b193d3dde81"
UPSTREAM_SCRATCH_DIR="$(mktemp -u -d -t compare-upstream)/superspec"
UPSTREAM_CHECKOUT_ERROR=""

MAX_BUDGET="${E2E_MAX_BUDGET_USD:-0.50}"
MAX_TURNS="${E2E_MAX_TURNS:-30}"
MODEL="${E2E_MODEL:-}"
RECORDED_MODEL=""

COMPARE_RUNS="${COMPARE_RUNS:-3}"
COMMITTED_RESULTS="$FORK_ROOT/specflow/examples/upstream-comparison/results.json"

# The spec probe's seeded feature (T593): examples/seeded-ambiguity/'s
# spec.md and its planted-phrase marker, plus the link-audit constitution
# every probe project needs.
SEEDED_AMBIGUITY_DIR="$FORK_ROOT/specflow/examples/seeded-ambiguity"
LINK_AUDIT_CONSTITUTION="$FORK_ROOT/specflow/examples/link-audit/.specify/memory/constitution.md"
PROBE_FEATURE_DIR="specs/001-link-audit"

# The review probe's seeded feature (T594): a full copy of
# examples/seeded-review-bug/, whose own .specify/memory/constitution.md
# already matches link-audit's. The planted fault's location, from that
# example's own README.md.
SEEDED_REVIEW_BUG_DIR="$FORK_ROOT/specflow/examples/seeded-review-bug"
REVIEW_PLANTED_FILE="src/link_audit/resolver.py"
REVIEW_PLANTED_LINE=87

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

# Prints the fork's own install line. Names SPECFLOW_ROOT, the extension
# directory extension.yml lives in, not FORK_ROOT: the fork never needs a
# clone, since compare-upstream.sh already runs inside it.
print_fork_install_command() {
  print_pipeline_label "specflow"
  printf 'specify extension add %s --dev\n' "$SPECFLOW_ROOT"
}

# Prints the git clone and checkout lines for the pinned upstream commit.
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

# Prints the specflow pipeline's probe prompt: spec runs brainstorm on the
# seeded ambiguity, review runs review on the seeded review bug. Neither
# probe has a user to answer a question, so each prompt says so.
specflow_probe_prompt() {
  case "$1" in
    spec)
      printf 'Run /speckit.specflow.brainstorm against the seeded feature. No user will answer, so answer every question the command would otherwise ask.'
      ;;
    review)
      printf 'Run /speckit.specflow.review against the seeded feature. No user will answer, so decide every judgment call the command would otherwise raise.'
      ;;
  esac
}

# Prints the superspec pipeline's probe prompt, naming only upstream's own
# command namespace. Same two probes as specflow_probe_prompt.
superspec_probe_prompt() {
  case "$1" in
    spec)
      printf 'Run /speckit.superspec.brainstorm against the seeded feature. No user will answer, so answer every question the command would otherwise ask.'
      ;;
    review)
      printf 'Run /speckit.superspec.review against the seeded feature. No user will answer, so decide every judgment call the command would otherwise raise.'
      ;;
  esac
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
# every results.json carries once per file (T595): the model a run used,
# the fork commit under test, and the pinned upstream commit. Argument 1,
# when given, overrides MODEL: a live run passes the model any entry's
# claude JSON reported, falling back to MODEL when no entry reported one.
assemble_results_json() {
  local model_value="${1:-$MODEL}"
  local fork_commit
  fork_commit="$(git -C "$FORK_ROOT" rev-parse HEAD)"
  if [ -n "$model_value" ]; then
    jq -s --arg model "$model_value" --arg fork_commit "$fork_commit" --arg upstream_commit "$UPSTREAM_COMMIT" \
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
  print_claude_invocation "$ALLOWED_TOOLS_SPECFLOW" "$(specflow_probe_prompt spec)"
  print_claude_invocation "$ALLOWED_TOOLS_SPECFLOW" "$(specflow_probe_prompt review)"
  print_upstream_install_command
  print_claude_invocation "$ALLOWED_TOOLS_SUPERSPEC" "$(superspec_probe_prompt spec)"
  print_claude_invocation "$ALLOWED_TOOLS_SUPERSPEC" "$(superspec_probe_prompt review)"

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

# Clones the pinned upstream commit into UPSTREAM_SCRATCH_DIR when no
# checkout path was given, and sets UPSTREAM_CHECKOUT to it. On failure,
# leaves UPSTREAM_CHECKOUT empty and UPSTREAM_CHECKOUT_ERROR set; every
# superspec entry then records that error instead of attempting an install
# against a checkout that does not exist.
ensure_upstream_checkout() {
  if [ -n "$UPSTREAM_CHECKOUT" ]; then
    return 0
  fi

  local step_stderr
  step_stderr="$(mktemp -t compare-upstream-clone)"
  mkdir -p "$(dirname "$UPSTREAM_SCRATCH_DIR")"

  if ! git clone "$UPSTREAM_URL" "$UPSTREAM_SCRATCH_DIR" >/dev/null 2>"$step_stderr"; then
    UPSTREAM_CHECKOUT_ERROR="git clone $UPSTREAM_URL failed: $(cat "$step_stderr")"
    rm -f "$step_stderr"
    return 1
  fi

  if ! git -C "$UPSTREAM_SCRATCH_DIR" checkout "$UPSTREAM_COMMIT" >/dev/null 2>"$step_stderr"; then
    UPSTREAM_CHECKOUT_ERROR="git -C $UPSTREAM_SCRATCH_DIR checkout $UPSTREAM_COMMIT failed: $(cat "$step_stderr")"
    rm -f "$step_stderr"
    return 1
  fi

  rm -f "$step_stderr"
  UPSTREAM_CHECKOUT="$UPSTREAM_SCRATCH_DIR"
  return 0
}

ensure_upstream_checkout || true

RESULTS_ENTRIES_FILE="$(mktemp -t compare-upstream-entries)"

# Appends one compact-JSON error entry to RESULTS_ENTRIES_FILE: hit and
# score stay null, so every failure path (a bad checkout, a failed install,
# a failed claude call, or a scorer crash) writes the same shape. cost
# defaults to null; a failed claude call passes its own cost_usd, since
# claude reports total_cost_usd even on a budget or turn-cap exit.
write_error_entry() {
  local pipeline="$1" probe="$2" run="$3" error="$4" cost="${5:-null}"
  jq -nc --arg pipeline "$pipeline" --arg probe "$probe" --argjson run "$run" --arg error "$error" --argjson cost "$cost" \
    '{pipeline: $pipeline, probe: $probe, run: $run, status: "error", hit: null, error: $error, cost_usd: $cost, score: null}' \
    >> "$RESULTS_ENTRIES_FILE"
}

# Creates one fresh spec-kit project and installs pipeline_path's checkout
# into it, so no run carries over another run's specs/, findings, or
# .specify/ state. On success, leaves the project directory in
# PROJECT_DIR. On failure, removes it, clears PROJECT_DIR, and reports the
# failing step's stderr in PROJECT_DIR_ERROR.
prepare_probe_project() {
  local pipeline_path="$1"
  local step_stderr
  PROJECT_DIR="$(mktemp -d -t compare-upstream-project)"
  PROJECT_DIR_ERROR=""
  step_stderr="$(mktemp -t compare-upstream-project-step)"

  if ! (cd "$PROJECT_DIR" && uvx --from git+https://github.com/github/spec-kit.git \
        specify init --here --integration claude --ignore-agent-tools --force \
        --non-interactive) \
      </dev/null >/dev/null 2>"$step_stderr"; then
    PROJECT_DIR_ERROR="$(cat "$step_stderr")"
    rm -f "$step_stderr"
    rm -rf "$PROJECT_DIR"
    PROJECT_DIR=""
    return 1
  fi

  if ! (cd "$PROJECT_DIR" && uvx --from git+https://github.com/github/spec-kit.git \
        specify extension add "$pipeline_path" --dev) \
      </dev/null >/dev/null 2>"$step_stderr"; then
    PROJECT_DIR_ERROR="$(cat "$step_stderr")"
    rm -f "$step_stderr"
    rm -rf "$PROJECT_DIR"
    PROJECT_DIR=""
    return 1
  fi

  rm -f "$step_stderr"
  return 0
}

# Seeds a fresh project for the spec probe (T593): the seeded-ambiguity spec
# and its planted-phrase marker under specs/001-link-audit/, plus the
# link-audit constitution.
seed_spec_probe_project() {
  local project_dir="$1"
  local feature_dir="$project_dir/$PROBE_FEATURE_DIR"
  mkdir -p "$feature_dir" "$project_dir/.specify/memory"
  cp "$SEEDED_AMBIGUITY_DIR/spec.md" "$feature_dir/spec.md"
  cp "$SEEDED_AMBIGUITY_DIR/.seeded-ambiguity" "$feature_dir/.seeded-ambiguity"
  cp "$LINK_AUDIT_CONSTITUTION" "$project_dir/.specify/memory/constitution.md"
}

# Seeds a fresh project for the review probe (T594): a full copy of
# examples/seeded-review-bug/, which already carries its own
# .specify/memory/constitution.md.
seed_review_probe_project() {
  local project_dir="$1"
  cp -R "$SEEDED_REVIEW_BUG_DIR/." "$project_dir/"
}

# Prints one line per file under project_dir: its path relative to
# project_dir, a tab, then a checksum. Two manifests taken before and after
# a review probe run (T594) tell a changed-or-created file apart from one
# the run never touched.
project_manifest() {
  local project_dir="$1" file rel
  (
    cd "$project_dir" || exit 1
    find . -type f | sort | while IFS= read -r file; do
      rel="${file#./}"
      printf '%s\t%s\n' "$rel" "$(cksum "$file" 2>/dev/null | awk '{print $1"-"$2}')"
    done
  )
}

# Reads the model field out of a claude --output-format json transcript and
# records it in RECORDED_MODEL, the first time any entry reports one, for
# T595's results.json. Falls back to the first modelUsage key when the
# transcript carries no top-level model field, since a budget or turn-cap
# exit reports usage per model there instead. A later entry's model, or an
# entry that reports none, never overwrites it.
record_claude_model() {
  local stdout_file="$1" model_value
  model_value="$(jq -r 'if (type == "object") and has("model") then .model else empty end' "$stdout_file" 2>/dev/null)"
  if [ -z "$model_value" ]; then
    model_value="$(jq -r 'if (type == "object") and has("modelUsage") then (.modelUsage | keys[0] // empty) else empty end' "$stdout_file" 2>/dev/null)"
  fi
  if [ -n "$model_value" ] && [ -z "$RECORDED_MODEL" ]; then
    RECORDED_MODEL="$model_value"
  fi
}

# Reads total_cost_usd out of a claude --output-format json transcript,
# printing "null" when the field is absent or the transcript is not JSON.
claude_cost_usd() {
  local stdout_file="$1" cost
  cost="$(jq -r 'if (type == "object") and has("total_cost_usd") then (.total_cost_usd | tostring) else "null" end' "$stdout_file" 2>/dev/null)"
  [ -z "$cost" ] && cost="null"
  printf '%s' "$cost"
}

# True when a claude --output-format json transcript carries is_error true,
# the shape a budget or turn-cap exit reports even when claude itself
# exits 0.
claude_reports_error() {
  local stdout_file="$1" value
  value="$(jq -r 'if (type == "object") and has("is_error") then (.is_error | tostring) else "false" end' "$stdout_file" 2>/dev/null)"
  [ "$value" = "true" ]
}

# Builds a failed claude call's error text: the transcript's subtype and
# errors when it carries them, since a budget or turn-cap exit reports its
# cause there and leaves stderr empty; stderr when the transcript carries
# neither; "claude exited <exit_code>" when both are empty, so an entry's
# error field is never empty (fix round 2, found by a live smoke run).
claude_error_text() {
  local stdout_file="$1" stderr_file="$2" exit_code="$3"
  local subtype errors_text stderr_text

  subtype="$(jq -r 'if (type == "object") and has("subtype") then .subtype else empty end' "$stdout_file" 2>/dev/null)"
  errors_text="$(jq -r 'if (type == "object") and has("errors") then (.errors | join("; ")) else empty end' "$stdout_file" 2>/dev/null)"

  if [ -n "$subtype" ] && [ -n "$errors_text" ]; then
    printf '%s: %s' "$subtype" "$errors_text"
    return
  fi
  if [ -n "$subtype" ]; then
    printf '%s' "$subtype"
    return
  fi
  if [ -n "$errors_text" ]; then
    printf '%s' "$errors_text"
    return
  fi

  stderr_text="$(cat "$stderr_file" 2>/dev/null)"
  if [ -n "$stderr_text" ]; then
    printf '%s' "$stderr_text"
    return
  fi

  printf 'claude exited %s' "$exit_code"
}

# Scores the spec probe's feature directory (T593) with score-artifacts.py,
# derives hit from its seeded_ambiguity.score via spec_hit_for_score, and
# appends the entry. A scorer crash is recorded as an error entry instead
# of stopping the run.
score_probe_entry() {
  local pipeline="$1" probe="$2" run="$3" project_dir="$4" cost="$5"
  local feature_dir="$project_dir/$PROBE_FEATURE_DIR"
  local score_stdout score_stderr score_val hit_val

  score_stdout="$(mktemp -t compare-upstream-score-out)"
  score_stderr="$(mktemp -t compare-upstream-score-err)"

  if ! python3 "$FORK_ROOT/specflow/scripts/score-artifacts.py" "$feature_dir" \
      >"$score_stdout" 2>"$score_stderr"; then
    write_error_entry "$pipeline" "$probe" "$run" "$(cat "$score_stderr")"
    rm -f "$score_stdout" "$score_stderr"
    return
  fi

  score_val="$(jq -r '.seeded_ambiguity.score | floor' "$score_stdout" 2>/dev/null)"
  [ -z "$score_val" ] && score_val="null"
  hit_val="$(spec_hit_for_score "$score_val")"

  jq -nc --arg pipeline "$pipeline" --arg probe "$probe" --argjson run "$run" \
    --argjson cost "$cost" --argjson score "$score_val" --argjson hit "$hit_val" \
    '{pipeline: $pipeline, probe: $probe, run: $run, status: "ok", hit: $hit, error: null, cost_usd: $cost, score: $score}' \
    >> "$RESULTS_ENTRIES_FILE"

  rm -f "$score_stdout" "$score_stderr"
}

# Judges the review probe (T594) with review-probe-hit.py: every file the
# run created or changed since before_manifest, plus claude's own final
# text, against the planted fault; a file the run never touched is passed
# as a baseline only, never as a hit source. Appends the entry.
review_probe_entry() {
  local pipeline="$1" probe="$2" run="$3" project_dir="$4" before_manifest="$5" stdout_file="$6" cost="$7"
  local after_manifest final_text_file path review_exit hit_val
  local changed_args=() baseline_args=()

  after_manifest="$(mktemp -t compare-upstream-manifest-after)"
  project_manifest "$project_dir" > "$after_manifest"

  final_text_file="$(mktemp -t compare-upstream-final-text)"
  jq -r 'if (type == "object") then (.result // "") else "" end' "$stdout_file" 2>/dev/null > "$final_text_file"

  while IFS= read -r path; do
    [ -n "$path" ] && changed_args+=(--changed-file "$project_dir/$path")
  done < <(comm -13 <(sort "$before_manifest") <(sort "$after_manifest") | cut -f1)

  while IFS= read -r path; do
    [ -n "$path" ] && baseline_args+=(--baseline-file "$project_dir/$path")
  done < <(comm -12 <(sort "$before_manifest") <(sort "$after_manifest") | cut -f1)

  python3 "$FORK_ROOT/specflow/scripts/review-probe-hit.py" \
    --planted-file "$REVIEW_PLANTED_FILE" --planted-line "$REVIEW_PLANTED_LINE" \
    "${changed_args[@]+"${changed_args[@]}"}" \
    --final-text-file "$final_text_file" \
    "${baseline_args[@]+"${baseline_args[@]}"}" \
    >/dev/null 2>/dev/null
  review_exit=$?

  case "$review_exit" in
    0) hit_val="true" ;;
    1) hit_val="false" ;;
    *)
      write_error_entry "$pipeline" "$probe" "$run" "review-probe-hit.py exited $review_exit"
      rm -f "$after_manifest" "$final_text_file"
      return
      ;;
  esac

  jq -nc --arg pipeline "$pipeline" --arg probe "$probe" --argjson run "$run" \
    --argjson cost "$cost" --argjson hit "$hit_val" \
    '{pipeline: $pipeline, probe: $probe, run: $run, status: "ok", hit: $hit, error: null, cost_usd: $cost, score: null}' \
    >> "$RESULTS_ENTRIES_FILE"

  rm -f "$after_manifest" "$final_text_file"
}

# Builds ALLOWED_TOOLS_RUN, the array claude's --allowedTools reads for one
# probe run: every path form e2e-agent-claude.sh's own ALLOWED_TOOLS array
# lists against project_dir, so claude parses each Bash(...) entry as its
# own allow pattern instead of one string with embedded spaces (ADR-0033).
# extension_id names the pipeline's own gates path (specflow or superspec).
build_allowed_tools() {
  local project_dir="$1" extension_id="$2" project_dir_real
  project_dir_real="$(cd "$project_dir" && pwd -P)"
  ALLOWED_TOOLS_RUN=(
    "Bash(.specify/scripts/bash/*)"
    "Bash($project_dir/.specify/scripts/bash/*)"
    "Bash($project_dir_real/.specify/scripts/bash/*)"
    "Bash(bash .specify/scripts/bash/*)"
    "Bash(.specify/extensions/$extension_id/gates/bash/*)"
    "Bash($project_dir/.specify/extensions/$extension_id/gates/bash/*)"
    "Bash($project_dir_real/.specify/extensions/$extension_id/gates/bash/*)"
    "Bash(bash .specify/extensions/$extension_id/gates/bash/*)"
    "Bash(cd *)"
    "Bash(git *)"
    "Bash(mkdir *)"
    "Bash(touch *)"
    "Bash(rm -f specs/*)"
    "Bash(python3 *)"
    "Bash(python *)"
    "Bash(pytest *)"
  )
}

# Runs one pipeline/probe/run entry end to end: a fresh project, the
# probe's seed, the claude call, and the probe's own judge. Appends exactly
# one entry to RESULTS_ENTRIES_FILE.
run_probe_entry() {
  local pipeline="$1" probe="$2" run="$3" prompt="$4"
  local pipeline_path project_dir before_manifest=""

  case "$pipeline" in
    specflow)
      pipeline_path="$SPECFLOW_ROOT"
      ;;
    superspec)
      if [ -n "$UPSTREAM_CHECKOUT_ERROR" ]; then
        write_error_entry "$pipeline" "$probe" "$run" "$UPSTREAM_CHECKOUT_ERROR"
        return
      fi
      pipeline_path="$UPSTREAM_CHECKOUT"
      ;;
  esac

  if ! prepare_probe_project "$pipeline_path"; then
    write_error_entry "$pipeline" "$probe" "$run" "$PROJECT_DIR_ERROR"
    return
  fi
  project_dir="$PROJECT_DIR"

  case "$probe" in
    spec) seed_spec_probe_project "$project_dir" ;;
    review)
      seed_review_probe_project "$project_dir"
      before_manifest="$(mktemp -t compare-upstream-manifest-before)"
      project_manifest "$project_dir" > "$before_manifest"
      ;;
  esac

  build_allowed_tools "$project_dir" "$pipeline"

  local stdout_file stderr_file exit_code claude_args
  stdout_file="$(mktemp -t compare-upstream-probe-out)"
  stderr_file="$(mktemp -t compare-upstream-probe-err)"
  claude_args=(-p --permission-mode acceptEdits --allowedTools "${ALLOWED_TOOLS_RUN[@]}"
    --max-budget-usd "$MAX_BUDGET" --max-turns "$MAX_TURNS" --output-format json)
  if [ -n "$MODEL" ]; then
    claude_args+=(--model "$MODEL")
  fi
  claude_args+=(-- "$prompt")

  (cd "$project_dir" && claude "${claude_args[@]}") >"$stdout_file" 2>"$stderr_file"
  exit_code=$?

  record_claude_model "$stdout_file"

  local cost
  cost="$(claude_cost_usd "$stdout_file")"

  if [ "$exit_code" -ne 0 ] || claude_reports_error "$stdout_file"; then
    local error_text
    error_text="$(claude_error_text "$stdout_file" "$stderr_file" "$exit_code")"
    write_error_entry "$pipeline" "$probe" "$run" "$error_text" "$cost"
    rm -f "$stdout_file" "$stderr_file"
    [ -n "$before_manifest" ] && rm -f "$before_manifest"
    rm -rf "$project_dir"
    return
  fi

  case "$probe" in
    spec) score_probe_entry "$pipeline" "$probe" "$run" "$project_dir" "$cost" ;;
    review) review_probe_entry "$pipeline" "$probe" "$run" "$project_dir" "$before_manifest" "$stdout_file" "$cost" ;;
  esac

  [ -n "$before_manifest" ] && rm -f "$before_manifest"
  rm -f "$stdout_file" "$stderr_file"
  rm -rf "$project_dir"
}

for pipeline in specflow superspec; do
  for probe in "${PROBES_TO_RUN[@]}"; do
    case "$pipeline" in
      specflow) prompt="$(specflow_probe_prompt "$probe")" ;;
      superspec) prompt="$(superspec_probe_prompt "$probe")" ;;
    esac
    for ((run = 1; run <= COMPARE_RUNS; run++)); do
      run_probe_entry "$pipeline" "$probe" "$run" "$prompt"
    done
  done
done

FINAL_MODEL="$MODEL"
[ -n "$RECORDED_MODEL" ] && FINAL_MODEL="$RECORDED_MODEL"

mkdir -p "$(dirname "$COMPARE_RESULTS")"
assemble_results_json "$FINAL_MODEL" < "$RESULTS_ENTRIES_FILE" > "$COMPARE_RESULTS"
rm -f "$RESULTS_ENTRIES_FILE"

exit 0
