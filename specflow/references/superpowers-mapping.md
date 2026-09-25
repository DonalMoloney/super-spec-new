# Superpowers Skill Mapping

Specflow finds an obra/superpowers skill, runs the skill's own process, and
writes what it produces into spec-kit's files. `SKILL.md` sends a reader here
for the detection rules and the adaptation rules.

## Detection Logic

Specflow looks for a superpowers skill at two paths, highest precedence first:

1. **Project-local**: `$PROJECT_DIR/.agents/skills/{skill-name}/SKILL.md`
2. **User-global**: `~/.agents/skills/{skill-name}/SKILL.md`

A skill counts as **available** when its `SKILL.md` exists at either path. The
project-local copy wins over the user-global one.

Tested range: `>=6.0.0 <7.0.0`. Superpowers 6.0 rewrote
`subagent-driven-development` and 6.2 moved its workspace, so a 5.x install runs
a different protocol. `/speckit.specflow.status` prints
`superpowers <version> is outside the tested range <range>` when the installed
version sits outside that range.

### Detection Steps

A specflow command that needs a superpowers skill runs these steps:

1. Read the skill name out of the mapping table below
2. Look at the project-local path first, with Glob or Read
3. If nothing is there, look at the user-global path
4. If found: log "Found {skill-name} at {path}" and switch to skill mode
5. If not found: log "Superpowers {skill-name} not detected, using built-in fallback"
   and switch to fallback mode

## Skill Mapping

| Specflow Command | Superpowers Skill Name | Skill Directory | Surface | When it runs |
|-------------------|------------------------|-----------------|---------|--------------|
| `/speckit.specflow.brainstorm` | `brainstorming` | `brainstorming/` | Both | Every run |
| `/speckit.specflow.tasks` | `writing-plans` | `writing-plans/` | Both | Every run |
| `/speckit.specflow.execute` | `subagent-driven-development` | `subagent-driven-development/` | Claude Code | Every run |
| `/speckit.specflow.execute` | `executing-plans` | `executing-plans/` | Copilot CLI | Every run |
| `/speckit.specflow.execute` | `test-driven-development` | `test-driven-development/` | Both | On a `[TDD]` task |
| `/speckit.specflow.execute` | `systematic-debugging` | `systematic-debugging/` | Both | On a failing test |
| `/speckit.specflow.execute` | `verification-before-completion` | `verification-before-completion/` | Both | Before ticking a task |
| `/speckit.specflow.execute` | `using-git-worktrees` | `using-git-worktrees/` | Claude Code | On `[SUBAGENT]` dispatch |
| `/speckit.specflow.execute` | `dispatching-parallel-agents` | `dispatching-parallel-agents/` | Claude Code | On a `[P]` batch |
| `/speckit.specflow.review` | `requesting-code-review` | `requesting-code-review/` | Both | Every run |
| `/speckit.specflow.review` | `receiving-code-review` | `receiving-code-review/` | Both | After findings are reported |
| `/speckit.specflow.review` | `finishing-a-development-branch` | `finishing-a-development-branch/` | Both | After the merge gate passes |

Claude Code runs `subagent-driven-development` for execute; the Copilot CLI has
no subagents, so it runs `executing-plans` instead.

## Invocation Pattern

Once the agent finds a skill, it runs these four steps.

### Step 1: Read the Skill

```
Read ~/.agents/skills/{skill-name}/SKILL.md
```

The file states the skill's process steps and what the skill produces.

### Step 2: Adapt Context

Set three rules before the skill's process starts:

- **Input context**: Hand the skill the spec-kit files it needs
  - Constitution: `.specify/memory/constitution.md`
  - Spec: `specs/NNN/spec.md`
  - Plan: `specs/NNN/plan.md` (if exists)
  - Tasks: `specs/NNN/tasks.md` (if exists)

- **Output location**: Every file the skill writes lands under `.specify/`
  - Superpowers defaults to `docs/superpowers/`; send it to `.specify/` instead
  - Brainstorming insights → spec.md, under Edge Cases, Open Questions, Brainstorm Log
  - Writing-plans output → merged into `specs/NNN/tasks.md`
  - Code review findings → reported to the user, optionally written to a checklist file

