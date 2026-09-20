# seeded-open-question

This directory is a feature directory for `specflow/scripts/score-artifacts.py` to
score. It is a copy of `../static-landing-page/specs/001-static-landing-page/` with one
deliberate flaw. A `.clarified` marker file was added beside `spec.md`, while `spec.md`
itself is untouched: two of the three rows in the `## Open Questions` table, OQ-001 and
OQ-002, still read `Open` rather than `Resolved`. The scorer must report
`open_questions.unresolved` as `["OQ-001", "OQ-002"]`, 1 resolved of 3 questions, and
must score every other dimension the same as the landing page golden. Reproduce with:

```bash
python3 specflow/scripts/score-artifacts.py specflow/examples/seeded-open-question
```
