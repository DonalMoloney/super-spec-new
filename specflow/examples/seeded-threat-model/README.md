# seeded-threat-model

This directory is a feature directory for `specflow/scripts/score-artifacts.py` to
score. It is a copy of `../static-landing-page/specs/001-static-landing-page/` with one
deliberate flaw. The `Spoofing` row's Mitigation cell in the `## Threat Model` table in
`spec.md` was emptied, while every other row keeps its filled or `N/A` cell. The scorer
must report `threat_model.missing_mitigation` as `["Spoofing"]`, 5 mitigated of 6 rows,
and must score every other dimension the same as the landing page golden. Reproduce
with:

```bash
python3 specflow/scripts/score-artifacts.py specflow/examples/seeded-threat-model
```