- **Naming conventions**: Keep spec-kit's names
  - Feature numbering: NNN (001, 002, ...)
  - File naming: spec.md, plan.md, tasks.md (not design-doc.md, blueprint.md)

### Step 3: Follow the Skill's Process

Run the skill's steps as its `SKILL.md` writes them, against the adapted context.
The skill owns the process. Specflow owns only where the files come from and
where they go.

### Step 4: Integrate Results

Once the skill's process ends:
- Check every file it wrote sits under `.specify/`
- Repoint a cross-reference the move broke, such as tasks.md naming spec.md
- Record what ran in the tracking section that covers it, such as the Brainstorm Log

## Skill-Specific Adaptation Rules

### brainstorming → `/speckit.specflow.brainstorm`

**Process adaptation**:
- Follow the brainstorming skill's questioning protocol: one question at a time,
  Socratic method, assumptions challenged
- Ask every question against the spec document under review
- Write each insight into the spec's "Open Questions" section and "Brainstorm Log"
- Read `decisions.md` at the project root first, when it exists, and skip a
  decision already recorded there
- Fold a "design document" the skill produces back into the existing spec.md
  instead of keeping it as a separate file

**Output mapping**:
| Superpowers Output | Specflow Destination |
|--------------------|-----------------------|
| Design document | Update spec.md Edge Cases + Open Questions |
| Clarified requirements | Update spec.md Functional Requirements |
| Resolved questions | Update spec.md Open Questions table (mark Resolved) |

### writing-plans → `/speckit.specflow.tasks`

**Process adaptation**:
- Break the work into tasks the way the writing-plans skill does
- Shape the result to specflow's `tasks-template.md`
- Read the plan's execution strategy section, then mark each task `[TDD]`,
  `[REVIEW]`, `[SUBAGENT]`, or `[P]`

**Output mapping**:
| Superpowers Output | Specflow Destination |
|--------------------|-----------------------|
| Implementation blueprint | `specs/NNN/tasks.md` |
| Task dependencies | Tasks Dependencies section |
| Parallel opportunities | Tasks marked with `[P]` and `[SUBAGENT]` |

### executing-plans → `/speckit.specflow.execute`

**Process adaptation**:
- Follow the executing-plans skill's batch protocol
- Stop at every checkpoint gate `tasks.md` names
- Specflow's checkpoint wins at a phase boundary: stop and wait for
  confirmation. Inside a phase the skill's no-pause rule holds. Reason: a phase
  boundary is where `progress.yml` is written and where a user can still
  redirect cheaply.

The Copilot CLI has no subagents, so it runs a task marked `[SUBAGENT]` in order
in its one session. On Claude Code the `subagent-driven-development` dispatch
protocol covers that marker.

**Combined with**:
- `test-driven-development`: follow this skill's RED-GREEN-REFACTOR discipline
  for a task marked `[TDD]`, on either surface

### requesting-code-review → `/speckit.specflow.review`

**Process adaptation**:
- Work through the requesting-code-review skill's pre-evaluation checklist
- Add three specflow dimensions to it:
  - Spec compliance, against the acceptance scenarios in spec.md
  - Constitution compliance, against the principles in constitution.md
  - Brainstorm coverage, against the edge cases the brainstorm raised
- Score each finding from 0 to 100 for confidence and report those at 80 or above
- Append each Critical or Important finding that reports a spec gap to the spec's
  `## Open Questions` table, with the finding ID opening the Question column

**Output mapping**:
| Superpowers Output | Specflow Destination |
|--------------------|-----------------------|
| Review findings | Reported to user |
| Findings JSON | `specs/NNN/review-findings.json` |
| Checklist | Optional: `specs/NNN/checklist-review.md` |

**Review personas**:

Claude Code can split the review across separate contexts, one persona per
dimension. The Copilot CLI has one session and covers the same ground from the
review command's own Process steps. "Review step 5" below names step 5 of
`/speckit.specflow.review`, whose five dimensions are spec compliance, edge case
coverage, constitution compliance, code quality, and test coverage. Neither
surface drops a dimension.

