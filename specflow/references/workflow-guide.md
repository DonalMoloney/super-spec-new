# Specflow Workflow Guide

This guide gives phase-by-phase instructions for the specflow workflow. SKILL.md
references this document for progressive disclosure: the agent reads only the
matching section while it runs a command.

## Phase 0: Project Initialization

**Command**: `/speckit.constitution`
**Gate**: None. This phase starts the workflow.
**Output**: `.specify/` directory structure + `memory/constitution.md`

### Steps

1. **Create directory structure**. Feature artifacts live in `specs/` at the
   project root, not under `.specify/`:
   ```
   your-project/
   ├── .specify/
   │   ├── extensions/specflow/templates/
   │   ├── memory/
   │   └── templates/
   └── specs/
   ```

2. **Resolve templates** through spec-kit's stack rather than copying them.
   Run `.specify/scripts/bash/resolve-template.sh <name> --json` and read
   `TEMPLATE_CONTENT`. The resolver layers project overrides, presets,
   extension templates, then core, so specflow's copies win without
   overwriting `.specify/templates/`. Stop and report when it fails.

3. **Interview the user** about:
   - Project name and purpose
   - Core principles (3-7 principles, each with a name and a description)
   - Technology stack (layers, technologies, purposes)
   - Development workflow preferences (which quality gates to enforce)
   - Governance rules

4. **Generate constitution** using `constitution-template.md` as skeleton.
   Fill in every section from the user's responses. Populate the "Development Workflow"
   and "Quality Gates" sections.

5. **Write** to `.specify/memory/constitution.md`

### Verification

- File exists at `.specify/memory/constitution.md`
- Every placeholder replaced with real content
- At least 3 core principles defined
- Quality gates section has at least one requirement marked

---

## Phase 1: Specification

**Command**: `/speckit.specify`
**Gate**: The constitution must exist at `.specify/memory/constitution.md`
**Output**: `specs/NNN-feature-name/spec.md`

### Steps

1. **Verify the constitution** exists. If it is missing, direct the user to run `/speckit.constitution` first.

2. **Determine the spec number**: scan `specs/` for existing directories.
   The next number is the highest existing number plus one, zero-padded to 3 digits (001, 002, ...).

3. **Read the constitution** to learn the project's constraints and principles.

4. **Interview the user** about:
   - The feature's name and a short description
   - User scenarios: who does what, why, and the expected outcome
   - Each scenario's priority (P1, P2, P3)
   - The known requirements and constraints
   - Measurable success criteria
   - Any assumptions

5. **Generate the spec** from `spec-template.md`.
   - Write each user story's acceptance scenarios in Given/When/Then form
   - Mark each functional requirement MUST/SHOULD/MAY
   - Flag an unclear item as `[NEEDS CLARIFICATION]`
   - Leave the "Open Questions", "Brainstorm Log", and "Brainstorm Prompts" sections
     with their initial prompts and no resolved content

6. **Write the spec** to `specs/NNN-feature-name/spec.md`

7. **Suggest the next step**: "Run `/speckit.specflow.brainstorm specs/NNN-feature-name/spec.md`
   to discover edge cases before planning."

### Verification

- The spec file exists at the expected path
- At least one user story has acceptance scenarios
- Each user story has an assigned priority
- The Functional Requirements section is populated
- The success criteria section is populated

---

## Phase 2: Brainstorming

**Command**: `/speckit.specflow.brainstorm`
**Gate**: The target spec file must exist.
**Output**: Spec file, updated with new edge cases, open questions, and a brainstorm log entry.

### Superpowers Integration

When the `brainstorming` skill is detected (see [superpowers-bridge.md](superpowers-bridge.md)), follow this process:
- Read the skill's SKILL.md file and follow its questioning protocol
- Write findings into the spec file rather than a separate document
- Ask one question at a time, in multiple-choice form where it fits, per the skill's session structure

### Built-in Fallback Protocol

When superpowers brainstorming is not available, run this 5-category questioning protocol instead:

#### Category 1: Boundary Conditions
Ask about minimum and maximum values, empty states, and inputs at the edge of a range.
- "What happens when [input] is empty?"
- "What's the maximum number of [items] the system should handle?"
- "What happens at exactly the boundary of [limit]?"

#### Category 2: Error Scenarios
Ask about failure modes, recovery, and degraded behavior.
- "What happens when [external service] is unavailable?"
- "How should the system recover from [failure type]?"
- "What error message should the user see when [scenario]?"

