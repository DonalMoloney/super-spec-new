# Specflow Workflow Guide

This guide gives phase-by-phase instructions for the specflow workflow. SKILL.md
references this document for progressive disclosure: the agent reads only the
matching section while it runs a command.

## Phase 0: Project Initialization

**Command**: `/speckit.constitution`
**Gate**: None. This phase starts the workflow.
**Output**: `.specify/` directory structure + `memory/constitution.md`

### Steps

1. **Create directory structure**:
   ```
   .specify/
   ├── memory/
   ├── specs/
   └── templates/
   ```

2. **Copy templates** from the specflow skill's `templates/` directory into
   `.specify/templates/`. The project keeps its own copy to customize.

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
**Gate**: The target spec file exists.
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
   Use multiple-choice form where it speeds up the exchange.

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
**Gate**: The spec file must exist. Brainstorming helps but isn't required.
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
- The technical context is filled in, with no NEEDS CLARIFICATION left without a stated reason
- The project structure names real file paths
- The execution strategy states at least the TDD and checkpoint decisions

---

## Phase 4: Task Decomposition

**Command**: `/speckit.specflow.tasks`
**Gate**: The target feature already has a plan.
**Output**: `specs/NNN-feature-name/tasks.md`

### Steps

1. **Read inputs**: plan, spec, constitution.

2. **Superpowers integration**: When the `writing-plans` skill is detected, read it
   and follow its task decomposition process. Structure the output with the
   `tasks-template.md` format.

3. **Split the plan** into phases:
   - Phase 1: Setup (project structure and dependencies)
   - Phase 2: Foundational (prerequisites that block later phases)
   - Phase 3+: one phase per user story, highest priority first
   - Final phase: Polish, plus concerns that cut across every phase

4. **Add the execution markers** from the plan's execution strategy:
   - `[TDD]` for a component that needs tests first
   - `[REVIEW]` for a component that needs a review gate
   - `[SUBAGENT]` for an independent work stream
   - `[P]` for a task in the same phase that can run in parallel with the rest

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
**Gate**: Constitution exists. The target feature has tasks and an `.analyzed` marker.
**Output**: Code changes, updated task checkboxes.

### Gate markers

The agent following this Specflow workflow owns these markers around core
spec-kit commands. Do not assume an upstream command creates them automatically.
Resolve one feature directory under the consuming project's root first.
`specs/NNN/` is shorthand for its actual directory, such as
`specs/001-user-login/`. Keep feature artifacts outside `.specify/`.

| Command | Artifact | Completion rule |
|---------|----------|-----------------|
| `/speckit.clarify` | `specs/NNN-feature-name/.clarified` | After specify, resolve every `NEEDS CLARIFICATION` in the spec before writing the marker. |
| `/speckit.analyze` | `specs/NNN-feature-name/.analyzed` | After tasks, write the marker only when the analysis reports zero critical inconsistencies. |
| `/speckit.checklist` | `specs/NNN-feature-name/checklist-*.md` | Write the requested checklist with at least one checked or unchecked checkbox line. |

After each successful clarify or analyze result, the agent writes the matching
empty marker file. Remove that marker before rerunning its command. An interrupted
run or a report with critical inconsistencies must leave `.analyzed` absent.
Resolve critical findings, rerun analysis, then retry execution. Never create an
analyze marker from artifact existence or inferred progress alone.

Remove `.clarified` when the spec changes. Remove `.analyzed` when the spec, plan,
tasks, or constitution changes. Changes to task completion checkboxes during
execution do not invalidate analysis. After a constitution change, invalidate
analysis markers for all features governed by it.

When invoking `/speckit.checklist`, direct its output to the feature's
`checklist-*.md` path. If the core command emits a checklist elsewhere, copy its
completed output to that path. Unchecked items are valid; an empty checklist fails
artifact linting.

Both execution entry points check `.analyzed` before implementation starts,
including resumed runs. A missing marker produces `ANALYZE_REQUIRED` with the
feature path and instructions to run `/speckit.analyze`. This gate applies even
when Superpowers skills are unavailable.

### Steps

1. **Verify gates**: Require the constitution, then the target feature's
   `.analyzed` marker. Stop with `ANALYZE_REQUIRED` if the marker is absent.
   Read tasks, plan, spec, and constitution after these checks pass.

2. **Superpowers detection**: Check for `executing-plans`,
   `subagent-driven-development`, and `test-driven-development` skills.

