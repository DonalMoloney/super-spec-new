# Example: Upstream comparison

This directory records one live run comparing this fork's specflow pipeline
against upstream's superspec pipeline on the same two seeded inputs, so a
claim about the fork's output rests on an outcome rather than a divergence
percentage.

## How it was recorded

`scripts/compare-upstream.sh` ran on 2026-09-28 with `E2E_MODEL=claude-sonnet-5`
and `E2E_MAX_BUDGET_USD=2.00`, comparing this fork at commit `bd78374` against
upstream `WangX0111/superspec` at commit `c20ac6c1` (upstream's `HEAD` on that
date). Each probe ran 3 times per pipeline, 12 `claude -p` calls in total, at
a combined cost of $5.85. Every call finished with status `ok`: no run hit
the budget cap or an install failure. `results.json` holds each run's cost
and outcome.

## The spec probe

Both brainstorm commands ran on `examples/seeded-ambiguity/spec.md`, whose
duplicate-heading suffix order is left unstated. `score-artifacts.py`'s
`seeded_ambiguity` dimension scores the resulting spec 100 when an Open
Questions row raises the order, 0 when it does not.

| Pipeline | Hits | Scores |
|---|---|---|
| specflow | 1 of 3 | 100, 0, 0 |
| superspec | 1 of 3 | 100, 0, 0 |

Tied. Catching this ambiguity did not depend on which pipeline ran the
brainstorm.

## The review probe

Both review commands ran on `examples/seeded-review-bug/`, a copy of
`link-audit/` whose `resolver.py` line 87 catch clause drops
`UnicodeDecodeError`, breaking FR-012, with the copied tests still passing.
A run counts as a hit when its findings name the planted file and line.

| Pipeline | Hits |
|---|---|
| specflow | 2 of 3 |
| superspec | 1 of 3 |

Specflow found the planted fault more often, but the comparison is not
blind: `examples/seeded-review-bug/specs/001-link-audit/tasks.md` keeps its
R-003 section (T054-T057), which describes the exact `OSError`/
`UnicodeDecodeError` handling the planted fault removes. A reviewer reading
`tasks.md` alongside the diff has a direct pointer to the fault that a blind
code review would not have. The probe measures whether each pipeline's
review command uses that context, not whether either pipeline can spot the
bug unaided.

## Reproducing it

```bash
cd specflow
E2E_MODEL=claude-sonnet-5 E2E_MAX_BUDGET_USD=2.00 bash scripts/compare-upstream.sh
```

`E2E_DRY_RUN=1` runs the same script for free and writes six entries marked
`dry-run` per probe instead of a live result.
