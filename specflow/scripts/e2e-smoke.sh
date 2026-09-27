#!/usr/bin/env bash
# scripts/e2e-smoke.sh
#
# Structural end-to-end smoke test for the specflow extension: installs this
# checkout into a fresh spec-kit project and asserts the file layout spec-kit
# and specflow jointly promise, without invoking an LLM.
#
# Usage: bash scripts/e2e-smoke.sh
#        KEEP_WORKDIR=1 bash scripts/e2e-smoke.sh
# Exit code: 0 when every assertion passes, 1 otherwise.
#
# A passing run deletes the workdirs it created. Any other outcome leaves them
# on disk and prints their paths, because the path is the only way to inspect
# the run. KEEP_WORKDIR=1 keeps them on a passing run too.

# -e is omitted on purpose: a failing install or feature-creation command is
# recorded as a failed assertion below rather than aborting the run.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEEP_WORKDIR="${KEEP_WORKDIR:-0}"
WORK="$(mktemp -d -t specflow-e2e.XXXXXX)"
INIT_LOG="$WORK/.init.log"
ADD_LOG="$WORK/.add.log"
FEAT_LOG="$WORK/.feat.log"

SPEC_KIT_GIT_URL="${SPEC_KIT_GIT_URL:-https://github.com/github/spec-kit.git}"
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
# The template stamp check reads the same manifest, so a template added to
# extension.yml gets a stamp assertion below without a second edit.
SPECFLOW_TEMPLATES=()
while IFS= read -r template_name; do
  SPECFLOW_TEMPLATES+=("$template_name")
done < <(awk '/^provides:/{p=1} p&&/^  templates:/{t=1;next} t&&/^  [a-z]/{t=0} t&&/-[ ]*name:/{sub(/.*name:[ ]*/,"");gsub(/["'"'"']/,"");print}' "$MANIFEST")
LOG_TAIL_LINES=30
RESOLVER_ERROR_LINES=3

# Process steps per command file, counted on 2026-09-20. A command file's
# numbered Process list is its behavior contract, so a step dropped by a bad
# merge or an edit has to fail here rather than pass unnoticed. bash 3.2 has no
# associative arrays, so each row is "<command> <count>".
EXPECTED_PROCESS_STEPS=(
  "status 8"
  "brainstorm 10"
  "tasks 12"
  "execute 9"
  "review 10"
  "gate 4"
  "agent-event 8"
)

# The workflow guide phase that mirrors each command, as
# "<command>|<phase heading>|<steps heading>". The guide is the protocol an
# agent follows when no superpowers skill is installed, so a phase that names
# fewer artifacts than its command does tells that agent to write less. The
# names do not line up on their own, so each pair is declared here.
MIRRORED_PHASES=(
  "brainstorm|## Phase 2: Brainstorming|### Process"
  "tasks|## Phase 4: Task Decomposition|### Steps"
  "execute|## Phase 5: Execution|### Steps"
  "review|## Phase 6: Review|### Steps"
)
# The guide is phase-structured, and neither status nor gate nor agent-event
# is a phase, so none of the three mirrors a phase. The Gate markers table
# under Phase 5 carries the protocol gate follows. agent-event runs as a
# spec-kit events hook dispatcher, outside the phase sequence entirely. Any
# other command missing from MIRRORED_PHASES fails below.
UNMIRRORED_COMMANDS=("status" "gate" "agent-event")
# Backticked names that match the artifact shape but name no project state.
# SKILL.md is the superpowers skill file a command reads; package-lock.json is
# one of the lock files review.md lists to classify risk.
NON_ARTIFACT_NAMES="SKILL.md package-lock.json"

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

# Print the path of every workdir the run leaves on disk. The copilot workdir
# is created midway, so an early exit names only the first one.
report_kept_workdirs() {
  printf '\nWorkdir kept at: %s\n' "$WORK"
  if [ -n "${WORK_COPILOT:-}" ]; then
    printf 'Copilot workdir kept at: %s\n' "$WORK_COPILOT"
  fi
}

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

