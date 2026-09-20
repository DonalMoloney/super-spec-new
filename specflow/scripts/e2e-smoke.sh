#!/usr/bin/env bash
# scripts/e2e-smoke.sh
#
# Structural end-to-end smoke test for the specflow extension: installs this
# checkout into a fresh spec-kit project and asserts the file layout spec-kit
# and specflow jointly promise, without invoking an LLM.
#
# Usage: bash scripts/e2e-smoke.sh
# Exit code: 0 when every assertion passes, 1 otherwise.
#
# The workdir is left on disk after the run for inspection; delete it
# manually when done (`rm -rf <path>`).

# -e is omitted on purpose: a failing install or feature-creation command is
# recorded as a failed assertion below rather than aborting the run.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d -t specflow-e2e.XXXXXX)"
INIT_LOG="$WORK/.init.log"
ADD_LOG="$WORK/.add.log"
FEAT_LOG="$WORK/.feat.log"

SPEC_KIT_GIT_URL="https://github.com/github/spec-kit.git"
MANIFEST="$REPO_ROOT/extension.yml"
# extension.yml is the only place that declares what ships. Deriving the
# command list and the hook count from it keeps every assertion below correct
# when a command or a hook is added.
SPECFLOW_COMMANDS=()
while IFS= read -r command_name; do
  SPECFLOW_COMMANDS+=("$command_name")
