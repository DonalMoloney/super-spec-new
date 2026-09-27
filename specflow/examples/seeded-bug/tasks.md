---
description: "Task list template for feature implementation"
---

# Tasks: Link Audit CLI

**Input**: Design documents from `specs/001-link-audit/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/cli-contract.md, quickstart.md

## Task Format

```
- [ ] [TaskID] [P?] [TDD?] [REVIEW?] [SUBAGENT?] [Story?] Description with file path
```

- **[P]**: Runs in parallel (different files, no dependencies on incomplete tasks)
- **[TDD]**: Follows RED-GREEN-REFACTOR — write the test, confirm it fails, implement, confirm it passes. Applied where plan.md's Execution Strategy names the logic as needing a pinning test per rule (`anchors.py` slugification, `resolver.py`'s FR-009/FR-010/FR-013 precedence, `discovery.py`'s exit-2 paths).
- **[REVIEW]**: Pauses for a human review before the next task starts. Applied at the three gates plan.md's Review Gates section names.
- **[SUBAGENT]**: Independent of the other modules in its wave (plan.md's Independent Work Streams) and can be dispatched to a parallel subagent.
- **[USn]**: Ties a task to User Story n (US1 = P1, US2 = P2, US3 = P3)
- Setup, Foundational, and Polish tasks carry no story label.

## Path Conventions

Single-package CLI (per plan.md Project Structure):

```text
src/link_audit/
├── __init__.py
├── cli.py
├── discovery.py
├── links.py
├── anchors.py
├── resolver.py
└── report.py

tests/
├── test_discovery.py
├── test_links.py
├── test_anchors.py
├── test_resolver.py
├── test_report.py
└── test_cli.py
```

---

## Phase 1: Setup

**Purpose**: Initialize the package and test harness.

- [x] T001 Create the `src/link_audit/` package directory with an empty `__init__.py`, and create the `tests/` directory, per plan.md's Project Structure
- [x] T002 Create `pyproject.toml` declaring the `link_audit` package, a Python `>=3.11` requirement, zero runtime dependencies (Constitution Principle I), `pytest` as a dev-only extra, and a console-script entry point `link-audit = link_audit.cli:main`
- [x] T003 [P] Add pytest configuration (`[tool.pytest.ini_options]` in `pyproject.toml`) and confirm `pytest -q` runs cleanly with zero tests collected

**Execution notes**: Confirm `pip install -e '.[dev]'` succeeds and `pytest -q` runs before Phase 2 starts.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build the two pipeline stages every user story depends on — the tracked-file list and raw link extraction.

**Critical**: No user story starts until this phase finishes.

- [x] T004 [P] [TDD] [SUBAGENT] Write a failing test in `tests/test_discovery.py` asserting `discovery.list_markdown_files()` returns the `.md` paths reported by `git ls-files -- '*.md'` inside a temporary git repo (FR-001 happy path)
- [x] T005 [SUBAGENT] Implement `discovery.list_markdown_files()` in `src/link_audit/discovery.py`, shelling out via `subprocess.run(["git", "ls-files", "--", "*.md"])` per research.md D1, making T004 pass
- [x] T006 [P] [TDD] [SUBAGENT] Write a failing test in `tests/test_links.py` asserting link extraction finds every inline `[text](target)` link in a Markdown string, each with its 1-based source line number (FR-002)
- [x] T007 [SUBAGENT] Implement `links.extract_links()` in `src/link_audit/links.py` with a single compiled regex applied per line (research.md D2), returning frozen `Link` dataclass instances (`source_file`, `line_number`, `text`, `target_raw`) per data-model.md, making T006 pass

**Checkpoint**: `discovery.py` and `links.py` work in isolation and `pytest -q` passes. Check the module layout against plan.md's Project Structure before any user story starts.

---

## Phase 3: User Story 1 - Catch broken relative links (Priority: P1) MVP

**Goal**: Report every relative link whose target file does not exist, and exit 0/1 accordingly.
**Independent Test**: Point the CLI at a repo with one Markdown file containing a relative link to a nonexistent file; confirm the CLI prints that link and exits 1.

### Tests for User Story 1

- [x] T008 [P] [TDD] [US1] Write a failing test in `tests/test_resolver.py` asserting a target with an external scheme (e.g. `https://example.com`, `mailto:a@b.com`) classifies with a non-`None` scheme and triggers no file-system check (FR-003)
- [x] T009 [P] [TDD] [US1] Write a failing test in `tests/test_resolver.py` asserting a target containing percent-encoded characters (e.g. `%20`) and a trailing query string is decoded to the correct path before resolution (FR-011)
- [x] T010 [P] [TDD] [US1] Write a failing test in `tests/test_resolver.py` asserting a relative link to an existing file resolves with `file_exists=True`, and a relative link to a missing file resolves with `file_exists=False`, resolved relative to the linking file's directory (FR-004)
- [x] T011 [P] [TDD] [US1] Write a failing test in `tests/test_report.py` asserting a `ResolvedTarget` with `file_exists=False` produces exactly one `Finding` with `reason="missing-file"`, carrying `source_file`, `line_number`, and `target` (FR-006, FR-009)
- [x] T012 [P] [TDD] [US1] Write a failing end-to-end test in `tests/test_cli.py` asserting the CLI exits 0 on a clean repo and exits 1 while printing a missing-file line (source file, line number, target) when a relative link's target is missing (FR-007; stdout shape per `contracts/cli-contract.md`)

