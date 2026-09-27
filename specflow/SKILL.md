---
name: specflow
description: >-
  Orchestrates specification-driven development by combining spec-kit project
  governance (constitution, specs, plans, tasks) with obra/superpowers
  capabilities (brainstorming, writing-plans, TDD, subagent-driven-development,
  code-review). Use when the user wants to create project constitutions, write
  feature specifications, brainstorm edge cases, plan implementations, decompose
  tasks, execute with TDD discipline, or request code reviews within a structured
  development workflow.
---

# Specflow

Specflow combines [spec-kit](https://github.com/github/spec-kit)'s specification-driven
workflow with [obra/superpowers](https://github.com/obra/superpowers) agent skills in one
pipeline. Spec-kit supplies the document structure and the governance gates; superpowers
adds deeper questioning, task breakdown, and execution discipline.

```mermaid
flowchart LR
  A[Constitution] --> B[Specify]
  B --> C[Brainstorm]
  C -->|open questions| B
  C --> D[Plan]
  D --> E[Tasks]
  E --> F[Execute]
  F --> G[Review]
```

## Specflow runs without superpowers

**Required**: None. Specflow runs on its own, using the built-in fallback protocols.

One gate is unconditional: `.specify/memory/constitution.md` must exist before
any other command runs. Every command checks for it first and stops with
guidance when it is absent.

**Optional (skill mode)**: Install the [obra/superpowers](https://github.com/obra/superpowers)
skills under `~/.agents/skills/` or `.agents/skills/` for deeper brainstorming,
planning, and execution. See [superpowers-mapping.md](references/superpowers-mapping.md)
for how specflow detects and wires them in.

## Target surface

Specflow runs on Claude Code and on the GitHub Copilot CLI, and every command works
on either surface. Two steps still diverge between them:

| Step | Claude Code | Copilot CLI |
|------|-------------|-------------|
| `[P]` and `[SUBAGENT]` tasks in execute | Task tool or Agent Teams, in parallel | In order, in the session |
| Test gate before ticking a task | `.claude/hooks/test-gate.sh`, in this repository only, runs on edit | The agent runs the test command itself |

The review risk tier no longer diverges: both surfaces run
`gates/bash/risk-classifier.sh`, which the extension archive carries.

`references/copilot-cli.md` names the fallback behavior for each command.

## Where the files land

Once initialized, specflow depends on the two top-level directories spec-kit creates
at the project root: `.specify/` for tool metadata and `specs/` for feature
artifacts.

```
your-project/
├── .specify/
│   ├── extensions/
│   │   └── specflow/
│   │       └── templates/       # Specflow's templates, resolved at command time
│   ├── memory/
│   │   └── constitution.md      # Project governance principles
│   ├── superpowers.yml          # Superpowers detection status (auto-managed)
│   ├── scripts/                 # Spec-kit's scripts, including the template resolver
│   └── templates/               # Core templates, written by `specify init`
└── specs/
    └── NNN-feature-name/
        ├── spec.md              # Feature specification
        ├── plan.md              # Implementation plan
        ├── tasks.md             # Task breakdown
        ├── progress.yml         # Phase progress tracker (auto-managed)
        └── checklist-*.md       # Generated checklists
```

Spec-kit resolves a template at command time rather than reading one path. The
resolver layers project overrides, then presets, then an extension's templates,
then core, so specflow's copies win over core without replacing the files under
`.specify/templates/`. Every command below resolves through
the resolver spec-kit installed under `.specify/scripts/` and reads
`TEMPLATE_CONTENT` from its output. Spec-kit writes one variant per project,
picked by `--script` at init and defaulting to PowerShell on Windows and bash
elsewhere:

- `.specify/scripts/bash/resolve-template.sh <name> --json`
- `.specify/scripts/powershell/resolve-template.ps1 <name> -Json`
- `.specify/scripts/python/resolve_template.py <name> --json`

When the resolver fails, stop with `RESOLVER_REQUIRED`, name the variant that
failed, and tell the user to reinstall spec-kit 0.16.2 or newer. Do not fall
back to reading `.specify/templates/<name>.md`, which holds only the core layer
and silently drops the others.

## Command index

| Command | Purpose |
|---------|---------|
| `/speckit.specflow.status` | Show the current progress and name the next step (resumable) |
| `/speckit.constitution` | Write or update the project's governance principles |
| `/speckit.specify` | Write a feature specification with user stories |
| `/speckit.clarify` | Resolve the spec's NEEDS CLARIFICATION markers, then write .clarified |
| `/speckit.specflow.brainstorm` | Question edge cases and update the spec document |
| `/speckit.plan` | Write a technical implementation plan |
| `/speckit.specflow.tasks` | Break the plan into a phased task list |
| `/speckit.analyze` | Check spec, plan, and tasks for inconsistency, then write .analyzed |
| `/speckit.specflow.execute` | Run the implementation through TDD and subagents |
| `/speckit.specflow.review` | Review the code against the spec's requirements |
| `/speckit.specflow.gate` | Write a feature's clarify or analyze marker once its gate passes |
| `/speckit.specflow.agent-event` | Run by spec-kit's `events:` block on hook payloads; not typed by a person |
| `/speckit.checklist` | Build a checklist for the given context |

## Six hooks fire on spec-kit's own commands

| Hook | Fires after | What it does |
|------|-------------|---------------|
| `after_clarify` | `/speckit.clarify` | Write the feature's `.clarified` file once the spec holds no NEEDS CLARIFICATION line |
| `after_analyze` | `/speckit.analyze` | Write the feature's `.analyzed` file once the report holds no CRITICAL row |
| `after_tasks` | `/speckit.tasks` | Check that every user story has tasks and that each task carries its markers |
| `before_tasks` | Before `/speckit.tasks` | Check the constitution and open-questions gates before `/speckit.tasks` starts |
| `before_implement` | Before `/speckit.implement` | Check the constitution and analyze gates before `/speckit.implement` starts |
| `after_implement` | `/speckit.implement` | Review the completed phase against the spec, the plan, and the constitution |

---

## The seven phases in order

The recommended path from start to finish:

```
Phase 0: /speckit.constitution          → Establish project governance
Phase 1: /speckit.specify               → Define feature requirements
Gate:    /speckit.clarify               → Writes specs/NNN-feature-name/.clarified
Phase 2: /speckit.specflow.brainstorm   → Clarify edge cases (iterate)
Phase 3: /speckit.plan                  → Design technical approach
Phase 4: /speckit.specflow.tasks        → Decompose into executable tasks
Gate:    /speckit.analyze               → Writes specs/NNN-feature-name/.analyzed
Phase 5: /speckit.specflow.execute      → Reads .analyzed, implements with TDD + subagents
Phase 6: /speckit.specflow.review       → Verify against spec
```

Every phase carries an explicit **gate**: the agent checks its prerequisites before
moving on. Two of those gates leave a marker file beside the spec, and the agent
writes both itself.

`/speckit.clarify` writes `.clarified` once no `NEEDS CLARIFICATION` is left in the
spec. `/speckit.analyze` writes `.analyzed` only when the analysis reports zero
critical inconsistencies. Execution stops with `ANALYZE_REQUIRED` while that marker
is absent. Remove a marker before rerunning the command that wrote it.

`/speckit.checklist` runs at any point in the workflow and writes
`checklist-*.md` into the feature directory. Run `/speckit.specflow.brainstorm` as
many times as it takes for the spec to hold up. The user decides when to advance to
the next phase.

---

## Every command resumes from the files on disk

Specflow resumes across sessions. State lives in two plain-text files:
`progress.yml` under `specs/NNN-feature-name/`, and `.specify/superpowers.yml`.
An agent timeout, a closed session, or a CLI crash drops no progress.

### The progress file

Each feature's spec directory holds a `progress.yml` file that tracks the status of every phase:

```yaml
# specs/NNN-feature-name/progress.yml
spec: NNN-feature-name
status: in_progress
current_phase: 2
brainstorm:
  sessions: 1
  last_session: 2026-09-14
phases:
  - phase: 1
    name: Setup
    status: complete
    tasks:
      T001: complete
      T002: complete
  - phase: 2
    name: Foundational
    status: in_progress
    tasks:
      T003: pending
gates:
  clarified: 2026-09-14
  analyze_attempts: 2
```

**Status values**: `pending`, `in_progress`, `complete`, `skipped`

The required top-level keys are `spec`, `status`, `current_phase`, and `phases`.
`current_phase` holds the number of one listed phase. Each phase requires a
number, name, and status; its `tasks` mapping is optional. The `brainstorm` and
`gates` mappings are optional.

Every command marks `progress.yml` `in_progress` on start and `complete` on finish.

### The skill detection cache

`.specify/superpowers.yml` records one entry per skill the Skill Mapping
table in `references/superpowers-mapping.md` names, plus the superpowers
release in `version`. No command re-runs detection while the file is
current. [workflow-guide.md](references/workflow-guide.md) holds the
file's shape and the events that rewrite it.

### The resume check runs first

Before running any specflow command, the agent MUST run the **resume check** first:

1. Check whether the `.specify/` directory exists
2. If it exists, scan every spec directory for a `progress.yml` file
3. Read the newest `progress.yml` and take its `current_phase` value
4. Read `.specify/superpowers.yml` for the available superpowers skills. When the
   file is missing, run superpowers detection and create it.
5. Report to user: "Detected existing progress for [feature]: [phase] is [status].
   Superpowers: [list detected skills]. Resuming from this point." or
   "No previous progress found, starting fresh."
6. For a phase marked `in_progress`, re-read that phase's artifacts and pick up
   where work stopped (e.g., resume brainstorming from the last logged session,
   resume execution from the first unchecked task). The per-phase rules are in
   [workflow-guide.md](references/workflow-guide.md) under Where each phase resumes.

---

## `/speckit.specflow.status`

**Input**: an optional spec number or "all" through `$ARGUMENTS`; with nothing given, it shows every feature.
**Output**: a progress report printed for the user.

**Process**:
1. Scan the `.specify/` directory structure
2. Check whether `constitution.md` exists
3. **Run superpowers detection**: Look for every skill the Skill Mapping table in
   `references/superpowers-mapping.md` names, at `.agents/skills/` and
   `~/.agents/skills/`. Update `.specify/superpowers.yml` with the result. When
   `~/.claude/plugins/installed_plugins.json` exists, read the superpowers
   entry's `version` and write it as `version:` in that file. When that version
   sits outside the tested range the mapping states, print
   `superpowers <version> is outside the tested range <range>`.
4. For each spec directory, read `progress.yml` (or infer progress from the files
   present when it is missing). Note whether `.clarified` and `.analyzed` sit
   beside `spec.md`.
5. Display a status summary:

```
Specflow Project Status
========================
Constitution: Done (2026-04-22)
Superpowers:  brainstorming (detected), writing-plans (not found)

Templates:
  template constitution-template: 1.0.2 (installed 1.0.2)
  template spec-template: 1.0.2 (installed 1.0.2)
  template plan-template: 1.0.2 (installed 1.0.2)
  template tasks-template: 1.0.1 (installed 1.0.2) stale
  template checklist-template: 1.0.2 (installed 1.0.2)

Features:
  001-user-auth    [####------] execute (Phase 5/6), gates: clarified, analyzed, T012/T019 tasks done
  002-photo-upload [##--------] brainstorm (Phase 2/6), gates: none, 2 open questions
  003-settings     [#---------] specify (Phase 1/6), gates: none, draft

Suggested next step: /speckit.specflow.execute 001
```

6. Choose the suggested next step from the gates: a feature with `tasks.md` and no
   `.analyzed` gets `/speckit.analyze NNN`; a feature with `spec.md` and no
   `.clarified` gets `/speckit.clarify NNN`; otherwise the next workflow command
   for its phase. Suggest the step for whichever feature is furthest along.
7. When no `.specify/` exists, suggest: "No specflow project found. Run
   `/speckit.constitution` to get started."

**File inference fallback**: When `progress.yml` does not exist, infer progress from
which files are present:
- `spec.md` exists → specify is done
- `spec.md` has Brainstorm Log entries → brainstorm ran
- `.clarified` exists beside `spec.md` → clarify is done; `.analyzed` exists → analyze is done
- `plan.md` exists → plan is done
- `tasks.md` exists → tasks are done
- `tasks.md` has `[x]` checkboxes → execute is in progress (count checked vs total)

---

## `/speckit.constitution`

**Input**: the project name and an optional description through `$ARGUMENTS`.
**Output**: `.specify/memory/constitution.md`

**Process**:
1. Create the `.specify/` directory structure when it does not exist
2. Resolve `constitution-template` through the template resolver named above and parse `TEMPLATE_CONTENT`
3. Interview the user on core principles, the technology stack, the design system, and quality gates
4. Fill the template with the user's answers to produce `constitution.md`
5. Write the result to `.specify/memory/constitution.md`

**Gate**: No other command runs before the constitution exists.

---

## `/speckit.specify`

**Input**: the feature name and description through `$ARGUMENTS`.
**Output**: `specs/NNN-feature-name/spec.md`

**Process**:
1. Verify `.specify/memory/constitution.md` exists (stop with guidance if not)
2. Work out the next spec number NNN by scanning the existing `specs/` directories
3. Resolve `spec-template` through the template resolver named above and parse `TEMPLATE_CONTENT`
4. Read the constitution for the project's principles and constraints
5. Interview the user on the user scenarios, the requirements, and the success criteria
6. Fill the template with the user's answers to produce `spec.md`
7. Write the result to `specs/NNN-feature-name/spec.md`

**Next step suggestion**: Run `/speckit.specflow.brainstorm` against the new spec to find its edge cases.

---

## `/speckit.specflow.brainstorm`

**Input**: the path to a spec file (e.g., `specs/001-auth/spec.md`) and an optional
focus topic through `$ARGUMENTS`.
**Output**: The spec file updated with sharper edge cases, resolved open questions,
and new brainstorm log entries.

**Process**:
1. Read the target spec file
2. Read the constitution for the project's constraints
3. **Superpowers detection**: Look for the `brainstorming` skill (see [superpowers-mapping.md](references/superpowers-mapping.md))
   - **If found**: Read the brainstorming SKILL.md and follow its questioning protocol,
     fitting every output to the target spec file
   - **If not found**: Follow the built-in questioning protocol instead (see [workflow-guide.md](references/workflow-guide.md) Phase 2)
4. Ask questions **one at a time**, covering:
   - Boundary conditions and edge cases
   - Error scenarios and failure modes
   - Scale and performance effects
   - Security and privacy concerns
   - User confusion and UX pitfalls
5. After each answer, update the spec's "Open Questions" section (mark resolved items)
6. Once the user confirms the spec is ready, add a dated summary of the session's
   insights to the "Brainstorm Log"

**Iteration**: This command can run against the same spec more than once. Each
session adds its own entry to the brainstorm log.

---

## `/speckit.plan`

**Input**: an optional spec number or path through `$ARGUMENTS`; it defaults to the latest spec.
**Output**: `specs/NNN-feature-name/plan.md`

**Process**:
1. Read the target spec file and the constitution
2. Resolve `plan-template` through the template resolver named above and parse `TEMPLATE_CONTENT`
3. Run a **constitution check**: confirm the plan follows every governance principle
4. Look through the codebase to establish the technical context (language, dependencies, storage,
   testing framework, project type)
5. Design the project structure and list the files to create or change
6. Set the **execution strategy**: which tasks need TDD, which allow parallel
   subagent execution, where a human checkpoint belongs
7. Fill the template to produce `plan.md`
8. Write the result to `specs/NNN-feature-name/plan.md`

**Skill mode**: When the `writing-plans` skill is detected, read it and use
its blueprint process to sharpen the plan's task structure section. See
[superpowers-mapping.md](references/superpowers-mapping.md).

---

## `/speckit.specflow.tasks`

**Input**: an optional spec number or path through `$ARGUMENTS`; it defaults to the latest spec.
**Output**: `specs/NNN-feature-name/tasks.md`

**Process**:
1. Read the spec, the plan, and the constitution for the target feature
2. Resolve `tasks-template` through the template resolver named above and parse `TEMPLATE_CONTENT`
3. **Superpowers detection**: Look for the `writing-plans` skill
   - **If found**: Read the writing-plans SKILL.md and follow its task decomposition
     process, fitting its output to the tasks template structure
   - **If not found**: Break the plan down directly with the template
4. Organize tasks by phase: Setup → Foundational → User Stories (by priority) → Polish
5. Apply execution markers to each task:
   - `[P]`: eligible to run in parallel (different files, no dependencies)
   - `[TDD]`: must follow RED-GREEN-REFACTOR discipline
   - `[REVIEW]`: waits for code review before it proceeds
   - `[SUBAGENT]`: eligible for delegation to a subagent
6. Keep each task singular: one outcome per line; split a description that needs "and"
7. Set the phase dependencies and the checkpoint gates
8. Write the result to `specs/NNN-feature-name/tasks.md`

---

## `/speckit.specflow.execute`

**Input**: an optional spec number or path through `$ARGUMENTS`; it defaults to the latest spec.
**Output**: Code changes in the project and updated task checkboxes.

**Process**:
1. Read the tasks file for the target feature
2. Read the plan and the constitution for context
3. **Superpowers detection**: Look for the `executing-plans`, `subagent-driven-development`,
   and `test-driven-development` skills
4. Work through the tasks phase by phase:
   - **`[TDD]` tasks**: Follow the TDD skill's RED-GREEN-REFACTOR process when found.
     Otherwise: write test → verify it fails → implement → verify it passes
   - **`[SUBAGENT]` tasks**: Follow the subagent-driven-development skill's dispatch
     protocol when found. Otherwise: implement sequentially in-session
   - **`[P]` tasks**: On Claude Code, dispatch the batch in parallel with the Task
     tool; on the Copilot CLI, run it in order
   - **`[REVIEW]` tasks**: Pause and run the review protocol (see `/speckit.specflow.review`)
5. At each **phase checkpoint**: Summarize the work finished, run tests if applicable,
   ask the user for approval before moving to the next phase
6. Check off each task in `tasks.md` as it finishes

**Human checkpoints**: The agent MUST stop at every phase boundary and wait for the
user's explicit approval. **Never skip a checkpoint.**

---

## `/speckit.specflow.review`

**Input**: an optional scope (file paths or "all changes") through `$ARGUMENTS`.
**Output**: Review findings reported to the user and written to
`specs/NNN-feature-name/review-findings.json`, optionally also written to a checklist file.

**Process**:
1. Read the spec and the plan for the feature under review
2. **Superpowers detection**: Look for the `requesting-code-review` skill
   - **If found**: Read the skill and follow its pre-evaluation checklist and review
     dispatch protocol
   - **If not found**: Fall back to the built-in review protocol below
3. Built-in review protocol:
   - **Spec compliance**: Confirm the code implements every acceptance scenario from the spec
   - **Edge case coverage**: Confirm brainstormed edge cases are handled
   - **Constitution compliance**: Check all governance principles are respected
   - **Code quality**: Check for bugs, security issues, error handling
   - **Test coverage**: Confirm tests exist for critical paths
4. Report findings with confidence scores (0-100, only report issues >= 80)
5. Group findings by severity: Critical > Important > Suggestion
6. Write the findings to `specs/NNN-feature-name/review-findings.json`

---

## `/speckit.checklist`

**Input**: the checklist type and optional context through `$ARGUMENTS`.
**Output**: `specs/NNN-feature-name/checklist-{type}.md`

**Process**:
1. Resolve `checklist-template` through the template resolver named above and parse `TEMPLATE_CONTENT`
2. Read the spec, the plan, and the tasks for context
3. Build a checklist matching the requested type (e.g., "launch readiness",
   "security audit", "accessibility review", "code review")
4. Write the result to `specs/NNN-feature-name/checklist-{type}.md`

## Where to read more

- A phase-by-phase walkthrough: [workflow-guide.md](references/workflow-guide.md)
- How the superpowers integration works: [superpowers-mapping.md](references/superpowers-mapping.md)
- A full recorded run: [examples/link-audit](https://github.com/DonalMoloney/super-spec-new/tree/main/specflow/examples/link-audit), which the install archive leaves out