#### Category 3: Scale & Performance
Ask about load, concurrency, and limits on resources.
- "What happens with [N]x expected traffic?"
- "Are there rate limits needed for [operation]?"
- "What's the acceptable response time for [action]?"

#### Category 4: Security & Privacy
Ask about attack vectors, data protection, and who holds authorization.
- "Can [feature] be abused by [actor type]?"
- "What data needs to be encrypted or redacted?"
- "Who should NOT have access to [resource]?"

#### Category 5: User Experience
Ask about points of confusion, accessibility, and use the design did not intend.
- "What if the user tries to [unintended action]?"
- "How does this work for users with [accessibility need]?"
- "What happens if the user navigates away mid-[process]?"

### Process

1. **Read the spec** and find the sections with thin coverage or a placeholder edge case.

2. **Ask one question at a time**. Wait for the user's answer before the next question.
   Prefer multiple-choice form when possible, for faster exploration.

3. **After each answer**:
   - A new requirement goes into the spec's Functional Requirements
   - A resolved question updates the Open Questions table
   - A new edge case goes into the Edge Cases section
   - A changed acceptance scenario updates the matching user story

4. **Continue** through all 5 categories and skip a question the spec already covers.

5. **When the user says the spec is ready** (or the agent has covered every category):
   - Log a dated entry in the "Brainstorm Log" section
   - State the number of questions asked, the insights found, and the updates made to the spec
   - Suggest: "Run `/speckit.plan` to create the implementation plan."

### Iteration

This phase may run more than once. Each session:
- Reads the previous brainstorm log entries first, so it does not repeat a question
- Focuses on the topic the user named, or on an unexplored category when none was named
- Appends a new entry to the brainstorm log

---

## Phase 3: Planning

**Command**: `/speckit.plan`
**Gate**: The spec file must exist. Brainstorming is recommended but not required.
**Output**: `specs/NNN-feature-name/plan.md`

### Steps

1. **Read inputs**: the spec file, the constitution, and any earlier plan for
   this feature.

2. **Constitution compliance check**: Check that the planned approach respects
   every principle. Record the result in the "Constitution Check" table.

3. **Research the codebase**: Use the Glob, Grep, and Read tools to find:
   - The language and framework already in use
   - The existing patterns and conventions
   - Files that need a change
   - The testing framework in use

4. **Design project structure**: Decide which files to create or change, and
   record them in the "Source Code" section of the plan.

5. **Determine execution strategy**:
   - Which components need TDD? (complex logic, critical paths)
   - Which work streams can run in parallel? (independent files)
   - Where does the work need a human checkpoint? (before integration, before merge)
   - What needs a code review? (APIs, security, data models)

6. **Superpowers integration**: When the `writing-plans` skill is found, read
   it and follow its blueprint process to sharpen the execution strategy section.

7. **Generate plan** from `plan-template.md`, filling every section.

8. **Write** the plan to `specs/NNN-feature-name/plan.md`

### Verification

- The Constitution check table is complete, with no violation unresolved
- The technical context is filled in, with no NEEDS CLARIFICATION left without good reason
- The project structure names real file paths
- The execution strategy states at least the TDD and checkpoint decisions

---

## Phase 4: Task Decomposition

**Command**: `/speckit.specflow.tasks`
**Gate**: A plan must exist for the target feature.
**Output**: `specs/NNN-feature-name/tasks.md`

### Steps

1. **Read inputs**: plan, spec, constitution.

2. **Superpowers integration**: When the `writing-plans` skill is detected, read it
   and follow its task decomposition process. Structure the output with the
   `tasks-template.md` format.

3. **Split the plan** into phases:
   - Phase 1: Setup (project structure and dependencies)
   - Phase 2: Foundational (prerequisites that block later phases)
   - Phase 3+: one phase per user story, ordered by priority
   - Final phase: Polish, plus concerns that cut across every phase

4. **Add the execution markers** from the plan's execution strategy:
   - `[TDD]` for a component that needs tests first
   - `[REVIEW]` for a component that needs a review gate
   - `[SUBAGENT]` for an independent work stream
   - `[P]` for tasks in the same phase that can run in parallel

5. **Keep each task singular**: one outcome per line; split a task description
   that needs "and".

6. **Add a checkpoint** at each phase boundary.

7. **Record the dependencies** and the execution order.

8. **Write the result** to `specs/NNN-feature-name/tasks.md`

### Verification

