#!/usr/bin/env bash
# Test harness for .claude/hooks/*.sh. Each hook reads Claude Code's JSON on
# stdin and signals with its exit code (0 = allow, 2 = block). Run:
#   bash .claude/hooks/tests/run.sh
set -u
HOOKS="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0; skipped=0
check() { # name expected_exit actual_exit
  if [ "$2" -eq "$3" ]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1 (expected exit $2, got $3)"; fi
}
skip() { # name reason
  skipped=$((skipped+1)); echo "skip $1 ($2)"
}
status_of() { # command... -> prints its exit code
  "$@"; echo $?
}
run_hook() { # hook json  -> prints exit code
  printf '%s' "$2" | bash "$HOOKS/$1" >/dev/null 2>&1; echo $?
}
fresh_repo() { # branch
  local d; d="$(mktemp -d)"
  git -C "$d" init -q -b "$1"
  git -C "$d" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  echo "$d"
}

# --- block-main-commit.sh (PreToolUse: Bash) ---
r="$(fresh_repo main)"; cd "$r" || exit 1
check "commit on main is blocked"        2 "$(run_hook block-main-commit.sh '{"tool_input":{"command":"git commit -m x"}}')"
check "branch created then commit allowed"  0 "$(run_hook block-main-commit.sh '{"tool_input":{"command":"git switch -c feat && git commit -m x"}}')"
check "checkout -b then commit allowed"    0 "$(run_hook block-main-commit.sh '{"tool_input":{"command":"git checkout -b feat && git commit -m x"}}')"
check "commit before a later switch blocked" 2 "$(run_hook block-main-commit.sh '{"tool_input":{"command":"git commit -m x && git switch -c feat"}}')"
check "checkout of a path does not retarget" 2 "$(run_hook block-main-commit.sh '{"tool_input":{"command":"git checkout . && git commit -m x"}}')"
check "commit on master is blocked"      2 "$(cd "$(fresh_repo master)" && run_hook block-main-commit.sh '{"tool_input":{"command":"git add -A && git commit -m x"}}')"
check "non-commit git on main allowed"   0 "$(run_hook block-main-commit.sh '{"tool_input":{"command":"git status"}}')"
check "empty command allowed"            0 "$(run_hook block-main-commit.sh '{"tool_input":{}}')"
git switch -q -c feature
check "commit on feature branch allowed" 0 "$(run_hook block-main-commit.sh '{"tool_input":{"command":"git commit -m x"}}')"
check "switch to main then commit blocked" 2 "$(run_hook block-main-commit.sh '{"tool_input":{"command":"git switch main && git commit -m x"}}')"
check "prose naming a switch does not retarget" 0 "$(run_hook block-main-commit.sh '{"tool_input":{"command":"git commit -m msg-mentioning git switch main && git commit inline"}}')"
cd /

# --- test-gate.sh (PostToolUse: Edit|Write) ---
r="$(fresh_repo feature)"; cd "$r" || exit 1
printf -- '- [ ] T001 first\n' > tasks.md
git add tasks.md && git -c user.email=t@t -c user.name=t commit -q -m tasks
J="{\"tool_input\":{\"file_path\":\"$r/tasks.md\"}}"
check "unchanged tasks.md allowed"       0 "$(run_hook test-gate.sh "$J")"
printf -- '- [x] T001 first\n' > tasks.md
check "task ticked, tests fail -> block" 2 "$(SPECFLOW_TEST_CMD=false run_hook test-gate.sh "$J")"
check "task ticked, tests pass -> allow" 0 "$(SPECFLOW_TEST_CMD=true  run_hook test-gate.sh "$J")"
check "non-tasks file skips tests"       0 "$(SPECFLOW_TEST_CMD=false run_hook test-gate.sh "{\"tool_input\":{\"file_path\":\"$r/spec.md\"}}")"
printf -- '- [ ] T001 first\n- [ ] T002 second\n' > tasks.md
check "task added but not ticked -> allow" 0 "$(SPECFLOW_TEST_CMD=false run_hook test-gate.sh "$J")"
cd /

r="$(fresh_repo feature)"; cd "$r" || exit 1
mkdir -p .specify/memory
printf -- '## Code Review Rules\n\nTest command: true\n' > .specify/memory/constitution.md
printf -- '- [ ] T001 first\n' > tasks.md
git add tasks.md .specify/memory/constitution.md
git -c user.email=t@t -c user.name=t commit -q -m init
printf -- '- [x] T001 first\n' > tasks.md
J="{\"tool_input\":{\"file_path\":\"$r/tasks.md\"}}"
check "constitution's Test command: true allows the ticked task" 0 "$(run_hook test-gate.sh "$J")"
printf -- '## Code Review Rules\n\nTest command: false\n' > .specify/memory/constitution.md
check "constitution's Test command: false blocks the ticked task" 2 "$(run_hook test-gate.sh "$J")"
cd /

r="$(fresh_repo feature)"; cd "$r" || exit 1
printf -- '- [ ] T001 first\n' > tasks.md
git add tasks.md
git -c user.email=t@t -c user.name=t commit -q -m tasks
printf -- '- [x] T001 first\n' > tasks.md
J="{\"tool_input\":{\"file_path\":\"$r/tasks.md\"}}"
check "no constitution and no specflow dir skips the gate" 0 "$(run_hook test-gate.sh "$J")"
cd /

