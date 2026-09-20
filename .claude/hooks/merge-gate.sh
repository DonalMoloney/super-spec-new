#!/usr/bin/env bash
# The gate ships in the extension archive; ADR-0025 records the move.
exec "$(dirname "$0")/../../specflow/gates/bash/merge-gate.sh" "$@"
