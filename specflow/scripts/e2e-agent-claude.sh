#!/usr/bin/env bash
# scripts/e2e-agent-claude.sh
#
# Full agent-driven end-to-end test for the specflow extension, run through
# Claude Code in headless (-p) mode. scripts/e2e-smoke.sh covers the other
# e2e test: structural assertions with no LLM, ~60s.
#
# Drives a deterministic feature ("a static landing page for the specflow
# project") through every stage of specflow's workflow and asserts, at each
# stage, that the expected artifact and section structure exist. Each stage
# is a separate `claude -p` invocation; the first failed assertion stops the
# run.
#
# Pipeline
#   Stage 1  /speckit.constitution, writes .specify/memory/constitution.md
#   Stage 2  /speckit.specify, writes specs/001-.../spec.md
#   Stage 3  /speckit.specflow.brainstorm  (mutates spec.md, adds Edge Cases,
#                                     records a resolved question in decisions.md)
#   Stage 4  /speckit.plan, writes specs/001-.../plan.md
#   Stage 5  /speckit.tasks, writes specs/001-.../tasks.md
#                                     (after_tasks hook may invoke .specflow.tasks)
#   Stage 6  /speckit.specflow.execute, writes web/index.html and progress updates
#   Stage 7  /speckit.specflow.review, writes checklists/review.md
#
# Environment
#   ANTHROPIC_API_KEY     required (unless E2E_DRY_RUN=1)
#   E2E_DRY_RUN=1         print the prompts, skip the claude call (free)
#   E2E_MAX_BUDGET_USD    per-stage budget cap, default 0.50
#   E2E_MAX_TURNS         per-stage turn cap, default 30
#   KEEP_WORKDIR=1        keep the tmp project at exit (default: keep it only
#                         when the run fails, or when E2E_RESUME_WORKDIR named it)
#
# Usage
#   ANTHROPIC_API_KEY=sk-ant-... bash scripts/e2e-agent-claude.sh
#   E2E_DRY_RUN=1            bash scripts/e2e-agent-claude.sh    # logic test only
#
# Exit code
#   0 if every stage's assertions pass, otherwise 1.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN="${E2E_DRY_RUN:-0}"
MAX_BUDGET="${E2E_MAX_BUDGET_USD:-0.50}"
MAX_TURNS="${E2E_MAX_TURNS:-30}"
KEEP_WORKDIR="${KEEP_WORKDIR:-0}"
# Resume support: skip prep + earlier stages by reusing an existing workdir.
#   E2E_RESUME_WORKDIR=/abs/path  reuse this workdir (skip prep stage)
#   E2E_RESUME_FROM=N             skip stages 1..N-1 (default: 1, run all)
RESUME_WORKDIR="${E2E_RESUME_WORKDIR:-}"
RESUME_FROM="${E2E_RESUME_FROM:-1}"

