# Example: Broken Link Audit

This directory holds one recorded run of the specflow pipeline, from
constitution through review, on a small Python CLI. Read it to see what each
stage writes into a real project.

## How it was recorded

`scripts/e2e-agent-claude.sh` drove Claude Code 2.1.282 in headless mode on
2026-09-27, one `claude -p` session per stage, with `E2E_MODEL=claude-sonnet-5`.
Stages 1 to 3 ran at commit `3697466`. Stage 4 stopped waiting for a shell
approval that headless mode cannot give, so stages 4 to 7 resumed the same
project at commit `f17fcc7`, which adds the shell allowlist to the driver. Both
commits install the same extension payload. That payload also carried two
uncommitted documentation lines: the resources link in `SKILL.md` and the
sample `spec:` value in `references/workflow-guide.md`.

The stage prompts live in `scripts/e2e-stages.sh`. Two of them tell the agent
that no user will answer: brainstorm answers its own questions, and execute
treats each phase checkpoint as confirmed. The run passed all 39 of the
driver's assertions, including 7 idempotence checks.

Every file here is the agent's output, copied without edits. The copy leaves
out the project's `.claude/`, `.specify/` apart from the constitution, `.venv/`,
the transcripts, and `__pycache__/`. `analyze-gate.md` records two later
sessions against a copy of the same project.

## The feature

`link-audit` walks the Markdown files `git ls-files` reports, resolves each
inline link target against the file system, prints the unresolved ones, and
exits 1 when any is unresolved. Heading anchors resolve against the slugified
headings of the target file. External schemes are skipped, so the scan needs no
network.

## The file set

| Path | Written by | Holds |
|------|-----------|-------|
| `.specify/memory/constitution.md` | `/speckit.constitution` | Five principles, quality standards, constraints |
| `specs/001-link-audit/spec.md` | `/speckit.specify`, `/speckit.specflow.brainstorm`, `/speckit.specflow.review` | 3 user stories, 13 FR, 4 SC, Threat Model, Traceability, Changelog, Q1 to Q7 |
| `decisions.md` | `/speckit.specflow.brainstorm` | ADR-0001 to ADR-0005, one per resolved question |
| `specs/001-link-audit/plan.md` | `/speckit.plan` | Technical context, constitution check, structure, with `research.md`, `data-model.md`, `quickstart.md`, `contracts/` |
| `specs/001-link-audit/tasks.md` | `/speckit.tasks` | 42 tasks over 6 phases |
| `specs/001-link-audit/.analyzed` | `/speckit.analyze` | Empty marker: the report held zero critical findings |
| `specs/001-link-audit/progress.yml` | `/speckit.specflow.execute` | Per-phase task state, gate dates |
| `specs/001-link-audit/handoff.md` | `/speckit.specflow.execute` | The execute session's hand-off |
| `src/link_audit/`, `tests/` | `/speckit.specflow.execute` | The CLI and its 29 pytest tests |
| `specs/001-link-audit/review-findings.json` | `/speckit.specflow.review` | R-001 to R-004, all open, verdict `BLOCK` |
| `specs/001-link-audit/checklists/` | `/speckit.specify`, `/speckit.specflow.review` | The requirements checklist, the review checklist |
| `analyze-gate.md` | Two sessions after the run | The `ANALYZE_REQUIRED` stop, then the `ANALYZE_CRITICAL` refusal |

The run did not include `/speckit.clarify`, so there is no `.clarified`
marker. Q6 and Q7 are open because review added them after brainstorm.

## Check it

Run the recorded test suite, then score the feature directory:

```bash
cd specflow/examples/link-audit
python3 -m pytest -q
cd ../..
python3 scripts/score-artifacts.py examples/link-audit/specs/001-link-audit
```

The tests print `29 passed`. The report scores 100 on spec sections,
traceability, and the threat model, with 42 of 43 checkbox lines carrying a task
id. The unnumbered line is a format example the agent kept from the template.
`.github/workflows/score-artifacts.yml` asserts these values on every pull
request that touches the templates, the commands, the scorer, or `examples/`.