# --- artifact-lint.sh (PostToolUse: Edit|Write) ---
r="$(fresh_repo feature)"; mkdir -p "$r/specs/001-x"; cd "$r/specs/001-x" || exit 1
lint() { run_hook artifact-lint.sh "{\"tool_input\":{\"file_path\":\"$PWD/$1\"}}"; }
printf '# Spec\n## User Scenarios & Testing\n## Requirements\n## Success Criteria\n' > spec.md
check "spec with mandatory sections passes"     0 "$(lint spec.md)"
printf '# Spec\n## Requirements\n' > spec.md
check "spec missing mandatory section blocked"  2 "$(lint spec.md)"
printf '# Spec\n## User Scenarios & Testing\n## Requirements\n' > spec.md
check "spec missing only Success Criteria blocked" 2 "$(lint spec.md)"
printf '# Spec\n## User Scenarios & Testing\n## Requirements\n## Success Criteria\n[NEEDS CLARIFICATION: x]\n' > spec.md
check "unclarified marker allowed before clarify" 0 "$(lint spec.md)"
touch .clarified
check "unclarified marker blocked after clarify" 2 "$(lint spec.md)"
mkdir -p "$r/tests"
printf 'def passes_when_present():\n    assert True\n' > "$r/tests/test_sample.py"
printf '# Spec\n## User Scenarios & Testing\n## Requirements\n## Success Criteria\n## Traceability\n\n| Criterion ID | Test name | Status |\n|--------------|-----------|--------|\n| FR-001 | `tests/test_sample.py::passes_when_present` | Passing |\n' > spec.md
touch .analyzed
check "traceability row naming a real test passes after analyze" 0 "$(lint spec.md)"
printf '# Spec\n## User Scenarios & Testing\n## Requirements\n## Success Criteria\n## Traceability\n\n| Criterion ID | Test name | Status |\n|--------------|-----------|--------|\n| FR-001 | `tests/test_missing.py::does_not_exist` | Passing |\n' > spec.md
check "traceability row naming a missing test blocked after analyze" 2 "$(lint spec.md)"
rm -f .analyzed
check "traceability row naming a missing test allowed before analyze" 0 "$(lint spec.md)"
printf '# Plan\n## Summary\n## Technical Context\n## Constitution Check\n' > plan.md
check "plan with mandatory sections passes"     0 "$(lint plan.md)"
printf '# Plan\n## Summary\n' > plan.md
check "plan missing section blocked"            2 "$(lint plan.md)"
printf '# Tasks\n- [ ] T001 do a\n- [x] T002 [P] do b\n' > tasks.md
check "tasks with stable IDs and [P] passes"    0 "$(lint tasks.md)"
printf '# Tasks\n- [ ] do a without an id\n' > tasks.md
check "tasks without T-ids blocked"             2 "$(lint tasks.md)"
printf '# Tasks\n- [ ] T001 do a\n- [ ] [P] do b\n' > tasks.md
check "malformed [P] line blocked"              2 "$(lint tasks.md)"
printf '# Tasks\n- [x] T001 do a\n- [ ] T002 do b\n' > tasks.md
printf 'spec: 001-x\nphases:\n  - phase: 1\n    tasks:\n      T001: complete\n' > progress.yml
check "completed id still in tasks.md passes"   0 "$(lint tasks.md)"
printf '# Tasks\n- [ ] T002 do b\n' > tasks.md
check "completed id dropped from tasks.md blocked" 2 "$(lint tasks.md)"
rm -f progress.yml
check "dropped id allowed with no progress.yml" 0 "$(lint tasks.md)"
printf -- '- [ ] T001 Add the login form and validate its fields\n' > tasks.md
check "compound task line joined by and fails"   2 "$(lint tasks.md)"
printf -- '- [ ] T001 Add the login form\n- [ ] T002 Validate the login form fields\n' > tasks.md
check "singular task lines pass"                  0 "$(lint tasks.md)"
printf -- '- [ ] T001 Add `and` to the reserved-word list in `lexer.py`\n' > tasks.md
check "and inside backticks is not a compound"   0 "$(lint tasks.md)"
printf -- '- [ ] T001 Wire the handler\nRun the linter and the tests before the checkpoint.\n' > tasks.md
check "and in prose outside a task line passes"  0 "$(lint tasks.md)"
printf '# Checklist\n- [ ] Confirm the requirement.\n' > checklist-quality.md
check "unchecked checklist passes"              0 "$(lint checklist-quality.md)"
printf '# Checklist\n- [x] Confirm the requirement.\n' > checklist-quality.md
check "checked checklist passes"                0 "$(lint checklist-quality.md)"
printf '# Checklist\n- [X] Confirm the requirement.\n' > checklist-quality.md
check "uppercase checked checklist passes"      0 "$(lint checklist-quality.md)"
printf '# Checklist\n' > checklist-quality.md
check "empty checklist blocked"                 2 "$(lint checklist-quality.md)"
printf '# Checklist\nThe prose mentions [ ] without a checkbox line.\n' > checklist-quality.md
check "checklist with only prose blocked"       2 "$(lint checklist-quality.md)"
printf 'anything\n' > notes.md
check "unrelated file ignored"                  0 "$(lint notes.md)"
check "nonexistent path allowed"                0 "$(lint no-such-dir/spec.md)"
cd /
EX="$HOOKS/../../specflow/examples/link-audit/specs"
for f in "$EX"/*/spec.md "$EX"/*/plan.md "$EX"/*/tasks.md; do
  check "shipped example passes: $(basename "$(dirname "$f")")/$(basename "$f")" 0 "$(run_hook artifact-lint.sh "{\"tool_input\":{\"file_path\":\"$f\"}}")"
done

# --- artifact-lint.sh runs the Markdown lint when the script is present ---
REPO="$(cd "$HOOKS/../.." && pwd -P)"
cd "$REPO" || exit 1
md="$(mktemp -d "$REPO/.artifact-lint-md.XXXXXX")"
printf 'Second \xe2\x80\x94 line.\n' > "$md/dash.md"
printf 'A plain sentence.\n' > "$md/clean.md"
check "markdown with an em-dash is blocked from the repo root" 2 "$(run_hook artifact-lint.sh "{\"tool_input\":{\"file_path\":\"$md/dash.md\"}}")"
check "markdown without findings passes from the repo root"    0 "$(run_hook artifact-lint.sh "{\"tool_input\":{\"file_path\":\"$md/clean.md\"}}")"
rm -rf "$md"
consumer="$(fresh_repo main)"
printf 'Second \xe2\x80\x94 line.\n' > "$consumer/dash.md"
check "markdown with an em-dash passes where the lint script is absent" 0 "$(cd "$consumer" && run_hook artifact-lint.sh "{\"tool_input\":{\"file_path\":\"$consumer/dash.md\"}}")"
cd / || exit 1

# --- artifact-lint.sh decides by path and stops at the repository boundary ---
r="$(fresh_repo feature)"; mkdir -p "$r/specs/001-x" "$r/specflow/commands" "$r/docs"; cd "$r" || exit 1
in_repo() { run_hook artifact-lint.sh "{\"tool_input\":{\"file_path\":\"$r/$1\"}}"; }
printf '# Tasks\n\nThe command writes `tasks.md` from the plan.\n\n## Process\n\n1. Read the plan.\n' > "$r/specflow/commands/tasks.md"
check "command contract named tasks.md is not a task list"  0 "$(in_repo specflow/commands/tasks.md)"
printf '# Tasks\n- [ ] do a without an id\n' > "$r/specs/001-x/tasks.md"
check "feature tasks.md without T-ids still blocked"        2 "$(in_repo specs/001-x/tasks.md)"
printf '# Plan\n## Summary\n' > "$r/docs/plan.md"
check "plan.md outside a feature directory is not an artifact" 0 "$(in_repo docs/plan.md)"
printf '# Spec\n## User Scenarios & Testing\n## Requirements\n' > "$r/specs/001-x/spec.md"
check "feature spec missing a mandatory section still blocked" 2 "$(in_repo specs/001-x/spec.md)"
outside="$(mktemp -d)"; mkdir -p "$outside/specs/001-x"
printf '# Spec\n## Requirements\n' > "$outside/specs/001-x/spec.md"
check "file outside the repository is not linted"           0 "$(run_hook artifact-lint.sh "{\"tool_input\":{\"file_path\":\"$outside/specs/001-x/spec.md\"}}")"
check "skipping a file outside the repository is reported"  0 \
  "$(printf '%s' "{\"tool_input\":{\"file_path\":\"$outside/specs/001-x/spec.md\"}}" | bash "$HOOKS/artifact-lint.sh" 2>&1 >/dev/null | grep -qF 'outside'; echo $?)"
rm -rf "$outside"
cd / || exit 1

# --- validate-progress.py (the progress.yml resumability contract) ---
PROGRESS="$HOOKS/../review/validate-progress.py"
validate_progress() { # -> exit code of the validator on ./progress.yml
  python3 "$PROGRESS" progress.yml >/dev/null 2>&1; echo $?
}
write_progress_fixture() { # current_phase task_id task_status [trailing block]
  printf 'spec: 001-x\nstatus: in_progress\ncurrent_phase: %s\nphases:\n  - phase: 1\n    name: Setup\n    status: in_progress\n    tasks:\n      %s: %s\n%s' \
    "$1" "$2" "$3" "${4:-}" > progress.yml
}
r="$(fresh_repo feature)"; mkdir -p "$r/specs/001-x"; cd "$r/specs/001-x" || exit 1
printf '# Tasks\n- [x] T001 Write the parser\n- [ ] T002 Write the report\n' > tasks.md
write_progress_fixture 1 T001 complete
check "valid progress.yml passes"                          0 "$(validate_progress)"
write_progress_fixture 9 T001 complete
check "current_phase outside the listed phases blocked"    1 "$(validate_progress)"
write_progress_fixture 1 T099 complete
check "completed task id absent from tasks.md blocked"     1 "$(validate_progress)"
write_progress_fixture 1 T099 pending
check "unstarted task id absent from tasks.md passes"      0 "$(validate_progress)"
write_progress_fixture 1 T001 skipped
check "skipped task status passes"                         0 "$(validate_progress)"
write_progress_fixture 1 T001 manual-browser-only
check "task status outside the settled set blocked"        1 "$(validate_progress)"
printf 'spec: 001-x\nstatus: in_progress\ncurrent_phase: 1\nphases:\n  - phase: 1\n    name: Setup\n    status: done\n' > progress.yml
check "phase status outside the settled set blocked"       1 "$(validate_progress)"
printf 'spec: 001-x\nstatus: done\ncurrent_phase: 1\nphases:\n  - phase: 1\n    name: Setup\n    status: complete\n' > progress.yml
check "top-level status outside the settled set blocked"   1 "$(validate_progress)"
write_progress_fixture 1 T001 complete 'gates:
  clarified: 2026-09-14
  analyze_attempts: 2
'
check "gate names from the workflow guide table pass"      0 "$(validate_progress)"
write_progress_fixture 1 T001 complete 'gates:
  clarifed: 2026-09-14
'
check "gate name outside the workflow guide table blocked" 1 "$(validate_progress)"
write_progress_fixture 1 T001 complete 'notes: a stray key
'
check "unknown top-level key blocked"                      1 "$(validate_progress)"
printf 'spec: 001-x\nstatus: in_progress\ncurrent_phse: 1\nphases:\n  - phase: 1\n    name: Setup\n    status: in_progress\n' > progress.yml
check "misspelled current_phase blocked"                   1 "$(validate_progress)"
printf 'spec: 001-x\nstatus: in_progress\ncurrent_phase: 1\nphases: [{phase: 1}]\n' > progress.yml
check "flow sequence outside the parsed subset blocked"    1 "$(validate_progress)"
lint_progress() { run_hook artifact-lint.sh "{\"tool_input\":{\"file_path\":\"$PWD/progress.yml\"}}"; }
write_progress_fixture 1 T001 complete
check "artifact-lint passes a valid progress.yml"          0 "$(lint_progress)"
write_progress_fixture 1 T099 complete
check "artifact-lint blocks an unknown task id"            2 "$(lint_progress)"
rm -f tasks.md
write_progress_fixture 1 T001 complete
check "completed task blocked when tasks.md is missing"    1 "$(validate_progress)"
write_progress_fixture 1 T001 pending
check "unstarted task passes when tasks.md is missing"     0 "$(validate_progress)"
cd / || exit 1
for f in "$HOOKS"/../../specflow/examples/*/specs/*/progress.yml; do
  check "shipped example passes: $(basename "$(dirname "$f")")/progress.yml" 0 \
    "$(python3 "$PROGRESS" "$f" >/dev/null 2>&1; echo $?)"
done

# --- session-start.sh (SessionStart) ---
session_start_out() { # json -> stdout
  printf '%s' "$1" | bash "$HOOKS/session-start.sh" 2>/dev/null
}
session_start_err() { # json -> stderr
  { printf '%s' "$1" | bash "$HOOKS/session-start.sh" >/dev/null; } 2>&1
}
session_start_exit() { # json -> exit code
  run_hook session-start.sh "$1"
}
check_has() { # name haystack needle
  if printf '%s' "$2" | grep -qF -- "$3"; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1 (expected to find: $3)"; fi
}
check_lacks() { # name haystack needle
  if printf '%s' "$2" | grep -qF -- "$3"; then fail=$((fail+1)); echo "FAIL $1 (unexpectedly found: $3)"
  else pass=$((pass+1)); echo "ok   $1"; fi
}
write_progress() { # dir spec status phase [malformed]
  mkdir -p "$1"
  if [ "${5:-}" = "malformed" ]; then
    { echo "spec: $2"; echo "status: $3"; echo "current_phase: $4"; } > "$1/progress.yml"
  else
    { echo "spec: $2"; echo "status: $3"; echo "current_phase: $4"; echo "phases:"; echo "  - phase: 1"; echo "    name: Setup"; echo "    status: complete"; echo "    tasks:"; echo "      T001: complete"; } > "$1/progress.yml"
  fi
}
set_mtime() { touch -d "${2}T00:00:00" "$1"; } # path yyyy-mm-dd

r="$(mktemp -d)"; write_progress "$r/specs/001-x" 001-x complete 6
check "valid JSON stdin exits 0"       0 "$(cd "$r" && session_start_exit '{"how_started":"resume"}')"
check "empty stdin exits 0"            0 "$(cd "$r" && session_start_exit '')"
check "non-JSON stdin exits 0"         0 "$(cd "$r" && session_start_exit 'not json at all {{{')"
out="$(cd "$r" && session_start_out '{"how_started":"resume"}')"
check_has "usable candidate's spec id appears in output" "$out" "001-x"

r2="$(mktemp -d)"
write_progress "$r2/specs/001-a" 001-a complete 3 malformed
write_progress "$r2/specs/002-b" 002-b complete 1 malformed
check "malformed-everywhere never blocks (exits 0)" 0 "$(cd "$r2" && session_start_exit '{"how_started":"startup"}')"
base_out="$(cd "$r2" && session_start_out '{"how_started":"resume"}')"
base_exit="$(cd "$r2" && session_start_exit '{"how_started":"resume"}')"
same=0
for hs in resume compact startup clear fork; do
  o="$(cd "$r2" && session_start_out "{\"how_started\":\"$hs\"}")"
  e="$(cd "$r2" && session_start_exit "{\"how_started\":\"$hs\"}")"
  [ "$o" = "$base_out" ] && [ "$e" = "$base_exit" ] || same=1
done
check "stdout and exit identical across how_started values" 0 "$same"

r3="$(mktemp -d)"
write_progress "$r3/specs/001-x" 001-x complete 2
set_mtime "$r3/specs/001-x/progress.yml" "2020-01-01"
mkdir -p "$r3/.specify/specs/999-ignored"
write_progress "$r3/.specify/specs/999-ignored" 999-ignored complete 1
set_mtime "$r3/.specify/specs/999-ignored/progress.yml" "2030-01-01"
out="$(cd "$r3" && session_start_out '{}')"
check_has  "specs/*/progress.yml candidate found"        "$out" "001-x"
check_lacks ".specify progress.yml ignored even when newer" "$out" "999-ignored"

