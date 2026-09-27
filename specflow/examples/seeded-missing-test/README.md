# seeded-missing-test

This directory is a feature directory for `specflow/scripts/score-artifacts.py` to
score. It is a copy of `../link-audit/specs/001-link-audit/`, the recorded run,
with one deliberate flaw. The `FR-001` row's Test cell in the `## Traceability` table in
`spec.md` was changed from `test_scans_only_git_ls_files_output` to
`` `checklists/review.md::FR-999` ``, an anchor `checklists/review.md` never contains.
The cell stays filled, so `traceability.score` is unaffected; only `test_exists`,
which checks that a `file::anchor` reference resolves inside the named file, catches
the break. The scorer must report `test_exists.missing` as `["FR-001"]`, 0 found of
1 reference, and must score every other dimension the same as the recorded run. Reproduce with:

```bash
python3 specflow/scripts/score-artifacts.py specflow/examples/seeded-missing-test
```
