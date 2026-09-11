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
printf '# Tasks\n- [x] T001 do a\n- [ ] T002 do b\n' > tasks.md
printf 'spec: 001-x\nphases:\n  - phase: 1\n    tasks:\n      T001: complete\n' > progress.yml
check "completed id still in tasks.md passes"   0 "$(lint tasks.md)"
printf '# Tasks\n- [ ] T002 do b\n' > tasks.md
check "completed id dropped from tasks.md blocked" 2 "$(lint tasks.md)"
rm -f progress.yml
check "dropped id allowed with no progress.yml" 0 "$(lint tasks.md)"
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
cd /
EX="$HOOKS/../../specflow/examples/static-landing-page/specs"
for f in "$EX"/*/spec.md "$EX"/*/plan.md "$EX"/*/tasks.md; do
  check "shipped example passes: $(basename "$(dirname "$f")")/$(basename "$f")" 0 "$(run_hook artifact-lint.sh "{\"tool_input\":{\"file_path\":\"$f\"}}")"
done

# --- session-start.sh (SessionStart) ---
session_start_out() { # json -> stdout
  printf '%s' "$1" | bash "$HOOKS/session-start.sh" 2>/dev/null
}
session_start_err() { # json -> stderr
  printf '%s' "$1" | bash "$HOOKS/session-start.sh" 2>&1 >/dev/null
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
check "malformed candidate produces no stderr output" 0 "$([ -z "$err" ]; echo $?)"

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
check "open-questions.md content precedes summary line" 0 "$([ -n "$oq_line" ] && [ -n "$sm_line" ] && [ "$oq_line" -lt "$sm_line" ]; echo $?)"

r9="$(mktemp -d)"
write_progress "$r9/specs/001-x" 001-x complete 3
out="$(cd "$r9" && session_start_out '{}')"
check "no open-questions.md means output starts with summary" 0 "$(printf '%s\n' "$out" | head -1 | grep -q '^spec: 001-x'; echo $?)"

r10="$(mktemp -d)"
write_progress "$r10/specs/001-x" 001-x complete 4
out="$(cd "$r10" && session_start_out '{}')"
count="$(printf '%s\n' "$out" | grep -c '^spec: 001-x status: complete current_phase: 4$')"
check "exactly one summary line with spec id status and phase" 0 "$([ "$count" -eq 1 ]; echo $?)"

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
check "no tasks.md produces no stderr" 0 "$([ -z "$err" ]; echo $?)"
check_lacks "no tasks.md means no task line" "$out" "- [ ] T"

r14="$(mktemp -d)"
write_progress "$r14/specs/001-x" 001-x complete 2
printf -- '- [ ] T001 pending task\n' > "$r14/specs/001-x/tasks.md"
printf 'HANDOFF-MARKER line one\n' > "$r14/specs/001-x/handoff.md"
out="$(cd "$r14" && session_start_out '{}')"
task_line="$(printf '%s\n' "$out" | grep -n "T001 pending task" | head -1 | cut -d: -f1)"
handoff_line="$(printf '%s\n' "$out" | grep -n "HANDOFF-MARKER" | head -1 | cut -d: -f1)"
check_has "handoff.md content appears in output" "$out" "HANDOFF-MARKER"
check "handoff.md content follows task line" 0 "$([ -n "$task_line" ] && [ -n "$handoff_line" ] && [ "$handoff_line" -gt "$task_line" ]; echo $?)"

r15="$(mktemp -d)"
write_progress "$r15/specs/001-x" 001-x complete 2
out="$(cd "$r15" && session_start_out '{}')"
check "no handoff.md and no tasks.md means output is exactly the summary line" 0 "$([ "$out" = "spec: 001-x status: complete current_phase: 2" ]; echo $?)"

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
check "section order is open-questions, summary, task, handoff" 0 "$([ -n "$oq" ] && [ -n "$sm" ] && [ -n "$tl" ] && [ -n "$hd" ] && [ "$oq" -lt "$sm" ] && [ "$sm" -lt "$tl" ] && [ "$tl" -lt "$hd" ]; echo $?)"

# --- risk-classifier.sh (run by the review pipeline against a base ref) ---
check_out() { # name expected actual
  if [ "$2" = "$3" ]; then pass=$((pass+1)); echo "ok   $1"
  else fail=$((fail+1)); echo "FAIL $1 (expected '$2', got '$3')"; fi
}
branch_with() { # path content -> repo on a feature branch holding that file
  local d; d="$(fresh_repo main)"
  git -C "$d" switch -q -c feature
  mkdir -p "$d/$(dirname "$1")"
  printf '%s\n' "$2" > "$d/$1"
  git -C "$d" add -A
  git -C "$d" -c user.email=t@t -c user.name=t commit -q -m change
  echo "$d"
}
classify() { # repo -> HIGH or STANDARD
  ( cd "$1" && bash "$HOOKS/risk-classifier.sh" main 2>/dev/null )
}
check_out "diff touching auth/ is HIGH"     HIGH     "$(classify "$(branch_with auth/session.sh 'check_token')")"
check_out "lockfile change is HIGH"         HIGH     "$(classify "$(branch_with package-lock.json '{}')")"
check_out "two-line doc change is STANDARD" STANDARD "$(classify "$(branch_with docs/notes.md $'line one\nline two')")"
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
check "cleared merge writes the approval marker" 0 "$([ -f "$d/$MARKER" ]; echo $?)"
d="$(review_dir)"; cp "$HOOKS/../review/schema.json" "$d/.claude/review/schema.json"
check "schema.json is not read as findings"      0 "$(merge_gate "$d")"
d="$(review_dir)"; printf 'not json at all\n' > "$d/.claude/review/claude.json"
check "unreadable findings document blocks"      1 "$(merge_gate "$d")"
d="$(review_dir)"; write_findings "$d" claude Critical open; touch "$d/$MARKER"
merge_gate "$d" >/dev/null
check "blocked merge clears a stale marker"      0 "$([ ! -f "$d/$MARKER" ]; echo $?)"

# --- log-phase.sh (Stop) ---
telemetry_repo() { # -> dir containing an empty .claude/
  local d; d="$(mktemp -d)"; mkdir -p "$d/.claude"; echo "$d"
}
log_phase() { # dir json -> prints exit code
  (cd "$1" && run_hook log-phase.sh "$2")
}

r17="$(telemetry_repo)"
check "stop hook exits 0" 0 "$(log_phase "$r17" '{"session_id":"abc"}')"
check "exactly one telemetry line is appended" 0 "$([ "$(wc -l < "$r17/.claude/telemetry.jsonl")" -eq 1 ]; echo $?)"
check "telemetry line parses as JSON" 0 "$(jq -e . "$r17/.claude/telemetry.jsonl" >/dev/null 2>&1; echo $?)"
check_has "telemetry line carries the session id" "$(jq -r '.session' "$r17/.claude/telemetry.jsonl")" "abc"
check_has "telemetry line names the stop event"   "$(jq -r '.event'   "$r17/.claude/telemetry.jsonl")" "stop"

r18="$(telemetry_repo)"; printf 'implement\n' > "$r18/.claude/.current-phase"
log_phase "$r18" '{"session_id":"abc"}' >/dev/null
check_has "phase is read from .current-phase" "$(jq -r '.phase' "$r18/.claude/telemetry.jsonl")" "implement"

r19="$(telemetry_repo)"
log_phase "$r19" '{"session_id":"abc"}' >/dev/null
check_has "absent .current-phase logs unknown" "$(jq -r '.phase' "$r19/.claude/telemetry.jsonl")" "unknown"

r20="$(telemetry_repo)"
log_phase "$r20" '{"session_id":"abc"}' >/dev/null
log_phase "$r20" '{"session_id":"def"}' >/dev/null
check "a second turn appends instead of overwriting" 0 "$([ "$(wc -l < "$r20/.claude/telemetry.jsonl")" -eq 2 ]; echo $?)"

r21="$(telemetry_repo)"
check "non-JSON stdin exits 0"  0 "$(log_phase "$r21" 'not json at all {{{')"
check "non-JSON stdin still logs a line that parses" 0 "$(jq -e . "$r21/.claude/telemetry.jsonl" >/dev/null 2>&1; echo $?)"
check "non-JSON stdin logs an empty session" 0 "$([ -z "$(jq -r '.session' "$r21/.claude/telemetry.jsonl")" ]; echo $?)"

r22="$(mktemp -d)"
check "missing .claude directory exits 0" 0 "$(log_phase "$r22" '{"session_id":"abc"}')"
check "missing .claude directory is not created" 0 "$([ ! -e "$r22/.claude" ]; echo $?)"

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
check "a rejected run creates no worktrees" 0 "$([ ! -e "$r23/worktrees" ]; echo $?)"

r24="$(diff_impl_repo)"; real24="$(cd "$r24" && pwd -P)"
out="$(cd "$r24" && bash "$HOOKS/diff-impl.sh" specs/001-x 2>/dev/null)"; st=$?
check "successful run exits 0"            0 "$st"
check "worktree a is created"             0 "$([ -d "$r24/worktrees/001-x-a" ]; echo $?)"
check "worktree b is created"             0 "$([ -d "$r24/worktrees/001-x-b" ]; echo $?)"
branch_a="$(git -C "$r24/worktrees/001-x-a" rev-parse --abbrev-ref HEAD)"
branch_b="$(git -C "$r24/worktrees/001-x-b" rev-parse --abbrev-ref HEAD)"
check_out "worktree a sits on the -a branch" 001-x-a "$branch_a"
check_out "worktree b sits on the -b branch" 001-x-b "$branch_b"
check "the two worktrees are on distinct branches" 0 "$([ "$branch_a" != "$branch_b" ]; echo $?)"
check_has "run prints worktree a's path"  "$out" "worktree-a: $real24/worktrees/001-x-a"
check_has "run prints worktree b's path"  "$out" "worktree-b: $real24/worktrees/001-x-b"
check_has "run prints the shared test command" "$out" "test-command: cd specflow && python3"
check "a second run on the same spec fails" 2 "$(diff_impl_exit "$r24" specs/001-x)"
diff_impl_clean "$r24" 001-x
check "cleanup leaves the repo with no extra worktree" 0 "$([ "$(git -C "$r24" worktree list | wc -l)" -eq 1 ]; echo $?)"

r25="$(diff_impl_repo)"
out="$(cd "$r25" && SPECFLOW_TEST_CMD='marker-test-cmd' bash "$HOOKS/diff-impl.sh" specs/001-x 2>/dev/null)"
check_has "SPECFLOW_TEST_CMD overrides the shared test command" "$out" "test-command: marker-test-cmd"
diff_impl_clean "$r25" 001-x

r26="$(diff_impl_repo)"
git -C "$r26" branch 001-x-a
check "an existing branch name fails"     2 "$(diff_impl_exit "$r26" specs/001-x)"
check "a name collision creates no worktrees" 0 "$([ ! -e "$r26/worktrees" ]; echo $?)"
git -C "$r26" branch -D 001-x-a >/dev/null

cd /

# --- .claude/review/schema.json (findings contract read by the reviewer agents) ---
cd "$HOOKS/../.."
python3 -c 'import json;json.load(open(".claude/review/schema.json"))' >/dev/null 2>&1
check "review findings schema parses as JSON" 0 $?

echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
