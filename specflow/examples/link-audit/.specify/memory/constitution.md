<!--
Sync Impact Report
Version: 1.0.0 (initial ratification)
Principles added: I Test-First, II One Command One Job, III Exit Codes Are The
  Contract, IV No Network During A Scan, V Errors Name The Fix
Templates aligned: plan-template.md Constitution Check, checklist-template.md
  Constitution Compliance
Follow-up: none
-->

# Link Audit Constitution

## Core Principles

### I. Test-First (NON-NEGOTIABLE)

Every behavior starts as a failing test. Write the test, run it, confirm it fails
for the stated reason, then write the smallest change that passes it. A task that
adds behavior without a test that failed first is rejected in review.

### II. One Command, One Job

`link-audit` reports broken links. It never rewrites a file, never creates a
branch, never opens an editor. A request to fix what the scan found becomes a
separate command with its own spec.

### III. Exit Codes Are The Contract

Exit 0 means no broken link. Exit 1 means at least one broken link. Exit 2 means
the scan could not run. Callers in CI depend on those three values, so a new
failure mode picks one of them rather than adding a fourth.

### IV. No Network During A Scan

The scan reads the file system only. An `http`, `https`, or `mailto` target is
skipped, not fetched. A scan stays reproducible offline, so a reviewer replays a
CI failure on a laptop with the same result.

### V. Errors Name The Fix

Every error states what was expected, what was found, then what the caller does
next. `link-audit: scan root /tmp/docs sits outside a git checkout; run it from
inside the repository you want audited.` No apology, no stack trace on a
user-facing path.

## Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Runtime | Python 3.11 | Matches the CI image already in use |
| CLI | `argparse` from the standard library | Keeps the install dependency-free |
| File discovery | `git ls-files` | Honours `.gitignore` without reimplementing it |
| Tests | pytest 8 | Matches the repository's other suites |

## Development Workflow

This project follows specification-driven development through the specflow
pipeline:

1. **Constitution** (`/speckit.constitution`): Set and keep these principles
2. **Specification** (`/speckit.specify`): Write requirements before any code
3. **Brainstorming** (`/speckit.specflow.brainstorm`): Question assumptions, find edge cases
4. **Planning** (`/speckit.plan`): Design the approach, check it against this file
5. **Task Decomposition** (`/speckit.specflow.tasks`): Split the plan into trackable tasks
6. **Execution** (`/speckit.specflow.execute`): Build under the discipline each task names
7. **Review** (`/speckit.specflow.review`): Check the result against spec and constitution

### Workflow Rules

- No code is written before the spec is approved.
- Every spec goes through at least one brainstorm session.
- The plan passes a constitution compliance check before tasks are written.
- A phase boundary pauses for human approval.

## Governance

This constitution governs every feature under `specs/`. An amendment needs a
version bump under semantic versioning: MAJOR for a removed or redefined
principle, MINOR for a new principle, PATCH for wording. Amending it invalidates
`.analyzed` for every feature it governs, so rerun `/speckit.analyze` after a
change.

**Version**: 1.0.0 | **Ratified**: 2026-09-14 | **Last Amended**: 2026-09-14
