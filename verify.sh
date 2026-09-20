#!/usr/bin/env bash
# Runs the checks .github/workflows/ci.yml runs, in its order, stopping at the
# first failure. tests/test_ci_parity.py compares the tables below with that
# workflow and fails when the two drift apart.
set -uo pipefail

PYTHON_FLOOR_MAJOR=3
PYTHON_FLOOR_MINOR=9
CI_PYTHON_VERSION="3.12"

# Each entry is "ci.yml step name|tool|working directory|command", with the name,
# directory and command copied verbatim. The tool field names the program the
# command needs beyond python3 and bash, and is empty when the command needs
# neither. A step whose tool is off PATH reports as skipped instead of running.
# The order matches ci.yml, and tests/test_ci_parity.py holds it there.
STEPS=(
  "Validate metadata and docs||specflow|python3 scripts/validate-extension-metadata.py"
  "Validate release archive||specflow|python3 scripts/validate-release-archive.py"
  "Script tests||specflow|python3 -m pytest scripts/tests -q"
  "Review findings validator tests||.|python3 -m pytest .claude/review/tests -q"
  "Divergence measurer tests||.|python3 -m pytest .claude/divergence/tests -q"
  "CI parity tests||.|python3 -m pytest tests -q"
  "Hook tests||.|bash .claude/hooks/tests/run.sh"
  "Lint Markdown against the documentation standard||.|python3 specflow/scripts/lint-standards.py"
  "Shellcheck|shellcheck|.|shellcheck -S warning verify.sh .claude/hooks/*.sh .claude/hooks/tests/run.sh specflow/scripts/*.sh"
  "Ruff|ruff|.|ruff check specflow/scripts .claude/review .claude/divergence"
  "Structural smoke test||specflow|bash scripts/e2e-smoke.sh"
  "Agent e2e dry run against the example snapshot||specflow|E2E_DRY_RUN=1 bash scripts/e2e-agent-claude.sh"
)

# Each entry is "ci.yml step name|why this script leaves the step to CI".
# A step belongs here when running it on a developer machine is wrong, not when
# a tool is absent; the tool field above covers absence. Every name here prints
# at the end, so a reader knows what went unchecked.
SKIPPED=(
  "Install test dependencies|installs ruff and pytest into the caller's Python; run it once by hand"
  "Verify install with latest spec-kit|downloads spec-kit over the network"
)

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v python3 >/dev/null 2>&1; then
  printf 'python3 is not on PATH; every step below needs it. Install Python %d.%d or newer.\n' \
    "$PYTHON_FLOOR_MAJOR" "$PYTHON_FLOOR_MINOR" >&2
  exit 1
fi

python_version="$(python3 -c 'import sys; print("%d.%d.%d" % sys.version_info[:3])')"
if ! python3 -c "import sys; raise SystemExit(0 if sys.version_info[:2] >= ($PYTHON_FLOOR_MAJOR, $PYTHON_FLOOR_MINOR) else 1)"; then
  printf 'python3 is %s; the suites need %d.%d or newer. Put a newer python3 first on PATH.\n' \
    "$python_version" "$PYTHON_FLOOR_MAJOR" "$PYTHON_FLOOR_MINOR" >&2
  exit 1
fi

printf 'python3 %s, against %s in CI.\n\n' "$python_version" "$CI_PYTHON_VERSION"

skipped_for_tool=()

for entry in "${STEPS[@]}"; do
  name="${entry%%|*}"
  remainder="${entry#*|}"
  tool="${remainder%%|*}"
  remainder="${remainder#*|}"
  workdir="${remainder%%|*}"
  step_command="${remainder#*|}"

  printf '==> %s\n' "$name"
  if [ -n "$tool" ] && ! command -v "$tool" >/dev/null 2>&1; then
    printf 'skipped: %s is not on PATH.\n\n' "$tool"
    skipped_for_tool+=("$name|$tool")
    continue
  fi

  if (cd "$repo_root/$workdir" && bash -c "$step_command"); then
    printf '\n'
  else
    status=$?
    printf '\n%s exited %d. Command: (cd %s && %s)\n' \
      "$name" "$status" "$workdir" "$step_command" >&2
    exit "$status"
  fi
done

# Reaching here means no step failed, so every step that ran also passed.
printf '%d passed, %d skipped, %d left to CI, of the %d steps ci.yml runs.\n' \
  "$(( ${#STEPS[@]} - ${#skipped_for_tool[@]} ))" "${#skipped_for_tool[@]}" \
  "${#SKIPPED[@]}" "$(( ${#STEPS[@]} + ${#SKIPPED[@]} ))"
if [ "${#skipped_for_tool[@]}" -gt 0 ]; then
  printf 'Skipped, tool not on PATH:\n'
  for entry in "${skipped_for_tool[@]}"; do
    printf '  %s: install %s\n' "${entry%%|*}" "${entry#*|}"
  done
fi
printf 'Left to CI:\n'
for entry in "${SKIPPED[@]}"; do
  printf '  %s: %s\n' "${entry%%|*}" "${entry#*|}"
done
