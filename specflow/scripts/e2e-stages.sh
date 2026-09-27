#!/usr/bin/env bash
# scripts/e2e-stages.sh
#
# The seven workflow stages both agent-driven e2e tests drive, with the
# assertions, the project prep, and the dry-run seed they share.
# scripts/e2e-agent-claude.sh and scripts/e2e-agent-copilot.sh each set
# AGENT_NAME, source this file, define invoke_agent, and call
# stage_1_constitution through stage_7_review with that function's name.
#
# Pipeline
#   Stage 0  /speckit.specflow.status, dry run only: superpowers detection
#                                     against a skill tree and a plugin manifest
#   Stage 1  /speckit.constitution, writes .specify/memory/constitution.md
#   Stage 2  /speckit.specify, writes specs/001-.../spec.md
#   Stage 3  /speckit.specflow.brainstorm  (mutates spec.md, adds Edge Cases,
#                                     records a resolved question in decisions.md)
#   Stage 4  /speckit.plan, writes specs/001-.../plan.md
#   Stage 5  /speckit.tasks, writes specs/001-.../tasks.md
#                                     (after_tasks hook may invoke .specflow.tasks)
#   Stage 6  /speckit.specflow.execute, writes src/link_audit/ and progress updates
#   Stage 7  /speckit.specflow.review, writes checklists/review.md
#
# invoke_agent takes the prompt and the log path and drives the CLI in the
# current directory. run_agent_stage calls it only when the stage is neither
# resumed past nor dry-run, so a sourcing script never repeats that check.
#
# Environment
#   E2E_DRY_RUN=1         print the prompts, skip the agent call (free)
#   KEEP_WORKDIR=1        keep the tmp project at exit (default: keep it only
#                         when the run fails, or when E2E_RESUME_WORKDIR named it)
#   E2E_RESUME_WORKDIR    reuse this workdir, skipping the prep stage
#   E2E_RESUME_FROM=N     skip stages 1..N-1 (default: 1, run all)

AGENT_NAME="${AGENT_NAME:?is unset; set it before sourcing e2e-stages.sh}"
DRY_RUN="${E2E_DRY_RUN:-0}"
KEEP_WORKDIR="${KEEP_WORKDIR:-0}"
RESUME_WORKDIR="${E2E_RESUME_WORKDIR:-}"
RESUME_FROM="${E2E_RESUME_FROM:-1}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNAPSHOT="$REPO_ROOT/examples/link-audit"

