#!/usr/bin/env bash
# Test harness for .claude/hooks/*.sh. Each hook reads Claude Code's JSON on
# stdin and signals with its exit code (0 = allow, 2 = block). Run:
#   bash .claude/hooks/tests/run.sh
set -u
HOOKS="$(cd "$(dirname "$0")/.." && pwd)"
pass=0; fail=0
check() { # name expected_exit actual_exit
  if [ "$2" -eq "$3" ]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1 (expected exit $2, got $3)"; fi
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
r="$(fresh_repo main)"; cd "$r"
check "commit on main is blocked"        2 "$(run_hook block-main-commit.sh '{"tool_input":{"command":"git commit -m x"}}')"
check "commit on master is blocked"      2 "$(cd "$(fresh_repo master)" && run_hook block-main-commit.sh '{"tool_input":{"command":"git add -A && git commit -m x"}}')"
check "non-commit git on main allowed"   0 "$(run_hook block-main-commit.sh '{"tool_input":{"command":"git status"}}')"
check "empty command allowed"            0 "$(run_hook block-main-commit.sh '{"tool_input":{}}')"
git switch -q -c feature
check "commit on feature branch allowed" 0 "$(run_hook block-main-commit.sh '{"tool_input":{"command":"git commit -m x"}}')"
cd /

# --- test-gate.sh (PostToolUse: Edit|Write) ---
r="$(fresh_repo feature)"; cd "$r"
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

# --- artifact-lint.sh (PostToolUse: Edit|Write) ---
r="$(fresh_repo feature)"; mkdir -p "$r/specs/001-x"; cd "$r/specs/001-x"
lint() { run_hook artifact-lint.sh "{\"tool_input\":{\"file_path\":\"$PWD/$1\"}}"; }
printf '# Spec\n## User Scenarios & Testing\n## Requirements\n## Success Criteria\n' > spec.md
check "spec with mandatory sections passes"     0 "$(lint spec.md)"
printf '# Spec\n## Requirements\n' > spec.md
check "spec missing mandatory section blocked"  2 "$(lint spec.md)"
printf '# Spec\n## User Scenarios & Testing\n## Requirements\n## Success Criteria\n[NEEDS CLARIFICATION: x]\n' > spec.md
check "unclarified marker allowed before clarify" 0 "$(lint spec.md)"
touch .clarified
check "unclarified marker blocked after clarify" 2 "$(lint spec.md)"
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
printf 'anything\n' > notes.md
check "unrelated file ignored"                  0 "$(lint notes.md)"
cd /
EX="$HOOKS/../../specflow/examples/static-landing-page/specs"
for f in "$EX"/*/spec.md "$EX"/*/plan.md "$EX"/*/tasks.md; do
  check "shipped example passes: $(basename "$(dirname "$f")")/$(basename "$f")" 0 "$(run_hook artifact-lint.sh "{\"tool_input\":{\"file_path\":\"$f\"}}")"
done

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