- Every user story in the spec maps to a task
- Each task traces to its user story with a `[US#]` label
- The execution markers match the plan's execution strategy
- Phase dependencies are on record
- Each phase transition has at least one checkpoint

---

## Phase 5: Execution

**Command**: `/speckit.specflow.execute`
**Gate**: The constitution exists, and the target feature already holds tasks and an `.analyzed` marker.
**Output**: Code changes, checked-off tasks.

### Gate markers

This workflow's agent owns these markers, not an upstream spec-kit command.
Do not assume a core command writes them for you.
First resolve one feature directory under the consuming project's root.
`specs/NNN/` stands for the actual directory, for example
`specs/001-user-login/`. Store feature artifacts outside `.specify/`.

| Command | Artifact | Completion rule |
|---------|----------|-----------------|
| `/speckit.clarify` | `specs/NNN-feature-name/.clarified` | After specify, resolve every `NEEDS CLARIFICATION` in the spec before writing the marker. |
| `/speckit.analyze` | `specs/NNN-feature-name/.analyzed` | After tasks, write the marker only when the analysis reports zero critical inconsistencies. |
| `/speckit.checklist` | `specs/NNN-feature-name/checklist-*.md` | Write the requested checklist with at least one checked or unchecked checkbox line. |

The agent writes the matching empty marker file after each successful clarify
or analyze run. Remove the marker before rerunning its command. A run that gets
interrupted, or a report with critical inconsistencies, must leave `.analyzed`
absent. Resolve the critical findings, rerun analysis, then retry execution.
Never create an analyze marker from artifact existence or inferred progress alone.

Remove `.clarified` when the spec changes. Remove `.analyzed` when the spec, plan,
tasks, or constitution changes. Checking off a task during execution does not
invalidate analysis. After a constitution change, invalidate the analysis markers
for every feature it governs.

When `/speckit.checklist` runs, direct its output to the feature's
`checklist-*.md` path. If the core command writes the checklist elsewhere, copy
the finished output to that path. Unchecked items are valid; an empty checklist
fails artifact linting.

Both execution entry points check `.analyzed` before implementation starts,
resumed runs included. A missing marker produces `ANALYZE_REQUIRED`, naming the
feature path and the `/speckit.analyze` command to run. This gate holds even
when Superpowers skills are unavailable.

### Steps

1. **Confirm the gates**: Require the constitution first, then the target
   feature's `.analyzed` marker. Stop with `ANALYZE_REQUIRED` when the marker
   is absent. Read tasks, plan, spec, and constitution once both checks pass.

2. **Detect superpowers**: Check whether the `executing-plans`,
   `subagent-driven-development`, and `test-driven-development` skills exist.

3. **Work through the tasks** phase by phase, honoring their execution markers:

   **For `[TDD]` tasks**:
   - Write the test first
   - Run it and confirm it FAILS
   - Write the minimal code that makes it pass
   - Run it and confirm it PASSES
   - Refactor when needed
   - If the TDD skill is available, follow its full process

   **For `[SUBAGENT]` tasks**:
   - On Claude Code, when the subagent-driven-development skill is found,
     follow its dispatch protocol
   - On Claude Code without the skill, dispatch one subagent per task through
     the Task tool and review each result before dispatching the next
   - On the Copilot CLI, implement each task in sequence, in the same session
   - When a task also carries `[P]`, the `[P]` rule below decides the surface

   **For `[REVIEW]` tasks**:
   - Finish the implementation
   - Show the changes to the user
   - Wait for explicit approval before moving on

   **For `[P]` tasks**:
   - On Claude Code, with Agent Teams available and
     `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` set: dispatch one teammate per
     `[P]` task in the batch, each in its own worktree, and state the file
     paths that task line names in the teammate's brief so no two teammates
     touch the same file. Do not nest teams. A teammate never dispatches its
     own team.
   - On Claude Code without Agent Teams: launch the batch in parallel through
     the Task tool
   - On the Copilot CLI: run the batch in order, the same as the non-parallel
     task path
   - Confirm no two parallel tasks name the same file

4. **At every checkpoint**:
   - Summarize the work completed
   - Run the applicable tests
   - Report the results
   - Ask: "Phase [N] complete. Proceed to Phase [N+1]?"
   - Wait for the user's explicit approval

5. **Check off each task** in `tasks.md` as it completes.

### Human Checkpoint Protocol

The agent MUST:
- Never skip a phase checkpoint
- Present a clear summary of the work done
- Report test results when tests ran
- Wait for the user's explicit "proceed" or "continue"
- Address any requested changes before proceeding

