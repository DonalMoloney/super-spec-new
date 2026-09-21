# Files still close to upstream

Read this before picking a rewrite target. It names the shipped files whose shape
is still upstream superspec's, and lists the headings, functions, and manifest
keys inside each one that match upstream verbatim. `reference.md` records how far
each file has moved; this file records what has not moved.

Measured 2026-09-21 against upstream `c20ac6c1`, after G-47 rewrote all six of
the files below. A named unit counts as shared when it appears in the local file
and the upstream file with the same spelling.

## The closest six, before and after G-47

These six were the only shipped files below 50 percent real change. G-47 gave
each one the `prose-rephraser` or `script-refactorer` pass it had never had.

| File | Real before | Real after | Identical lines after | Units shared after |
|------|-------------|------------|-----------------------|--------------------|
| `templates/plan-template.md` | 21% | 23% | 103 of 133 (77%) | 12 of 13 headings |
| `templates/spec-template.md` | 33% | 38% | 123 of 197 (62%) | 15 of 19 headings |
| `templates/checklist-template.md` | 41% | 45% | 67 of 121 (55%) | 11 of 12 headings |
| `templates/constitution-template.md` | 44% | 48% | 65 of 126 (52%) | 15 of 17 headings |
| `templates/tasks-template.md` | 46% | 49% | 115 of 225 (51%) | 19 of 20 headings |
| `scripts/validate-release-archive.py` | 39% | 87% | 106 of 273 (39%) | 3 of 13 functions |

## Why a template moved 3 points and the script moved 48

A template's prose is a small part of its line count. G-47 counted what each
template's still-identical lines are made of:

| Template | Identical lines | Free prose | Frozen scaffolding |
|----------|-----------------|------------|--------------------|
| `tasks-template.md` | 115 | 26 | 89, of which 64 are blank |
| `spec-template.md` | 123 | 44 | 79 |
| `plan-template.md` | 103 | 24 | 78 |
| `checklist-template.md` | 67 | 10 | 57 |
| `constitution-template.md` | 65 | 3 | 62 |

Scaffolding is a heading, a blank line, a table row, a fenced block, or a
bracket placeholder. The contract freezes all of it: `artifact-lint.sh` and
`score-artifacts.py` grep the headings, and spec-kit fills the placeholders. A
prose pass reaches the rest, so `constitution-template.md` had 3 lines left to
change and moved 4 points. The script carries no such floor, so the same sweep
took it from 39 percent to 87 percent.

Read a template's Real column against its free prose count, never against a
script's.

## What each file still shares

### templates/plan-template.md

Twelve headings are upstream's: `# Implementation Plan: [FEATURE]`,
`## Summary`, `## Technical Context`, `## Constitution Check`,
`## Project Structure`, `### Documentation (this feature)`,
`### Source Code (repository root)`, `## Execution Strategy`,
`### TDD Requirements`, `### Human Checkpoints`, `### Review Gates`,
`## Complexity Tracking`.

Ours: `### Independent Work Streams`. It replaced upstream's
`### Parallel Execution Opportunities`, which asked a plan author for work the
Copilot CLI cannot do, having no subagents.

The Technical Context field labels and the `**Branch**` metadata line are frozen
beyond the contract: eight recorded `plan.md` files under `specflow/examples/`
reproduce them verbatim, so renaming one would drift the template from its own
recorded output.

### templates/spec-template.md

Shared: `# Feature Specification: [FEATURE NAME]`,
`## User Scenarios & Testing *(mandatory)*`, the three
`### User Story N` slots, `### Edge Cases`, `#### Brainstorm Prompts`,
`## Open Questions`, `## Requirements *(mandatory)*`,
`### Functional Requirements`, `### Key Entities`,
`## Success Criteria *(mandatory)*`, `### Measurable Outcomes`,
`## Assumptions`, `## Brainstorm Log`.

Ours: `## Threat Model`, `## Traceability`, `## Changelog`, and
`### Session [YYYY-MM-DD]`. The last one replaced upstream's hardcoded
`### Session 2026-04-22`, which shipped a pre-dated Brainstorm Log entry to
every project that installed the extension.

### scripts/validate-release-archive.py

Three function names are still upstream's: `declared_payload_files`,
`build_archive`, `main`.