r4="$(mktemp -d)"
write_progress "$r4/specs/001-old" 001-old complete 1
set_mtime "$r4/specs/001-old/progress.yml" "2020-01-01"
write_progress "$r4/specs/002-new" 002-new complete 2
set_mtime "$r4/specs/002-new/progress.yml" "2024-01-01"
out="$(cd "$r4" && session_start_out '{}')"
check_has  "newest well-formed candidate selected"     "$out" "002-new"
check_lacks "older well-formed candidate not selected" "$out" "001-old"

r5="$(mktemp -d)"
write_progress "$r5/specs/001-good" 001-good complete 1
set_mtime "$r5/specs/001-good/progress.yml" "2020-01-01"
write_progress "$r5/specs/002-bad" 002-bad complete 2 malformed
set_mtime "$r5/specs/002-bad/progress.yml" "2024-01-01"
out="$(cd "$r5" && session_start_out '{}')"
err="$(cd "$r5" && session_start_err '{}')"
check_has  "well-formed candidate selected when newest is malformed" "$out" "001-good"
check_lacks "malformed candidate's spec id absent from stdout"       "$out" "002-bad"
check "malformed candidate produces no stderr output" 0 "$(status_of [ -z "$err" ])"

r6="$(mktemp -d)"
check "zero-candidate repo exits 0" 0 "$(cd "$r6" && session_start_exit '{}')"
out="$(cd "$r6" && session_start_out '{}')"
check_lacks "zero-candidate repo prints no spec-state text" "$out" "spec:"

r7="$(mktemp -d)"
write_progress "$r7/specs/001-a" 001-a complete 1 malformed
write_progress "$r7/specs/002-b" 002-b complete 2 malformed
check "all-malformed repo exits 0" 0 "$(cd "$r7" && session_start_exit '{}')"
out="$(cd "$r7" && session_start_out '{}')"
check_lacks "all-malformed repo prints no spec-state text" "$out" "spec:"

r8="$(mktemp -d)"
write_progress "$r8/specs/001-x" 001-x complete 3
printf 'OPEN-Q-MARKER line one\n' > "$r8/open-questions.md"
out="$(cd "$r8" && session_start_out '{}')"
oq_line="$(printf '%s\n' "$out" | grep -n "OPEN-Q-MARKER" | head -1 | cut -d: -f1)"
sm_line="$(printf '%s\n' "$out" | grep -n "^spec: 001-x" | head -1 | cut -d: -f1)"
check_has "open-questions.md content appears in output" "$out" "OPEN-Q-MARKER"
check "open-questions.md content precedes summary line" 0 "$(if [ -n "$oq_line" ] && [ -n "$sm_line" ] && [ "$oq_line" -lt "$sm_line" ]; then echo 0; else echo 1; fi)"

r9="$(mktemp -d)"
write_progress "$r9/specs/001-x" 001-x complete 3
out="$(cd "$r9" && session_start_out '{}')"
check "no open-questions.md means output starts with summary" 0 "$(printf '%s\n' "$out" | head -1 | grep -q '^spec: 001-x'; echo $?)"

r10="$(mktemp -d)"
write_progress "$r10/specs/001-x" 001-x complete 4
out="$(cd "$r10" && session_start_out '{}')"
count="$(printf '%s\n' "$out" | grep -c '^spec: 001-x status: complete current_phase: 4$')"
check "exactly one summary line with spec id status and phase" 0 "$(status_of [ "$count" -eq 1 ])"

r11="$(mktemp -d)"
write_progress "$r11/specs/001-x" 001-x complete 2
printf -- '- [x] T001 done already\n- [ ] T002 do the thing\n- [ ] T003 later\n' > "$r11/specs/001-x/tasks.md"
out="$(cd "$r11" && session_start_out '{}')"
check_has  "first unchecked task line appears in output" "$out" "- [ ] T002 do the thing"
check_lacks "second unchecked task line not duplicated"  "$out" "T003 later"

r12="$(mktemp -d)"
write_progress "$r12/specs/001-x" 001-x complete 2
printf -- '- [x] T001 done\n- [x] T002 also done\n' > "$r12/specs/001-x/tasks.md"
out="$(cd "$r12" && session_start_out '{}')"
check_lacks "all tasks checked means no task line" "$out" "T001"

r13="$(mktemp -d)"
write_progress "$r13/specs/001-x" 001-x complete 2
check "no tasks.md exits 0" 0 "$(cd "$r13" && session_start_exit '{}')"
out="$(cd "$r13" && session_start_out '{}')"
err="$(cd "$r13" && session_start_err '{}')"
check "no tasks.md produces no stderr" 0 "$(status_of [ -z "$err" ])"
check_lacks "no tasks.md means no task line" "$out" "- [ ] T"

r14="$(mktemp -d)"
write_progress "$r14/specs/001-x" 001-x complete 2
printf -- '- [ ] T001 pending task\n' > "$r14/specs/001-x/tasks.md"
printf 'HANDOFF-MARKER line one\n' > "$r14/specs/001-x/handoff.md"
out="$(cd "$r14" && session_start_out '{}')"
task_line="$(printf '%s\n' "$out" | grep -n "T001 pending task" | head -1 | cut -d: -f1)"
handoff_line="$(printf '%s\n' "$out" | grep -n "HANDOFF-MARKER" | head -1 | cut -d: -f1)"
check_has "handoff.md content appears in output" "$out" "HANDOFF-MARKER"
check "handoff.md content follows task line" 0 "$(if [ -n "$task_line" ] && [ -n "$handoff_line" ] && [ "$handoff_line" -gt "$task_line" ]; then echo 0; else echo 1; fi)"