| Persona | Dimension it covers | Step the Copilot CLI runs instead |
|---------|---------------------|-----------------------------------|
| `spec-red-team-reviewer` | Tests every acceptance criterion for ambiguity before code exists | The questioning protocol in [workflow-guide.md](workflow-guide.md) Phase 2, before `/speckit.plan` |
| `threat-model-reviewer` | STRIDE pass over the trust boundaries the spec names | The security and privacy category of that same Phase 2 protocol |
| `conformance-reviewer` | One observable check per acceptance criterion, from the spec and the diff alone | Review step 5, spec compliance |
| `correctness-reviewer` | Logic bugs, boundary values, error propagation, resource cleanup | Review step 5, code quality |
| `security-reviewer` | Injection, authentication, authorization, secret exposure, supply chain | Review step 5, code quality |
| `maintainability-reviewer` | Names, coupling, duplication, test isolation | Review step 5, code quality |
| `performance-reviewer` | Complexity, query count, repeated IO, unbounded retries | Review step 5, code quality |
| `code-reviewer` | One pass over a whole change set: tests, implementation, refactors | Review step 5, all five dimensions in order |
| `payload-compatibility-reviewer` | A change to specflow's own payload, read against both target surfaces | None. The row covers the extension, not a feature |
| `release-archive-reviewer` | The install archive after a manifest or payload change | None. The row covers the extension, not a feature |

The personas are Claude Code support files in specflow's own repository. The
install archive leaves them out, so a project that installs specflow gets the
review command and its built-in protocol on either surface. The last two rows
check the extension itself and have no counterpart in a feature review.

## Graceful Degradation

Every superpowers integration carries a built-in fallback. A missing superpowers
install never stops a command.

### Fallback Behavior Summary

| Superpowers Skill | Fallback | Where Defined |
|-------------------|----------|---------------|
| `brainstorming` | Questions across 5 categories: boundary, error, scale, security, UX | [workflow-guide.md](workflow-guide.md) Phase 2 |
| `writing-plans` | Task breakdown straight from the plan, against the template | [workflow-guide.md](workflow-guide.md) Phase 4 |
| `executing-plans` | Tasks walked in order, with a manual confirmation at each checkpoint | [workflow-guide.md](workflow-guide.md) Phase 5 |
| `subagent-driven-development` | Implementation in the one session, in order, with no parallel dispatch | [workflow-guide.md](workflow-guide.md) Phase 5 |
| `test-driven-development` | Inline TDD: write test → verify fail → implement → verify pass | [workflow-guide.md](workflow-guide.md) Phase 5 |
| `requesting-code-review` | Built-in checklist: spec compliance, constitution, code quality | [workflow-guide.md](workflow-guide.md) Phase 6 |

### Fallback Quality

A fallback does less than the superpowers skill it stands in for:

- **Brainstorming fallback**: asks about the same 5 categories from a fixed
  question list. Superpowers brainstorming adds the Socratic method and
  challenges the assumption behind an answer.

- **Writing-plans fallback**: breaks the plan down against the task template.
  Superpowers writing-plans reads task dependencies more closely and finds work
  that can run in parallel.

- **Execution fallback**: walks the tasks in order and stops at each manual
  checkpoint. Superpowers batches the tasks, dispatches subagents where the
  surface has them, and judges a checkpoint itself.

- **Review fallback**: works through a fixed checklist. Superpowers runs several
  reviewers in parallel, scores each finding for confidence, and drops the false
  positives.

## Troubleshooting

### Skills Not Detected

If superpowers is installed and a skill still reads as missing:

1. Check the skill directory name matches exactly, including case
2. Check `SKILL.md` sits inside that skill directory
3. Check both paths: `.agents/skills/` (project) and `~/.agents/skills/` (global)
4. Check the file is readable

### Skill Process Conflicts

If the skill's process conflicts with a specflow convention, four rules settle it:

1. Specflow's output locations win: every file goes under `.specify/`
2. Specflow's names win: spec.md, plan.md, tasks.md
3. The skill's process and its questions win over the fallback protocol
4. Otherwise follow the superpowers process and change only where the files land