if [ -t 1 ]; then
  C_GREEN=$'\033[32m'; C_RED=$'\033[31m'; C_YELLOW=$'\033[33m'
  C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'; C_RST=$'\033[0m'
else
  C_GREEN=""; C_RED=""; C_YELLOW=""; C_DIM=""; C_BOLD=""; C_RST=""
fi

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
if ! command -v uvx >/dev/null 2>&1; then
  printf '%sFAIL%s uvx not in PATH. Install uv: https://docs.astral.sh/uv/\n' "$C_RED" "$C_RST"; exit 1
fi

WORK=""
if [ -n "$RESUME_WORKDIR" ]; then
  if [ ! -d "$RESUME_WORKDIR" ]; then
    printf '%sFAIL%s E2E_RESUME_WORKDIR=%s does not exist.\n' "$C_RED" "$C_RST" "$RESUME_WORKDIR"; exit 1
  fi
  WORK="$RESUME_WORKDIR"
else
  WORK="$(mktemp -d -t specflow-agent.XXXXXX)"
fi
LOGS="$WORK/.logs"; mkdir -p "$LOGS"

# Exit 0 when the run may discard its workdir: it exited clean, nothing asked
# to keep it, and it created the directory rather than being handed one.
# Args: <exit status>.
workdir_is_disposable() {
  [ "$1" -eq 0 ] && [ "$KEEP_WORKDIR" != "1" ] && [ -z "$RESUME_WORKDIR" ]
}

# The EXIT trap runs after every exit path, so the result line prints here to
# land last. The exit status is the only signal that separates a clean finish
# from an early exit on a hard error, which leaves the workdir for inspection.
cleanup() {
  local status=$?
  if workdir_is_disposable "$status"; then
    rm -rf "$WORK"
    printf '\n%sworkdir removed:%s %s\n' "$C_DIM" "$C_RST" "$WORK"
  else
    printf '\n%sworkdir kept:%s %s\n' "$C_DIM" "$C_RST" "$WORK"
  fi
  printf '\n%d assertions, %d failed\n' "$PASS" "$FAIL"
}

# output helpers
PASS=0; FAIL=0; FAILED_STAGE=""
trap cleanup EXIT
pass()  { printf '    %sok%s   %s\n' "$C_GREEN" "$C_RST" "$1"; PASS=$((PASS+1)); }
miss()  { printf '    %sFAIL%s %s\n' "$C_RED"   "$C_RST" "$1"; FAIL=$((FAIL+1)); }
note()  { printf '    %s-%s    %s\n' "$C_DIM"   "$C_RST" "$1"; }
title() { printf '\n%s[Stage %s]%s %s\n'   "$C_BOLD" "$1" "$C_RST" "$2"; }

skip()           { printf '    %s~%s    %s %s(dry-run)%s\n' "$C_YELLOW" "$C_RST" "$1" "$C_DIM" "$C_RST"; }
assert_file()    { [ -f "$2" ]   && pass "$1" || { miss "$1 (missing: ${2#$WORK/})"; return 1; }; }
assert_no_path() { [ ! -e "$2" ] && pass "$1" || { miss "$1 (unexpected: ${2#$WORK/})"; return 1; }; }
assert_grep() {
  local desc="$1" pattern="$2" file="$3"
  if [ -f "$file" ] && grep -qE -- "$pattern" "$file"; then pass "$desc"
  else miss "$desc (pattern '$pattern' missing from ${file#$WORK/})"; return 1; fi
}

# brainstorm.md step 7 appends an ADR-lite entry for each Open Questions row the
# run marks Resolved, so every resolved id must appear in decisions.md. A run
# that resolved nothing has nothing to record.
assert_resolved_questions_recorded() {
  local spec="$1" decisions="$2" ids id rc=0
  ids="$(grep -E '^\|[[:space:]]*OQ-[0-9]+[[:space:]]*\|.*\|[[:space:]]*Resolved[[:space:]]*\|' "$spec" 2>/dev/null \
         | grep -oE 'OQ-[0-9]+')"
  if [ -z "$ids" ]; then
    note "no Open Questions row marked Resolved; nothing to record in decisions.md"
    return 0
  fi
  assert_grep "  decisions.md carries an ADR-NNNN heading" '^#{2}[[:space:]]+ADR-[0-9]{4}:' "$decisions" || rc=1
  for id in $ids; do
    if [ -f "$decisions" ] && grep -qF -- "$id" "$decisions"; then
      pass "  $id is Resolved in spec.md and recorded in decisions.md"
    else
      miss "  $id is Resolved in spec.md but absent from ${decisions#$WORK/}"
      rc=1
    fi
  done
  return "$rc"
}

# Stops the run once a stage has set FAILED_STAGE.
stop_if_stage_failed() {
  [ -z "$FAILED_STAGE" ] && return 0
  printf '\n%sStopped at Stage %s%s\n' "$C_RED" "$FAILED_STAGE" "$C_RST"
  exit 1
}

PROMPT_PREVIEW_CHARS=400

# Runs one workflow stage's prompt through claude -p.
# Args: <stage_id> <prompt>. Requires cwd == $WORK so claude picks up
# .claude/ and .specify/.
run_claude() {
  local stage_id="$1"; shift
  local prompt="$1"
  local log="$LOGS/stage-$stage_id.log"

  if [ "$stage_id" -lt "$RESUME_FROM" ]; then
    note "SKIP claude call (resumed past stage $stage_id, reusing prior artifacts)"
    return 0
  fi

  if [ "$DRY_RUN" = "1" ]; then
    note "DRY_RUN: would call claude with prompt:"
    printf '%s        %s%s\n' "$C_DIM" "$prompt" "$C_RST" | head -c "$PROMPT_PREVIEW_CHARS"; echo
    : > "$log"
    return 0
  fi

  # --permission-mode acceptEdits: no interactive prompt for file writes
  # --max-turns: caps agent loops
  # --max-budget-usd: caps per-stage spend
  # --output-format text: response format; the caller does not parse it
  # claude reads the project dir (.claude/, .specify/, AGENTS.md auto-discovery)
  # to find the spec-kit and specflow slash commands. claude exits non-zero on
  # max-turns or budget after writing artifacts, so the on-disk assertions
  # below decide whether the stage delivered.
  if claude -p \
        --permission-mode acceptEdits \
        --max-turns "$MAX_TURNS" \
        --max-budget-usd "$MAX_BUDGET" \
        --output-format text \
        "$prompt" >"$log" 2>&1; then
    note "claude transcript: ${log#$WORK/}"
  else
    local rc=$?
    note "claude exited non-zero (rc=$rc), likely max-turns or budget. Checking artifacts."
    note "claude transcript: ${log#$WORK/}"
  fi
}

LOG_TAIL_LINES=20
SKILLS_LIST_LIMIT=30

# Runs one `uvx --from spec-kit specify ...` step, logging output and
# printing pass/fail. Exits 1 on failure, after showing the log tail.
run_uvx_step() {
  local log="$1" ok_msg="$2" fail_msg="$3"; shift 3
  uvx --from git+https://github.com/github/spec-kit.git "$@" \
      </dev/null >"$log" 2>&1 \
    || { miss "$fail_msg (see $log)"; tail -n "$LOG_TAIL_LINES" "$log"; exit 1; }
  pass "$ok_msg"
}

if [ -n "$RESUME_WORKDIR" ]; then
  title 0 "prep: resuming from existing workdir"
  cd "$WORK" || exit 1
  pass "reusing workdir: $WORK"
  note "skipping init/install (will reuse existing .specify/, .claude/, specs/)"
else
  title 0 "prep: init spec-kit + install specflow (--dev)"
  cd "$WORK" || exit 1

  run_uvx_step "$LOGS/init.log" "specify init (--integration claude) succeeded" "specify init failed" \
    specify init --here --integration claude --ignore-agent-tools --force
  run_uvx_step "$LOGS/add.log" "specflow installed --dev" "specify extension add failed" \
    specify extension add "$REPO_ROOT" --dev
fi

assert_file ".specify/extensions.yml present" "$WORK/.specify/extensions.yml" || exit 1
[ -d "$WORK/.claude" ] && pass ".claude/ scaffolding present (slash commands discoverable)" \
                       || miss ".claude/ missing; the agent cannot see slash commands"

# A missing skill file here explains a stage 1+ failure before the agent runs.
note "slash commands visible to claude (.claude/skills/):"
find "$WORK/.claude" -type f \( -name '*.md' -o -name 'SKILL.md' \) 2>/dev/null \
  | sed "s|^$WORK/.claude/|        |" | sort | head -n "$SKILLS_LIST_LIMIT" || true

# spec-kit compiles commands/X.md into SKILL.md with frontmatter, but in some
# install modes the compiled artifacts land under
#   .specify/extensions/<slug>/.specify-dev/agent-commands/claude/...
# instead of .claude/skills/, leaving them invisible to the agent.
DISTRIB_FAIL=0
for c in status brainstorm tasks execute review; do
  if [ -f "$WORK/.claude/skills/speckit-specflow-$c/SKILL.md" ]; then
    pass "  /speckit.specflow.$c is visible to claude"
  else
    miss "  /speckit.specflow.$c NOT in .claude/skills/; the agent cannot see it"
    DISTRIB_FAIL=1
  fi
done
if [ "$DISTRIB_FAIL" = "1" ]; then
  printf '\n%sDistribution gap detected.%s specflow SKILLs were compiled here:\n' "$C_YELLOW" "$C_RST"
  find "$WORK/.specify/extensions/specflow" -name 'SKILL.md' 2>/dev/null \
    | sed "s|^$WORK/|    |"
  printf '%sBut not symlinked/copied into .claude/skills/.%s\n' "$C_YELLOW" "$C_RST"
  printf 'Skipping agent stages; the results would be meaningless.\n'
  exit 1
fi

# A dry run copies the shipped example snapshot into the project and runs
# every stage assertion against it, so a broken assertion fails without an
# agent call. The snapshot is a real run's output, so it is the fixture.
SNAPSHOT="$REPO_ROOT/examples/static-landing-page"
if [ "$DRY_RUN" = "1" ]; then
  title 0 "dry run: seeding the project from examples/static-landing-page"
  cp -R "$SNAPSHOT/specs" "$WORK/"
  cp -R "$SNAPSHOT/web" "$WORK/"
  cp "$SNAPSHOT/.specify/memory/constitution.md" "$WORK/.specify/memory/constitution.md"
  cp "$SNAPSHOT/decisions.md" "$WORK/decisions.md"
  pass "snapshot copied into ${WORK##*/}"
fi

# stage 1: /speckit.constitution
title 1 "/speckit.constitution: establish project principles"
LANDING_VISION='Static landing page for the specflow project.
Audience: developers evaluating spec-kit extensions.
Constraints: pure HTML+CSS, no build tooling, output goes to web/index.html.
Quality bars: semantic HTML, mobile-friendly, no external network deps at runtime.'

run_claude 1 "$(cat <<EOF
You are working in a fresh spec-kit project. Use the slash command
/speckit.constitution to establish a constitution for this project.

Project intent:
$LANDING_VISION

Run /speckit.constitution and produce .specify/memory/constitution.md with at
least these sections: ## Core Principles, ## Quality Standards, ## Constraints.
Then stop.
EOF
)" || { FAILED_STAGE=1; }