Ours: `report_failure`, `report_pass`, `format_mib`, `check_limit`,
`read_archive_manifest`, `check_size_limits`, `check_member_sizes`,
`check_required_members`, `check_declared_members`, `check_excluded_paths`.
Upstream's `human`, `fail`, and `ok` are gone.

### templates/checklist-template.md

Shared: `# [CHECKLIST TYPE] Checklist: [FEATURE NAME]`, `## Spec Compliance`,
`## Code Review`, `### Correctness`, `### Security`, `### Performance`,
`### Code Quality`, `## Constitution Compliance`, `## Test Coverage`,
`## [Custom Category]`, `## Notes`. Ours: `## Review Findings`.

### templates/constitution-template.md

Shared: `# [PROJECT_NAME] Constitution`, `## Core Principles`, the five
`### [PRINCIPLE_N_NAME]` slots, `## Technology Stack`, `## Development Workflow`,
`### Workflow Rules`, `## Quality Gates`, `### Testing Requirements`,
`### Review Requirements`, `### Deployment Gates`, `## Governance`.

Ours: `### Review Stages`, `## Code Review Rules`. The five principle examples
were upstream's prose until G-47; ADR-0028 records why an example is rewritten
rather than frozen.

### templates/tasks-template.md

Nineteen headings are upstream's, from `# Tasks: [FEATURE NAME]` through
`## Notes`, including every `## Phase N` slot, `## Dependencies & Execution
Order`, `## Superpowers Execution`, and `### Checkpoint Protocol`. Ours:
`## Task Verification`.

## Prose moved, structure held

The command files, the hook prompts, and the manifest read at 56 to 79 percent
changed, yet nearly every heading and key is still upstream's. ADR-0013 bars
`prose-rephraser` from touching a heading, so a rewrite pass moves the Real
column without moving the shape. Read the percentage as wording, not structure.

| File | Real | Named units shared |
|------|------|--------------------|
| `commands/hooks/after-tasks.md` | 60% | 3 of 3 |
| `commands/hooks/after-execute.md` | 65% | 3 of 3 |
| `commands/hooks/before-execute.md` | 70% | 3 of 3 |
| `extension.yml` | 56% | 6 of 6 |
| `commands/execute.md` | 60% | 5 of 6 |
| `commands/status.md` | 62% | 4 of 5 |
| `commands/brainstorm.md` | 66% | 5 of 6 |
| `commands/tasks.md` | 74% | 5 of 6 |
| `commands/review.md` | 79% | 5 of 7 |
| `references/workflow-guide.md` | 64% | 36 of 44 |
| `SKILL.md` | 57% | 16 of 23 |

Each command file's one unshared heading is its `# speckit.specflow.*` title,
which the namespace rename moved. The bodies keep upstream's `## Usage`,
`## Process`, `## Output`, and `## Superpowers Adaptation`.

`extension.yml` keeps all six top-level keys: `schema_version`, `extension`,
`requires`, `provides`, `hooks`, `tags`.

The three hook prompts keep every heading: `# Hook: after_tasks` with `## Checks`
and `## Output`, and `# Hook: before_implement` and `# Hook: after_implement`,
each with `## Checks` and `## Gate`.

## Files that left upstream behind

| File | Real | Named units shared |
|------|------|--------------------|
| `scripts/validate-release-archive.py` | 87% | 3 of 13 functions |
| `scripts/e2e-agent-claude.sh` | 90% | 0 of 11 upstream functions |
| `scripts/validate-extension-metadata.py` | 90% | 2 of 4 |
| `scripts/e2e-smoke.sh` | 83% | 8 shared, 14 added |
| `README.md` | 134% | rewritten |

## Reproduce

From the repository root, with `$SCRATCH` pointing at a writable directory:

```bash
git clone -q https://github.com/WangX0111/superspec "$SCRATCH/upstream"
python3 .claude/divergence/measure-divergence.py \
  --local specflow --upstream "$SCRATCH/upstream" \
  templates/plan-template.md templates/spec-template.md \
  templates/checklist-template.md templates/constitution-template.md \
  templates/tasks-template.md scripts/validate-release-archive.py
```

The named-unit counts come from reading each file's headings, `def` lines, shell
function definitions, and top-level YAML keys, then keeping the ones spelled the
same on both sides.
