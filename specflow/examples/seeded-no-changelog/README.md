# seeded-no-changelog

This directory is a feature directory for `specflow/scripts/score-artifacts.py` to
score. It is a copy of `../link-audit/specs/001-link-audit/`, the recorded run,
with one deliberate flaw. All three version rows were deleted from the `## Changelog` table in
`spec.md`, leaving the heading and the table header. The recorded run carries three
rows and scores 100; a heading with nothing recorded under it must score 0. The
scorer must report `changelog.present` as `true`, `changelog.rows` as `0`, and must
score every other dimension the same as the recorded run. Reproduce with:

```bash
python3 specflow/scripts/score-artifacts.py specflow/examples/seeded-no-changelog
```