# Print "<command> <script>" for every command file whose frontmatter declares
# a bash script. The event dispatcher resolves that path under the installed
# extension directory and returns 0 when it lands nowhere, so an unresolvable
# path is a handler that passes everything (docs/agent-event-mapping.md).
declared_bash_scripts() {
  local name
  for name in "${SPECFLOW_COMMANDS[@]}"; do
    awk -v cmd="$name" '
      NR == 1 && $0 != "---"  { exit }
      NR > 1  && $0 == "---"  { exit }
      /^scripts:/             { inside = 1; next }
      inside && /^[^[:space:]]/ { exit }
      inside && /^[[:space:]]+sh:/ {
        sub(/^[[:space:]]+sh:[[:space:]]*/, "")
        sub(/[[:space:]].*$/, "")
        print cmd, $0
        exit
      }
    ' "$REPO_ROOT/commands/$name.md"
  done
}

# Assert every declared bash script exists in the installed extension. Runs per
# surface, because the dispatcher resolves the same path on both.
assert_declared_scripts() {
  local surface="$1" workdir="$2" cmd script
  while read -r cmd script; do
    [ -n "$cmd" ] || continue
    assert_file "$surface: commands/$cmd.md declares $script, which the install carries" \
                "$workdir/.specify/extensions/specflow/$script"
  done < <(declared_bash_scripts)
}

# Assert each installed skill carries the description its command file declares.
# spec-kit falls back to "Extension command: <name>" when a command file has no
# frontmatter, so the fallback text proves the frontmatter did not land.
assert_skill_descriptions() {
  local surface="$1" skills_dir="$2" cmd
  for cmd in "${SPECFLOW_COMMANDS[@]}"; do
    assert_no_grep "$surface: skill speckit-specflow-$cmd carries its command file's description" \
                   "Extension command: speckit.specflow.$cmd" \
                   "$skills_dir/speckit-specflow-$cmd/SKILL.md"
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

# Print the MIRRORED_PHASES row for a command name, or exit 1 when the table
# holds no row for it.
mirrored_phase() {
  local name="$1" row
  for row in "${MIRRORED_PHASES[@]}"; do
    case "$row" in
      "$name|"*) printf '%s' "${row#*|}"; return 0 ;;
    esac
  done
  return 1
}

# Exit 0 when UNMIRRORED_COMMANDS lists the command name.
is_unmirrored_command() {
  local name="$1" entry
  for entry in "${UNMIRRORED_COMMANDS[@]}"; do
    [ "$entry" = "$name" ] && return 0
  done
  return 1
}

# Print the lines of a numbered-step section: the command file's Process list,
# or one phase's step list in the workflow guide. An empty third argument scans
# from the top of the file.
step_section() {
  awk -v phase="${3:-}" -v steps="$2" '
    BEGIN { in_phase = (phase == "") ? 1 : 0 }
    !in_phase   { if (index($0, phase) == 1) in_phase = 1; next }
    !in_section { if ($0 == steps) in_section = 1; next }
    /^#/        { exit }
    { print }
  ' "$1"
}