### Implementation for User Story 1

- [x] T013 [US1] Implement `resolver.classify_and_decode()` in `src/link_audit/resolver.py`, using `urllib.parse.urlsplit().scheme` for scheme classification (FR-003, D5) and `urlsplit`/`unquote` for percent-decode + query-strip (FR-011, D4), producing a `ParsedTarget`, making T008 and T009 pass
- [x] T014 [US1] Implement `resolver.resolve_file()` in `src/link_audit/resolver.py`, performing the FR-004 file-existence check relative to the linking file's directory and producing a `ResolvedTarget` with `anchor_checked=False`, making T010 pass (depends on T013)
- [x] T015 [US1] [REVIEW] Implement `report.build_finding()` in `src/link_audit/report.py`, converting a `ResolvedTarget` with `file_exists=False` into a `Finding(reason="missing-file")`, making T011 pass — review the `Finding` record shape (fields, ordering) before `cli.py` consumes it, per plan.md's Review Gates
- [x] T016 [US1] Implement `cli.main()` in `src/link_audit/cli.py`, wiring `discovery` → `links` → `resolver` → `report`, printing each `Finding` per `contracts/cli-contract.md`'s stdout format, and returning exit 0 or 1 per FR-007, making T012 pass (depends on T005, T007, T014, T015)

**Checkpoint**: User Story 1 works standalone — a repo with one missing relative link is reported with exit 1, a clean repo exits 0. Get human approval before Phase 4.

---

## Phase 4: User Story 2 - Catch broken heading anchors (Priority: P2)

**Goal**: Report `file.md#anchor` links whose anchor matches no slugified heading in the target file.
**Independent Test**: Create a target file with known headings and a linking file with a `file.md#anchor` link whose anchor matches none of them; confirm the CLI reports it.

### Tests for User Story 2

- [x] T017 [P] [TDD] [US2] Write a failing test in `tests/test_anchors.py` asserting GitHub-convention slugification: lowercase, spaces converted to hyphens, characters outside `[a-z0-9 _-]` stripped (FR-005, D3)
- [x] T018 [P] [TDD] [US2] Write a failing test in `tests/test_anchors.py` asserting that when two headings in the same file slugify to the same base slug, the second and later occurrences get `-1`, `-2`, ... suffixes in document order (FR-005 duplicate-slug rule)
- [x] T019 [P] [TDD] [US2] Write a failing test in `tests/test_resolver.py` asserting a `file.md#anchor` link resolves with `anchor_checked=True, anchor_resolved=True` when the anchor matches a slugified heading in the target file, and `anchor_resolved=False` when it matches none (FR-005)
- [x] T020 [P] [TDD] [US2] Write a failing test in `tests/test_resolver.py` asserting a link to a missing target file yields `file_exists=False` and `anchor_checked=False` — it is never also evaluated for anchor resolution (FR-009)
- [x] T021 [P] [TDD] [US2] Write a failing test in `tests/test_resolver.py` asserting a bare anchor (`#anchor`, no file part) resolves against the linking file's own slugified headings, with `resolved_path=None` (FR-010)
- [x] T022 [P] [TDD] [US2] Write a failing test in `tests/test_resolver.py` asserting `anchor_checked=False` when the resolved target file exists but is not a `.md` file, even if an anchor fragment is present in the link (FR-013)
- [x] T023 [P] [TDD] [US2] Write a failing test in `tests/test_report.py` asserting a `ResolvedTarget` with `anchor_checked=True, anchor_resolved=False` produces exactly one `Finding` with `reason="missing-anchor"` (FR-006)
- [x] T024 [P] [TDD] [US2] Write a failing end-to-end test in `tests/test_cli.py` asserting the CLI reports a missing-anchor line and exits 1 when a `file.md#anchor` link's anchor matches no heading, and reports nothing for a link whose anchor does match (SC-004)