if [ -z "$FAILED_STAGE" ]; then
  assert_file ".specify/memory/constitution.md exists" "$WORK/.specify/memory/constitution.md"           || FAILED_STAGE=1
  assert_grep "  has ## Core Principles section"        '^#{2,4}[[:space:]]+Core Principles' "$WORK/.specify/memory/constitution.md" || FAILED_STAGE=1
fi
stop_if_stage_failed

# stage 2: /speckit.specify
title 2 "/speckit.specify: write the feature spec"
run_claude 2 "$(cat <<EOF
Use the slash command /speckit.specify with this feature description:

"Static landing page for specflow. Three priorities:
 P1: Hero section with project name, tagline, and a 'Get Started' button.
 P2: Features grid showing the 5 core commands (status, brainstorm, tasks, execute, review).
 P3: Workflow diagram and an install command snippet.
 Output target: web/index.html, pure HTML+CSS, no JavaScript build."

Run /speckit.specify, ensure spec.md is created under specs/<NNN>-<slug>/spec.md
at the project ROOT (not under .specify/), and that it contains user scenarios
labeled P1, P2, P3. Then stop.
EOF
)" || FAILED_STAGE=2

# Locate the spec dir (slug is agent-chosen, so glob it)
SPEC_DIR=""
if [ -z "$FAILED_STAGE" ]; then
  SPEC_DIR="$(ls -d "$WORK"/specs/[0-9][0-9][0-9]-* 2>/dev/null | head -n1 || true)"
  if [ -n "$SPEC_DIR" ]; then
    pass "spec dir at project root: ${SPEC_DIR#$WORK/}"
  else
    miss "no specs/NNN-*/ directory found at project root"
    FAILED_STAGE=2
  fi
