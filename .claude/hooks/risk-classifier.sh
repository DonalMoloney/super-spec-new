#!/usr/bin/env bash
# Prints HIGH or STANDARD for the diff between a base ref and HEAD. The review
# pipeline runs the critic stage and the cross-model panel only on HIGH.
# Thresholds come from imporvements/imporvements2.md section 3.10.
set -euo pipefail
SENSITIVE_DIRS='(^|/)(auth|payments|billing|migrations|infra|secrets|crypto)/'
DEPENDENCY_MANIFESTS='(package-lock\.json|yarn\.lock|Cargo\.lock|poetry\.lock|go\.sum|requirements.*\.txt)$'
MAX_STANDARD_LINES=400
MAX_STANDARD_FILES=15
base="${1:-main}"
if ! git rev-parse --verify --quiet "$base^{commit}" >/dev/null; then
  echo "risk-classifier: base ref '$base' does not resolve to a commit; expected a ref this repository contains, such as main. Pass an existing ref." >&2
  exit 2
fi
changed_files="$(git diff --name-only "$base"...HEAD)"
if printf '%s\n' "$changed_files" | grep -Eq "$SENSITIVE_DIRS"; then echo HIGH; exit 0; fi
if printf '%s\n' "$changed_files" | grep -Eq "$DEPENDENCY_MANIFESTS"; then echo HIGH; exit 0; fi
# Counts stay integers, so bash arithmetic replaces the bc call in the source draft.
file_count=0
changed_lines=0
while read -r added removed path; do
  [ -n "$path" ] || continue
  file_count=$((file_count + 1))
  case "$added$removed" in
    *[!0-9]*) continue ;; # numstat reports a dash instead of a count for a binary file
  esac
  changed_lines=$((changed_lines + added + removed))
done < <(git diff --numstat "$base"...HEAD)
if [ "$changed_lines" -gt "$MAX_STANDARD_LINES" ] || [ "$file_count" -gt "$MAX_STANDARD_FILES" ]; then
  echo HIGH
  exit 0
fi
echo STANDARD