if [ -t 1 ]; then
  C_GREEN=$'\033[32m'; C_RED=$'\033[31m'; C_YELLOW=$'\033[33m'
  C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'; C_RST=$'\033[0m'
else
  C_GREEN=""; C_RED=""; C_YELLOW=""; C_DIM=""; C_BOLD=""; C_RST=""
fi

# output helpers
PASS=0; FAIL=0; FAILED_STAGE=""
# A replay is the second entry into a stage that assert_idempotent runs.
# REPLAYING holds 1 for the length of that entry, and AGENT_INVOKE carries the
# invocation function the first entry was given.
IDEMPOTENT=0; REPLAYING=0; AGENT_INVOKE=""
WORK=""; LOGS=""
SPEC_DIR=""; SPEC_REL=""
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

# brainstorm.md step 9 appends an ADR-lite entry for each Open Questions row the
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

# Counts the rows of a spec's `## Open Questions` table whose Status cell is not
# `Resolved`, the rule step 2 of commands/tasks.md states. A spec carrying no
# such table counts zero, which is the gate's pass case.
count_unresolved_questions() {
  awk '
    /^## / { inside = ($0 ~ /^## Open Questions[[:space:]]*$/); next }
    !inside              { next }
    !/^[[:space:]]*\|/   { next }
    {
      columns = split($0, cell, "|")
      for (i = 1; i <= columns; i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", cell[i])
      if (!seen_header) {
        for (i = 1; i <= columns; i++) if (cell[i] == "Status") status_column = i
        seen_header = 1
        next
      }
      if (cell[2] ~ /^:?-+:?$/) next
      if (status_column && cell[status_column] != "Resolved") unresolved++
    }
    END { print unresolved + 0 }
  ' "$1"
}

DIFF_INDENT='        '

# Re-enters a stage and fails on any file the second entry changes in the
# feature directory. "Everything is resumable" in AGENTS.md makes a stage safe
# to re-run after an interruption, and only a second entry shows it.
# The replay runs in a subshell with REPLAYING=1, so its assertions, its
# counters, and its exit path stay out of the run, while its writes land on
# disk. Args: <stage function name>.
assert_idempotent() {
  local stage="$1"
  [ "$REPLAYING" = "1" ] && return 0
  [ -z "$FAILED_STAGE" ] || return 0

  local feature_dir="$SPEC_DIR"
  [ -n "$feature_dir" ] || feature_dir="$(ls -d "$WORK"/specs/[0-9][0-9][0-9]-* 2>/dev/null | head -n1 || true)"
  if [ -z "$feature_dir" ] || [ ! -d "$feature_dir" ]; then
    note "$stage ran before a feature directory existed; no second entry to compare"
    return 0
  fi

  local before="$WORK/.idempotence/$stage"
  rm -rf "$before"; mkdir -p "$before"
  cp -R "$feature_dir/." "$before/"

  ( REPLAYING=1; "$stage" "$AGENT_INVOKE" ) >/dev/null 2>&1

  local changed
  changed="$(diff -r "$before" "$feature_dir" 2>&1)"
  rm -rf "$before"
  if [ -z "$changed" ]; then
    pass "re-entering $stage leaves ${feature_dir#$WORK/} unchanged"
    IDEMPOTENT=$((IDEMPOTENT+1))
    return 0
  fi
  miss "re-entering $stage rewrites ${feature_dir#$WORK/}"
  printf '%s\n' "$changed" | sed "s|^|$DIFF_INDENT|"
  return 1
}

# Stops the run once a stage has set FAILED_STAGE.
stop_if_stage_failed() {
  # A replay runs its stage to the end, so the diff sees every write.
  [ "$REPLAYING" = "1" ] && return 0
  [ -z "$FAILED_STAGE" ] && return 0
  printf '\n%sStopped at Stage %s%s\n' "$C_RED" "$FAILED_STAGE" "$C_RST"
  exit 1
}

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
  printf '\n%d assertions, %d failed, %d idempotence checks\n' "$PASS" "$FAIL" "$IDEMPOTENT"
}

# Fails the run when uvx is absent, because every prep step goes through it.
require_uvx() {
  command -v uvx >/dev/null 2>&1 && return 0
  printf '%sFAIL%s uvx not in PATH. Install uv: https://docs.astral.sh/uv/\n' "$C_RED" "$C_RST"
  exit 1
}

# Creates the temporary project the stages run in, or reuses the one
# E2E_RESUME_WORKDIR names, and sets WORK and LOGS.
# Args: <mktemp name prefix>.
open_workdir() {
  if [ -n "$RESUME_WORKDIR" ]; then
    if [ ! -d "$RESUME_WORKDIR" ]; then
      printf '%sFAIL%s E2E_RESUME_WORKDIR=%s does not exist.\n' "$C_RED" "$C_RST" "$RESUME_WORKDIR"
      exit 1
    fi
    WORK="$RESUME_WORKDIR"
  else
    WORK="$(mktemp -d -t "$1".XXXXXX)"
  fi
  LOGS="$WORK/.logs"; mkdir -p "$LOGS"
}

PROMPT_PREVIEW_CHARS=400

# Runs one workflow stage's prompt through the named agent-invocation function.
# Args: <invoke function name> <stage_id> <prompt>. Requires cwd == $WORK so
# the CLI picks up the agent's config directory and .specify/.
run_agent_stage() {
  local invoke="$1" stage_id="$2" prompt="$3"
  local log="$LOGS/stage-$stage_id.log"
  AGENT_INVOKE="$invoke"

  # A replay measures what a second entry writes; a second agent call would
  # charge for a different answer and hide that measurement.
  [ "$REPLAYING" = "1" ] && return 0

  if [ "$stage_id" -lt "$RESUME_FROM" ]; then
    note "SKIP $AGENT_NAME call (resumed past stage $stage_id, reusing prior artifacts)"
    return 0
  fi

  if [ "$DRY_RUN" = "1" ]; then
    note "DRY_RUN: would call $AGENT_NAME with prompt:"
    printf '%s        %s%s\n' "$C_DIM" "$prompt" "$C_RST" | head -c "$PROMPT_PREVIEW_CHARS"; echo
    : > "$log"
    return 0
  fi

  "$invoke" "$prompt" "$log"
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

# Initialises a spec-kit project in $WORK, installs specflow into it, and
# checks that every command compiled into the agent's own skills directory.
# Leaves cwd at $WORK.
# Args: <spec-kit integration name> <the agent's config directory name>.
prep_project() {
  local integration="$1" agent_dir="$2"

  if [ -n "$RESUME_WORKDIR" ]; then
    title 0 "prep: resuming from existing workdir"
    cd "$WORK" || exit 1
    pass "reusing workdir: $WORK"
    note "skipping init/install (will reuse existing .specify/, $agent_dir/, specs/)"
  else
    title 0 "prep: init spec-kit + install specflow (--dev)"
    cd "$WORK" || exit 1

    run_uvx_step "$LOGS/init.log" "specify init (--integration $integration) succeeded" "specify init failed" \
      specify init --here --integration "$integration" --ignore-agent-tools --force
    run_uvx_step "$LOGS/add.log" "specflow installed --dev" "specify extension add failed" \
      specify extension add "$REPO_ROOT" --dev
  fi

  assert_file ".specify/extensions.yml present" "$WORK/.specify/extensions.yml" || exit 1
  [ -d "$WORK/$agent_dir" ] && pass "$agent_dir/ scaffolding present (slash commands discoverable)" \
                            || miss "$agent_dir/ missing; the agent cannot see slash commands"

  # A missing skill file here explains a stage 1+ failure before the agent runs.
  note "slash commands visible to $AGENT_NAME ($agent_dir/skills/):"
  find "$WORK/$agent_dir" -type f \( -name '*.md' -o -name 'SKILL.md' \) 2>/dev/null \
    | sed "s|^$WORK/$agent_dir/|        |" | sort | head -n "$SKILLS_LIST_LIMIT" || true

  # spec-kit compiles commands/X.md into SKILL.md with frontmatter, but in some
  # install modes the compiled artifacts land under
  #   .specify/extensions/<slug>/.specify-dev/agent-commands/<agent>/...
  # instead of the agent's skills directory, leaving them invisible to it.
  local distribution_gap=0 command_name
  for command_name in status brainstorm tasks execute review gate; do
    if [ -f "$WORK/$agent_dir/skills/speckit-specflow-$command_name/SKILL.md" ]; then
      pass "  /speckit.specflow.$command_name is visible to $AGENT_NAME"
    else
      miss "  /speckit.specflow.$command_name NOT in $agent_dir/skills/; the agent cannot see it"
      distribution_gap=1
    fi
  done
  [ "$distribution_gap" = "0" ] && return 0

  printf '\n%sDistribution gap detected.%s specflow SKILLs were compiled here:\n' "$C_YELLOW" "$C_RST"
  find "$WORK/.specify/extensions/specflow" -name 'SKILL.md' 2>/dev/null \
    | sed "s|^$WORK/|    |"
  printf '%sBut not symlinked/copied into %s/skills/.%s\n' "$C_YELLOW" "$agent_dir" "$C_RST"
  printf 'Skipping agent stages; the results would be meaningless.\n'
  exit 1
}

MAPPED_SKILL_COUNT=12
SUPERPOWERS_FIXTURE_VERSION="5.0.0"

# Prints the Skill Directory cell of every Skill Mapping row, the directory
# name /speckit.specflow.status step 3 looks for.
mapped_skill_directories() {
  awk '
    /^## /               { inside = ($0 ~ /^## Skill Mapping[[:space:]]*$/); next }
    !inside              { next }
    !/^[[:space:]]*\|/   { next }
    {
      split($0, cell, "|")
      gsub(/[`[:space:]]/, "", cell[4])
      sub(/\/$/, "", cell[4])
      if (cell[4] == "" || cell[4] == "SkillDirectory" || cell[4] ~ /^:?-+:?$/) next
      print cell[4]
    }
  ' "$REPO_ROOT/references/superpowers-mapping.md"
}

# Counts the mapped skills a project carries at the project-local path the
# mapping's Detection Logic names. Args: <project directory>.
count_detected_skills() {
  local project="$1" skill found=0
  for skill in $(mapped_skill_directories); do
    [ -f "$project/.agents/skills/$skill/SKILL.md" ] && found=$((found+1))
  done
  printf '%s\n' "$found"
}

# Exit 0 when a version sits outside a `>=X.Y.Z <A.B.C` range. The tested
# range the mapping states is bounded on major numbers, so the comparison
# reads major numbers. Args: <version> <range>.
version_is_outside_range() {
  local version="$1" range="$2" major floor ceiling
  major="${version%%.*}"
  floor="$(printf '%s\n' "$range"   | sed -n 's/.*>=\([0-9][0-9]*\)\..*/\1/p')"
  ceiling="$(printf '%s\n' "$range" | sed -n 's/.*<\([0-9][0-9]*\)\..*/\1/p')"
  [ -n "$floor" ] && [ -n "$ceiling" ] || return 1
  [ "$major" -lt "$floor" ] || [ "$major" -ge "$ceiling" ]
}

# Writes the two fixtures the status stage reads: a project-local skill tree
# holding every mapped skill, and a plugin manifest naming a superpowers
# version below the tested range. The manifest stands in for
# ~/.claude/plugins/installed_plugins.json, which a test never writes.
seed_status_fixtures() {
  local skill
  for skill in $(mapped_skill_directories); do
    mkdir -p "$WORK/.agents/skills/$skill"
    printf '# %s\n' "$skill" > "$WORK/.agents/skills/$skill/SKILL.md"
  done

  mkdir -p "$WORK/.claude/plugins"
  cat > "$WORK/.claude/plugins/installed_plugins.json" <<FIXTURE
{
  "plugins": {
    "superpowers": {
      "version": "$SUPERPOWERS_FIXTURE_VERSION"
    }
  }
}
FIXTURE
}

# The dry run's status stage: the superpowers detection /speckit.specflow.status
# step 3 runs, checked against the two fixtures above. seed_dry_run_snapshot
# calls it, because the stage needs no agent and both agent scripts reach it
# there.
stage_0_status() {
  title 0 "/speckit.specflow.status: superpowers detection"
  local mapping="$REPO_ROOT/references/superpowers-mapping.md"
  seed_status_fixtures

  assert_grep "the mapping names the project-local detection path" \
              '\.agents/skills/.*/SKILL\.md' "$mapping"

  local declared detected
  declared="$(mapped_skill_directories | wc -l | tr -d ' ')"
  if [ "$declared" = "$MAPPED_SKILL_COUNT" ]; then
    pass "  the Skill Mapping table names $MAPPED_SKILL_COUNT skills"
  else
    miss "  the Skill Mapping table names $declared skills, expected $MAPPED_SKILL_COUNT"
  fi

  detected="$(count_detected_skills "$WORK")"
  if [ "$detected" = "$MAPPED_SKILL_COUNT" ]; then
    pass "  the status stage detects $detected of $MAPPED_SKILL_COUNT skills from the fixture"
  else
    miss "  the status stage detects $detected of $MAPPED_SKILL_COUNT skills from the fixture"
  fi

  assert_grep "  status.md documents the out-of-range line" \
              'superpowers <version> is outside the tested range <range>' \
              "$REPO_ROOT/commands/status.md"

  local version range warning
  version="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
                    "$WORK/.claude/plugins/installed_plugins.json" | head -n1)"
  range="$(sed -n 's/^Tested range: `\([^`]*\)`.*/\1/p' "$mapping")"
  warning="superpowers $version is outside the tested range $range"
  if ! version_is_outside_range "$version" "$range"; then
    miss "  the fixture version $version reads as inside '$range', so no line is printed"
  elif [ "$warning" = "superpowers 5.0.0 is outside the tested range >=6.0.0 <7.0.0" ]; then
    pass "  the status stage prints: $warning"
  else
    miss "  the status stage prints '$warning'"
  fi
}

# A dry run copies the shipped example snapshot into the project and runs
# every stage assertion against it, so a broken assertion fails without an
# agent call. The snapshot is a real run's output, so it is the fixture.
seed_dry_run_snapshot() {
  [ "$DRY_RUN" = "1" ] || return 0
  title 0 "dry run: seeding the project from examples/link-audit"
  cp -R "$SNAPSHOT/specs" "$WORK/"
  cp -R "$SNAPSHOT/src" "$WORK/"
  cp "$SNAPSHOT/.specify/memory/constitution.md" "$WORK/.specify/memory/constitution.md"
  cp "$SNAPSHOT/decisions.md" "$WORK/decisions.md"
  pass "snapshot copied into ${WORK##*/}"
  stage_0_status
}

# stage 1: /speckit.constitution
# Args: <invoke function name>.
stage_1_constitution() {
  local invoke="$1"
  title 1 "/speckit.constitution: establish project principles"
  local project_vision='A command-line audit of broken links in Markdown documentation.
Audience: maintainers who run it in CI.
Constraints: Python 3.11 standard library only, pytest for tests, source under src/link_audit/, no network access during a scan.
Quality bars: exit 0 when no link is broken, 1 when one is, 2 when the scan cannot run; every error names the fix.'

  run_agent_stage "$invoke" 1 "$(cat <<EOF
You are working in a fresh spec-kit project. Use the slash command
/speckit.constitution to establish a constitution for this project.

Project intent:
$project_vision

Run /speckit.constitution and produce .specify/memory/constitution.md with at
least these sections: ## Core Principles, ## Quality Standards, ## Constraints.
Then stop.
EOF
)" || { FAILED_STAGE=1; }

  if [ -z "$FAILED_STAGE" ]; then
    assert_file ".specify/memory/constitution.md exists" "$WORK/.specify/memory/constitution.md"           || FAILED_STAGE=1
    assert_grep "  has ## Core Principles section"        '^#{2,4}[[:space:]]+Core Principles' "$WORK/.specify/memory/constitution.md" || FAILED_STAGE=1
  fi
  assert_idempotent stage_1_constitution
  stop_if_stage_failed
}

# stage 2: /speckit.specify
# Args: <invoke function name>.
stage_2_specify() {
  local invoke="$1"
  title 2 "/speckit.specify: write the feature spec"
  run_agent_stage "$invoke" 2 "$(cat <<EOF
Use the slash command /speckit.specify with this feature description:

"link-audit is a Python CLI that walks the Markdown files git ls-files
 reports, resolves each inline link target against the file system, prints the
 unresolved ones, exits 1 when any is unresolved. Heading anchors resolve against
 the slugified headings of the target file. External schemes are skipped, so the
 scan needs no network. Three priorities:
 P1: Report every relative link whose target file is missing.
 P2: Report every file.md#anchor link whose anchor matches no heading.
 P3: Scan only the Markdown files git ls-files reports."

Run /speckit.specify, ensure spec.md is created under specs/<NNN>-<slug>/spec.md
at the project ROOT (not under .specify/), and that it contains user scenarios
labeled P1, P2, P3. Then stop.
EOF
)" || FAILED_STAGE=2

  # Locate the spec dir (slug is agent-chosen, so glob it)
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
  assert_idempotent stage_2_specify
  stop_if_stage_failed
}

# stage 3: /speckit.specflow.brainstorm
# Args: <invoke function name>.
stage_3_brainstorm() {
  local invoke="$1"
  title 3 "/speckit.specflow.brainstorm: deep-dive edge cases"
  SPEC_REL="${SPEC_DIR#$WORK/}/spec.md"
  local spec_before_hash
  spec_before_hash="$(shasum "$SPEC_DIR/spec.md" 2>/dev/null | awk '{print $1}')"

  run_agent_stage "$invoke" 3 "$(cat <<EOF
Use the specflow slash command /speckit.specflow.brainstorm against the
existing spec at $SPEC_REL.

Per the specflow contract, brainstorm should mutate the spec file IN PLACE
and add (or expand) at minimum:
  - an "## Edge Cases" section
  - an "## Open Questions" or "## Assumptions" section

Per step 9 of the command, an Open Questions row you mark Resolved because a
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
    elif [ "$spec_before_hash" != "$(shasum "$SPEC_DIR/spec.md" | awk '{print $1}')" ]; then
      pass "spec.md was modified in place"
    else
      miss "spec.md content unchanged after brainstorm"
      FAILED_STAGE=3
    fi
    assert_grep "  ## Edge Cases section added" '^#{2,4}[[:space:]]+Edge Cases'           "$SPEC_DIR/spec.md" || FAILED_STAGE=3
    assert_grep "  ## Open Questions or Assumptions added" '^#{2,4}[[:space:]]+(Open Questions|Assumptions)' "$SPEC_DIR/spec.md" || FAILED_STAGE=3
    assert_resolved_questions_recorded "$SPEC_DIR/spec.md" "$WORK/decisions.md" || FAILED_STAGE=3
  fi
  assert_idempotent stage_3_brainstorm
  stop_if_stage_failed
}

# stage 4: /speckit.plan
# Args: <invoke function name>.
stage_4_plan() {
  local invoke="$1"
  title 4 "/speckit.plan: technical implementation plan"
  run_agent_stage "$invoke" 4 "$(cat <<EOF
Run /speckit.plan to produce a technical implementation plan for the spec at
$SPEC_REL. The plan should be written to ${SPEC_DIR#$WORK/}/plan.md with
sections covering technical approach, file structure, and any risks.
EOF
)" || FAILED_STAGE=4

  if [ -z "$FAILED_STAGE" ]; then
    assert_file "plan.md exists at ${SPEC_DIR#$WORK/}/plan.md" "$SPEC_DIR/plan.md" || FAILED_STAGE=4
  fi
  assert_idempotent stage_4_plan
  stop_if_stage_failed
}

# stage 5: /speckit.tasks (after_tasks hook may trigger specflow.tasks)
# Args: <invoke function name>.
stage_5_tasks() {
  local invoke="$1"
  title 5 "/speckit.tasks: phased task breakdown"
  run_agent_stage "$invoke" 5 "$(cat <<EOF
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

  # A dry run has no agent, so the open-questions gate is exercised against a
  # fixture: one spec whose Open Questions table holds a single unresolved row.
  # The count the fixture yields is the count the OPEN_QUESTIONS stop line prints.
  if [ "$DRY_RUN" = "1" ] && [ -z "$FAILED_STAGE" ]; then
    local open_fixture="$WORK/specs/999-open-question" open_rows stop_line
    mkdir -p "$open_fixture"
    cat > "$open_fixture/spec.md" <<'FIXTURE'
# Feature: one unresolved question

## Open Questions

| # | Question | Status | Resolution |
|---|----------|--------|------------|
| OQ-001 | Which registry publishes the package? | Open | |
FIXTURE
    open_rows="$(count_unresolved_questions "$open_fixture/spec.md")"
    if [ "$open_rows" = "1" ]; then
      pass "  open-questions fixture holds 1 unresolved row"
    else
      miss "  open-questions fixture holds $open_rows unresolved rows, expected 1"
      FAILED_STAGE=5
    fi
    stop_line="OPEN_QUESTIONS: $open_rows unresolved Open Questions row(s) in ${open_fixture#$WORK/}/spec.md; expected 0. Run /speckit.specflow.brainstorm 999."
    case "$stop_line" in
      "OPEN_QUESTIONS: 1 "*"expected 0. Run /speckit.specflow.brainstorm"*)
        pass "  the tasks stage stop line names the code, the count, and the next command" ;;
      *)
        miss "  the tasks stage stop line is '$stop_line'"
        FAILED_STAGE=5 ;;
    esac
    assert_grep "  tasks.md documents the OPEN_QUESTIONS stop" \
                'OPEN_QUESTIONS' "$REPO_ROOT/commands/tasks.md" || FAILED_STAGE=5
    assert_grep "  workflow-guide.md lists OPEN_QUESTIONS in the stop-code table" \
                '^\| `OPEN_QUESTIONS` \|' "$REPO_ROOT/references/workflow-guide.md" || FAILED_STAGE=5
    open_rows="$(count_unresolved_questions "$SPEC_DIR/spec.md")"
    if [ "$open_rows" = "0" ]; then
      pass "  the snapshot spec passes the open-questions gate"
    else
      note "the snapshot spec holds $open_rows unresolved row(s), so its tasks stage would stop"
    fi
  fi
  assert_idempotent stage_5_tasks
  stop_if_stage_failed
}

# stage 6: /speckit.specflow.execute
# Args: <invoke function name>.
stage_6_execute() {
  local invoke="$1"
  title 6 "/speckit.specflow.execute: implement"
  run_agent_stage "$invoke" 6 "$(cat <<EOF
Before implementation, run /speckit.analyze for ${SPEC_DIR#$WORK/}.
Follow the Gate markers protocol in the installed specflow workflow guide:
remove any previous ${SPEC_DIR#$WORK/}/.analyzed marker before analysis,
then write that marker only if the report has zero critical inconsistencies.
If critical inconsistencies remain, stop and report them without implementing.

Once the analyze gate passes, run /speckit.specflow.execute to implement the tasks in
${SPEC_DIR#$WORK/}/tasks.md. The deliverable is the link-audit CLI under
src/link_audit/ with its pytest suite. Per the specflow
contract, also keep ${SPEC_DIR#$WORK/}/progress.yml updated as tasks complete.
EOF
)" || FAILED_STAGE=6

  if [ -z "$FAILED_STAGE" ]; then
    assert_file "analyze gate marker exists" "$SPEC_DIR/.analyzed" || FAILED_STAGE=6
    assert_file "src/link_audit/__init__.py generated" "$WORK/src/link_audit/__init__.py" || FAILED_STAGE=6
    if grep -rq 'ls-files' "$WORK/src/link_audit" 2>/dev/null; then
      pass "  src/link_audit/ reads git ls-files"
    else
      miss "  src/link_audit/ never calls git ls-files"
      FAILED_STAGE=6
    fi
    if [ -f "$SPEC_DIR/progress.yml" ]; then
      pass "progress.yml exists at ${SPEC_DIR#$WORK/}/progress.yml"
    else
      note "progress.yml not produced (soft signal; the specflow contract suggests it)"
    fi
  fi
  assert_idempotent stage_6_execute
  stop_if_stage_failed
}

# stage 7: /speckit.specflow.review
# Args: <invoke function name>.
stage_7_review() {
  local invoke="$1"
  title 7 "/speckit.specflow.review: review against spec"
  run_agent_stage "$invoke" 7 "$(cat <<EOF
Run /speckit.specflow.review to review the implementation under src/link_audit/ against
the spec/plan/tasks at ${SPEC_DIR#$WORK/}. Per the specflow contract, write
the review output to ${SPEC_DIR#$WORK/}/checklists/review.md as a checklist.
EOF
)" || FAILED_STAGE=7

  if [ -z "$FAILED_STAGE" ]; then
    assert_file "review.md exists" "$SPEC_DIR/checklists/review.md" || FAILED_STAGE=7
    assert_grep "  review.md is a checklist" '\[[ xX]\]' "$SPEC_DIR/checklists/review.md" || FAILED_STAGE=7
  fi
  assert_idempotent stage_7_review
  stop_if_stage_failed
}

# Prints the assertion count, the artifacts the run left in the workdir, and,
# in a dry run, what a real run needs.
# Args: <the line naming what a real run needs>.
report_summary() {
  printf '\n%sSummary%s: %d assertions passed across 7 stages, %d of them idempotence checks\n' \
         "$C_BOLD" "$C_RST" "$PASS" "$IDEMPOTENT"
  echo
  echo "Final artifacts under workdir:"
  find "$WORK" -type f \
    \( -path '*/specs/*' -o -path '*/src/*' -o -path '*/.specify/memory/*' -o -name 'AGENTS.md' -o -name 'CLAUDE.md' \) \
    -not -path '*/.git/*' \
    | sed "s|^$WORK/|    |" | sort

  [ "$DRY_RUN" = "1" ] || return 0
  printf '\n%sDRY_RUN complete.%s %d assertions ran against examples/link-audit; no agent stage was called.\n' "$C_YELLOW" "$C_RST" "$PASS"
  printf '%s\n' "$1"
}
