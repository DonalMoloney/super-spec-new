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
SPECFLOW_COMMANDS=(status brainstorm tasks execute review)
EXPECTED_HOOK_COUNT=3
LOG_TAIL_LINES=30

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
assert_grep "extension list shows 'Commands: 5 | Hooks: 3'" \
            "Commands: 5 | Hooks: 3" \
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
