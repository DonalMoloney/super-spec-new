# seeded-open-question

This directory is a feature directory for `specflow/scripts/score-artifacts.py` to
score. It is a copy of `../link-audit/specs/001-link-audit/`, the recorded run,
with one deliberate flaw. A `.clarified` marker file was added beside `spec.md`, while
`spec.md` itself is untouched. Two of the seven rows in the `## Open Questions` table,
Q6 and Q7, still read `Open`, because review added them after brainstorm. The scorer
must report `open_questions.unresolved` as `["Q6", "Q7"]`, 5 resolved of 7
questions, and must score every other dimension the same as the recorded run. Reproduce with:

```bash
python3 specflow/scripts/score-artifacts.py specflow/examples/seeded-open-question
```