# Print one artifact name per line for a numbered-step section: every
# backticked path, gate marker, execution marker, task or finding ID form, and
# `##` section heading the steps name, sorted and deduplicated. A path under
# references/, commands/, templates/, .specify/templates/, .specify/scripts/ or
# .claude/ names the extension's own payload or a tool a step runs rather than
# state the run writes, so it is skipped, as is every NON_ARTIFACT_NAMES entry.
artifact_names() {
  step_section "$@" | awk -v exempt="$NON_ARTIFACT_NAMES" '
    function words(span,   count, word, i, base) {
      count = split(span, word, /[ \t]+/)
      for (i = 1; i <= count; i++) {
        if (word[i] ~ /^\[[A-Z]+\]$/) { print word[i]; continue }
        sub(/[,.;:)]+$/, "", word[i])
        if (word[i] ~ /^\.[a-z]+$/)        { print word[i]; continue }
        if (word[i] ~ /^[A-Z]+-?N{3,4}$/)  { print word[i]; continue }
        if (word[i] !~ /\.(md|yml|json)$/) continue
        if (word[i] ~ /^(references|commands|templates)\//) continue
        if (word[i] ~ /^\.specify\/(templates|scripts)\//) continue
        if (word[i] ~ /^\.claude\//) continue
        base = word[i]
        sub(/.*\//, "", base)
        if (base in skip) continue
        print base
      }
    }
    BEGIN {
      count = split(exempt, entry, " ")
      for (i = 1; i <= count; i++) skip[entry[i]] = 1
    }
    /^```/ { fenced = !fenced }
    fenced { next }
    {
      count = split($0, part, "`")
      for (i = 2; i <= count; i += 2) {
        if (part[i] == "") continue
        if (substr(part[i], 1, 3) == "## ") { print part[i]; continue }
        words(part[i])
      }
    }
  ' | sort -u
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
# Assert a file exists and does not contain pattern.
assert_no_grep() {
  local desc="$1" pattern="$2" file="$3"
  if [ ! -f "$file" ]; then
    fail "$desc (missing: $file)"
  elif grep -q -- "$pattern" "$file"; then
    fail "$desc (pattern '$pattern' found in $file)"
  else
    pass "$desc"
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
  report_kept_workdirs
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

# gates/ carries no export-ignore rule, so a catalog install and a --dev install
# both land the gate scripts beside the commands (ADR-0025).
assert_file "gates/bash/risk-classifier.sh installed" \
            "$WORK/.specify/extensions/specflow/gates/bash/risk-classifier.sh"

assert_declared_scripts "claude" "$WORK"

assert_resolved_template "claude" "$WORK"

# Every shipped template stamps its own name and the extension version it
# installed with, so status.md can grep each installed copy for drift.
for tmpl in "${SPECFLOW_TEMPLATES[@]}"; do
  assert_grep "claude: $tmpl.md installed copy carries the version stamp" \
              "specflow template:" \
              "$WORK/.specify/extensions/specflow/templates/$tmpl.md"
done

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

assert_skill_descriptions "claude" "$WORK/.claude/skills"

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
  report_kept_workdirs
  exit 1
fi
run_specify extension add "$REPO_ROOT" --dev \
    </dev/null >"$WORK_COPILOT/.add.log" 2>&1 \
  || fail "specify extension add for copilot exited non-zero (see $WORK_COPILOT/.add.log)"
for cmd in "${SPECFLOW_COMMANDS[@]}"; do
  assert_file "Copilot command file for speckit.specflow.$cmd" \
              "$WORK_COPILOT/.github/skills/speckit-specflow-$cmd/SKILL.md"
done
assert_skill_descriptions "copilot" "$WORK_COPILOT/.github/skills"
assert_file "copilot: gates/bash/risk-classifier.sh installed" \
            "$WORK_COPILOT/.specify/extensions/specflow/gates/bash/risk-classifier.sh"
assert_declared_scripts "copilot" "$WORK_COPILOT"
assert_resolved_template "copilot" "$WORK_COPILOT"

for tmpl in "${SPECFLOW_TEMPLATES[@]}"; do
  assert_grep "copilot: $tmpl.md installed copy carries the version stamp" \
              "specflow template:" \
              "$WORK_COPILOT/.specify/extensions/specflow/templates/$tmpl.md"
done

# The events: block in extension.yml registers agent-event on pre_tool_use,
# post_tool_use, and session_start; spec-kit's Copilot writer resolves that
# block into .github/hooks/speckit.json (docs/agent-event-mapping.md).
assert_file "copilot: .github/hooks/speckit.json written from the events: block" \
            "$WORK_COPILOT/.github/hooks/speckit.json"
assert_grep "copilot: agent-event.md installed copy declares its sh script" \
            "sh: gates/bash/agent-event.sh" \
            "$WORK_COPILOT/.specify/extensions/specflow/commands/agent-event.md"
SPECKIT_JSON_CHECK="$(python3 -c "
import json, sys
path = '$WORK_COPILOT/.github/hooks/speckit.json'
try:
    with open(path) as f:
        doc = json.load(f)
except (OSError, json.JSONDecodeError) as exc:
    print(f'FAIL {exc}')
    sys.exit(1)
hooks = doc.get('hooks', {})
for key in ('preToolUse', 'postToolUse', 'sessionStart'):
    entries = hooks.get(key)
    if not entries:
        print(f'FAIL {key} is missing from speckit.json')
        sys.exit(1)
    if isinstance(entries, list):
        bash_cmds = [entry.get('bash', '') for entry in entries]
        found = any('speckit.specflow.agent-event' in cmd for cmd in bash_cmds)
        if not found:
            print(f'FAIL {key}.bash does not carry speckit.specflow.agent-event in any entry')
            sys.exit(1)
    else:
        print(f'FAIL {key} is not a list')
        sys.exit(1)
print('OK')
")"
if [ "$SPECKIT_JSON_CHECK" = "OK" ]; then
  pass "copilot: speckit.json's preToolUse, postToolUse, sessionStart each run speckit.specflow.agent-event"
else
  fail "copilot: speckit.json's preToolUse, postToolUse, sessionStart each run speckit.specflow.agent-event ($SPECKIT_JSON_CHECK)"
fi

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
  hits=$(grep -rEn '\.specify/specs/' "$@" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$hits" -eq 0 ]; then
    pass "$desc"
  else
    fail "$desc: $hits stale '.specify/specs/' reference(s):"
    grep -rEn '\.specify/specs/' "$@" 2>/dev/null | sed 's|^|        |'
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

# A command's Process steps and the guide phase that mirrors them must name the
# same artifacts. An artifact the phase omits is one an agent running the
# built-in fallback never writes.
GUIDE="references/workflow-guide.md"
for cmd in "${SPECFLOW_COMMANDS[@]}"; do
  is_unmirrored_command "$cmd" && continue
  if ! mirror_row=$(mirrored_phase "$cmd"); then
    fail "commands/$cmd.md has no row in the MIRRORED_PHASES table in scripts/e2e-smoke.sh; name the $GUIDE phase that mirrors it, or list the command in UNMIRRORED_COMMANDS"
    continue
  fi
  phase_heading="${mirror_row%%|*}"
  steps_heading="${mirror_row##*|}"
  phase_steps=$(step_section "$REPO_ROOT/$GUIDE" "$steps_heading" "$phase_heading")
  if [ -z "$phase_steps" ]; then
    fail "$GUIDE has no '$steps_heading' list under '$phase_heading', the phase the $cmd row of MIRRORED_PHASES names"
    continue
  fi
  command_artifacts=$(artifact_names "$REPO_ROOT/commands/$cmd.md" "## Process")
  if [ -z "$command_artifacts" ]; then
    fail "no artifact name was read from the Process steps of commands/$cmd.md; the artifact_names extractor in scripts/e2e-smoke.sh no longer matches the file"
    continue
  fi
  missing=""
  while IFS= read -r artifact; do
    [ -n "$artifact" ] || continue
    case "$phase_steps" in
      *"$artifact"*) ;;
      *) missing="$missing, $artifact" ;;
    esac
  done <<EOF
$command_artifacts
EOF
  if [ -z "$missing" ]; then
    pass "$GUIDE '$phase_heading' names every artifact commands/$cmd.md writes"
  else
    fail "$GUIDE '$phase_heading' does not name ${missing#, }, which the Process steps of commands/$cmd.md name. Add each one to the phase's '$steps_heading' list, so an agent without superpowers writes it too"
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
  report_kept_workdirs
  exit 1
fi
printf '\n'
if [ "$KEEP_WORKDIR" = "1" ]; then
  report_kept_workdirs
  exit 0
fi
# Every earlier exit path is a failure that left its workdir on disk, so
# reaching here with no failed assertion is the one outcome that discards them.
rm -rf "$WORK" "$WORK_COPILOT"
printf 'Workdirs removed. Set KEEP_WORKDIR=1 to keep them.\n'
exit 0
