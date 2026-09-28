---
description: "Task list template for feature implementation"
---
<!-- specflow template: tasks-template 1.1.0 -->

# Tasks: [FEATURE NAME]

**Input**: Design documents from `specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), spec.md (required for user stories)

## Task Format

```
[ID] [markers] [Story] Description
```

**Markers**:
- **[P]**: Runs in parallel (different files, no dependencies)
- **[TDD]**: Follows RED-GREEN-REFACTOR (write test, fail, implement, pass, refactor)
- **[REVIEW]**: Pauses for a code review before the next task starts
- **[SUBAGENT]**: Delegates to a subagent for parallel work

**One outcome per task**: a description that needs "and" is two tasks. Split it.

**One check per task**: the Task Verification table names the check for each task.

**Story labels**: `[US1]`, `[US2]`, and further labels tie a task to its user story.

## Path Conventions

- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Match these paths to the structure decisions in plan.md

<!--
  ============================================================================
  These sample tasks show the format, not real work.

  /speckit.specflow.tasks replaces them with real tasks, built from:
  - The user stories in spec.md, each with its priority (P1, P2, P3, and so on)
  - The technical decisions in plan.md
  - The execution strategy in plan.md (TDD, parallel work, review gates)
  - The entities in spec.md

  Tasks group by user story, so each one can:
  - Ship independently
  - Test independently
  - Deliver as an MVP increment

  /speckit.specflow.tasks removes these sample tasks from the generated tasks.md file.
  ============================================================================
-->

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Set up the project and its basic structure

- [ ] T001 Create the project structure from plan.md
- [ ] T002 Initialize the project with its dependencies
- [ ] T003 [P] Configure the linter

**Execution notes**: This phase needs no special discipline. Confirm the build before the next phase starts.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build the infrastructure every user story depends on

**Critical**: No user story starts until this phase finishes.

- [ ] T004 [TDD] Set up the core data models
- [ ] T005 [P] Implement the shared utilities
- [ ] T006 [P] [REVIEW] Set up the API routing
- [ ] T007 Configure the error handling

**Execution notes**: For a task marked [TDD], write the test first and run it. Confirm it fails, then implement.
For a task marked [REVIEW], pause for a human review of the API contracts before building a consumer.

**Checkpoint**: The foundation is ready. Get human approval before any user story starts.

---

## Phase 3: User Story 1 - [Title] (Priority: P1) MVP

**Goal**: [Brief description of what this story delivers]
**Independent Test**: [How to verify this story works on its own]

### Tests for User Story 1 (if TDD applies)

> Write these tests first. Confirm they fail before you implement.

- [ ] T008 [P] [TDD] [US1] Write a contract test for [endpoint] in tests/contract/
- [ ] T009 [P] [TDD] [US1] Write an integration test for [user flow] in tests/integration/

### Implementation for User Story 1

- [ ] T010 [P] [US1] Create the [Entity1] model in src/models/
- [ ] T011 [P] [US1] Create the [Entity2] model in src/models/
- [ ] T012 [US1] Implement the [Service] in src/services/ (depends on T010, T011)
- [ ] T013 [US1] Implement the [endpoint/feature] in src/
- [ ] T014 [US1] [REVIEW] Add input validation

**Execution notes**: If `subagent-driven-development` is available, dispatch T010 and T011
as parallel subagents. T014 needs review before the next task starts.

**Checkpoint**: User Story 1 works and can be tested on its own. Get human approval.

---

## Phase 4: User Story 2 - [Title] (Priority: P2)

**Goal**: [Brief description]
**Independent Test**: [How to verify]

### Implementation for User Story 2

- [ ] T015 [P] [SUBAGENT] [US2] Create the [Entity] model
- [ ] T016 [US2] Implement the [Service]
- [ ] T017 [US2] Implement the [endpoint/feature]
- [ ] T018 [US2] If needed, integrate with the User Story 1 components

**Checkpoint**: User Stories 1 and 2 both work independently. Get human approval.

---

[Add more user story phases as needed, following the same pattern]

---

## Phase N: Polish & Cross-Cutting Concerns

**Purpose**: Polish work that spans multiple user stories

- [ ] TXXX [P] [SUBAGENT] Update the documentation
- [ ] TXXX Clean up the code
- [ ] TXXX [P] Optimize performance
- [ ] TXXX [REVIEW] Harden security
- [ ] TXXX Run the full test suite

**Execution notes**: Most polish tasks run in parallel. The final security hardening
needs review. Every test must pass before this phase ends.

---

## Task Verification

Give every task a row. The Verify cell names the command or the observation that
proves the task is done. A reader then checks it without asking the implementer.

| Task | Verify |
|------|--------|
| T001 | `ls src/ tests/` lists the directories plan.md names |
| T004 | The model test fails before the implementation, passes after it |
| T014 | A request with an empty `email` field returns 400 |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies. Starts immediately.
- **Foundational (Phase 2)**: Depends on Setup. Blocks every user story.
- **User Stories (Phase 3+)**: Each depends on the Foundational phase completing.
  - Stories run in parallel with subagents, or in order by priority.
- **Polish (Final Phase)**: Depends on every chosen user story finishing.

### Order within a user story

1. Under [TDD], write the tests and confirm they fail before implementation starts
2. Models come before services
3. Services come before endpoints
4. Core implementation comes before integration
5. A [REVIEW] task pauses for human review
6. Finish the story before moving to the next priority

### Parallel Opportunities

- Tasks marked [P] in the same phase run in parallel
- The executor can dispatch tasks marked [SUBAGENT] to subagents
- Once the Foundational phase completes, user stories can start in parallel
- Different subagents can work on different user stories

---

## Execution rules

<!--
  /speckit.specflow.execute reads this section to decide how it processes the task list.
-->

### What each marker requires

- **[TDD]**: Follow RED-GREEN-REFACTOR. When the `test-driven-development` skill is
  available, read it and follow its process. Otherwise: write the test → run it
  (must fail) → implement → run it (must pass) → refactor if needed.
- **[SUBAGENT]**: When the `subagent-driven-development` skill is available, dispatch
  the task to a subagent. Otherwise: implement it in the current session, in order.
- **[REVIEW]**: Pause execution. Show the completed work to the user. Wait for
  explicit approval before the next task starts.
- **[P]**: On Claude Code, launch the tasks in parallel with the Task tool. On the
  Copilot CLI, run them in order.

### Checkpoint Protocol

At every phase boundary, follow `references/workflow-guide.md`'s Human Checkpoint
Protocol. It names what the agent summarizes, reports, and waits for before the
next phase starts.

---

## Notes

- The [Story] label maps a task to its user story, for traceability
- Commit after every task or logical group
- Stop at any checkpoint to confirm the work independently
