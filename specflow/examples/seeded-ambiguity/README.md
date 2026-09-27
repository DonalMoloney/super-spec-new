# seeded-ambiguity

This directory is a feature directory for `specflow/scripts/score-artifacts.py` to
score. It is a copy of `../link-audit/specs/001-link-audit/`, the recorded run,
with one deliberate flaw. `spec.md` no longer states which duplicate heading keeps the bare
slug: "in order of appearance" was deleted from the Q1 resolution and FR-005, and
the Edge Cases line now says "the duplicates get a numeric suffix" instead of "the
second and later occurrences". `.seeded-ambiguity` names the phrase `order`. No
`## Open Questions` row names it, so the scorer must report
`seeded_ambiguity.surfaced` as `false` with a score of 0. A brainstorm or clarify
run that raises the suffix order as a question lifts the score to 100. The match is
a case-insensitive substring, so a row that says "order" for another reason also
counts. Reproduce with:

```bash
python3 specflow/scripts/score-artifacts.py specflow/examples/seeded-ambiguity
```