r15="$(mktemp -d)"
write_progress "$r15/specs/001-x" 001-x complete 2
out="$(cd "$r15" && session_start_out '{}')"
check "no handoff.md and no tasks.md means output is exactly the summary line" 0 "$(status_of [ "$out" = "spec: 001-x status: complete current_phase: 2" ])"

r16="$(mktemp -d)"
write_progress "$r16/specs/001-x" 001-x complete 5
printf 'OPEN-Q-MARKER content\n' > "$r16/open-questions.md"
printf -- '- [x] T001 done\n- [ ] T002 pending\n' > "$r16/specs/001-x/tasks.md"
printf 'HANDOFF-MARKER content\n' > "$r16/specs/001-x/handoff.md"
out="$(cd "$r16" && session_start_out '{}')"
oq="$(printf '%s\n' "$out" | grep -n "OPEN-Q-MARKER" | head -1 | cut -d: -f1)"
sm="$(printf '%s\n' "$out" | grep -n "^spec: 001-x" | head -1 | cut -d: -f1)"
tl="$(printf '%s\n' "$out" | grep -n "T002 pending" | head -1 | cut -d: -f1)"
hd="$(printf '%s\n' "$out" | grep -n "HANDOFF-MARKER" | head -1 | cut -d: -f1)"
check "section order is open-questions, summary, task, handoff" 0 "$(if [ -n "$oq" ] && [ -n "$sm" ] && [ -n "$tl" ] && [ -n "$hd" ] && [ "$oq" -lt "$sm" ] && [ "$sm" -lt "$tl" ] && [ "$tl" -lt "$hd" ]; then echo 0; else echo 1; fi)"

# --- .github/hooks/adapter.sh (Copilot CLI native hooks, ADR-0031) ---
ADAPTER="$HOOKS/../../.github/hooks/adapter.sh"
run_adapter() { # event gate json -> prints stdout
  printf '%s' "$3" | bash "$ADAPTER" "$1" "$2" 2>/dev/null
}
run_adapter_exit() { # event gate json -> prints exit code
  printf '%s' "$3" | bash "$ADAPTER" "$1" "$2" >/dev/null 2>&1; echo $?
}

check "hooks.json parses as valid JSON" 0 \
  "$(python3 -c 'import json;json.load(open("'"$HOOKS"'/../../.github/hooks/hooks.json"))' >/dev/null 2>&1; echo $?)"

r="$(fresh_repo main)"; cd "$r" || exit 1
PAYLOAD_BLOCK='{"toolName":"bash","toolArgs":{"command":"git commit -m x"}}'
out="$(run_adapter preToolUse block-main-commit.sh "$PAYLOAD_BLOCK")"
check "adapter denies a blocked commit on main"           0 "$(run_adapter_exit preToolUse block-main-commit.sh "$PAYLOAD_BLOCK")"
check_has "adapter's deny response names permissionDecision deny" "$out" '"permissionDecision":"deny"'
check "adapter's deny JSON parses as JSON" 0 \
  "$(printf '%s' "$out" | python3 -c 'import json,sys;json.load(sys.stdin)' >/dev/null 2>&1; echo $?)"

PAYLOAD_ALLOW='{"toolName":"bash","toolArgs":{"command":"git status"}}'
check "adapter allows a non-commit command"               0 "$(run_adapter_exit preToolUse block-main-commit.sh "$PAYLOAD_ALLOW")"
check "adapter prints nothing on allow" 0 "$(status_of [ -z "$(run_adapter preToolUse block-main-commit.sh "$PAYLOAD_ALLOW")" ])"
cd / || exit 1

r="$(fresh_repo feature)"; cd "$r" || exit 1
printf -- '- [ ] T001 first\n' > tasks.md
git add tasks.md && git -c user.email=t@t -c user.name=t commit -q -m tasks
printf -- '- [x] T001 first\n' > tasks.md
PAYLOAD_EDIT="{\"toolName\":\"str_replace_editor\",\"toolArgs\":{\"path\":\"$r/tasks.md\"}}"
out="$(SPECFLOW_TEST_CMD=false run_adapter postToolUse test-gate.sh "$PAYLOAD_EDIT")"
check "adapter surfaces a failed postToolUse gate (exit 2)" 0 \
  "$(SPECFLOW_TEST_CMD=false run_adapter_exit postToolUse test-gate.sh "$PAYLOAD_EDIT")"
check_has "postToolUse failure carries additionalContext"        "$out" '"additionalContext"'
check_lacks "postToolUse response carries no permissionDecision" "$out" 'permissionDecision'
check "adapter allows a passing postToolUse gate" 0 \
  "$(SPECFLOW_TEST_CMD=true run_adapter_exit postToolUse test-gate.sh "$PAYLOAD_EDIT")"
cd / || exit 1

r="$(fresh_repo main)"; mkdir -p "$r/specs/001-x"; cd "$r" || exit 1
printf 'spec: 001-x\nstatus: in_progress\ncurrent_phase: 1\nphases:\n  - phase: 1\n    name: Setup\n    status: in_progress\n' > specs/001-x/progress.yml
out="$(run_adapter sessionStart session-start.sh '{}')"
check "adapter wraps session-start.sh output" 0 "$(run_adapter_exit sessionStart session-start.sh '{}')"
check_has "sessionStart response carries additionalContext" "$out" '"additionalContext"'
check_has "sessionStart response carries the progress summary" "$out" '001-x'
cd / || exit 1

# --- risk-classifier.sh (run by the review pipeline against a base ref) ---
check_out() { # name expected actual
  if [ "$2" = "$3" ]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1 (expected '$2', got '$3')"; fi
}

# --- gates/bash/write-marker.sh (the shipped clarify and analyze gate) ---
WRITE_MARKER="$HOOKS/../../specflow/gates/bash/write-marker.sh"
feature_with_spec() { # spec body -> feature directory holding that spec.md
  local d; d="$(mktemp -d)"; mkdir -p "$d/specs/001-x"
  printf '%s\n' "$1" > "$d/specs/001-x/spec.md"
  echo "$d/specs/001-x"
}
write_marker() { # feature_dir marker [stdin] -> exit code
  bash "$WRITE_MARKER" "$1" "$2" </dev/null >/dev/null 2>&1; echo $?
}
write_marker_from() { # feature_dir marker report -> exit code
  printf '%s\n' "$3" | bash "$WRITE_MARKER" "$1" "$2" >/dev/null 2>&1; echo $?
}
CRITICAL_REPORT='| ID | Category | Severity | Location | Summary |
|----|----------|----------|----------|---------|
| A1 | Coverage | CRITICAL | spec.md:L10 | no task covers FR-003 |'
CLEAN_REPORT='| ID | Category | Severity | Location | Summary |
|----|----------|----------|----------|---------|
| A1 | Style | LOW | spec.md:L10 | wording |'
f="$(feature_with_spec '# Spec')"
check "clarified marker written for a resolved spec"   0 "$(write_marker "$f" clarified)"
check "the clarified marker file lands beside spec.md" 0 "$(status_of [ -f "$f/.clarified" ])"
f="$(feature_with_spec '# Spec

A gap remains: [NEEDS CLARIFICATION: which registry?]')"
check "unresolved spec refuses the clarified marker"   1 "$(write_marker "$f" clarified)"
check "the refused clarify run writes no marker"       0 "$(status_of [ ! -f "$f/.clarified" ])"
check_out "the refused clarify run names the count and the fix" \
  "CLARIFY_INCOMPLETE: $f/spec.md holds 1 'NEEDS CLARIFICATION' marker(s); expected 0. Resolve each one, then rerun /speckit.clarify." \
  "$(bash "$WRITE_MARKER" "$f" clarified 2>&1 >/dev/null)"
f="$(feature_with_spec '# Spec')"
check "a report with a CRITICAL row refuses the analyzed marker" 1 \
  "$(write_marker_from "$f" analyzed "$CRITICAL_REPORT")"
check "the refused analyze run writes no marker"       0 "$(status_of [ ! -f "$f/.analyzed" ])"
check "a report with no CRITICAL row writes the analyzed marker" 0 \
  "$(write_marker_from "$f" analyzed "$CLEAN_REPORT")"
