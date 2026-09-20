<!-- specflow template: plan-template 1.0.2 -->
# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link to spec.md]
**Input**: Feature specification from `specs/[###-feature-name]/spec.md`

## Summary

[Extract from feature spec: primary requirement + technical approach]

## Technical Context

<!--
  ACTION REQUIRED: Replace each placeholder with the real technical detail.
  Mark an unknown item as NEEDS CLARIFICATION.
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

*GATE: The plan must pass this check before it proceeds. Re-check it after the design phase.*

<!--
  Check the plan against each constitution principle.
  Mark each principle PASS, NEEDS ATTENTION, or VIOLATION, with justification.
-->

| Principle | Status | Notes |
|-----------|--------|-------|
| [Principle 1 from constitution] | PASS / NEEDS ATTENTION / VIOLATION | [explanation] |
| [Principle 2 from constitution] | PASS / NEEDS ATTENTION / VIOLATION | [explanation] |

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
  ACTION REQUIRED: Replace the layout below with this feature's real structure.
  Drop the unused options and list the real paths.
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
  This section states how tasks run.
  `/speckit.specflow.tasks` reads it to build the task breakdown.
  `/speckit.specflow.execute` reads it during execution.
-->

### TDD Requirements

<!--
  List the areas of this feature that need strict RED-GREEN-REFACTOR discipline.
  The task breakdown marks their tasks [TDD].
-->

- [ ] [Component/module]: [Why TDD is needed, e.g., "Complex business logic with many edge cases"]
- [ ] [Component/module]: [Why TDD is needed]

### Parallel Execution Opportunities

<!--
  List the work streams that run independently and can go to parallel subagents.
  The task breakdown marks their tasks [SUBAGENT].
-->

- [ ] [Work stream A] and [Work stream B] share no files or dependencies
- [ ] [Work stream C] runs independently after [prerequisite]

### Human Checkpoints

<!--
  Define each gate where the agent pauses for human approval.
  Each gate becomes a phase boundary in the task breakdown.
-->

1. After the foundational setup, check that the project structure and dependencies are correct
2. After each user story, check that its behavior matches the acceptance scenarios
3. After all stories, run the full test suite before the polish phase
4. Before the merge, review the work against the spec

### Review Gates

<!--
  List the tasks that need code review before the plan proceeds.
  The task breakdown marks their tasks [REVIEW].
-->

- [ ] [API contracts/interfaces]: Review before implementing consumers
- [ ] [Security-sensitive code]: Review before integration
- [ ] [Data model changes]: Review before migration

## Complexity Tracking

> **Fill in this table only when the Constitution Check lists a violation to justify**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., extra dependency] | [current need] | [why simpler approach insufficient] |