done < <(awk '/^provides:/{p=1} p&&/^  commands:/{c=1;next} c&&/^  [a-z]/{c=0} c&&/-[ ]*name:/{sub(/.*speckit\.specflow\./,"");gsub(/["'"'"']/,"");print}' "$MANIFEST")
EXPECTED_COMMAND_COUNT=${#SPECFLOW_COMMANDS[@]}
EXPECTED_HOOK_COUNT=$(awk '/^hooks:/{h=1;next} h&&/^[a-z]/{h=0} h&&/^  [a-z_]+:/{n++} END{print n+0}' "$MANIFEST")
LOG_TAIL_LINES=30
RESOLVER_ERROR_LINES=3

# Process steps per command file, counted on 2026-09-20. A command file's
# numbered Process list is its behavior contract, so a step dropped by a bad
# merge or an edit has to fail here rather than pass unnoticed. bash 3.2 has no
# associative arrays, so each row is "<command> <count>".
EXPECTED_PROCESS_STEPS=(
  "status 7"
  "brainstorm 8"
  "tasks 10"
  "execute 9"
  "review 9"
)

if [ -t 1 ]; then
  C_GREEN=$'\033[32m'; C_RED=$'\033[31m'; C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'; C_RST=$'\033[0m'
else
  C_GREEN=""; C_RED=""; C_DIM=""; C_BOLD=""; C_RST=""
fi

PASS=0
FAIL=0
FAILS=()

# Run `specify` from spec-kit's git ref via uvx without a local install.
run_specify() { uvx --from "git+$SPEC_KIT_GIT_URL" specify "$@"; }

# Print a passing assertion and count it.
pass() { printf '  %sok%s   %s\n' "$C_GREEN" "$C_RST" "$1"; PASS=$((PASS+1)); }
# Print a failing assertion, count it, and record its label for the summary.
fail() { printf '  %sFAIL%s %s\n' "$C_RED"   "$C_RST" "$1"; FAIL=$((FAIL+1)); FAILS+=("$1"); }
# Print a numbered step header.
step() { printf '\n%s[%s]%s %s\n' "$C_BOLD" "$1" "$C_RST" "$2"; }

# Assert a file exists at path.
assert_file()    { if [ -f "$2" ]; then pass "$1";   else fail "$1 (missing: $2)"; fi; }
# Assert a directory exists at path.
assert_dir()     { if [ -d "$2" ]; then pass "$1";   else fail "$1 (missing: $2)"; fi; }
# Assert a directory does not exist at path.
assert_no_dir()  { if [ ! -d "$2" ]; then pass "$1"; else fail "$1 (unexpected: $2)"; fi; }
# Print the decoded TEMPLATE_CONTENT string of the resolver's one-line JSON
# object, and exit 1 when the object carries no such field. awk decodes it
# because the resolver treats jq as optional and this script must too.
decode_template_content() {
  awk '
    {
      key = "\"TEMPLATE_CONTENT\":\""
      start = index($0, key)
      if (start == 0) next
      found = 1
      escaped = substr($0, start + length(key))
      for (i = 1; i <= length(escaped); i++) {
        c = substr(escaped, i, 1)
        if (c == "\"") break
        if (c != "\\") { printf "%s", c; continue }
        i++
        e = substr(escaped, i, 1)
        if      (e == "n") printf "\n"
        else if (e == "t") printf "\t"
        else if (e == "r") printf "\r"
        else               printf "%s", e
      }
    }
    END { exit found ? 0 : 1 }
  ' "$1"
}

# specify init writes core's templates before an extension installs, so
# asserting that .specify/templates/spec-template.md exists proves nothing
# about specflow. Every command file instructs the --json form and reads
# TEMPLATE_CONTENT, so the assertion runs that form and checks the sections
# only specflow's copy carries. Runs per surface, because a shipped file must
# work on the Copilot CLI as well as Claude Code.
assert_resolved_template() {
  local surface="$1" workdir="$2"
  local resolver_json="$workdir/.resolve-template.json"
  local resolver_error="$workdir/.resolve-template.err"
  if ! ( cd "$workdir" && bash .specify/scripts/bash/resolve-template.sh spec-template --json ) \
         >"$resolver_json" 2>"$resolver_error"; then
    # The resolver names the layer it could not resolve on stderr. Dropping it
    # leaves a CI failure with no cause.
    local detail
    detail="$(tail -n "$RESOLVER_ERROR_LINES" "$resolver_error" | tr '\n' ' ')"
    detail="${detail% }"
    fail "$surface: resolve-template.sh spec-template --json did not run in the installed project: ${detail:-no stderr output}"
    return
  fi
  local resolved="$workdir/.resolved-spec-template.md"
  if ! decode_template_content "$resolver_json" >"$resolved"; then
    fail "$surface: resolve-template.sh spec-template --json printed no TEMPLATE_CONTENT field"
    return
  fi
  local section
  for section in "## Open Questions" "## Threat Model" "## Traceability" "## Brainstorm Log"; do
    assert_grep "$surface: resolved TEMPLATE_CONTENT carries '$section'" "$section" "$resolved"
  done
}

# Print the number of top-level numbered steps in a command file's Process
# section. A nested list is indented, so the anchored pattern skips it.
count_process_steps() {
  awk '
    /^## Process$/ { inside = 1; next }
    inside && /^## /  { exit }
    inside && /^[0-9]+\. / { steps++ }
    END { print steps + 0 }
  ' "$1"
}

# Print the counted step total for a command name, or exit 1 when the
# EXPECTED_PROCESS_STEPS table holds no row for it.
expected_process_steps() {
  local name="$1" row
  for row in "${EXPECTED_PROCESS_STEPS[@]}"; do
    case "$row" in
      "$name "*) printf '%s' "${row##* }"; return 0 ;;
    esac
  done
  return 1
}

# Assert a file exists and contains pattern.
assert_grep()    {
  local desc="$1" pattern="$2" file="$3"
  if [ -f "$file" ] && grep -q -- "$pattern" "$file"; then
    pass "$desc"
  else
    fail "$desc (pattern '$pattern' not found in $file)"
  fi
}

step "1/5" "Initialize spec-kit in a fresh project"
cd "$WORK" || exit 1
if ! run_specify init \
        --here --integration claude --ignore-agent-tools --force \
        </dev/null >"$INIT_LOG" 2>&1; then
  fail "specify init exited non-zero (see $INIT_LOG)"
  echo "----- last 30 lines of init log -----"
  tail -n "$LOG_TAIL_LINES" "$INIT_LOG"
  exit 1
fi

assert_dir  ".specify/ created"                              "$WORK/.specify"
assert_file ".specify/memory/constitution.md present"        "$WORK/.specify/memory/constitution.md"
assert_file ".specify/templates/spec-template.md present"    "$WORK/.specify/templates/spec-template.md"
assert_file ".specify/templates/plan-template.md present"    "$WORK/.specify/templates/plan-template.md"
assert_file ".specify/templates/tasks-template.md present"   "$WORK/.specify/templates/tasks-template.md"
assert_file "create-new-feature.sh present"                  "$WORK/.specify/scripts/bash/create-new-feature.sh"

step "2/5" "Install specflow from local checkout (--dev)"
if ! run_specify extension add "$REPO_ROOT" --dev \
        </dev/null >"$ADD_LOG" 2>&1; then
  fail "specify extension add exited non-zero (see $ADD_LOG)"
  echo "----- last 30 lines of add log -----"
  tail -n "$LOG_TAIL_LINES" "$ADD_LOG"
fi

assert_file ".specify/extensions.yml created" "$WORK/.specify/extensions.yml"

assert_resolved_template "claude" "$WORK"

# Every specflow command is advertised in the install output (spec-kit prints them).
for cmd in "${SPECFLOW_COMMANDS[@]}"; do
  assert_grep "command speckit.specflow.$cmd advertised on install" \
              "speckit.specflow.$cmd" \
              "$ADD_LOG"
done

# spec-kit registers each command as a skill directory holding a SKILL.md
# symlink into .specify/extensions/, so -f resolves the link before checking.
for cmd in "${SPECFLOW_COMMANDS[@]}"; do
  assert_file "Claude Code command file for speckit.specflow.$cmd" \
              "$WORK/.claude/skills/speckit-specflow-$cmd/SKILL.md"
done

# extensions.yml nests each hook's commands as `command: speckit.specflow.<name>`
# lines under the hook's own key; counting those lines counts the hooks.
HOOK_COUNT=0
if [ -f "$WORK/.specify/extensions.yml" ]; then
  HOOK_COUNT=$(grep -cE "^[[:space:]]+command:[[:space:]]*speckit\.specflow\." \
               "$WORK/.specify/extensions.yml" 2>/dev/null || true)
  HOOK_COUNT=${HOOK_COUNT:-0}
fi
if [ "$HOOK_COUNT" = "$EXPECTED_HOOK_COUNT" ]; then
  pass "$EXPECTED_HOOK_COUNT hooks reference speckit.specflow.* in extensions.yml"
else
  fail "expected $EXPECTED_HOOK_COUNT hooks referencing speckit.specflow.*, got $HOOK_COUNT"
fi

# Cross-check via `specify extension list`, the same assertion CI runs.
LIST_LOG="$WORK/.list.log"
run_specify extension list \
    </dev/null >"$LIST_LOG" 2>&1 || true
assert_grep "extension list shows 'Commands: $EXPECTED_COMMAND_COUNT | Hooks: $EXPECTED_HOOK_COUNT'" \
            "Commands: $EXPECTED_COMMAND_COUNT | Hooks: $EXPECTED_HOOK_COUNT" \
            "$LIST_LOG"

step "2b/5" "Install specflow for the GitHub Copilot CLI"
WORK_COPILOT="$(mktemp -d -t specflow-e2e-copilot.XXXXXX)"
cd "$WORK_COPILOT" || exit 1
if ! run_specify init \
        --here --integration copilot --ignore-agent-tools --force \
        </dev/null >"$WORK_COPILOT/.init.log" 2>&1; then
  fail "specify init for copilot exited non-zero (see $WORK_COPILOT/.init.log)"
  tail -n "$LOG_TAIL_LINES" "$WORK_COPILOT/.init.log"
  exit 1
fi
run_specify extension add "$REPO_ROOT" --dev \
    </dev/null >"$WORK_COPILOT/.add.log" 2>&1 \
  || fail "specify extension add for copilot exited non-zero (see $WORK_COPILOT/.add.log)"
for cmd in "${SPECFLOW_COMMANDS[@]}"; do
  assert_file "Copilot command file for speckit.specflow.$cmd" \
              "$WORK_COPILOT/.github/skills/speckit-specflow-$cmd/SKILL.md"
done
assert_resolved_template "copilot" "$WORK_COPILOT"

step "3/5" "Simulate /speckit.specify (calls create-new-feature.sh directly)"
cd "$WORK" || exit 1
bash .specify/scripts/bash/create-new-feature.sh \
     --short-name "smoke-test-feature" \
     "Smoke test feature for end-to-end validation" \
     >"$FEAT_LOG" 2>&1 || true

FEATURE_DIR_ACTUAL="$(ls -d "$WORK"/specs/*-smoke-test-feature 2>/dev/null | head -n1 || true)"

assert_dir     "specs/ created at project ROOT"        "$WORK/specs"
assert_no_dir  "no .specify/specs/ (issue #4 anti-regression)"  "$WORK/.specify/specs"

if [ -n "$FEATURE_DIR_ACTUAL" ] && [ -d "$FEATURE_DIR_ACTUAL" ]; then
  pass "feature dir created: ${FEATURE_DIR_ACTUAL#$WORK/}"
  assert_file "  spec.md inside feature dir" "$FEATURE_DIR_ACTUAL/spec.md"
else
  fail "feature dir matching specs/*-smoke-test-feature not found"
  echo "----- create-new-feature log -----"
  cat "$FEAT_LOG"
fi

step "4/5" "Verify specflow docs match spec-kit's real layout"
# check_drift asserts none of the given paths reference the stale
# `.specify/specs/` layout from issue #4; the real path is `specs/`.
check_drift() {
  local desc="$1"; shift
  local hits=0
  # static-landing-page/ is a real-run e2e snapshot whose README teaches the
  # old path in prose, so drift checks exclude that directory.
  hits=$(grep -rEn --exclude-dir='static-landing-page' '\.specify/specs/' "$@" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$hits" -eq 0 ]; then
    pass "$desc"
  else
    fail "$desc: $hits stale '.specify/specs/' reference(s):"
    grep -rEn --exclude-dir='static-landing-page' '\.specify/specs/' "$@" 2>/dev/null | sed 's|^|        |'
  fi
}

cd "$REPO_ROOT" || exit 1
check_drift "commands/ uses 'specs/' not '.specify/specs/'"      commands/
check_drift "templates/ uses 'specs/' not '.specify/specs/'"     templates/
check_drift "README/SKILL/examples use 'specs/' not '.specify/specs/'" \
            README.md SKILL.md examples/ references/

# Every marker the Gate markers table names must be one a command file writes
# or reads; a marker no command mentions is documentation with no behavior.
GATE_MARKERS="$(grep -oE '`specs/[^`]*/\.[a-z]+`' references/workflow-guide.md | grep -oE '/\.[a-z]+`' | tr -d '/`' | sort -u)"
if [ -z "$GATE_MARKERS" ]; then
  fail "Gate markers table in references/workflow-guide.md names no marker"
fi
for marker in $GATE_MARKERS; do
  if grep -rqF -- "$marker" commands/; then
    pass "gate marker $marker is named by a command file"
  else
    fail "gate marker $marker is in the Gate markers table but no file under commands/ names it"
  fi
done

# The status sample prints the gate markers per feature.
assert_grep "status.md sample output reports gate markers" 'gates: clarified, analyzed' "$REPO_ROOT/commands/status.md"
# The after_implement hook hands review a scope file, and review hands the
# merge gate a findings file. Both names are part of the command contract.
assert_grep "after-execute.md writes review-scope.md"  'review-scope\.md'     "$REPO_ROOT/commands/hooks/after-execute.md"
assert_grep "review.md reads review-scope.md"          'review-scope\.md'     "$REPO_ROOT/commands/review.md"
assert_grep "review.md writes review-findings.json"    'review-findings\.json' "$REPO_ROOT/commands/review.md"
# The tasks command carries the singular-task rule from AGENTS.md.
assert_grep "tasks.md states the one-outcome-per-task rule" 'one outcome per task' "$REPO_ROOT/commands/tasks.md"

# Every command extension.yml declares is counted, so a new command without a
# row in the table fails here instead of shipping with its steps unchecked.
for cmd in "${SPECFLOW_COMMANDS[@]}"; do
  command_file="$REPO_ROOT/commands/$cmd.md"
  if ! expected=$(expected_process_steps "$cmd"); then
    fail "commands/$cmd.md has no row in the EXPECTED_PROCESS_STEPS table in scripts/e2e-smoke.sh; count its Process steps and add one"
    continue
  fi
  actual=$(count_process_steps "$command_file")
  if [ "$actual" = "$expected" ]; then
    pass "commands/$cmd.md has $expected Process steps"
  else
    fail "commands/$cmd.md has $actual Process steps, expected $expected. Restore the missing step, or change the $cmd row of the EXPECTED_PROCESS_STEPS table in scripts/e2e-smoke.sh when the step count moved on purpose"
  fi
done

step "5/5" "Generated artifacts (for human review)"
cd "$WORK" || exit 1
echo "  ${C_DIM}workdir:${C_RST} $WORK"
echo
find . -type f \
  \( -path './.specify/*' -o -path './specs/*' -o -name 'AGENTS.md' -o -name 'CLAUDE.md' \) \
  -not -path '*/.git/*' \
  | sed 's|^./|    |' \
  | sort

TOTAL=$((PASS + FAIL))
printf '\n%sSummary:%s %d/%d passed' "$C_BOLD" "$C_RST" "$PASS" "$TOTAL"
if [ "$FAIL" -gt 0 ]; then
  printf ', %s%d failed%s\n' "$C_RED" "$FAIL" "$C_RST"
  printf 'Failures:\n'
  for f in "${FAILS[@]}"; do printf '  - %s\n' "$f"; done
  printf '\nWorkdir kept at: %s\n' "$WORK"
  exit 1
fi
printf '\n'
printf 'Workdir kept at: %s\n' "$WORK"
exit 0