fi
if [ -z "$FAILED_STAGE" ]; then
  assert_file "  spec.md exists"       "$SPEC_DIR/spec.md"              || FAILED_STAGE=2
  # issue #4 anti-regression: spec must be at root specs/, not under .specify/
  assert_no_path "  no .specify/specs/ leak (issue #4)" "$WORK/.specify/specs"  || FAILED_STAGE=2
  assert_grep "  spec.md mentions P1/P2/P3" '\b(P1|P2|P3)\b' "$SPEC_DIR/spec.md" || FAILED_STAGE=2
fi
stop_if_stage_failed

# stage 3: /speckit.specflow.brainstorm
title 3 "/speckit.specflow.brainstorm: deep-dive edge cases"
SPEC_REL="${SPEC_DIR#$WORK/}/spec.md"
SPEC_BEFORE_HASH="$(shasum "$SPEC_DIR/spec.md" 2>/dev/null | awk '{print $1}')"

run_claude 3 "$(cat <<EOF
Use the specflow slash command /speckit.specflow.brainstorm against the
existing spec at $SPEC_REL.

Per the specflow contract, brainstorm should mutate the spec file IN PLACE
and add (or expand) at minimum:
  - an "## Edge Cases" section
  - an "## Open Questions" or "## Assumptions" section

