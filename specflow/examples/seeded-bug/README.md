# seeded-bug

This directory is a feature directory for `specflow/scripts/score-artifacts.py` to
score. It is a copy of `../static-landing-page/specs/001-static-landing-page/` with one
deliberate flaw. The `SC-003` row was deleted from the `## Traceability` table in
`spec.md`, while `SC-003` remains declared under Success Criteria. The scorer must
report `traceability.untraced` as `["SC-003"]`, 22 traced of 23 criteria, and must score
every other dimension the same as the landing page golden. Reproduce with:

```bash
python3 specflow/scripts/score-artifacts.py specflow/examples/seeded-bug
```
