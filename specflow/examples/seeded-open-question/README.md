# seeded-open-question

This directory is a feature directory for `specflow/scripts/score-artifacts.py` to
score. It is a copy of `../link-audit/specs/001-link-audit/`, the recorded run,
with one deliberate flaw. The Status cells of Q6 and Q7 in the `## Open Questions` table
of `spec.md` were set back from `Resolved` to `Open`, while the `.clarified` marker
beside `spec.md` stays. A clarified spec with open questions is the gap. The scorer
must report `open_questions.unresolved` as `["Q6", "Q7"]`, 5 resolved of 7
questions, and must score every other dimension the same as the recorded run. Reproduce with:

```bash
python3 specflow/scripts/score-artifacts.py specflow/examples/seeded-open-question
```
