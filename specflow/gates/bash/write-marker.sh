#!/usr/bin/env bash
# Writes a feature's .clarified or .analyzed marker, and refuses while the
# artifact behind the marker still reports unresolved work. The Gate markers
# table in references/workflow-guide.md defines both markers.
# Exit codes: 0 marker written, 1 gate refused, 2 bad arguments or missing file.
set -euo pipefail
CLARIFICATION_MARKER='NEEDS CLARIFICATION'
# A finding row of spec-kit's analysis report: the third cell holds the severity.
CRITICAL_ROW='^[[:space:]]*\|[^|]*\|[^|]*\|[[:space:]]*CRITICAL[[:space:]]*\|'
if [ "$#" -ne 2 ]; then
  echo "write-marker: got $# argument(s); expected 2. Run write-marker.sh <feature-directory> clarified|analyzed." >&2
  exit 2
fi
feature_dir="$1"
marker_name="$2"
if [ ! -d "$feature_dir" ]; then
  echo "write-marker: '$feature_dir' is not a directory; expected a feature directory such as specs/001-user-login. Pass the directory holding spec.md." >&2
  exit 2
fi
case "$marker_name" in
  clarified)
    spec="$feature_dir/spec.md"
    if [ ! -f "$spec" ]; then
      echo "write-marker: '$spec' is missing; expected the feature's spec. Run /speckit.specify for this feature first." >&2
      exit 2
    fi
    unresolved="$(grep -c "$CLARIFICATION_MARKER" "$spec" || true)"
    if [ "$unresolved" -gt 0 ]; then
      echo "CLARIFY_INCOMPLETE: $spec holds $unresolved '$CLARIFICATION_MARKER' marker(s); expected 0. Resolve each one, then rerun /speckit.clarify." >&2
      exit 1
    fi
    ;;
  analyzed)
    report="$(cat)"
    critical="$(printf '%s\n' "$report" | grep -Ec "$CRITICAL_ROW" || true)"
    if [ "$critical" -gt 0 ]; then
      echo "ANALYZE_CRITICAL: the analysis report holds $critical CRITICAL finding(s); expected 0. Fix each one, then rerun /speckit.analyze." >&2
      exit 1
    fi
    ;;
  *)
    echo "write-marker: marker name is '$marker_name'; expected 'clarified' or 'analyzed'. Pass one of the two." >&2
    exit 2
    ;;
esac
touch "$feature_dir/.$marker_name"
echo "$feature_dir/.$marker_name"