Per step 7 of the command, an Open Questions row you mark Resolved because a
choice was settled also gets an ADR-lite entry appended to decisions.md at the
project root.

Run /speckit.specflow.brainstorm $SPEC_REL and stop when the spec file has
been updated.
EOF
)" || FAILED_STAGE=3

if [ -z "$FAILED_STAGE" ]; then
  # No agent ran in a dry run or on a resumed stage, so the file is unchanged by design.
  if [ "$DRY_RUN" = "1" ] || [ 3 -lt "$RESUME_FROM" ]; then
    skip "spec.md was modified in place"
  elif [ "$SPEC_BEFORE_HASH" != "$(shasum "$SPEC_DIR/spec.md" | awk '{print $1}')" ]; then
    pass "spec.md was modified in place"
  else
    miss "spec.md content unchanged after brainstorm"
    FAILED_STAGE=3
  fi
  assert_grep "  ## Edge Cases section added" '^#{2,4}[[:space:]]+Edge Cases'           "$SPEC_DIR/spec.md" || FAILED_STAGE=3
  assert_grep "  ## Open Questions or Assumptions added" '^#{2,4}[[:space:]]+(Open Questions|Assumptions)' "$SPEC_DIR/spec.md" || FAILED_STAGE=3
  assert_resolved_questions_recorded "$SPEC_DIR/spec.md" "$WORK/decisions.md" || FAILED_STAGE=3
fi
stop_if_stage_failed

# stage 4: /speckit.plan
title 4 "/speckit.plan: technical implementation plan"
run_claude 4 "$(cat <<EOF
Run /speckit.plan to produce a technical implementation plan for the spec at
$SPEC_REL. The plan should be written to ${SPEC_DIR#$WORK/}/plan.md with
sections covering technical approach, file structure, and any risks.
EOF
)" || FAILED_STAGE=4

if [ -z "$FAILED_STAGE" ]; then
  assert_file "plan.md exists at ${SPEC_DIR#$WORK/}/plan.md" "$SPEC_DIR/plan.md" || FAILED_STAGE=4
fi
stop_if_stage_failed

