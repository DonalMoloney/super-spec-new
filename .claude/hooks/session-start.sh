#!/usr/bin/env bash
# SessionStart hook (matcher: resume, compact). Prints open questions, the
# current feature's progress summary, its next unchecked task, and its
# handoff notes so a resumed session skips rediscovering state. Always exits 0.
set -u
shopt -s nullglob
cat >/dev/null

project_root="$PWD"
best=""
candidates=("$project_root"/specs/*/progress.yml)
if [ "${#candidates[@]}" -gt 0 ]; then
  sorted=()
  while IFS= read -r line; do sorted+=("$line"); done < <(ls -t "${candidates[@]}")
  for candidate in "${sorted[@]}"; do
    if grep -q '^spec:' "$candidate" && grep -q '^phases:' "$candidate"; then
      best="$candidate"
      break
    fi
  done
fi

if [ -f "$project_root/open-questions.md" ]; then
  cat "$project_root/open-questions.md"
fi

if [ -n "$best" ]; then
  feature_dir="$(dirname "$best")"
  spec="$(grep '^spec:' "$best" | head -1 | sed 's/^spec:[[:space:]]*//')"
  status="$(grep '^status:' "$best" | head -1 | sed 's/^status:[[:space:]]*//')"
  phase="$(grep '^current_phase:' "$best" | head -1 | sed 's/^current_phase:[[:space:]]*//')"
  echo "spec: $spec status: $status current_phase: $phase"

  tasks_file="$feature_dir/tasks.md"
  if [ -f "$tasks_file" ]; then
    grep -m1 -E '^- \[ \] T[0-9]{3}' "$tasks_file"
  fi

  handoff_file="$feature_dir/handoff.md"
  if [ -f "$handoff_file" ]; then
    cat "$handoff_file"
  fi
fi

exit 0
