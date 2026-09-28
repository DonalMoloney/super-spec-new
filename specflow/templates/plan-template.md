<!-- specflow template: plan-template 1.1.0 -->
# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link to spec.md]
**Input**: Feature specification from `specs/[###-feature-name]/spec.md`

## Summary

[Extract from feature spec: primary requirement + technical approach]

## Technical Context

<!--
  Fill each placeholder with the real technical choice.
  Flag an unresolved item as NEEDS CLARIFICATION.
-->

**Language/Version**: [e.g., Python 3.11, TypeScript 5.x, Rust 1.75 or NEEDS CLARIFICATION]
**Primary Dependencies**: [e.g., FastAPI, React, Express or NEEDS CLARIFICATION]
**Storage**: [if applicable, e.g., PostgreSQL, localStorage, files or N/A]
**Testing**: [e.g., pytest, vitest, cargo test or NEEDS CLARIFICATION]
**Target Platform**: [e.g., Linux server, iOS 15+, mobile-first H5 or NEEDS CLARIFICATION]
**Project Type**: [e.g., library/cli/web-service/mobile-app or NEEDS CLARIFICATION]
**Performance Goals**: [domain-specific targets or NEEDS CLARIFICATION]
**Constraints**: [domain-specific constraints or NEEDS CLARIFICATION]

## Constitution Check

*GATE: The plan must pass this check before work starts. Re-run the check once the Project Structure and Execution Strategy sections are filled.*

<!--
  Weigh the plan against every principle in the constitution.
  Mark each principle PASS, NEEDS ATTENTION, or VIOLATION, and name the
  command, file, or plan section a reader runs or opens to confirm the status.
-->

| Principle | Status | Evidence |
|-----------|--------|----------|
| [Principle 1 from constitution] | PASS / NEEDS ATTENTION / VIOLATION | [command, path, or plan section that shows it] |
| [Principle 2 from constitution] | PASS / NEEDS ATTENTION / VIOLATION | [command, path, or plan section that shows it] |

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── spec.md              # Feature specification
├── plan.md              # This file
├── tasks.md             # Task breakdown (/speckit.specflow.tasks output)
└── checklist-*.md       # Generated checklists
```

### Source Code (repository root)

<!--
  Swap the layout below for this feature's real structure.
  Delete the options this feature skips, and list its real paths.
-->

```text
src/
├── models/
├── services/
└── [feature-specific]/

tests/
├── unit/
├── integration/
└── contract/
```

**Structure Decision**: [Document the selected structure and rationale]

## Execution Strategy

<!--
  Record how tasks run here.
  `/speckit.specflow.tasks` reads it to build the task breakdown.
  `/speckit.specflow.execute` reads it while it runs the tasks.
-->

### TDD Requirements

<!--
  Name the areas of this feature that need strict RED-GREEN-REFACTOR discipline.
  The task breakdown flags its tasks with [TDD].
-->

- [ ] [Component/module]: [Why TDD is needed, e.g., "Complex business logic with many edge cases"]
- [ ] [Component/module]: [Why TDD is needed]

### Independent Work Streams

<!--
  Name each work stream that carries no dependency on another.
  The task breakdown flags its tasks with [SUBAGENT], and marks tasks
  inside one stream [P] when they touch different files.
  Claude Code dispatches them as parallel subagents.
  The Copilot CLI keeps one session, so it runs them in order.
-->

- [ ] [Work stream A] shares no files or dependencies with [Work stream B]
- [ ] [Work stream C] runs independently after [prerequisite]

### Human Checkpoints

<!--
  Name each gate where the agent pauses for human approval.
  Each gate marks a phase boundary in the task breakdown.
-->

The agent pauses at every phase boundary and follows the Human Checkpoint
Protocol in `references/workflow-guide.md`. List here only a checkpoint this
feature adds inside a phase, with what the reviewer checks at it.

- [ ] [Checkpoint]: [what the reviewer confirms before work continues]

### Review Gates

<!--
  Name the tasks that need code review before the plan continues.
  The task breakdown flags its tasks with [REVIEW].
-->

- [ ] [API contracts/interfaces]: Review before implementing consumers
- [ ] [Security-sensitive code]: Review before integration
- [ ] [Data model changes]: Review before migration

## Justified constitution violations

> **Fill in this table only when the Constitution Check flags a violation to justify**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., extra dependency] | [current need] | [why simpler approach insufficient] |
