---
description: "Task list for the broken link audit"
---

# Tasks: Broken Link Audit

**Input**: Design documents from `specs/001-link-audit/`
**Prerequisites**: plan.md (required), spec.md (required for user stories)

## Task Format

```
[ID] [markers] [Story] Description
```

**Markers**:
- **[P]**: Runs in parallel (different files, no dependencies)
- **[TDD]**: Follows RED-GREEN-REFACTOR (write test, fail, implement, pass, refactor)
- **[REVIEW]**: Pauses for a code review before the next task starts
- **[SUBAGENT]**: Can be delegated to a subagent for parallel execution

**One outcome per task**: a description that needs "and" is two tasks. Split it.

**One check per task**: the Task Verification table names how each task is proven.

**Story labels**: `[US1]`, `[US2]`, `[US3]` map tasks to user stories for traceability.

## Path Conventions

- **Single project**: `src/link_audit/`, `tests/` at repository root
- Paths below match the structure decision in plan.md

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Stand up the package skeleton

- [x] T001 Create the `src/link_audit/` package with an empty `__init__.py`
- [x] T002 Declare the `link-audit` console entry point in `pyproject.toml`
- [x] T003 [P] Set the ruff line length to 100 in `pyproject.toml`

**Execution notes**: No special discipline. Confirm `python -c "import link_audit"` before the next phase.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: File discovery, link parsing, the result record

**CRITICAL**: No user story work begins until this phase is complete.

- [x] T004 [TDD] Write `tests/test_discovery.py::lists_tracked_markdown_only`
- [x] T005 [TDD] Implement tracked-file discovery in `src/link_audit/discovery.py`
- [x] T006 [P] [TDD] Write `tests/test_parser.py::extracts_inline_link_targets`
- [x] T007 [TDD] Implement inline link extraction in `src/link_audit/parser.py`
- [x] T008 [P] [TDD] Write `tests/test_parser.py::skips_link_inside_code_fence`
- [x] T009 [TDD] Skip a fenced code block in `src/link_audit/parser.py`
- [x] T010 [REVIEW] Define the `BrokenLink` record in `src/link_audit/report.py`
- [x] T011 [TDD] Write `tests/test_discovery.py::rejects_root_outside_git`
- [x] T012 [TDD] Raise `LinkAuditError` for a scan root outside a git checkout

**Execution notes**: T010 pauses for review. The record shape reaches two renderers, so a later change costs both.

**Checkpoint**: The foundation is ready. Get human approval before User Story 1 starts.

---

## Phase 3: User Story 1 - Find the broken file links (Priority: P1) MVP

**Goal**: Report every relative link whose target file is missing
**Independent Test**: Delete a linked file, run `link-audit`, confirm the report names the link

### Tests for User Story 1

> Write these tests first. Confirm they fail before you implement.

- [x] T013 [P] [TDD] [US1] Write `tests/test_scanner.py::reports_missing_target`
- [x] T014 [P] [TDD] [US1] Write `tests/test_scanner.py::accepts_existing_target`
- [x] T015 [P] [TDD] [US1] Write `tests/test_cli.py::exits_1_on_broken_link`
- [x] T016 [P] [TDD] [US1] Write `tests/test_cli.py::exits_0_on_clean_repository`

### Implementation for User Story 1

- [x] T017 [US1] Resolve a relative target against the linking file's directory in `src/link_audit/scanner.py`
- [x] T018 [US1] Reject a resolved path that escapes the scan root
- [x] T019 [US1] Report each unresolved target as a `BrokenLink`
- [x] T020 [US1] Return exit code 1 from `src/link_audit/cli.py` when the report is non-empty

**Execution notes**: Dispatch T013 through T016 as parallel subagents when `subagent-driven-development` is available.

**Checkpoint**: User Story 1 works on its own. Get human approval.

---

## Phase 4: User Story 2 - Catch the stale heading anchors (Priority: P2)

**Goal**: Report a `#anchor` fragment that matches no heading in the target file
**Independent Test**: Rename a heading, run `link-audit`, confirm the stale anchor appears

- [x] T021 [P] [TDD] [US2] Write `tests/test_anchors.py::rejects_missing_heading_anchor`
- [x] T022 [P] [TDD] [US2] Write `tests/test_anchors.py::accepts_slugified_heading_anchor`
- [x] T023 [US2] Slugify each target file's headings in `src/link_audit/anchors.py`
- [x] T024 [US2] Report an unmatched fragment with the nearest heading in the fix hint

**Checkpoint**: User Stories 1, 2 both work independently. Get human approval.

---

## Phase 5: User Story 3 - Keep the scan to what the team owns (Priority: P3)

**Goal**: Skip external schemes, honour an exclusion glob
**Independent Test**: Pass `--ignore 'vendor/**'`, confirm no vendored path is scanned

- [x] T025 [P] [TDD] [US3] Write `tests/test_scanner.py::skips_http_target`
- [x] T026 [US3] Skip a target carrying an `http`, `https`, `mailto` scheme
- [x] T027 [P] [TDD] [US3] Write `tests/test_cli.py::honours_ignore_glob`
- [x] T028 [US3] Accept a repeatable `--ignore GLOB` option in `src/link_audit/cli.py`

**Checkpoint**: All three stories work independently. Get human approval.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: The JSON surface, the scan cap, the docs

