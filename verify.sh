#!/usr/bin/env bash
# Runs the checks .github/workflows/ci.yml runs, in its order, stopping at the
# first failure. tests/test_ci_parity.py compares the tables below with that
# workflow and fails when the two drift apart.
set -uo pipefail

PYTHON_FLOOR_MAJOR=3
PYTHON_FLOOR_MINOR=9
CI_PYTHON_VERSION="3.12"

# Each entry is "ci.yml step name|working directory|command", copied verbatim.
# A step belongs here when python3, bash and this checkout are all it needs.
STEPS=(
  "Validate metadata and docs|specflow|python3 scripts/validate-extension-metadata.py"
  "Validate release archive|specflow|python3 scripts/validate-release-archive.py"
  "Script tests|specflow|python3 -m pytest scripts/tests -q"
  "Review findings validator tests|.|python3 -m pytest .claude/review/tests -q"
  "Divergence measurer tests|.|python3 -m pytest .claude/divergence/tests -q"
  "CI parity tests|.|python3 -m pytest tests -q"
  "Hook tests|.|bash .claude/hooks/tests/run.sh"
  "Lint Markdown against the documentation standard|.|python3 specflow/scripts/lint-standards.py"
  "Structural smoke test|specflow|bash scripts/e2e-smoke.sh"
  "Agent e2e dry run against the example snapshot|specflow|E2E_DRY_RUN=1 bash scripts/e2e-agent-claude.sh"
)

# Each entry is "ci.yml step name|why this script leaves the step to CI".
# Every name here prints at the end, so a reader knows what went unchecked.
SKIPPED=(
  "Install test dependencies|installs into the caller's Python; run it once by hand"
  "Shellcheck|needs the shellcheck binary, which the CI runner ships"
  "Ruff|needs the ruff binary from requirements-dev.txt"
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

for entry in "${STEPS[@]}"; do
  name="${entry%%|*}"
  remainder="${entry#*|}"
  workdir="${remainder%%|*}"
  step_command="${remainder#*|}"

  printf '==> %s\n' "$name"
  if (cd "$repo_root/$workdir" && bash -c "$step_command"); then
    printf '\n'
  else
    status=$?
    printf '\n%s exited %d. Command: (cd %s && %s)\n' \
      "$name" "$status" "$workdir" "$step_command" >&2
    exit "$status"
  fi
done

printf '%d of the %d steps ci.yml runs passed.\n' \
  "${#STEPS[@]}" "$(( ${#STEPS[@]} + ${#SKIPPED[@]} ))"
printf 'Left to CI:\n'
for entry in "${SKIPPED[@]}"; do
  printf '  %s: %s\n' "${entry%%|*}" "${entry#*|}"
done
