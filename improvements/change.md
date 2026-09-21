# Files still close to upstream

Read this before picking a rewrite target. It names the shipped files whose shape
is still upstream superspec's, and lists the headings, functions, and manifest
keys inside each one that match upstream verbatim. `reference.md` records how far
each file has moved; this file records what has not moved.

Measured 2026-09-21 against upstream `c20ac6c1`. A named unit counts as shared
when it appears in the local file and the upstream file with the same spelling.
Percentages in the Real column come from `reference.md`'s measured state.

## The closest six

Six files sit below 50 percent real change. Every other shipped file sits at 56
percent or above, so the gap after `tasks-template.md` marks where upstream's
work ends.

| File | Real | Identical lines | Named units shared |
|------|------|-----------------|--------------------|
| `templates/plan-template.md` | 21% | 104 of 131 (79%) | 13 of 13 headings |
| `templates/spec-template.md` | 33% | 132 of 198 (67%) | 16 of 19 headings |
| `scripts/validate-release-archive.py` | 39% | 157 of 241 (65%) | 5 of 7 functions |
| `templates/checklist-template.md` | 41% | 71 of 121 (59%) | 11 of 12 headings |
| `templates/constitution-template.md` | 44% | 70 of 126 (56%) | 15 of 17 headings |
| `templates/tasks-template.md` | 46% | 122 of 226 (54%) | 19 of 20 headings |

### templates/plan-template.md

Every heading is upstream's. The fork added no section here.

`# Implementation Plan: [FEATURE]`, `## Summary`, `## Technical Context`,
`## Constitution Check`, `## Project Structure`, `### Documentation (this feature)`,
`### Source Code (repository root)`, `## Execution Strategy`,
`### TDD Requirements`, `### Parallel Execution Opportunities`,
`### Human Checkpoints`, `### Review Gates`, `## Complexity Tracking`.

### templates/spec-template.md

Shared: `# Feature Specification: [FEATURE NAME]`,
`## User Scenarios & Testing *(mandatory)*`,
`### User Story 1 - [Brief Title] (Priority: P1)`, the P2 and P3 siblings,
`### Edge Cases`, `#### Brainstorm Prompts`, `## Open Questions`,
`## Requirements *(mandatory)*`, `### Functional Requirements`,
`### Key Entities *(include if feature involves data)*`,
`## Success Criteria *(mandatory)*`, `### Measurable Outcomes`, `## Assumptions`,
`## Brainstorm Log`, `### Session 2026-04-22`.

Ours: `## Threat Model`, `## Traceability`, `## Changelog`.

Line 179 still carries upstream's sample date, `### Session 2026-04-22`.

### scripts/validate-release-archive.py

Shared functions: `fail`, `ok`, `declared_payload_files`, `build_archive`, `main`.

Ours: `format_mib`, `check_limit`. Upstream's `human` is gone.

`declared_payload_files` and `build_archive` carry the archive contract, so a
rewrite here changes what the release check reads.

### templates/checklist-template.md

Shared: `# [CHECKLIST TYPE] Checklist: [FEATURE NAME]`, `## Spec Compliance`,
`## Code Review`, `### Correctness`, `### Security`, `### Performance`,
`### Code Quality`, `## Constitution Compliance`, `## Test Coverage`,
`## [Custom Category]`, `## Notes`.

Ours: `## Review Findings`.

### templates/constitution-template.md

Shared: `# [PROJECT_NAME] Constitution`, `## Core Principles`, the five
`### [PRINCIPLE_N_NAME]` slots, `## Technology Stack`, `## Development Workflow`,
`### Workflow Rules`, `## Quality Gates`, `### Testing Requirements`,
`### Review Requirements`, `### Deployment Gates`, `## Governance`.

Ours: `### Review Stages`, `## Code Review Rules`.

### templates/tasks-template.md

Shared: `# Tasks: [FEATURE NAME]`, `## Task Format`, `## Path Conventions`,
`## Phase 1: Setup (Shared Infrastructure)`,
`## Phase 2: Foundational (Blocking Prerequisites)`,
`## Phase 3: User Story 1 - [Title] (Priority: P1) MVP`,
`### Tests for User Story 1 (if TDD applies)`,
`### Implementation for User Story 1`,
`## Phase 4: User Story 2 - [Title] (Priority: P2)`,
`### Implementation for User Story 2`,
`## Phase N: Polish & Cross-Cutting Concerns`,
`## Dependencies & Execution Order`, `### Phase Dependencies`,
`### Within Each User Story`, `### Parallel Opportunities`,
`## Superpowers Execution`, `### Execution Discipline by Marker`,
`### Checkpoint Protocol`, `## Notes`.

Ours: `## Task Verification`.

## Prose moved, structure held

The command files, the hook prompts, and the manifest read at 56 to 79 percent
changed, yet nearly every heading and key is still upstream's. ADR-0013 bars
`prose-rephraser` from touching a heading, so a rewrite pass moves the Real column
without moving the shape. Read the percentage as wording, not as structure.

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

Two scripts moved in structure, not only in wording. Neither is a rewrite target.

| File | Real | Named units shared |
|------|------|--------------------|
| `scripts/e2e-agent-claude.sh` | 90% | 0 of 11 upstream functions |
| `scripts/validate-extension-metadata.py` | 90% | 2 of 4 (`extract_extension_id`, `main`) |
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
