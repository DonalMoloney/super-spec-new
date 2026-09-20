# seeded-missing-test

This directory is a feature directory for `specflow/scripts/score-artifacts.py` to
score. It is a copy of `../static-landing-page/specs/001-static-landing-page/` with one
deliberate flaw. The `FR-001` row's Test cell in the `## Traceability` table in
`spec.md` was changed from `` `checklists/review.md::FR-001` `` to
`` `checklists/review.md::FR-999` ``, an anchor `checklists/review.md` never contains.
The cell stays filled, so `traceability.score` is unaffected; only `test_exists`, which
checks that the named anchor resolves inside the named file, catches the break. The
scorer must report `test_exists.missing` as `["FR-001"]`, 22 found of 23 tests, and
must score every other dimension the same as the landing page golden. Reproduce with:

```bash
python3 specflow/scripts/score-artifacts.py specflow/examples/seeded-missing-test
```