---

## Phase 6: Review

**Command**: `/speckit.specflow.review`
**Gate**: An implementation must exist (at least one task complete).
**Output**: The review reports its findings to the user.

### Steps

1. **Read inputs**: Pull the acceptance scenarios from the spec, the
   constitution check from the plan, the principles from the constitution,
   and `specs/NNN-feature-name/review-scope.md` when the `after_implement`
   hook wrote one.

2. **Superpowers detection**: When the `requesting-code-review` skill is
   available, follow its review protocol.

3. **Risk tier**: Add the changed lines and count the changed files from
   `git diff --numstat main...HEAD`. The tier is HIGH when the diff exceeds
   400 lines, touches more than 15 files, changes a path under a directory
   named `auth`, `payments`, `billing`, `migrations`, `infra`, `secrets`, or
   `crypto`, or changes a dependency lock file. Otherwise the tier is
   STANDARD. Use the `.claude/hooks/risk-classifier.sh` result instead, when
   the repository has that script. HIGH runs step 4 and then audits each
   finding for a `file:line` reference and evidence. STANDARD runs step 4
   once.

4. **Review dimensions** (built-in protocol):

   a. **Spec compliance**: Verify that each acceptance scenario in the spec is
      implemented and can be demonstrated.

   b. **Edge case coverage**: Verify that every edge case in the spec,
      including any found during brainstorming, has handling.

   c. **Constitution compliance**: Check that the implementation respects
      every principle.

   d. **Code quality**: Check correctness, security, error handling, and
      performance.

   e. **Test coverage**: Verify that tests exist for the critical paths.

5. **Report findings** with:
   - Confidence score (0-100, reported only when >= 80)
   - Severity (Critical / Important / Suggestion)
   - File path and line number
   - A specific recommendation

6. **Group** the findings by severity, highest first.

7. **Write** the findings to `specs/NNN-feature-name/review-findings.json`, in
   the shape `commands/review.md` defines under Findings File.

---

## Quick Reference

| Phase | Command | Gate | Output |
|-------|---------|------|--------|
| 0 | `/speckit.constitution` | None | `.specify/memory/constitution.md` |
| 1 | `/speckit.specify` | Constitution exists | `specs/NNN/spec.md` |
| 2 | `/speckit.specflow.brainstorm` | Spec exists | Updated spec.md |
| 3 | `/speckit.plan` | Spec exists | `specs/NNN/plan.md` |
| 4 | `/speckit.specflow.tasks` | Plan exists | `specs/NNN/tasks.md` |
| 5 | `/speckit.specflow.execute` | Constitution, tasks, and `.analyzed` exist | Code + updated tasks.md |
| 6 | `/speckit.specflow.review` | Implementation exists | Review report |

---

## Budgets

Each phase carries a recommended token ceiling and a suggested model class. A headless run enforces the ceiling with `claude -p --max-budget-usd`, the flag `merge-gate.yml` passes. Tune these values per organization. A higher ceiling buys deeper exploration; a lower ceiling keeps cost down.

| Phase | Token Ceiling | Model Class | Notes |
|-------|---------------|-------------|-------|
| 0 - Constitution | 150k | Haiku | Lightweight interview; mechanical |
| 1 - Specify | 200k | Sonnet | Balanced specification; user interview |
| 2 - Brainstorm | 250k | Opus | Thorough questioning; divergent thinking pays off |
| 3 - Plan | 200k | Sonnet | Technical planning; research codebase |
| 4 - Tasks | 150k | Sonnet | Task decomposition; mechanical breakdown |
| 5 - Execute | 500k | Variable | Most expensive; actual implementation. Mix: Haiku (mechanical), Sonnet (normal), Opus (complex). |
| 6 - Review | 300k | Opus | Multi-lens review; high-stakes reasoning. Scale with risk level (STRIDE, security, cross-model). |

**Headless gating:** In CI, pass `--max-turns 6` and `--max-budget-usd` to the `claude -p` invocation. Example: `claude -p "..." --output-format json --max-turns 6 --max-budget-usd 1.00`. The JSON output reports phase overages as `total_cost_usd`. A gate can reject a run that exceeds the ceiling.

**Tuning:** Track actual spend per phase (`.claude/telemetry.jsonl` + `jq` rollup). Adjust ceilings weekly for feature complexity and CLI speed. HIGH-risk features (auth, payments, migrations) often exceed standard ceilings by 20–50%. Allocate more budget or extend the critic loop allowance.

