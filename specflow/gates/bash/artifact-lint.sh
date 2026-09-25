#!/usr/bin/env bash
# PostToolUse hook (matcher: Edit|Write). Validates the structure of a just
# edited spec.md / plan.md / tasks.md / checklist-*.md against specflow's templates. Exit 2
# feeds the findings back to Claude so it fixes them before moving on.
# Required sections mirror the *(mandatory)* headings in specflow/templates/.
set -euo pipefail
input="$(cat)"
path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')"
[ -n "$path" ] && [ -f "$path" ] || exit 0
project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)"
project_root="$(cd "$project_root" && pwd -P)"
resolved="$(cd "$(dirname "$path")" && pwd -P)/$(basename "$path")"
case "$resolved" in
  "$project_root"/*) ;;
  *) echo "ARTIFACT LINT: skipped $path; it sits outside $project_root." >&2; exit 0 ;;
esac
relative="${resolved#"$project_root"/}"
fail=0
err(){ echo "ARTIFACT LINT ($(basename "$path")): $1" >&2; fail=1; }
require_sections(){ for s in "$@"; do grep -qF "$s" "$path" || err "missing section: $s"; done; }
# spec-kit generates an artifact into specs/NNN-name/. A file elsewhere carrying
# one of those names, such as the commands/tasks.md contract, is not one.
case "$relative" in
  specs/[0-9][0-9][0-9]-*/*|*/specs/[0-9][0-9][0-9]-*/*) artifact_name="$(basename "$path")" ;;
  *) artifact_name="" ;;
esac
case "$artifact_name" in
  spec.md)
    require_sections "## User Scenarios & Testing" "## Requirements" "## Success Criteria"
    feature_dir="$(dirname "$path")"
    if [ -f "$feature_dir/.clarified" ] && grep -q 'NEEDS CLARIFICATION' "$path"; then
      err "still has NEEDS CLARIFICATION markers after the clarify gate"
    fi
    # An invented Traceability Test name passes conformance scoring silently;
    # check it once the analyze gate confirms the spec is no longer a draft.
    if [ -f "$feature_dir/.analyzed" ]; then
      trace_rows="$(awk '/^## Traceability/{f=1;next} /^## /{f=0} f && /^\|/' "$path")"
      while IFS= read -r row; do
        [ -n "$row" ] || continue
        criterion="$(printf '%s' "$row" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2); print $2}')"
        case "$criterion" in
          FR-*|SC-*) ;;
          *) continue ;;
        esac
        test_name="$(printf '%s' "$row" | awk -F'|' '{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$3); print $3}')"
        test_name="${test_name#\`}"
        test_name="${test_name%\`}"
        if [ -z "$test_name" ]; then
          err "$criterion: Traceability row has no Test name"
          continue
        fi
        file_part="${test_name%%::*}"
        ident_part=""
        [ "$file_part" = "$test_name" ] || ident_part="${test_name#*::}"
        resolved_file=""
        for candidate in "$feature_dir/$file_part" "$project_root/$file_part" "$file_part"; do
          if [ -f "$candidate" ]; then
            resolved_file="$candidate"
            break
          fi
        done
        if [ -z "$resolved_file" ]; then
          err "$criterion: Traceability names '$test_name', but $file_part does not exist"
          continue
        fi
        if [ -n "$ident_part" ]; then
          case "$file_part" in
            *.py) needle="def ${ident_part}(" ;;
            *) needle="$ident_part" ;;
          esac
          grep -qF "$needle" "$resolved_file" \
            || err "$criterion: Traceability names '$test_name', but '$ident_part' is absent from $file_part"
        fi
      done <<TRACEOF
$trace_rows
TRACEOF
    fi
    ;;
  plan.md)
    require_sections "## Summary" "## Technical Context" "## Constitution Check"
    ;;
  checklist-*.md)
    grep -Eq '^[[:space:]]*[-*+][[:space:]]+\[[ xX]\]([[:space:]]|$)' "$path" || err "no checkbox lines (expected '- [ ] ...' or '- [x] ...')"
    ;;
  tasks.md)
    grep -Eq '^- \[[ xX]\] T[0-9]{3}' "$path" || err "no task lines with stable IDs (expected '- [ ] T001 ...')"
    # [P] in prose (the task-format legend) is fine; on a checkbox line it must follow a T-id.
    if grep -E '^- \[[ xX]\].*\[P\]' "$path" | grep -vqE '^- \[[ xX]\] T[0-9]{3}'; then
      err "malformed [P] marker: a checkbox line with [P] must start with '- [ ] TNNN'"
    fi
    # AGENTS.md: one outcome per task; a description that needs "and" is two tasks.
    compound="$(grep -E '^- \[[ xX]\] T[0-9]{3}' "$path" | sed -E 's/`[^`]*`//g' | grep -E '[[:space:]]and[[:space:]]' | head -n1 || true)"
    [ -z "$compound" ] || err "compound task: '$compound'. One outcome per task; split it at 'and'."
    # A regenerated tasks.md that drops a completed id orphans its progress.yml entry.
    progress="$(dirname "$path")/progress.yml"
    if [ -f "$progress" ]; then
      done_ids="$(grep -E '^[[:space:]]*T[0-9]{3}:[[:space:]]*complete[[:space:]]*$' "$progress" | tr -d '[:space:]' | cut -d: -f1 || true)"
      for id in $done_ids; do
        grep -Eq "(^|[^[:alnum:]])$id([^[:digit:]]|$)" "$path" \
          || err "progress.yml records $id complete, but $id is absent from tasks.md. Restore the id or clear its progress.yml entry."
      done
    fi
    ;;
  progress.yml)
    # The validator ships beside this hook under .claude/, so it resolves from $0
    # rather than from the consuming project's root.
    progress_validator="$(dirname "$0")/../../../.claude/review/validate-progress.py"
    if [ -f "$progress_validator" ] \
      && ! progress_out="$(python3 "$progress_validator" "$path" 2>&1)"; then
      err "$(printf '%s' "$progress_out" | sed "s|^$path: ||" | tr '\n' ';')"
    fi
    ;;
esac
# The lint lives under scripts/, which the archive strips, so a consuming project without it skips this check.
MARKDOWN_LINT="specflow/scripts/lint-standards.py"
case "$path" in
  *.md)
    if [ -f "$MARKDOWN_LINT" ] && ! lint_out="$(python3 "$MARKDOWN_LINT" "$path" 2>&1)"; then
      err "$(printf '%s' "$lint_out" | grep -v '^FAIL:' | sed "s|^$path:||" | tr '\n' ';')"
    fi
    ;;
esac
[ "$fail" -eq 0 ] || exit 2
exit 0