### Implementation for User Story 2

- [x] T025 [SUBAGENT] [US2] Implement `anchors.slugify_headings()` in `src/link_audit/anchors.py`, extracting Markdown headings and applying the GitHub slug algorithm with duplicate-suffix handling per research.md D3, making T017 and T018 pass
- [x] T026 [TDD] [REVIEW] [US2] Extend `resolver.resolve_file()` in `src/link_audit/resolver.py` to call `anchors.slugify_headings()` on the target file and set `anchor_checked`/`anchor_resolved` per FR-005/FR-009/FR-010/FR-013, making T019, T020, T021, and T022 pass (depends on T014, T025) — review the FR-009/FR-010/FR-013 precedence logic before it is wired into `cli.py` (T028), per plan.md's Review Gates: this is the module most likely to hide a false negative
- [x] T027 [US2] Extend `report.build_finding()` in `src/link_audit/report.py` to emit `Finding(reason="missing-anchor")` for a `ResolvedTarget` with `anchor_checked=True, anchor_resolved=False`, making T023 pass (depends on T015)
- [x] T028 [US2] Wire anchor findings into `cli.main()` in `src/link_audit/cli.py` so both missing-file and missing-anchor findings are printed, making T024 pass (depends on T016, T026 review sign-off, T027)

**Checkpoint**: User Stories 1 and 2 both work, standalone and together. Review `resolver.py`'s FR-009/FR-010/FR-013 precedence logic (plan.md Review Gates) before Phase 5. Get human approval.

---

## Phase 5: User Story 3 - Scan exactly the tracked Markdown files (Priority: P3)

**Goal**: Limit scanning to `git ls-files` output, and fail loudly (exit 2) rather than silently when the scan cannot complete.
**Independent Test**: Create a repo with a tracked Markdown file containing a broken link and an untracked Markdown file containing a different broken link; confirm the CLI reports only the tracked file's link.

### Tests for User Story 3

- [x] T029 [P] [TDD] [US3] Write a failing test in `tests/test_discovery.py` asserting an untracked (or `.gitignore`d) `.md` file that exists on disk is excluded from `discovery.list_markdown_files()`'s result (FR-001, US3 Scenario 2)
- [x] T030 [P] [TDD] [US3] Write a failing test in `tests/test_discovery.py` asserting `discovery.list_markdown_files()` raises a `LinkAuditError` naming the git failure when invoked outside a git repository or when `git ls-files` returns non-zero or `git` is not on PATH (US3 Scenario 3)
- [x] T031 [P] [TDD] [US3] Write a failing test in `tests/test_discovery.py` asserting `discovery.list_markdown_files()` returns an empty list, without raising, when `git ls-files` reports zero `.md` files (US3 Scenario 4)
- [x] T032 [P] [TDD] [US3] Write a failing test in `tests/test_cli.py` asserting the CLI exits 2 and prints exactly one stderr line naming the git failure when run outside a git repository (`contracts/cli-contract.md` stderr contract)
- [x] T033 [P] [TDD] [US3] Write a failing test in `tests/test_cli.py` asserting a `git ls-files`-tracked file that cannot be opened or decoded (permission denied or undecodable bytes) aborts the scan with exit 2 and one stderr line naming the specific file and reason, and prints no `Finding` (FR-012)

### Implementation for User Story 3