check "the analyzed marker file lands beside spec.md"  0 "$(status_of [ -f "$f/.analyzed" ])"
check "an unknown marker name exits 2"                 2 "$(write_marker "$f" bogus)"
check "a missing feature directory exits 2"            2 "$(write_marker "$f/absent" clarified)"
commit_feature() { # dir -> commits the working tree on a new feature branch
  git -C "$1" switch -q -c feature
  git -C "$1" add -A
  git -C "$1" -c user.email=t@t -c user.name=t commit -q -m change
}
branch_with() { # path content -> repo on a feature branch holding that file
  local d; d="$(fresh_repo main)"
  mkdir -p "$d/$(dirname "$1")"
  printf '%s\n' "$2" > "$d/$1"
  commit_feature "$d"
  echo "$d"
}
branch_with_lines() { # count -> repo on a feature branch adding that many lines to one file
  branch_with notes.txt "$(seq 1 "$1")"
}
branch_with_files() { # count -> repo on a feature branch adding that many one-line files
  local d i; d="$(fresh_repo main)"
  for i in $(seq 1 "$1"); do printf 'line\n' > "$d/f$i.txt"; done
  commit_feature "$d"
  echo "$d"
}
branch_with_binary() { # -> repo on a feature branch adding one binary file and ten text lines
  local d; d="$(fresh_repo main)"
  printf '\0\1\2\3' > "$d/logo.bin"
  seq 1 10 > "$d/notes.txt"
  commit_feature "$d"
  echo "$d"
}
classify() { # repo -> HIGH or STANDARD
  ( cd "$1" && bash "$HOOKS/risk-classifier.sh" main 2>/dev/null )
}
check_out "diff touching auth/ is HIGH"     HIGH     "$(classify "$(branch_with auth/session.sh 'check_token')")"
check_out "lockfile change is HIGH"         HIGH     "$(classify "$(branch_with package-lock.json '{}')")"
check_out "two-line doc change is STANDARD" STANDARD "$(classify "$(branch_with docs/notes.md $'line one\nline two')")"
check_out "400 changed lines is STANDARD"   STANDARD "$(classify "$(branch_with_lines 400)")"
check_out "401 changed lines is HIGH"       HIGH     "$(classify "$(branch_with_lines 401)")"
check_out "15 changed files is STANDARD"    STANDARD "$(classify "$(branch_with_files 15)")"
check_out "16 changed files is HIGH"        HIGH     "$(classify "$(branch_with_files 16)")"
check_out "binary file counts as a file, not lines" STANDARD "$(classify "$(branch_with_binary)")"
classify_exit() { # repo base -> exit code
  ( cd "$1" && bash "$HOOKS/risk-classifier.sh" "$2" >/dev/null 2>&1 ); echo $?
}
check "unknown base ref fails closed" 2 "$(classify_exit "$(branch_with docs/notes.md one)" no-such-ref)"

# --- merge-gate.sh (run before a merge; reads the reviewer findings documents) ---
MARKER=".claude/review/.merge-approved"
review_dir() { # -> project dir holding an empty .claude/review/
  local d; d="$(mktemp -d)"; mkdir -p "$d/.claude/review"; echo "$d"
}
write_findings() { # dir reviewer severity status
  cat > "$1/.claude/review/$2.json" <<JSON
{"schema_version":"1.0","reviewer":"$2","verdict":"BLOCK","findings":[{"id":"F1","severity":"$3","location":"a.sh:1","evidence":"failing test","fix":"do the thing","status":"$4"}]}
JSON
}
merge_gate() { # dir -> exit code
  ( cd "$1" && bash "$HOOKS/merge-gate.sh" >/dev/null 2>&1 ); echo $?
}
d="$(review_dir)"; write_findings "$d" claude Critical open
check "open Critical blocks the merge"           1 "$(merge_gate "$d")"
d="$(review_dir)"; write_findings "$d" claude Critical accepted
check "accepted Critical blocks the merge"       1 "$(merge_gate "$d")"
d="$(review_dir)"; write_findings "$d" claude Critical rebutted
check "rebutted Critical clears the merge"       0 "$(merge_gate "$d")"
d="$(review_dir)"; write_findings "$d" claude Important open
check "open Important blocks the merge"          1 "$(merge_gate "$d")"
d="$(review_dir)"; write_findings "$d" claude Important rebutted
check "rebutted Important clears the merge"      0 "$(merge_gate "$d")"
d="$(review_dir)"; write_findings "$d" claude Important fixed
check "fixed Important clears the merge"         0 "$(merge_gate "$d")"
d="$(review_dir)"; write_findings "$d" claude Minor open
check "open Minor never blocks the merge"        0 "$(merge_gate "$d")"
d="$(review_dir)"
printf '%s\n' '{"schema_version":"1.0","reviewer":"claude","verdict":"BLOCK","findings":[{"id":"F1","severity":"Critical","location":"a.sh:1","evidence":"failing test","fix":"do the thing"}]}' > "$d/.claude/review/claude.json"
check "Critical with no status blocks the merge" 1 "$(merge_gate "$d")"
d="$(review_dir)"
check "no findings documents clears the merge"   0 "$(merge_gate "$d")"
check "cleared merge writes the approval marker" 0 "$(status_of [ -f "$d/$MARKER" ])"
d="$(review_dir)"; cp "$HOOKS/../../specflow/references/findings-schema.json" "$d/.claude/review/schema.json"
check "schema.json is not read as findings"      0 "$(merge_gate "$d")"
d="$(review_dir)"; printf 'not json at all\n' > "$d/.claude/review/claude.json"
check "unreadable findings document blocks"      1 "$(merge_gate "$d")"
d="$(review_dir)"; write_findings "$d" claude Critical open; touch "$d/$MARKER"
merge_gate "$d" >/dev/null
check "blocked merge clears a stale marker"      0 "$(status_of [ ! -f "$d/$MARKER" ])"
merge_gate_glob() { # dir glob -> exit code
  ( cd "$1" && bash "$HOOKS/merge-gate.sh" "$2" >/dev/null 2>&1 ); echo $?
}
write_review_findings() { # dir severity status [feature] -> writes the file the review command produces
  local feature="${4:-001-x}"
  mkdir -p "$1/specs/$feature"
  cat > "$1/specs/$feature/review-findings.json" <<JSON
{"schema_version":"1.0","reviewer":"speckit.specflow.review","verdict":"BLOCK","findings":[{"id":"R-001","severity":"$2","location":"a.sh:1","evidence":"failing test","fix":"do the thing","status":"$3"}]}
JSON
}
d="$(review_dir)"; write_review_findings "$d" Critical open
check "review command findings under specs/ block the merge" 1 "$(merge_gate_glob "$d" 'specs/*/review-findings.json')"
d="$(review_dir)"; write_review_findings "$d" Critical fixed
check "fixed review command findings clear the merge"        0 "$(merge_gate_glob "$d" 'specs/*/review-findings.json')"
merge_gate_message() { # dir [glob...] -> prints what the gate wrote to stderr
  local d="$1"; shift
  # SC2069 reads this as an attempt to merge both streams. The order is
  # deliberate: stdout goes to /dev/null after stderr is duplicated to it, so
  # only stderr reaches the caller.
  # shellcheck disable=SC2069
  ( cd "$d" && bash "$HOOKS/merge-gate.sh" "$@" 2>&1 >/dev/null )
}
d="$(review_dir)"; write_review_findings "$d" Critical open
check "review command findings block the default glob"       1 "$(merge_gate "$d")"
d="$(review_dir)"; write_review_findings "$d" Critical fixed
check "fixed review command findings clear the default glob" 0 "$(merge_gate "$d")"
d="$(review_dir)"; write_review_findings "$d" Minor open
check "Minor review command findings never block"            0 "$(merge_gate "$d")"
d="$(review_dir)"; write_findings "$d" claude Critical open; write_review_findings "$d" Critical open
check_out "the default globs count each location once" \
  "MERGE BLOCKED: Critical findings unresolved: 2. Expected 0. Fix or rebut each finding, then rerun." \
  "$(merge_gate_message "$d")"
d="$(review_dir)"; write_review_findings "$d" Critical open 001-x; write_review_findings "$d" Critical open 002-y
check_out "one glob sums every feature it matches" \
  "MERGE BLOCKED: Critical findings unresolved: 2. Expected 0. Fix or rebut each finding, then rerun." \
  "$(merge_gate_message "$d")"
d="$(review_dir)"; write_findings "$d" claude Critical open
check "a caller's glob replaces the defaults" 0 "$(merge_gate_glob "$d" 'specs/*/review-findings.json')"
d="$(review_dir)"; write_findings "$d" claude critical open
check "a severity the schema does not enumerate blocks the merge" 1 "$(merge_gate "$d")"
check "the blocked merge names the schema violation" 0 \
  "$(printf '%s' "$(merge_gate_message "$d")" | grep -Fq "severity: 'critical' is not one of 'Critical', 'Important', 'Minor'"; echo $?)"
d="$(review_dir)"
printf '%s\n' '{"schema_version":"1.0","reviewer":"claude","verdict":"BLOCK","findings":[{"id":"F1","severity":"Minor","location":"a.sh:1","evidence":"failing test"}]}' > "$d/.claude/review/claude.json"
check "a finding missing a required key blocks the merge" 1 "$(merge_gate "$d")"
d="$(review_dir)"; write_findings "$d" claude Minor open; write_findings "$d" critic critical open
check "a schema violation in a later file blocks the merge" 1 "$(merge_gate "$d")"
d="$(review_dir)"; write_review_findings "$d" critical open
check "a schema violation under specs/ blocks the merge" 1 "$(merge_gate_glob "$d" 'specs/*/review-findings.json')"