3. **Walk through tasks** phase by phase, respecting execution markers:

   **For `[TDD]` tasks**:
   - Write the test first
   - Run it and confirm it FAILS
   - Implement the minimum code to pass
   - Run it and confirm it PASSES
   - Refactor if needed
   - If TDD skill available: follow its full process

   **For `[SUBAGENT]` tasks**:
   - On Claude Code with the subagent-driven-development skill found, follow
     its dispatch protocol
   - On Claude Code without the skill, dispatch one subagent per task with the
     Task tool and review each result before the next dispatch
   - On the Copilot CLI, implement sequentially in-session
   - If marked `[P]` as well, the `[P]` rule below decides the surface

   **For `[REVIEW]` tasks**:
   - Complete the implementation
   - Present the changes to the user
   - Wait for explicit approval before continuing

   **For `[P]` tasks**:
   - On Claude Code with Agent Teams available and
     `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` set: dispatch one teammate per
     `[P]` task in the batch, each in its own worktree, with the file paths the
     task line names stated in the teammate's brief so no two teammates touch
     the same file. Do not nest teams. A teammate never dispatches its own team.
   - On Claude Code without Agent Teams: launch the batch in parallel with the
     Task tool
   - On the Copilot CLI: run the batch in order, identical to the non-parallel
     task path
   - Check that no two parallel tasks name the same file

4. **At each checkpoint**:
   - Summarize completed work
   - Run applicable tests
   - Report results
   - Ask: "Phase [N] complete. Proceed to Phase [N+1]?"
   - Wait for explicit user approval

5. **Update task checkboxes** in `tasks.md` as each task completes.

### Human Checkpoint Protocol

The agent MUST:
- Never skip a phase checkpoint
- Present a clear summary of what was done
- Report test results if tests were run
- Wait for explicit "proceed" or "continue" from the user
- If the user requests changes, address them before proceeding

---

## Phase 6: Review

**Command**: `/speckit.specflow.review`
**Gate**: Implementation must exist (at least some tasks completed).
**Output**: Review findings reported to user.

### Steps

1. **Read inputs**: spec (acceptance scenarios), plan (constitution check),
   constitution (principles), and `specs/NNN-feature-name/review-scope.md`
   when the `after_implement` hook wrote one.

2. **Superpowers detection**: If `requesting-code-review` skill is available,
   follow its review protocol.

3. **Risk tier**: Sum the lines and count the files in
   `git diff --numstat main...HEAD`. HIGH when more than 400 lines or more than
   15 files changed, when a changed path has a directory named `auth`,
   `payments`, `billing`, `migrations`, `infra`, `secrets`, or `crypto`, or
   when a dependency lock file changed. Otherwise STANDARD. Take the answer of
   `.claude/hooks/risk-classifier.sh` instead when the repository has it. HIGH
   runs step 4 and then audits each finding for a `file:line` reference and
   evidence; STANDARD runs step 4 once.

4. **Review dimensions** (built-in protocol):

   a. **Spec compliance**: For each acceptance scenario in the spec, verify it
      is implemented and can be demonstrated.

   b. **Edge case coverage**: For each edge case in the spec (including those
      from brainstorming), verify handling exists.

   c. **Constitution compliance**: For each principle, verify the implementation
      respects it.

   d. **Code quality**: Check for correctness, security, error handling, performance.

   e. **Test coverage**: Verify tests exist for critical paths.

5. **Report findings** with:
   - Confidence score (0-100, only report issues >= 80)
   - Severity (Critical / Important / Suggestion)
   - File path and line reference
   - Specific recommendation

6. **Group** by severity, highest first.

7. **Write** the findings to `specs/NNN-feature-name/review-findings.json` in
   the shape `commands/review.md` documents under Findings File.

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

Each phase has a recommended token ceiling and suggested model class. Headless runs can enforce the ceiling via the Claude budget-cap flag (name not yet confirmed; see G-09 T092). Tune these values per organization: higher ceilings allow more thorough exploration; lower ceilings prioritize cost.

| Phase | Token Ceiling | Model Class | Notes |
|-------|---------------|-------------|-------|
| 0 - Constitution | 150k | Haiku | Lightweight interview; mechanical |
| 1 - Specify | 200k | Sonnet | Balanced specification; user interview |
| 2 - Brainstorm | 250k | Opus | Thorough questioning; divergent thinking pays off |
| 3 - Plan | 200k | Sonnet | Technical planning; research codebase |
| 4 - Tasks | 150k | Sonnet | Task decomposition; mechanical breakdown |
| 5 - Execute | 500k | Variable | Most expensive; actual implementation. Mix: Haiku (mechanical), Sonnet (normal), Opus (complex). |
| 6 - Review | 300k | Opus | Multi-lens review; high-stakes reasoning. Scale with risk level (STRIDE, security, cross-model). |