# stage 5: /speckit.tasks (after_tasks hook may trigger specflow.tasks)
title 5 "/speckit.tasks: phased task breakdown"
run_claude 5 "$(cat <<EOF
Run /speckit.tasks to produce a phased task breakdown for the plan at
${SPEC_DIR#$WORK/}/plan.md. Tasks should be written to
${SPEC_DIR#$WORK/}/tasks.md with phase markers and ID-style task numbers
(e.g. T001, T002, ...). If the after_tasks hook prompts you to also run
/speckit.specflow.tasks, accept and run it.
EOF
)" || FAILED_STAGE=5

if [ -z "$FAILED_STAGE" ]; then
  assert_file "tasks.md exists" "$SPEC_DIR/tasks.md" || FAILED_STAGE=5
  assert_grep "  contains T001-style task IDs" '\bT[0-9]{3}\b' "$SPEC_DIR/tasks.md" || FAILED_STAGE=5
fi
stop_if_stage_failed

# stage 6: /speckit.specflow.execute
title 6 "/speckit.specflow.execute: implement"
run_claude 6 "$(cat <<EOF
Before implementation, run /speckit.analyze for ${SPEC_DIR#$WORK/}.
Follow the Gate markers protocol in the installed specflow workflow guide:
remove any previous ${SPEC_DIR#$WORK/}/.analyzed marker before analysis,
then write that marker only if the report has zero critical inconsistencies.
If critical inconsistencies remain, stop and report them without implementing.

Once the analyze gate passes, run /speckit.specflow.execute to implement the tasks in
${SPEC_DIR#$WORK/}/tasks.md. The deliverable is a static landing page at
web/index.html (pure HTML+CSS, no JS build tooling). Per the specflow
contract, also keep ${SPEC_DIR#$WORK/}/progress.yml updated as tasks complete.
EOF
)" || FAILED_STAGE=6

if [ -z "$FAILED_STAGE" ]; then
  assert_file "analyze gate marker exists" "$SPEC_DIR/.analyzed" || FAILED_STAGE=6
  assert_file "web/index.html generated"        "$WORK/web/index.html"      || FAILED_STAGE=6
  assert_grep "  index.html has <html>"        '<html'                     "$WORK/web/index.html" || FAILED_STAGE=6
  assert_grep "  index.html mentions specflow" 'specflow'                "$WORK/web/index.html" || FAILED_STAGE=6
  if [ -f "$SPEC_DIR/progress.yml" ]; then
    pass "progress.yml exists at ${SPEC_DIR#$WORK/}/progress.yml"
  else
    note "progress.yml not produced (soft signal; the specflow contract suggests it)"
  fi
fi
stop_if_stage_failed

# stage 7: /speckit.specflow.review
title 7 "/speckit.specflow.review: review against spec"
run_claude 7 "$(cat <<EOF
Run /speckit.specflow.review to review the implementation under web/ against
the spec/plan/tasks at ${SPEC_DIR#$WORK/}. Per the specflow contract, write
the review output to ${SPEC_DIR#$WORK/}/checklists/review.md as a checklist.
EOF
)" || FAILED_STAGE=7

if [ -z "$FAILED_STAGE" ]; then
  assert_file "review.md exists" "$SPEC_DIR/checklists/review.md" || FAILED_STAGE=7
  assert_grep "  review.md is a checklist" '\[[ xX]\]' "$SPEC_DIR/checklists/review.md" || FAILED_STAGE=7
fi
stop_if_stage_failed

# summary
printf '\n%sSummary%s: %d assertions passed across 7 stages\n' "$C_BOLD" "$C_RST" "$PASS"
echo
echo "Final artifacts under workdir:"
find "$WORK" -type f \
  \( -path '*/specs/*' -o -path '*/web/*' -o -path '*/.specify/memory/*' -o -name 'AGENTS.md' -o -name 'CLAUDE.md' \) \
  -not -path '*/.git/*' \
  | sed "s|^$WORK/|    |" | sort

if [ "$DRY_RUN" = "1" ]; then
  printf '\n%sDRY_RUN complete.%s %d assertions ran against examples/static-landing-page; no agent stage was called.\n' "$C_YELLOW" "$C_RST" "$PASS"
  printf 'Set ANTHROPIC_API_KEY and re-run without E2E_DRY_RUN=1 to run the agent stages.\n'
  [ "$FAIL" -gt 0 ] && exit 1
  exit 0
fi
[ "$FAIL" -gt 0 ] && exit 1
exit 0