# --- rebut-findings.sh (CI; marks a findings document rebutted when the PR carries the label) ---
rebut() { # dir file reason -> exit code
  ( cd "$1" && bash "$HOOKS/rebut-findings.sh" "$2" "$3" >/dev/null 2>&1 ); echo $?
}
d="$(review_dir)"; write_findings "$d" headless-ci Critical open
check "rebut-findings marks every finding rebutted"  0 "$(rebut "$d" .claude/review/headless-ci.json "label findings-rebutted on PR #1")"
check "rebutted document then clears the merge"      0 "$(merge_gate "$d")"
check_out "rebuttal reason is recorded on the finding" "label findings-rebutted on PR #1" \
  "$(jq -r '.findings[0].rebuttal' "$d/.claude/review/headless-ci.json")"
d="$(review_dir)"
check "rebut-findings fails on a missing document"   2 "$(rebut "$d" .claude/review/headless-ci.json reason)"
d="$(review_dir)"; write_findings "$d" headless-ci Important open
check "rebut-findings needs a reason"                2 "$(rebut "$d" .claude/review/headless-ci.json "")"

# --- log-phase.sh (Stop) ---
telemetry_repo() { # -> dir containing an empty .claude/
  local d; d="$(mktemp -d)"; mkdir -p "$d/.claude"; echo "$d"
}
log_phase() { # dir json -> prints exit code
  (cd "$1" && run_hook log-phase.sh "$2")
}

r17="$(telemetry_repo)"
check "stop hook exits 0" 0 "$(log_phase "$r17" '{"session_id":"abc"}')"
check "exactly one telemetry line is appended" 0 "$(status_of [ "$(wc -l < "$r17/.claude/telemetry.jsonl")" -eq 1 ])"
check "telemetry line parses as JSON" 0 "$(jq -e . "$r17/.claude/telemetry.jsonl" >/dev/null 2>&1; echo $?)"
check_has "telemetry line carries the session id" "$(jq -r '.session' "$r17/.claude/telemetry.jsonl")" "abc"
check_has "telemetry line names the stop event"   "$(jq -r '.event'   "$r17/.claude/telemetry.jsonl")" "stop"

r18="$(telemetry_repo)"; mkdir -p "$r18/specs/001-x"
printf 'spec: 001-x\nstatus: in_progress\ncurrent_phase: 3\n' > "$r18/specs/001-x/progress.yml"
log_phase "$r18" '{"session_id":"abc"}' >/dev/null
check_out "phase is read from the newest progress.yml"   3     "$(jq -r '.phase'   "$r18/.claude/telemetry.jsonl")"
check_out "feature is read from the newest progress.yml" 001-x "$(jq -r '.feature' "$r18/.claude/telemetry.jsonl")"

r19="$(telemetry_repo)"
log_phase "$r19" '{"session_id":"abc"}' >/dev/null
check_has "absent progress.yml logs unknown" "$(jq -r '.phase' "$r19/.claude/telemetry.jsonl")" "unknown"

r19b="$(telemetry_repo)"; printf 'implement\n' > "$r19b/.claude/.current-phase"
log_phase "$r19b" '{"session_id":"abc"}' >/dev/null
check_out "a leftover .current-phase file does not set the phase" unknown "$(jq -r '.phase' "$r19b/.claude/telemetry.jsonl")"

r20="$(telemetry_repo)"
log_phase "$r20" '{"session_id":"abc"}' >/dev/null
log_phase "$r20" '{"session_id":"def"}' >/dev/null
check "a second turn appends instead of overwriting" 0 "$(status_of [ "$(wc -l < "$r20/.claude/telemetry.jsonl")" -eq 2 ])"

r21="$(telemetry_repo)"
check "non-JSON stdin exits 0"  0 "$(log_phase "$r21" 'not json at all {{{')"
check "non-JSON stdin still logs a line that parses" 0 "$(jq -e . "$r21/.claude/telemetry.jsonl" >/dev/null 2>&1; echo $?)"
check "non-JSON stdin logs an empty session" 0 "$(status_of [ -z "$(jq -r '.session' "$r21/.claude/telemetry.jsonl")" ])"

r22="$(mktemp -d)"
check "missing .claude directory exits 0" 0 "$(log_phase "$r22" '{"session_id":"abc"}')"
check "missing .claude directory is not created" 0 "$(status_of [ ! -e "$r22/.claude" ])"

# --- cost-report.sh (Stop; sums the headless spend each feature recorded) ---
write_spend() { # dir feature cost... -> one telemetry line per cost
  local d="$1" feature="$2" cost
  shift 2
  mkdir -p "$d/.claude"
  for cost in "$@"; do
    printf '{"ts":"2026-09-20T00:00:00Z","event":"headless","feature":"%s","total_cost_usd":%s}\n' \
      "$feature" "$cost" >> "$d/.claude/telemetry.jsonl"
  done
}
cost_report() { # dir -> prints exit code, leaving the ceiling at its default
  ( cd "$1" && bash "$HOOKS/cost-report.sh" >/dev/null 2>&1 ); echo $?
}

budget_over="$(mktemp -d)"; write_spend "$budget_over" 001-x 0.75 0.75
check "a feature summing past the ceiling exits 1" 1 "$(cost_report "$budget_over")"
check_has "the over-budget report names the feature" \
  "$( ( cd "$budget_over" && bash "$HOOKS/cost-report.sh" 2>&1 ) )" "001-x"
budget_under="$(mktemp -d)"; write_spend "$budget_under" 001-x 0.25 0.25
check "a feature summing below the ceiling exits 0" 0 "$(cost_report "$budget_under")"
check "a non-numeric ceiling reports no sum" 3 \
  "$( ( cd "$budget_under" && SPECFLOW_BUDGET_USD=abc bash "$HOOKS/cost-report.sh" >/dev/null 2>&1 ); echo $?)"

# --- diff-impl.sh (sets up the two worktrees a differential run implements in) ---
diff_impl_repo() { # -> temp repo holding a committed spec directory
  local d; d="$(fresh_repo main)"
  mkdir -p "$d/specs/001-x"
  printf '# Spec\n' > "$d/specs/001-x/spec.md"
  git -C "$d" add -A
  git -C "$d" -c user.email=t@t -c user.name=t commit -q -m spec
  echo "$d"
}
diff_impl_exit() { # dir args... -> exit code
  local d="$1"; shift
  ( cd "$d" && bash "$HOOKS/diff-impl.sh" "$@" >/dev/null 2>&1 ); echo $?
}
diff_impl_clean() { # dir feature -> removes every worktree and branch the run created
  local d="$1" f="$2" side
  for side in a b; do
    git -C "$d" worktree remove --force "worktrees/$f-$side" >/dev/null 2>&1
    git -C "$d" branch -D "$f-$side" >/dev/null 2>&1
  done
  git -C "$d" worktree prune >/dev/null 2>&1
}

r23="$(diff_impl_repo)"
check "missing spec-dir argument fails"   2 "$(diff_impl_exit "$r23")"
check "nonexistent spec-dir fails"        2 "$(diff_impl_exit "$r23" specs/999-none)"
check "a rejected run creates no worktrees" 0 "$(status_of [ ! -e "$r23/worktrees" ])"

r24="$(diff_impl_repo)"; real24="$(cd "$r24" && pwd -P)"
out="$(cd "$r24" && bash "$HOOKS/diff-impl.sh" specs/001-x 2>/dev/null)"; st=$?
check "successful run exits 0"            0 "$st"
check "worktree a is created"             0 "$(status_of [ -d "$r24/worktrees/001-x-a" ])"
check "worktree b is created"             0 "$(status_of [ -d "$r24/worktrees/001-x-b" ])"
branch_a="$(git -C "$r24/worktrees/001-x-a" rev-parse --abbrev-ref HEAD)"
branch_b="$(git -C "$r24/worktrees/001-x-b" rev-parse --abbrev-ref HEAD)"
check_out "worktree a sits on the -a branch" 001-x-a "$branch_a"
check_out "worktree b sits on the -b branch" 001-x-b "$branch_b"
check "the two worktrees are on distinct branches" 0 "$(status_of [ "$branch_a" != "$branch_b" ])"
check_has "run prints worktree a's path"  "$out" "worktree-a: $real24/worktrees/001-x-a"
check_has "run prints worktree b's path"  "$out" "worktree-b: $real24/worktrees/001-x-b"
check_has "run prints the shared test command" "$out" "test-command: cd specflow && python3"
check "a second run on the same spec fails" 2 "$(diff_impl_exit "$r24" specs/001-x)"
diff_impl_clean "$r24" 001-x
check "cleanup leaves the repo with no extra worktree" 0 "$(status_of [ "$(git -C "$r24" worktree list | wc -l)" -eq 1 ])"

r25="$(diff_impl_repo)"
out="$(cd "$r25" && SPECFLOW_TEST_CMD='marker-test-cmd' bash "$HOOKS/diff-impl.sh" specs/001-x 2>/dev/null)"
check_has "SPECFLOW_TEST_CMD overrides the shared test command" "$out" "test-command: marker-test-cmd"
diff_impl_clean "$r25" 001-x