---

## Hotfix path

A defect in a released feature follows the hotfix path, which skips Phase 2
brainstorming and keeps every gate.

1. Branch from the release tag that carries the defect.
2. Write a failing test that reproduces the defect before changing any code.
3. Write the smallest fix that turns the test green.
4. Add tasks for the fix to the feature's `tasks.md` under new IDs. Completed
   IDs keep their numbers.
5. Remove `.clarified` and `.analyzed`, then rerun `/speckit.clarify` and
   `/speckit.analyze`. A hotfix changes the spec, so the prior analysis no
   longer holds.
6. Run the merge gate. The merge gate is the one step the hotfix path cannot
   skip, whatever the defect's severity.
7. Append a row to the spec's `## Changelog`: the new version, the date, and
   one line naming the defect and the fix.

A hotfix has one known outcome and nothing left to explore, so Phase 2 drops
out. Every other phase runs in its usual order.

---

## Differential implementation

Two executors implement the same spec in separate worktrees, then each runs
the other's tests. A disagreement between the implementations marks the spec
as ambiguous. Two implementations cost more than one, so this is not the
default Phase 5 path.

### Trigger

Run the differential implementation only when one of these holds. Otherwise,
follow the normal Phase 5 path.

- `.claude/hooks/risk-classifier.sh` prints `HIGH` for the change. Its other
  value is `STANDARD`.
- The feature's `spec.md` lists more than three open questions.

### Steps

1. Create the worktrees: `bash .claude/hooks/diff-impl.sh specs/NNN-feature-name`.
   The command prints both worktree paths and the test command each side runs.
   The script sits outside the extension archive a consuming project installs.
   Without it, run `git worktree add -b <feature>-a worktrees/<feature>-a HEAD`,
   then run it again for the `-b` worktree.
2. Implement worktree A with `implementation-engineer`, working from `spec.md`.
3. Implement worktree B with `codex:codex-rescue`, working from the same
   `spec.md`. Neither executor sees the other's diff.
4. Run A's tests in worktree B, then B's tests in worktree A.
5. Collect the divergences. A divergence is a test that passes in its own
   worktree and fails in the other, or an observable behavior difference the
   tests miss.
6. Append one row per divergence to the spec's `## Open Questions` table, with
   the failing test name opening the Question column. A divergence marks a gap
   in the spec, not a bug in one worktree, until answered.
7. Answer the questions. Keep one worktree, then delete the other with its
   branch.

---

## Session Resumability

Specflow survives a session interruption: all state lives in plain-text files.
`.specify/memory/` holds governance state (`constitution.md`); `specs/NNN-*/`
holds per-feature state (`spec.md`, `plan.md`, `tasks.md`, `progress.yml`). The
agent detects the resume point from these files and continues from there.

### Progress File: `progress.yml`

A feature spec directory may hold a `progress.yml` file:

```yaml
spec: 001-static-landing-page
status: complete
current_phase: 6
phases:
  - phase: 1
    name: Setup
    status: complete
    tasks:
      T001: complete
```

### Resume Check Protocol

Every specflow command runs this check first:

1. **Scan `.specify/`**: confirm the directory exists and look for spec directories inside it.
2. **Read `superpowers.yml`**: find which superpowers skills the project has detected.
   If the file is missing, run detection and create it.
3. **Read `progress.yml`**: get the current phase of each feature.
4. **If `progress.yml` is missing**: infer progress from which files exist:
   - `constitution.md` → constitution done
   - `spec.md` → specify done
   - `spec.md` has Brainstorm Log entries → brainstorm was run at least once
   - `plan.md` → plan done
   - `tasks.md` → tasks done
   - `tasks.md` has `[x]` checkboxes → execute in progress
5. **Report** the current state, including superpowers status, to the user before continuing
6. **Resume** work from the detected point; see the phase-specific rules below

`.claude/hooks/session-start.sh` prints `specs/NNN/handoff.md` at session start,
when the feature has one, before any command runs its own resume check.
`handoff.md` stays at 5 lines or fewer; `/speckit.specflow.execute` writes it at
each phase checkpoint under that limit.

### Phase-Specific Resume Rules

**Constitution** (`in_progress`):
- Re-read `constitution.md`
- Find sections that still hold a template placeholder such as `[PRINCIPLE_NAME]`
- Ask only about the sections left unresolved