**Headless gating:** In CI workflows, pass `--max-turns 6` and the budget-cap flag to the `claude -p` invocation. Example: `claude -p "..." --output-format json --max-turns 6 [budget-flag-TBD]`. Phase overages are reported in the JSON output as `total_cost_usd`; gates can reject runs exceeding the ceiling.

**Tuning:** Track actual spend per phase (`.specify/telemetry.jsonl` + `jq` rollup); adjust ceilings weekly based on feature complexity and CLI speed. HIGH-risk features (auth, payments, migrations) typically exceed standard ceilings by 20–50%; allocate accordingly or extend the critic loop allowance.

---

## Hotfix path

A defect in a released feature takes the hotfix path. The hotfix path skips
Phase 2 brainstorming and keeps every gate.

1. Branch from the release tag that carries the defect.
2. Write a failing test that reproduces the defect before changing any code.
3. Write the smallest fix that turns the test green.
4. Add tasks for the fix to the feature's `tasks.md` with new IDs. Completed
   IDs keep their numbers.
5. Remove `.clarified` and `.analyzed`, then run `/speckit.clarify` and
   `/speckit.analyze` again. A hotfix changes the spec, so the analysis that
   preceded it no longer holds.
6. Run the merge gate. The merge gate is the one step the hotfix path cannot
   skip, whatever the severity of the defect.
7. Append a row to the spec's `## Changelog`: the new version, the date, and
   one line naming the defect and the fix.

Phase 2 drops out because a hotfix has one known outcome and nothing left to
explore. Every other phase runs in its usual order.

---

## Differential implementation

Two executors implement the same spec in separate worktrees, then each side runs
the other's tests. Where the two implementations disagree, the spec is ambiguous.
The run pays for two implementations, so it is not the default Phase 5 path.

### Trigger

Run it only when one of these holds. Otherwise take the normal Phase 5 path.

- `.claude/hooks/risk-classifier.sh` prints `HIGH` for the change. Its other
  value is `STANDARD`.
- The feature's `spec.md` lists more than three open questions.

### Steps

1. Create the worktrees: `bash .claude/hooks/diff-impl.sh specs/NNN-feature-name`.
   It prints the two paths and the test command both sides run. The script is not
   part of the extension archive a consuming project installs; without it, run
   `git worktree add -b <feature>-a worktrees/<feature>-a HEAD` and the same for
   `-b`.
2. Implement worktree A with `implementation-engineer`, working from `spec.md`.
3. Implement worktree B with `codex:codex-rescue`, working from the same
   `spec.md`. Neither executor sees the other's diff.
4. Run A's tests in worktree B, then B's tests in worktree A.
5. Collect the divergences: every test that passes in its own worktree and fails
   in the other, plus every observable behavior difference the tests miss.
6. Append one row per divergence to the spec's `## Open Questions` table, with
   the failing test name opening the Question column. A divergence names a gap in
   the spec, not a bug in one worktree, until the question is answered.
7. Answer the questions, keep one worktree, and delete the other with its branch.

---

## Session Resumability

Specflow survives session interruptions. All state lives in plain-text
files under `.specify/memory/` (governance: `constitution.md`) and `specs/NNN-*/`
(per-feature: `spec.md`, `plan.md`, `tasks.md`, `progress.yml`). This section
documents how the agent detects and resumes work.

### Progress File: `progress.yml`

Each feature spec directory may contain a `progress.yml` file:

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

Every specflow command begins with:

1. **Scan `.specify/`**: does it exist? Are there spec directories?
2. **Read `superpowers.yml`**: which superpowers skills are available?
   If the file does not exist, run detection and create it.
3. **Read `progress.yml`**: what phase is each feature in?
4. **If no `progress.yml`**: Infer progress from file existence:
   - `constitution.md` → constitution done
   - `spec.md` → specify done
   - `spec.md` has Brainstorm Log entries → brainstorm was run at least once
   - `plan.md` → plan done
   - `tasks.md` → tasks done
   - `tasks.md` has `[x]` checkboxes → execute in progress
5. **Report** current state to the user (including superpowers status) before proceeding
6. **Resume** from the detected point (see phase-specific rules below)