- [x] T029 [P] [TDD] Write `tests/test_cli.py::prints_json_report`
- [x] T030 Render the report as JSON under `--format json` in `src/link_audit/report.py`
- [x] T031 [P] [TDD] Write `tests/test_scanner.py::stops_above_file_cap`
- [x] T032 [REVIEW] Stop the scan at the 5000-file cap plan.md names
- [x] T033 [P] [TDD] Write `tests/test_performance.py::audits_500_files_under_5s`
- [x] T034 [P] [SUBAGENT] Document `link-audit` in `README.md`
- [x] T035 Run `pytest -q`: every test passes

**Execution notes**: T032 pauses for review, because the cap changes the exit code a caller sees.

---

## Task Verification

Give every task a row. The Verify cell names the command or the observation that
proves the task is done, so a reader checks it without asking the implementer.

| Task | Verify |
|------|--------|
| T001 | `python -c "import link_audit"` exits 0 |
| T002 | `link-audit --help` prints the usage line |
| T003 | `ruff check src tests` reports no `E501` |
| T004 | The test fails with `ModuleNotFoundError: link_audit.discovery` |
| T005 | `pytest tests/test_discovery.py::lists_tracked_markdown_only` passes |
| T006 | The test fails with `ModuleNotFoundError: link_audit.parser` |
| T007 | `pytest tests/test_parser.py::extracts_inline_link_targets` passes |
| T008 | The test fails: the parser returns the fenced target |
| T009 | `pytest tests/test_parser.py::skips_link_inside_code_fence` passes |
| T010 | The reviewer approves the `BrokenLink` field list in `report.py` |
| T011 | The test fails: discovery returns an empty list instead of raising |
| T012 | `pytest tests/test_discovery.py::rejects_root_outside_git` passes |
| T013 | The test fails with `ModuleNotFoundError: link_audit.scanner` |
| T014 | The test fails with `ModuleNotFoundError: link_audit.scanner` |
| T015 | The test fails with `ModuleNotFoundError: link_audit.cli` |
| T016 | The test fails with `ModuleNotFoundError: link_audit.cli` |
| T017 | `pytest tests/test_scanner.py::accepts_existing_target` passes |
| T018 | A link to `../../../../etc/passwd` appears in the report as broken |
| T019 | `pytest tests/test_scanner.py::reports_missing_target` passes |
| T020 | `pytest tests/test_cli.py::exits_1_on_broken_link` passes |
| T021 | The test fails with `ModuleNotFoundError: link_audit.anchors` |
| T022 | The test fails with `ModuleNotFoundError: link_audit.anchors` |
| T023 | `pytest tests/test_anchors.py::accepts_slugified_heading_anchor` passes |
| T024 | `pytest tests/test_anchors.py::rejects_missing_heading_anchor` passes |
| T025 | The test fails: the scanner reports the `https://` target as broken |
| T026 | `pytest tests/test_scanner.py::skips_http_target` passes |
| T027 | The test fails: `--ignore` is an unrecognised option |
| T028 | `pytest tests/test_cli.py::honours_ignore_glob` passes |
| T029 | The test fails: `--format` is an unrecognised option |
| T030 | `pytest tests/test_cli.py::prints_json_report` passes |
| T031 | The test fails: a 5001-file tree scans to completion |
| T032 | The reviewer approves the exit-2 stop path; the test passes |
| T033 | `pytest tests/test_performance.py::audits_500_files_under_5s` passes |
| T034 | `README.md` shows the usage line the CLI prints |
| T035 | `pytest -q` reports `47 passed` |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies. Starts immediately.
- **Foundational (Phase 2)**: Depends on Setup. Blocks every user story.
- **User Stories (Phase 3, 4, 5)**: Each depends on the Foundational phase completing.
- **Polish (Phase 6)**: Depends on every user story finishing.

### Within Each User Story

1. Under [TDD], write the test, confirm it fails, then implement
2. Discovery comes before parsing
3. Parsing comes before resolution
4. Resolution comes before rendering
5. A [REVIEW] task pauses for human review
6. Finish the story before the next priority starts

### Parallel Opportunities

- Tasks marked [P] in the same phase run in parallel
- T013 through T016 write four separate test files, so no two collide
- User Story 2 can start while User Story 3 runs, once Phase 2 is complete

---

## Superpowers Execution

### Execution Discipline by Marker

- **[TDD]**: Follow RED-GREEN-REFACTOR. When the `test-driven-development` skill is
  available, read it, follow its process. Otherwise: write the test, run it
  (must fail), implement, run it (must pass), refactor when needed.
- **[SUBAGENT]**: When the `subagent-driven-development` skill is available, dispatch
  the task to a subagent. Otherwise: implement it in the current session, in order.
- **[REVIEW]**: Pause execution. Show the completed work to the user. Wait for
  explicit approval before the next task starts.
- **[P]**: On Claude Code, launch the tasks in parallel with the Task tool. On the
  Copilot CLI, run them in order.

### Checkpoint Protocol

At every phase boundary:
1. Summarize what this phase completed
2. Run the applicable tests
3. Report the test results
4. Ask the user: "Phase [N] complete. Proceed to Phase [N+1]?"
5. Continue only after the user gives explicit approval

---

## Notes

- [P] tasks touch different files, with no dependencies
- [TDD] tasks follow strict RED-GREEN-REFACTOR discipline
- [REVIEW] tasks stop at a human review gate
- [SUBAGENT] tasks are candidates for parallel subagent dispatch
- The [Story] label maps a task to its user story, for traceability
- Commit after every task or logical group
- Stop at any checkpoint to confirm the work independently