write_plan() { # dir line... -> writes specs/001-x/plan.md
  local d="$1"; shift
  printf '%s\n' "# Plan" "$@" > "$d/specs/001-x/plan.md"
}
diff_impl_out() { # dir -> stdout of a successful run
  ( cd "$1" && bash "$HOOKS/diff-impl.sh" specs/001-x 2>/dev/null )
}

r27="$(diff_impl_repo)"
write_plan "$r27" '**Test command**: `marker-from-plan`'
out="$(diff_impl_out "$r27")"
check_has "plan.md names the shared test command" "$out" "test-command: marker-from-plan"
diff_impl_clean "$r27" 001-x

r28="$(diff_impl_repo)"
write_plan "$r28" '**Testing**: manual browser checks at three viewports'
out="$(diff_impl_out "$r28")"
check_has "plan.md naming no command falls back to the default" "$out" "test-command: cd specflow && python3"
diff_impl_clean "$r28" 001-x

r29="$(diff_impl_repo)"
write_plan "$r29" '**Test command**: `marker-from-plan`'
out="$(cd "$r29" && SPECFLOW_TEST_CMD='marker-from-env' bash "$HOOKS/diff-impl.sh" specs/001-x 2>/dev/null)"
check_has "SPECFLOW_TEST_CMD outranks the plan.md line" "$out" "test-command: marker-from-env"
diff_impl_clean "$r29" 001-x

r30="$(diff_impl_repo)"
write_plan "$r30" '**Test command**: `marker-first`' '**Test command**: `marker-second`'
out="$(diff_impl_out "$r30")"
check_has "the first plan.md line wins"          "$out" "test-command: marker-first"
check_lacks "a later plan.md line is ignored"    "$out" "marker-second"
diff_impl_clean "$r30" 001-x

r31="$(diff_impl_repo)"
write_plan "$r31" '**Test command**: no backticks here'
out="$(diff_impl_out "$r31")"
check_has "a plan.md line without backticks falls back to the default" "$out" "test-command: cd specflow && python3"
diff_impl_clean "$r31" 001-x

r26="$(diff_impl_repo)"
git -C "$r26" branch 001-x-a
check "an existing branch name fails"     2 "$(diff_impl_exit "$r26" specs/001-x)"
check "a name collision creates no worktrees" 0 "$(status_of [ ! -e "$r26/worktrees" ])"
git -C "$r26" branch -D 001-x-a >/dev/null

cd /

# --- mutation-gate.sh (runs mutmut on a project and blocks below MUTATION_THRESHOLD) ---
SAMPLE="$HOOKS/../../specflow/examples/mutation-gate-sample"
mutation_gate() { # project-dir -> exit code
  bash "$HOOKS/mutation-gate.sh" "$1" >/dev/null 2>&1; echo $?
}
mutation_gate_message() { # project-dir -> stdout and stderr
  bash "$HOOKS/mutation-gate.sh" "$1" 2>&1
}
# CI installs mutmut from requirements-dev.txt; a plain checkout has no mutmut,
# and the cases that measure a score report skipped rather than failed there.
MUTMUT_ABSENT="mutmut is not on PATH; see requirements-dev.txt"
has_mutmut=1
command -v mutmut >/dev/null 2>&1 || has_mutmut=0
check_scored() { # name expected_exit actual_exit
  if [ "$has_mutmut" -eq 1 ]; then check "$1" "$2" "$3"; else skip "$1" "$MUTMUT_ABSENT"; fi
}
check_has_scored() { # name haystack needle
  if [ "$has_mutmut" -eq 1 ]; then check_has "$1" "$2" "$3"; else skip "$1" "$MUTMUT_ABSENT"; fi
}
survivor_copy() { # -> copy of the sample with the free-shipping boundary test removed
  local d; d="$(mktemp -d)/sample"
  # The copy keeps the mutants/ cache the passing run left, so its first run is the stale-cache case.
  cp -R "$SAMPLE" "$d"
  python3 - "$d/tests/test_pricing.py" <<'PY'
import pathlib, sys
path = pathlib.Path(sys.argv[1])
lines = path.read_text().splitlines(keepends=True)
start = lines.index("def test_order_at_free_shipping_line_pays_nothing():\n")
path.write_text("".join(lines[:start] + lines[start + 4:]))
PY
  echo "$d"
}
check "missing project-dir argument fails"   2 "$(mutation_gate "")"
check "nonexistent project-dir fails"        2 "$(mutation_gate /nonexistent/project)"
check "project-dir without pyproject.toml fails" 2 "$(mutation_gate "$(mktemp -d)")"
check "mutmut missing from PATH fails"       2 "$(PATH=/usr/bin:/bin mutation_gate "$SAMPLE")"
check_has "the mutmut failure names mutmut" "$(PATH=/usr/bin:/bin mutation_gate_message "$SAMPLE")" "mutmut is not on PATH"
check "non-integer threshold fails"          2 "$(MUTATION_THRESHOLD=abc mutation_gate "$SAMPLE")"
check "threshold above 100 fails"            2 "$(MUTATION_THRESHOLD=101 mutation_gate "$SAMPLE")"
check "threshold beyond the integer range fails" 2 "$(MUTATION_THRESHOLD=9223372036854775808 mutation_gate "$SAMPLE")"
shim="$(mktemp -d)"
ln -s "$(command -v bash)" "$shim/bash"
# The gate checks mutmut before jq and exits before running either, so a
# stand-in carries the case to the jq check on a machine with no mutmut
# installed. The stub exits nonzero, so a reordered gate fails the case.
printf '#!/bin/sh\necho "stand-in mutmut ran; the gate reached mutmut before the jq check" >&2\nexit 1\n' > "$shim/mutmut"
chmod +x "$shim/mutmut"
check "jq missing from PATH fails"           2 "$(PATH="$shim" mutation_gate "$SAMPLE")"
check_has "the jq failure names jq" "$(PATH="$shim" mutation_gate_message "$SAMPLE")" "jq is not on PATH"
out="$(bash "$HOOKS/mutation-gate.sh" "$SAMPLE" 2>&1)"; st=$?
check_scored "the sample passes the gate"           0 "$st"
check_has_scored "the sample reports a full score"  "$out" "mutation score 100%; expected >= 80%"
s="$(survivor_copy)"
out="$(MUTATION_THRESHOLD=100 bash "$HOOKS/mutation-gate.sh" "$s" 2>&1)"; st=$?
check_scored "a surviving mutant fails the gate at threshold 100" 1 "$st"
check_has_scored "the failing run prints the score line" "$out" "mutation score 95%; expected >= 100%"
check_has_scored "the failing run counts the survivors" "$out" "22 of 23 mutants killed; 1 survived, 0 uncovered or timed out"
check_scored "a surviving mutant passes at the default threshold" 0 "$(mutation_gate "$s")"
u="$(mktemp -d)/sample"
cp -R "$SAMPLE" "$u"
printf '\n\ndef tax_cents(subtotal_cents: int, rate_percent: int) -> int:\n    return subtotal_cents * rate_percent // 100\n' >> "$u/pricing.py"
out="$(MUTATION_THRESHOLD=100 bash "$HOOKS/mutation-gate.sh" "$u" 2>&1)"; st=$?
check_scored "an untested function fails the gate at threshold 100" 1 "$st"
check_has_scored "the failing run counts the uncovered mutants" "$out" "23 of 26 mutants killed; 0 survived, 3 uncovered or timed out"

# --- check-upstream.sh (compares the vendored commit to upstream HEAD) ---
CHECK_UPSTREAM="$HOOKS/../divergence/check-upstream.sh"
# A stub git answers ls-remote from two variables, so no case reaches the
# network. It is first on PATH and forwards nothing else.
STUB_BIN="$(mktemp -d)"
cat > "$STUB_BIN/git" <<'STUB'
#!/usr/bin/env bash
if [ "${1:-}" = "ls-remote" ]; then
  printf '%s\n' "${STUB_LS_REMOTE_OUT:-}"
  exit "${STUB_LS_REMOTE_EXIT:-0}"
fi
echo "stub git refuses $*" >&2
exit 127
STUB
chmod +x "$STUB_BIN/git"
check_upstream_out() { # ls-remote-stdout ls-remote-exit -> stdout and stderr
  PATH="$STUB_BIN:$PATH" STUB_LS_REMOTE_OUT="$1" STUB_LS_REMOTE_EXIT="$2" \
    bash "$CHECK_UPSTREAM" 2>&1
}
check_upstream_exit() { # ls-remote-stdout ls-remote-exit -> exit code
  PATH="$STUB_BIN:$PATH" STUB_LS_REMOTE_OUT="$1" STUB_LS_REMOTE_EXIT="$2" \
    bash "$CHECK_UPSTREAM" >/dev/null 2>&1
  echo $?
}
ls_remote_line() { printf '%s\tHEAD' "$1"; } # sha -> one ls-remote answer
# The drifted run names the pinned commit, so no case has to repeat the pin.
MOVED_HEAD="0123456789abcdef0123456789abcdef01234567"
drift_out="$(check_upstream_out "$(ls_remote_line "$MOVED_HEAD")" 0)"
vendored="$(printf '%s\n' "$drift_out" | awk '/^vendored /{print $2}')"
check "a moved upstream HEAD exits 1" 1 \
  "$(check_upstream_exit "$(ls_remote_line "$MOVED_HEAD")" 0)"
