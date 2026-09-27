# Example: Broken Link Audit

This directory holds one recorded run of the specflow pipeline on a small
Python CLI, from constitution through a review that blocked, then the clarify,
remediation, and re-review sessions that cleared the analyze gate. Read it to
see what each stage writes into a real project.

## How it was recorded

`scripts/e2e-agent-claude.sh` drove Claude Code 2.1.282 in headless mode on
2026-09-27, one `claude -p` session per stage, with `E2E_MODEL=claude-sonnet-5`.
Stages 1 to 3 ran at commit `3697466`. Stage 4 stopped waiting for a shell
approval that headless mode cannot give, so stages 4 to 7 resumed the same
project at commit `f17fcc7`. It carries the shell allowlist from `2d7a76d` and a
fix to the stage 3 assertion. Both commits install the same extension payload. That payload also carried two
uncommitted documentation lines: the resources link in `SKILL.md` and the
sample `spec:` value in `references/workflow-guide.md`.

The `--dev` install copied this directory's earlier hand-built version into
the project with the rest of `examples/`. The stage 4 session found it and read
its `plan.md`, and one sentence of that file reappears verbatim in the recorded
`plan.md`. A catalog install strips `examples/`, so a user's run cannot see it.

The stage prompts live in `scripts/e2e-stages.sh`. Two of them tell the agent
that no user will answer: brainstorm answers its own questions, and execute
treats each phase checkpoint as confirmed. The run passed all 39 of the
driver's assertions, including 7 idempotence checks. The driver's allowlist did
not yet name the gate scripts, so stage 6 could not run `write-marker.sh` and
wrote its `.analyzed` with a file write instead. Commit `fb38d0f` adds the
gate scripts to the list.

The seven stages ended with review verdict `BLOCK`. Seven more headless
sessions on the same model continued a copy of the project: execute stopped,
analyze refused the marker, clarify resolved the two questions review raised
and wrote `.clarified`, execute fixed the four findings, review returned
`CLEAN`, and a last analyze wrote `.analyzed`. `analyze-gate.md` records each
session's final message and the one that failed on a network error. These
sessions ran outside the driver with its flags and allowlist plus the gate
scripts, so both markers here come from `write-marker.sh`. Clarify ran after
review because the driver's seven stages have no clarify stage.

Every file here is the agent's output from the end of those sessions, copied
without edits. The copy leaves out the project's `.claude/`, `.specify/` apart
from the constitution, `.venv/`, the transcripts, and `__pycache__/`.

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
| `specs/001-link-audit/spec.md` | `/speckit.specify`, `/speckit.specflow.brainstorm`, `/speckit.specflow.review`, `/speckit.clarify` | 3 user stories, 15 FR, 4 SC, Threat Model, Traceability, Changelog, Q1 to Q7 resolved |
| `specs/001-link-audit/.clarified` | `/speckit.clarify` | Empty marker: the spec holds no clarification marker |
| `decisions.md` | `/speckit.specflow.brainstorm` | ADR-0001 to ADR-0005, one per resolved question |
| `specs/001-link-audit/plan.md` | `/speckit.plan` | Technical context, constitution check, structure, with `research.md`, `data-model.md`, `quickstart.md`, `contracts/` |
| `specs/001-link-audit/tasks.md` | `/speckit.tasks`, `/speckit.specflow.tasks` | 59 tasks over 7 phases; phase 7 fixes the review findings |
| `specs/001-link-audit/.analyzed` | `/speckit.analyze` | Empty marker: the last report held zero critical findings |
| `specs/001-link-audit/progress.yml` | `/speckit.specflow.execute` | Per-phase task state, gate dates |
| `specs/001-link-audit/handoff.md` | `/speckit.specflow.execute` | The execute session's hand-off |
| `src/link_audit/`, `tests/` | `/speckit.specflow.execute` | The CLI and its 37 pytest tests |
| `specs/001-link-audit/review-findings.json` | `/speckit.specflow.review` | R-001 to R-004, all fixed, verdict `CLEAN` |
| `specs/001-link-audit/checklists/` | `/speckit.specify`, `/speckit.specflow.review` | The requirements checklist, the review checklist |
| `analyze-gate.md` | Seven sessions after the run | The `ANALYZE_REQUIRED` stop, the `ANALYZE_CRITICAL` refusal, the fixes, the rerun that cleared the gate |

## Check it

Run the recorded test suite, then score the feature directory:

```bash
cd specflow/examples/link-audit
python3 -m pytest -q
cd ../..
python3 scripts/score-artifacts.py examples/link-audit/specs/001-link-audit
```

The tests print `37 passed`. The report scores 100 on spec sections,
traceability, the threat model, and open questions, with 59 of 60 checkbox
lines carrying a task id. The unnumbered line is a format example the agent kept from the template.
`.github/workflows/score-artifacts.yml` asserts these values on every pull
request that touches the templates, the commands, the scorer, or `examples/`.
