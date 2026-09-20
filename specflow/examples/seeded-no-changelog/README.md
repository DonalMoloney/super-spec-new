# seeded-no-changelog

This directory is a feature directory for `specflow/scripts/score-artifacts.py` to
score. It is a copy of `../static-landing-page/specs/001-static-landing-page/` with one
deliberate flaw. A `## Changelog` heading and table header were appended to `spec.md`
with zero version rows beneath them. The landing page golden carries no `## Changelog`
heading at all, which the scorer treats as a changelog not yet started and scores 100;
this fixture instead has the heading present with nothing recorded under it, which the
scorer must score 0. The scorer must report `changelog.present` as `true`,
`changelog.rows` as `0`, and must score every other dimension the same as the landing
page golden. Reproduce with:

```bash
python3 specflow/scripts/score-artifacts.py specflow/examples/seeded-no-changelog
```