check_has "the drifted run prints the vendored commit" "$drift_out" "vendored "
check_has "the drifted run prints the upstream commit" "$drift_out" "upstream $MOVED_HEAD"
check "the drifted run read a vendored commit of at least 7 characters" 0 \
  "$(status_of [ "${#vendored}" -ge 7 ])"
same_head="$(printf '%s%040d' "$vendored" 0)"; same_head="${same_head:0:40}"
check "an unmoved upstream HEAD exits 0" 0 \
  "$(check_upstream_exit "$(ls_remote_line "$same_head")" 0)"
check_has "the unmoved run prints the vendored commit" \
  "$(check_upstream_out "$(ls_remote_line "$same_head")" 0)" "vendored $vendored"
check "a failing ls-remote exits 2" 2 "$(check_upstream_exit "" 1)"
check_has "a failing ls-remote names the remote" "$(check_upstream_out "" 1)" "superspec"
check "an empty ls-remote answer exits 2" 2 "$(check_upstream_exit "" 0)"

# --- open-drift-issue.sh (opens one drift issue, never a second) ---
OPEN_DRIFT_ISSUE="$HOOKS/../divergence/open-drift-issue.sh"
# A stub gh records its arguments and answers `issue list` with a JSON array
# read from a variable, so no case reaches GitHub.
cat > "$STUB_BIN/gh" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$STUB_GH_LOG"
if [ "${1:-}" = "issue" ] && [ "${2:-}" = "list" ]; then
  printf '%s\n' "${STUB_GH_ISSUES:-[]}"
  exit 0
fi
exit 0
STUB
chmod +x "$STUB_BIN/gh"
open_drift_issue() { # open-issues-json -> exit code, logging gh calls to STUB_GH_LOG
  : > "$STUB_GH_LOG"
  printf 'vendored c20ac6c\nupstream %s\n' "$MOVED_HEAD" > "$STUB_BIN/report.txt"
  PATH="$STUB_BIN:$PATH" STUB_GH_ISSUES="$1" STUB_GH_LOG="$STUB_GH_LOG" \
    bash "$OPEN_DRIFT_ISSUE" "$STUB_BIN/report.txt" >/dev/null 2>&1
  echo $?
}
STUB_GH_LOG="$(mktemp)"
DRIFT_TITLE="Upstream superspec has moved past the vendored commit"
check "no open issue means the script exits 0" 0 "$(open_drift_issue '[]')"
check "no open issue means one issue is created" 0 \
  "$(status_of grep -qF 'issue create' "$STUB_GH_LOG")"
check "the created issue carries the fixed title" 0 \
  "$(status_of grep -qF "$DRIFT_TITLE" "$STUB_GH_LOG")"
check "an unrelated open issue still creates one" 0 \
  "$(open_drift_issue '[{"title":"Something else"}]')"
check "an unrelated open issue does not suppress creation" 0 \
  "$(status_of grep -qF 'issue create' "$STUB_GH_LOG")"
check "a matching open issue exits 0" 0 \
  "$(open_drift_issue "[{\"title\":\"$DRIFT_TITLE\"}]")"
check "a matching open issue creates no second issue" 1 \
  "$(status_of grep -qF 'issue create' "$STUB_GH_LOG")"
mixed_exit="$(open_drift_issue "[{\"title\":\"Other\"},{\"title\":\"$DRIFT_TITLE\"}]")"
check "a matching open issue among others exits 0" 0 "$mixed_exit"
check "a matching open issue among others creates no second issue" 1 \
  "$(status_of grep -qF 'issue create' "$STUB_GH_LOG")"
check "a missing report argument exits 2" 2 \
  "$(PATH="$STUB_BIN:$PATH" STUB_GH_LOG="$STUB_GH_LOG" bash "$OPEN_DRIFT_ISSUE" >/dev/null 2>&1; echo $?)"
check "a missing report file exits 2" 2 \
  "$(PATH="$STUB_BIN:$PATH" STUB_GH_LOG="$STUB_GH_LOG" bash "$OPEN_DRIFT_ISSUE" /nonexistent/report.txt >/dev/null 2>&1; echo $?)"

# --- .github/workflows/upstream-drift.yml (the weekly drift check) ---
cd "$HOOKS/../.." || exit 1
DRIFT_WORKFLOW=".github/workflows/upstream-drift.yml"
drift_src="$(cat "$DRIFT_WORKFLOW" 2>/dev/null || true)"
python3 -c 'import yaml;yaml.safe_load(open("'"$DRIFT_WORKFLOW"'"))' >/dev/null 2>&1
check "upstream drift workflow parses as YAML" 0 $?
python3 - "$DRIFT_WORKFLOW" <<'PY' >/dev/null 2>&1
import sys
import yaml
document = yaml.safe_load(open(sys.argv[1]))
# YAML 1.1 reads the bare key `on` as the boolean True.
triggers = document[True] if True in document else document["on"]
sys.exit(0 if "schedule" in triggers else 1)
PY
check "upstream drift workflow runs on a schedule" 0 $?
check "upstream drift workflow runs the check script" 0 \
  "$(printf '%s' "$drift_src" | grep -Fq '.claude/divergence/check-upstream.sh'; echo $?)"
check "upstream drift workflow opens the issue through the dedupe script" 0 \
  "$(printf '%s' "$drift_src" | grep -Fq '.claude/divergence/open-drift-issue.sh'; echo $?)"
check "upstream drift workflow may write issues" 0 \
  "$(printf '%s' "$drift_src" | grep -Fq 'issues: write'; echo $?)"
cd / || exit 1

# --- specflow/references/findings-schema.json (findings contract, ADR-0025) ---
cd "$HOOKS/../.." || exit 1
python3 -c 'import json;json.load(open("specflow/references/findings-schema.json"))' >/dev/null 2>&1
check "review findings schema parses as JSON" 0 $?
CODE_REVIEWER=".claude/agents/code-reviewer.md"
check "code reviewer uses the findings schema" 0 \
  "$(grep -Fq 'specflow/references/findings-schema.json' "$CODE_REVIEWER"; echo $?)"
check "code reviewer writes a gate-readable findings document" 0 \
  "$(grep -Fq '.claude/review/code-reviewer.json' "$CODE_REVIEWER"; echo $?)"
check "the risk classifier hook execs the shipped gate" 0 \
  "$(grep -Fq 'specflow/gates/bash/risk-classifier.sh' "$HOOKS/risk-classifier.sh"; echo $?)"
check "the merge gate hook execs the shipped gate" 0 \
  "$(grep -Fq 'specflow/gates/bash/merge-gate.sh' "$HOOKS/merge-gate.sh"; echo $?)"

# --- .github/workflows/merge-gate.yml (the CI merge gate) ---
GATE_WORKFLOW=".github/workflows/merge-gate.yml"
gate_src="$(cat "$GATE_WORKFLOW" 2>/dev/null || true)"
python3 -c 'import yaml;yaml.safe_load(open("'"$GATE_WORKFLOW"'"))' >/dev/null 2>&1
check "merge gate workflow parses as YAML" 0 $?
high_gated="$(grep -c "level == 'HIGH'" "$GATE_WORKFLOW" 2>/dev/null || echo 0)"
check "merge gate workflow gates three steps on HIGH risk" 0 \
  "$(status_of [ "${high_gated:-0}" -eq 3 ])"
check "security review action is pinned to a commit" 0 \
  "$(printf '%s' "$gate_src" | grep -Eq 'claude-code-security-review@[0-9a-f]{40}$'; echo $?)"
check "headless review CLI is pinned to a version" 0 \
  "$(printf '%s' "$gate_src" | grep -Eq '@anthropic-ai/claude-code@[0-9]+\.[0-9]+\.[0-9]+$'; echo $?)"
check "merge gate workflow runs the gate hook under .claude" 0 \
  "$(printf '%s' "$gate_src" | grep -Fq '.claude/hooks/merge-gate.sh'; echo $?)"
check_lacks "merge gate workflow names no .specify hook path" "$gate_src" ".specify/scripts/hooks/"
check "merge gate workflow reruns when a label changes" 0 \
  "$(printf '%s' "$gate_src" | grep -Eq '^\s+types: \[.*labeled.*\]'; echo $?)"
check "merge gate workflow honors the findings-rebutted label" 0 \
  "$(printf '%s' "$gate_src" | grep -Fq "'findings-rebutted'"; echo $?)"
check "merge gate workflow runs the rebuttal hook under .claude" 0 \
  "$(printf '%s' "$gate_src" | grep -Fq '.claude/hooks/rebut-findings.sh'; echo $?)"

echo "$pass passed, $fail failed, $skipped skipped"
[ "$fail" -eq 0 ]