**Specify** (`in_progress`):
- Re-read `spec.md`
- Look for a `[NEEDS CLARIFICATION]` marker or an empty placeholder section
- Continue the interview, covering only the unresolved items

**Brainstorm** (`in_progress`):
- Re-read the `spec.md` Brainstorm Log to see which sessions ran already
- Read the Open Questions table and count each `Open` and `Resolved` entry
- Skip any category a previous session already covered
- Resume at the first unexplored category or open question

**Plan** (`in_progress`):
- Re-read `plan.md`
- Look for a `NEEDS CLARIFICATION` field
- Fill in the missing technical context; do not regenerate a section that is already complete

**Tasks** (`in_progress`):
- Re-read `tasks.md`
- Check that every user story in `spec.md` maps to a task
- Add any missing task without disturbing the existing numbering

**Execute** (`in_progress`):
- Re-read `tasks.md` and parse its checkboxes
- Count the `[x]` entries against the `[ ]` entries
- Find the **current phase**: the first phase with an unchecked task
- Skip every completed task and resume at the first `[ ]` task in that phase
- Re-present the checkpoint summary if a phase checkpoint is still unconfirmed

**Review** (`in_progress`):
- Re-read any checklist file already on disk
- Continue from the first unchecked review item

### Writing `progress.yml`

The agent writes to `progress.yml` at these points:

| Event | Update |
|-------|--------|
| Command starts | Set phase to `in_progress`, update timestamp |
| Command completes successfully | Set phase to `done`, update timestamp |
| Brainstorm session ends | Increment `sessions` counter |
| Task checkbox toggled during execute | Update `completed_tasks` and `current_task` |
| User explicitly skips a phase | Set phase to `skipped` |

If `progress.yml` does not exist when a command runs, the command creates it
and infers every prior phase as `done` from the files already on disk.

### Superpowers Status File: `superpowers.yml`

The project-level file `.specify/superpowers.yml` stores the superpowers
detection result so it stays **visible in the project docs** and **doesn't
need re-detection on every command**.

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

**When to update `superpowers.yml`**:

| Event | Action |
|-------|--------|
| `/speckit.constitution` (first run) | Create the file with full detection results |
| `/speckit.specflow.status` | Re-run detection, update the file |
| Any command that needs a superpowers skill | If the skill was previously `detected: false`, re-check once (user may have installed it) |
| User manually edits the file | Respect the manual override, do not overwrite |

**Why persist this**:

1. **Visibility**: a reader of `.specify/` can see which superpowers the project uses
2. **Auditability**: the `last_checked` timestamp records when detection last ran
3. **Speed**: the command reads the cache instead of checking the filesystem on every invocation
4. **Override**: a user can set `detected: true/false` by hand to force the behavior

**Reading superpowers status during resume**:

The resume check reads `superpowers.yml` instead of re-detecting.
`/speckit.specflow.brainstorm`, for example, uses the cached result to choose
between enhanced mode (superpowers) and fallback mode (built-in). When a skill
was `detected: false` last time, the command runs one re-check before it falls
back, in case the user installed the skill since the last session.

---

## Review stack

Four review stages run against a feature. Each stage writes findings JSON that
conforms to `.claude/review/schema.json`.

- **Stage 0: spec red-team.** `spec-red-team-reviewer` and `threat-model-reviewer`
  attack `spec.md` before any code exists. The gate is no unresolved
  `[NEEDS CLARIFICATION]` marker and no Critical inconsistency.
- **Stage 1: conformance.** `conformance-reviewer` sees only `spec.md` and the diff.
  It derives one test per acceptance criterion. The gate is a passing test for
  every criterion.
- **Stage 2: panel.** `correctness-reviewer`, `security-reviewer`, and
  `maintainability-reviewer` review in parallel fresh contexts. Add
  `performance-reviewer` for a performance-sensitive diff. A finding raised by two
  or more personas is promoted one severity level.
- **Stage 3: critic.** For a HIGH risk change only, `critic` audits the panel's
  findings, not the code. It rejects any finding without a `file:line`
  reference or a failing test. The loop stops after three rounds.

The agents live in `.claude/agents/`. They are not part of the extension archive a
consuming project installs. When they are absent, `/speckit.specflow.review` and
its built-in protocol above are the fallback for all four stages. The command
writes the same findings shape to `specs/NNN-feature-name/review-findings.json`.
This repository's gate reads that file with
`bash .claude/hooks/merge-gate.sh 'specs/*/review-findings.json'`.
