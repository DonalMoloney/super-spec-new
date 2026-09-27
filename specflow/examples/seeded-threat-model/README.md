# seeded-threat-model

This directory is a feature directory for `specflow/scripts/score-artifacts.py` to
score. It is a copy of `../link-audit/specs/001-link-audit/`, the recorded run,
with one deliberate flaw. The `Spoofing` row's Mitigation cell in the `## Threat Model`
table in `spec.md` was emptied, while every other row keeps its filled or `N/A` cell.
The scorer must report `threat_model.missing_mitigation` as `["Spoofing"]`, 5
mitigated of 6 rows, and must score every other dimension the same as the recorded
run. Reproduce with:

```bash
python3 specflow/scripts/score-artifacts.py specflow/examples/seeded-threat-model
```
