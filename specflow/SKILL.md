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

## Prerequisites

**Required**: None. Specflow runs on its own, using the built-in fallback protocols.

**Optional (enhanced)**: Install the [obra/superpowers](https://github.com/obra/superpowers)
skills under `~/.agents/skills/` or `.agents/skills/` for deeper brainstorming,
planning, and execution. See [superpowers-bridge.md](references/superpowers-bridge.md)
for how specflow detects and wires them in.

## Target surface

Specflow runs on Claude Code and on the GitHub Copilot CLI, and every command works
on either surface. Three steps still diverge between them:

| Step | Claude Code | Copilot CLI |
|------|-------------|-------------|
| `[P]` and `[SUBAGENT]` tasks in execute | Task tool or Agent Teams, in parallel | In order, in the session |
| Test gate before ticking a task | `.claude/hooks/test-gate.sh` runs on edit | The agent runs the test command itself |
| Review risk tier | `.claude/hooks/risk-classifier.sh` when present | The prose rule in `commands/review.md` |

`references/copilot-cli.md` names the fallback behavior for each command.

## Project Structure

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
`.specify/scripts/bash/resolve-template.sh <name> --json` and reads
`TEMPLATE_CONTENT`, or `.specify/scripts/powershell/resolve-template.ps1
<name> -Json` where PowerShell is the shell. Spec-kit installs whichever
matches the platform. When the resolver fails, stop and report the error. Do
not fall back to reading `.specify/templates/<name>.md`, which holds only the
core layer and silently drops the others.

## Commands

| Command | Purpose |
|---------|---------|
| `/speckit.specflow.status` | Show the current progress and name the next step (resumable) |
| `/speckit.constitution` | Write or update the project's governance principles |
| `/speckit.specify` | Write a feature specification with user stories |
| `/speckit.specflow.brainstorm` | Question edge cases and update the spec document |
| `/speckit.plan` | Write a technical implementation plan |
| `/speckit.specflow.tasks` | Break the plan into a phased task list |
| `/speckit.specflow.execute` | Run the implementation through TDD and subagents |
| `/speckit.specflow.review` | Review the code against the spec's requirements |
| `/speckit.checklist` | Build a checklist for the given context |

---

## Session Resumability

Specflow is **fully resumable across sessions**. It keeps all state as Markdown
inside the `.specify/` directory, so an agent timeout, a closed session, or a CLI
crash never drops progress.

### Progress Tracking

Each feature's spec directory holds a `progress.yml` file that tracks the status of every phase:

```yaml
# specs/NNN-feature-name/progress.yml
feature: feature-name
created: 2026-04-22
current_phase: brainstorm
phases:
  constitution: { status: done, updated: 2026-04-22 }
  specify:      { status: done, updated: 2026-04-22 }
  brainstorm:   { status: in_progress, updated: 2026-04-22, sessions: 1 }
  plan:         { status: pending }
  tasks:        { status: pending }
  execute:      { status: pending }
  review:       { status: pending }
```

**Status values**: `pending`, `in_progress`, `done`, `skipped`

Every command marks `progress.yml` `in_progress` on start and `done` on finish.

### Superpowers Status Tracking

A **project-level file**, `.specify/superpowers.yml`, records which superpowers
skills are available. Recording them keeps the integration **visible in the project docs**
and **stable across sessions**, so no command re-runs detection.

```yaml
# .specify/superpowers.yml
last_checked: 2026-04-22T14:30:00
skills:
  brainstorming:
    detected: true
    path: ~/.agents/skills/brainstorming/SKILL.md
  writing-plans:
    detected: true
    path: ~/.agents/skills/writing-plans/SKILL.md
  executing-plans:
    detected: false
  subagent-driven-development:
    detected: false
  test-driven-development:
    detected: true
    path: .agents/skills/test-driven-development/SKILL.md
  requesting-code-review:
    detected: false
```

**When this file is updated**:
- On `/speckit.constitution`, at initial creation
- On `/speckit.specflow.status`, as a re-check
- On any command that needs a superpowers skill, as a lazy re-check when the skill was not detected before
- A user can hand-edit the file to override the detection result

**Why persist this**: the project's documentation then shows which superpowers
skills are in use. A teammate reading `.specify/` sees the enhanced skills at a
glance, without running a command.

### Resume Protocol

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
   resume execution from the first unchecked task)

### How Each Phase Resumes

| Phase | Resume Signal | Resume Behavior |
|-------|---------------|-----------------|
| `constitution` | `constitution.md` exists but incomplete | Re-read it and ask about the sections still missing |
| `specify` | `spec.md` exists with `[NEEDS CLARIFICATION]` markers | Pick the interview back up on the unresolved items |
| `brainstorm` | `Brainstorm Log` has entries, `Open Questions` has `Open` items | Skip the categories already covered and continue from the open questions |
| `plan` | `plan.md` exists with `NEEDS CLARIFICATION` fields | Fill in the technical context that's missing |
| `tasks` | `tasks.md` exists | Check the list is complete and add any missing task |
| `execute` | `tasks.md` has mix of `[x]` and `[ ]` checkboxes | Skip the finished tasks and resume at the first unchecked one in the current phase |
| `review` | Review checklist partially completed | Pick review back up at the first unchecked item |

---

## `/speckit.specflow.status`

**Input**: an optional spec number or "all" through `$ARGUMENTS`; with nothing given, it shows every feature.
**Output**: a progress report printed for the user.

**Process**:
1. Scan the `.specify/` directory structure
2. Check whether `constitution.md` exists
3. **Run superpowers detection**: Look for every superpowers skill at
   `.agents/skills/` and `~/.agents/skills/`. Update `.specify/superpowers.yml`
   with the result.
4. For each spec directory, read `progress.yml` (or infer progress from the files
   present when it is missing). Note whether `.clarified` and `.analyzed` sit
   beside `spec.md`.
5. Display a status summary:

```
Specflow Project Status
========================
Constitution: Done (2026-04-22)
Superpowers:  brainstorming (detected), writing-plans (not found)

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
3. **Superpowers detection**: Look for the `brainstorming` skill (see [superpowers-bridge.md](references/superpowers-bridge.md))
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

**Superpowers bridge**: When the `writing-plans` skill is detected, read it and use
its blueprint process to sharpen the plan's task structure section. See
[superpowers-bridge.md](references/superpowers-bridge.md).

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

---

## Unified Workflow

The recommended path from start to finish:

```
Phase 0: /speckit.constitution     → Establish project governance
Phase 1: /speckit.specify          → Define feature requirements
Phase 2: /speckit.specflow.brainstorm       → Clarify edge cases (iterate)
Phase 3: /speckit.plan             → Design technical approach
Phase 4: /speckit.specflow.tasks            → Decompose into executable tasks
Phase 5: /speckit.specflow.execute          → Implement with TDD + subagents
Phase 6: /speckit.specflow.review           → Verify against spec
```

Every phase carries an explicit **gate**: the agent checks its prerequisites before
moving on. Run `/speckit.specflow.brainstorm` as many times as it takes for the spec
to hold up. The user decides when to advance to the next phase.

## Additional Resources

- A phase-by-phase walkthrough: [workflow-guide.md](references/workflow-guide.md)
- How the superpowers integration works: [superpowers-bridge.md](references/superpowers-bridge.md)
- A full worked example: [sample-workflow.md](https://github.com/DonalMoloney/super-spec-new/blob/main/specflow/examples/sample-workflow.md), which the install archive leaves out
