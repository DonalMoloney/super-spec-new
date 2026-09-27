# seeded-bug

This directory is a feature directory for `specflow/scripts/score-artifacts.py` to
score. It is a copy of `../link-audit/specs/001-link-audit/`, the recorded run,
with one deliberate flaw. The `SC-003` row was deleted from the `## Traceability` table in
`spec.md`, while `SC-003` stays declared under Success Criteria. The scorer must
report `traceability.untraced` as `["SC-003"]`, 18 traced of 19 criteria, and must
score every other dimension the same as the recorded run. Reproduce with:

```bash
python3 specflow/scripts/score-artifacts.py specflow/examples/seeded-bug
```