`.claude/hooks/session-start.sh` prints `specs/NNN/handoff.md` at session start if the
feature has one, ahead of any command-driven resume check. `handoff.md` stays at 5
lines or fewer, the convention `/speckit.specflow.execute` follows when it writes the
file at each phase checkpoint.

### Phase-Specific Resume Rules

**Constitution** (`in_progress`):
- Re-read `constitution.md`
- Identify sections still containing template placeholders (`[PRINCIPLE_NAME]`, etc.)
- Ask user about remaining sections only

**Specify** (`in_progress`):
- Re-read `spec.md`
- Look for `[NEEDS CLARIFICATION]` markers and empty placeholder sections
- Continue the interview for unresolved items only

**Brainstorm** (`in_progress`):
- Re-read `spec.md` Brainstorm Log to see which sessions have been completed
- Re-read Open Questions table and count `Open` vs `Resolved`
- Skip categories already covered in previous sessions
- Resume from the first unexplored category or open question

**Plan** (`in_progress`):
- Re-read `plan.md`
- Look for `NEEDS CLARIFICATION` fields
- Fill in missing technical context; do not regenerate completed sections

**Tasks** (`in_progress`):
- Re-read `tasks.md`
- Verify all user stories from `spec.md` have corresponding tasks
- Add missing tasks without disrupting existing task numbering

**Execute** (`in_progress`):
- Re-read `tasks.md` and parse checkboxes
- Count `[x]` (completed) vs `[ ]` (remaining)
- Identify the **current phase** (first phase with unchecked tasks)
- Skip all completed tasks; resume from the first `[ ]` task in that phase
- If a phase checkpoint was not yet confirmed, re-present the checkpoint summary

**Review** (`in_progress`):
- Re-read any existing checklist files
- Continue from unchecked review items

### Writing `progress.yml`

The agent updates `progress.yml` at these moments:

| Event | Update |
|-------|--------|
| Command starts | Set phase to `in_progress`, update timestamp |
| Command completes successfully | Set phase to `done`, update timestamp |
| Brainstorm session ends | Increment `sessions` counter |
| Task checkbox toggled during execute | Update `completed_tasks` and `current_task` |
| User explicitly skips a phase | Set phase to `skipped` |

If `progress.yml` does not exist when a command runs, create it with all
prior phases inferred as `done` based on existing files.

### Superpowers Status File: `superpowers.yml`

A project-level file `.specify/superpowers.yml` persists the superpowers detection
results so they are **visible in the project docs** and **don't require re-detection
on every command**.

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

1. **Visibility**: Anyone reading `.specify/` can see which superpowers the project uses
2. **Auditability**: The `last_checked` timestamp shows when detection last ran
3. **Speed**: No need to check the filesystem on every command invocation
4. **Override**: Users can manually set `detected: true/false` to force behavior

**Reading superpowers status during resume**:

When the resume check runs, it reads `superpowers.yml` instead of re-detecting.
This means a command like `/speckit.specflow.brainstorm` will use the cached detection
result to decide between enhanced mode (superpowers) and fallback mode (built-in).
If a skill was `detected: false` last time, the command does a single re-check
before falling back, in case the user installed it since the last session.

---

## Review stack

Four review stages run against a feature. Each stage writes findings JSON that
conforms to `.claude/review/schema.json`.

- **Stage 0: spec red-team.** `spec-red-team-reviewer` and `threat-model-reviewer`
  attack `spec.md` before any code exists. The gate is no unresolved
  `[NEEDS CLARIFICATION]` marker and no Critical inconsistency.
- **Stage 1: conformance.** `conformance-reviewer` sees only `spec.md` and the diff,
  and derives one test per acceptance criterion. The gate is a passing test for
  every criterion.
- **Stage 2: panel.** `correctness-reviewer`, `security-reviewer`, and
  `maintainability-reviewer` review in parallel fresh contexts. Add
  `performance-reviewer` for a performance-sensitive diff. A finding raised by two
  or more personas is promoted one severity level.
- **Stage 3: critic.** For a HIGH risk change only, `critic` audits the panel's
  findings rather than the code, and rejects any finding without a `file:line`
  reference or a failing test. The loop stops after three rounds.

The agents live in `.claude/agents/` and are not part of the extension archive a
consuming project installs. When they are absent, `/speckit.specflow.review` and
its built-in protocol above are the fallback for all four stages, and the
command writes the same findings shape to `specs/NNN-feature-name/review-findings.json`.
This repository's gate reads that file with
`bash .claude/hooks/merge-gate.sh 'specs/*/review-findings.json'`.