- [x] T034 [TDD] [REVIEW] [US3] Add a `LinkAuditError` exception (carrying `file: Path | None` and `reason: str` per data-model.md `ScanError`) and raise it from `discovery.list_markdown_files()` in `src/link_audit/discovery.py` when the `git ls-files` subprocess returns non-zero or `git` is missing, using the command's stderr as the reason, making T030 pass — review `discovery.py`'s exit-2 paths before merge, per plan.md's Review Gates: Principle II treats exit-code semantics as a stability contract
- [x] T035 [US3] Verify T029 and T031 pass against the existing `discovery.list_markdown_files()` implementation from T005 (git's own tracked-file semantics already exclude untracked and produce an empty list correctly); add no production code beyond what T034 requires
- [x] T036 [US3] Catch `LinkAuditError` at the top of `cli.main()` in `src/link_audit/cli.py`, printing `f"{error.file or 'git'}: {error.reason}"` to stderr and returning exit 2, making T032 pass (depends on T016, T034 review sign-off)
- [x] T037 [US3] Wrap each tracked file's read in `cli.main()` in `src/link_audit/cli.py` with a `try`/`except` over `OSError` and `UnicodeDecodeError`, raising `LinkAuditError(file=path, reason=str(exc))` on either, making T033 pass (depends on T036)

**Checkpoint**: All three user stories work independently and together. Run `pytest -q` — every test must pass. Review `discovery.py`'s exit-2 paths (plan.md Review Gates) before the polish phase.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Cover the spec's non-functional requirements (determinism, no network access, aggregate accuracy) and close out traceability.

- [x] T038 [P] [TDD] Write and pass a test in `tests/test_report.py` asserting stdout output is deterministic — identical input produces identical output text and ordering across repeated runs (`contracts/cli-contract.md` stdout contract)
- [x] T039 [P] [TDD] Write and pass the FR-008/SC-002 test in `tests/test_cli.py`, monkeypatching `socket.socket.connect` and `socket.create_connection` to raise if invoked during a full CLI run against a fixture repo containing every link category (research.md D7)
- [x] T040 [P] [TDD] Write and pass an SC-001 test in `tests/test_cli.py` asserting a fixture repo with N missing-file links and M missing-anchor links reports exactly N + M findings with zero false positives
- [x] T041 Update `spec.md`'s Traceability table Status column from "Pending" to "Passing" for every FR/SC row whose named test now passes
- [x] T042 Run `pytest -q` for the full suite and confirm every test named in `spec.md`'s Traceability table passes

---

## Phase 7: Remediation — Fenced Code Blocks & Root-Relative Links (FR-014, FR-015, Findings R-001–R-004)

**Purpose**: Close the four open Critical/Important findings from `review-findings.json`. R-001 and R-002 both stem from FR-014 (fenced-code-block exclusion); R-004 stems from FR-015 (root-relative resolution); R-003 is an unhandled-exception code-quality gap in the anchor-target read path.

**Independent Test**: Run `pytest -q` — every new test below fails before its paired implementation task and passes after.

### R-001 / R-002 — Fenced code block exclusion (FR-014)

- [x] T043 [P] [TDD] Write a failing test in `tests/test_anchors.py` asserting a heading-like line (`# ...`) inside a fenced code block (` ``` ` or `~~~`) is NOT extracted as a heading by `anchors.slugify_headings()` (FR-014, R-001)
- [x] T044 [TDD] [REVIEW] Implement fenced-code-block state tracking in `anchors.slugify_headings()` in `src/link_audit/anchors.py`, skipping heading-pattern matching between fence delimiters, making T043 pass (depends on T043) — review the fence-state tracking logic before it is wired anywhere else, since R-001 showed a phantom heading can both mask a real broken anchor (false negative) and shift duplicate-slug numbering for genuine headings below the fence (false positive)
- [x] T045 [P] [TDD] Write a failing test in `tests/test_links.py` asserting a link-like string (`[text](target)`) inside a fenced code block is NOT extracted as a link by `links.extract_links()` (FR-014, R-002)
- [x] T046 [TDD] Implement fenced-code-block state tracking in `links.extract_links()` in `src/link_audit/links.py`, mirroring T044's fence-state approach, making T045 pass (depends on T045)
- [x] T047 [P] [TDD] Write a failing end-to-end test in `tests/test_cli.py` asserting a fixture repo with a fenced code block containing both heading-like and link-like example text produces zero findings from that block's content (FR-014, SC-001 regression test for R-001/R-002)
- [x] T048 Verify T047 passes against T044 and T046's implementations; add no production code beyond what T044/T046 require (depends on T044, T046)

### R-004 — Root-relative link resolution (FR-015)

- [x] T049 [P] [TDD] Write a failing test in `tests/test_resolver.py` asserting a link target beginning with `/` resolves against the repository root — not the linking file's directory and not the OS filesystem root (FR-015, R-004)
- [x] T050 [TDD] [REVIEW] Implement root-relative resolution in `resolver.resolve_file()` in `src/link_audit/resolver.py`: when the parsed target's file part starts with `/`, join it against a repository-root parameter instead of `base_dir`, making T049 pass (depends on T049) — review that this signature change (an added repo-root parameter) doesn't break T014's existing base_dir-relative resolution for non-root-relative targets, per plan.md's Review Gates
- [x] T051 Thread the repository root path from `cli.main()` in `src/link_audit/cli.py` into every `resolver.resolve_file()` call, so root-relative targets resolve correctly end-to-end (depends on T050)
- [x] T052 [P] [TDD] Write a failing end-to-end test in `tests/test_cli.py` asserting a fixture repo with a root-relative link (`/docs/x.md`) to an existing file produces no finding, and one to a missing file is reported (FR-015)
- [x] T053 Verify T052 passes against T050/T051's implementation (depends on T051)

### R-003 — Unhandled read error on anchor-target file

- [x] T054 [P] [TDD] Write a failing test in `tests/test_resolver.py` asserting that when the anchor-target file exists but raises `OSError` or `UnicodeDecodeError` on read, `resolver.resolve_file()` raises `LinkAuditError` naming that file and the reason, instead of propagating the raw exception (R-003)
- [x] T055 [TDD] [REVIEW] Wrap the anchor-target file's `read_text()` call in `src/link_audit/resolver.py` (the `_check_anchor()` path) in the same `OSError`/`UnicodeDecodeError` handling already used for the linking file, raising `LinkAuditError(file=target_file, reason=...)`, making T054 pass (depends on T054) — review that `cli.py`'s existing `LinkAuditError` handler (T036) now also catches this path and still exits 2 with an actionable message, per Constitution Principle II and IV
- [x] T056 [P] [TDD] Write a failing end-to-end test in `tests/test_cli.py` asserting the CLI exits 2 and names the specific unreadable file when a `file.md#anchor` link's target file exists but cannot be read, rather than crashing with an uncaught traceback (R-003)
- [x] T057 Verify T056 passes against T055's implementation (depends on T055)

### Close-out

- [x] T058 Update `spec.md`'s Traceability table Status column from "Pending" to "Passing" for the FR-014 and FR-015 rows, now that T048 and T053 pass
- [x] T059 Run `pytest -q` for the full suite and confirm every test passes, including the new fenced-code-block, root-relative, and anchor-target-read-error tests

**Checkpoint**: Findings R-001–R-004 are all closed and FR-014/FR-015 have passing named tests. Get human approval before re-running `/speckit.analyze`.

---

## Task Verification

| Task | Verify |
|------|--------|
| T001 | `ls src/link_audit tests` lists the directories plan.md names |
| T005 | T004 fails before T005, passes after |
| T007 | T006 fails before T007, passes after |
| T016 | `link-audit` in a fixture repo with one missing relative link exits 1 and prints it |
| T025 | T017 and T018 fail before T025, pass after |
| T028 | `link-audit` in a fixture repo with one missing anchor exits 1 and prints it, alongside any missing-file findings |
| T036 | `link-audit` outside a git repo exits 2 with one stderr line |
| T037 | `link-audit` against an unreadable tracked file exits 2 naming that file |
| T042 | `pytest -q` reports all tests passing, zero failures |
| T044 | T043 fails before T044, passes after |
| T046 | T045 fails before T046, passes after |
| T048 | `pytest -q tests/test_cli.py` shows the fenced-code-block fixture test passing |
| T050 | T049 fails before T050, passes after |
| T053 | `pytest -q tests/test_cli.py` shows the root-relative-link fixture test passing |
| T055 | T054 fails before T055, passes after |
| T057 | `pytest -q tests/test_cli.py` shows the unreadable-anchor-target fixture test passing |
| T059 | `pytest -q` reports all tests passing, zero failures |

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies. Starts immediately.
- **Foundational (Phase 2)**: Depends on Setup. Blocks every user story — `discovery.py` and `links.py` are consumed by `cli.py` in every subsequent phase.
- **User Story 1 (Phase 3)**: Depends on Foundational. No dependency on US2 or US3.
- **User Story 2 (Phase 4)**: Depends on Foundational; extends the `resolver.py`/`report.py`/`cli.py` surfaces US1 built (T014, T015, T016), so build it after Phase 3 completes even though its own acceptance scenarios are independent of US1's.
- **User Story 3 (Phase 5)**: Depends on Foundational (T005 already implements the git-scoping mechanism); extends `discovery.py`'s error path and `cli.py`'s error handling (T016), so build it after Phase 3.
- **Polish (Phase 6)**: Depends on every prior phase.
- **Remediation (Phase 7)**: Depends on Phase 6 (all modules already exist and are implemented). R-001/R-002 tasks (T043–T048) touch `anchors.py`/`links.py` and are independent of R-004's `resolver.py` tasks (T049–T053) and R-003's `resolver.py` tasks (T054–T057); the latter two share a file but touch different functions (`resolve_file()`'s root-relative branch vs. `_check_anchor()`'s read-error handling) and should land as separate commits to keep review scoped.

### Within Each User Story

1. Write the tests for that story and confirm they fail.
2. Implement the resolver/report changes the story needs.
3. Wire the change into `cli.py`.
4. Confirm the story's tests now pass.

### Parallel Opportunities

- T004 and T006 (Phase 2) touch different files and can run in parallel; both are marked `[SUBAGENT]` since `discovery.py` and `links.py` share no file and no runtime dependency (plan.md's Independent Work Streams) and can be dispatched to separate subagents in the same wave.
- T008–T012 (US1 tests) touch different test files and can run in parallel; likewise T017–T024 (US2 tests) and T029–T033 (US3 tests).
- T025 (`anchors.py`) is marked `[SUBAGENT]`: it shares no file and no runtime dependency with `discovery.py` or `links.py`, so a subagent can implement it as soon as its own tests (T017, T018) exist, even though it is scheduled in Phase 4 for story-mapping purposes.
- T038–T040 (Polish) touch different test files and can run in parallel.
- `[TDD]` tasks (all "write a failing test" tasks, plus T026 and T034) must complete their RED step — confirm the named test fails — before the paired implementation task starts.
- `[REVIEW]` tasks (T015, T026, T034, T044, T050, T055) pause for human sign-off before the next task in their phase starts, per plan.md's Review Gates.
- T043, T045, T049, T052, T054, T056 (Phase 7 tests) touch different test files or different, independent assertions and can run in parallel.

---

## Implementation Strategy

### MVP Scope

**User Story 1 only** (Phases 1–3, tasks T001–T016) is a shippable MVP: a CLI that catches every broken relative link and exits 0/1 accordingly, with no anchor-checking or explicit tracked-file-scoping tests yet (though the scoping mechanism itself, T005, is already in place from Phase 2).

### Incremental Delivery

1. Ship Phases 1–3 (US1) — broken relative links are caught.
2. Add Phase 4 (US2) — broken heading anchors are caught on top of US1.
3. Add Phase 5 (US3) — tracked-file scoping and scan-abort paths are explicitly tested and hardened.
4. Close with Phase 6 — determinism, no-network, and aggregate-accuracy guarantees are locked in with tests, and the Traceability table is marked complete.
5. Close remaining findings with Phase 7 — fenced-code-block exclusion (R-001/R-002), root-relative link resolution (R-004), and the anchor-target read-error path (R-003) are fixed and pinned with tests, and the FR-014/FR-015 Traceability rows move from Pending to Passing.

Each checkpoint above is a point to run `pytest -q`, demo the CLI against the quickstart.md scratch repository, and get human approval before continuing.
