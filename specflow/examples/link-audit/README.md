# Example: Broken Link Audit

This directory shows the artifact set the specflow pipeline produces for one
small CLI feature, from constitution through review.

**This snapshot was constructed, not recorded.** It was written by resolving the
templates in `specflow/templates/` and the gate rules in
`specflow/references/workflow-guide.md` by hand, because no API key was
available to drive a live agent run. Every file here shows what the pipeline is
defined to produce. None of it is evidence that a run produced it. Read it as a
worked example of the artifact shapes, not as a transcript. The scores in
`.github/workflows/score-artifacts.yml` grade these shapes, so a template change
that this directory no longer matches is a signal to rebuild it.

## The feature

`link-audit` is a Python CLI that walks the Markdown files `git ls-files`
reports, resolves each inline link target against the file system, prints the
unresolved ones, exits 1 when any is unresolved. Heading anchors resolve against
the slugified headings of the target file. External schemes are skipped, so the
scan needs no network.

The feature is not built here. This directory holds its specification artifacts
only; the paths its artifacts name, such as `src/link_audit/scanner.py`, belong
to the consuming project the pipeline would have driven.

## The file set

| Path | Written by | Holds |
|------|-----------|-------|
| `.specify/memory/constitution.md` | `/speckit.constitution` | Five principles, the stack table, the workflow rules |
| `specs/001-link-audit/spec.md` | `/speckit.specify`, then `/speckit.specflow.brainstorm` | Three user stories, 12 FR, 4 SC, Threat Model, Traceability, Changelog |
| `specs/001-link-audit/.clarified` | `/speckit.clarify` | Empty marker: the spec carries no `NEEDS CLARIFICATION` |
| `specs/001-link-audit/plan.md` | `/speckit.plan` | Technical context, constitution check, execution strategy |
| `specs/001-link-audit/tasks.md` | `/speckit.specflow.tasks` | 35 tasks over 6 phases, with the Task Verification table |
| `specs/001-link-audit/.analyzed` | `/speckit.analyze` | Empty marker: the second analyze run found zero critical inconsistencies |
| `specs/001-link-audit/progress.yml` | `/speckit.specflow.execute` | Per-phase task state, the gate dates |
| `specs/001-link-audit/review-findings.json` | `/speckit.specflow.review` | R-001 fixed, R-002 open, verdict `CONCERNS` |
| `specs/001-link-audit/checklists/` | `/speckit.checklist`, `/speckit.specflow.review` | The requirements checklist, the review checklist with its findings join |
| [`analyze-gate.md`](analyze-gate.md) | `/speckit.specflow.execute` | The `ANALYZE_REQUIRED` stop, then the rerun that cleared it |

## What joins to what

The artifacts are internally consistent, which is what makes the set worth
reading:

- Every `TNNN` id in `progress.yml` appears in `tasks.md`.
- Every test name in the spec's Traceability table appears in a `tasks.md` task line.
- Every `CHK` id in the review checklist's Review Findings table exists in that checklist.
- Every `R-NNN` id in that table exists in `review-findings.json`.
- R-001 appears in the spec's Open Questions table as Q4, per the review command's Process step 8.

## Score it

```bash
cd specflow
python3 scripts/score-artifacts.py examples/link-audit/specs/001-link-audit
```

The report scores 100 on spec sections, on traceability, on task ids, with zero
clarification markers. `.github/workflows/score-artifacts.yml` asserts those
four values on every pull request that touches the templates, the commands, the
scorer, or this directory.
