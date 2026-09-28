<!-- specflow template: plan-template 1.1.0 -->
# Implementation Plan: Link Audit CLI

**Branch**: `001-link-audit` | **Date**: 2026-09-27 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/001-link-audit/spec.md`

## Summary

Ship a `link-audit` Python CLI that lists Markdown files via `git ls-files`,
extracts every inline `[text](target)` link from each, and validates each
target offline: relative file targets are checked against the file system
(P1), `file.md#anchor` targets are additionally checked against the target
file's GitHub-slugified headings (P2), and the scan is scoped exclusively to
the files `git ls-files` reports (P3). External-scheme links are skipped.
The CLI prints every unresolved link and exits 0 (clean), 1 (unresolved
links found), or 2 (scan could not complete), per the constitution's
exit-code contract. Content inside fenced code blocks is excluded from
both heading and link extraction (FR-014), and a root-relative link
target (e.g. `/docs/x.md`) resolves against the repository root rather
than the linking file's directory or the OS filesystem root (FR-015).

## Technical Context

**Language/Version**: Python 3.11
**Primary Dependencies**: standard library only — `argparse`, `pathlib`, `re`, `subprocess`, `urllib.parse` (percent-decoding, query stripping); `pytest` as a dev/test-only dependency (Constitution Principle I)
**Storage**: N/A — the CLI reads the working tree and writes only to stdout/stderr
**Testing**: `pytest`, run as `pytest -q`; TDD required for all new behavior (Constitution Principle V)
**Target Platform**: Any platform with Python 3.11 and `git` on PATH (Linux/macOS CI runners, local dev)
**Project Type**: Single-package CLI (console script)
**Performance Goals**: No numeric target in the spec; a bounded, linear-time single pass over `git ls-files` output is sufficient (see Threat Model "Denial of service" row) — no artificial file-count cap is imposed
**Constraints**: Zero network I/O during a scan (Principle III); zero runtime dependencies beyond the standard library (Principle I); exit codes limited to {0, 1, 2} (Principle II); every finding and error names the specific fix (Principle IV)

## Constitution Check

*GATE: The plan must pass this check before work starts. Re-run the check after the design phase.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Standard Library Only | PASS | `src/link_audit/` imports only stdlib modules (`argparse`, `pathlib`, `re`, `subprocess`, `urllib.parse`). `pytest` is a test-only dependency and is never imported under `src/link_audit/`. |
| II. CI-First Exit Codes | PASS | `cli.main()` returns exactly 0 (clean), 1 (unresolved links per FR-007), or 2 (scan aborted per FR-012 / git failure per US3 Scenario 3). No other code is produced. |
| III. No Network Access During a Scan | PASS | External-scheme targets are classified and skipped before any I/O (FR-003); all resolution is `pathlib` existence checks and local file reads. No socket/HTTP module is imported. |
| IV. Actionable Errors | PASS | `report.Finding` always carries source file, target, and reason (FR-006); scan-abort errors name the unreadable file and the reason (FR-012). |
| V. Test-Driven Development | PASS | `tasks.md` (next phase) sequences a failing `pytest` test before each behavior task; the Traceability table in spec.md pre-names one test per FR/SC. |

## Project Structure

### Documentation (this feature)

```text
specs/001-link-audit/
├── spec.md              # Feature specification
├── plan.md              # This file
├── research.md           # Phase 0 output
├── data-model.md          # Phase 1 output
├── quickstart.md          # Phase 1 output
├── contracts/
│   └── cli-contract.md    # Phase 1 output
└── tasks.md              # Task breakdown (/speckit.specflow.tasks output, not yet generated)
```

### Source Code (repository root)

```text
src/link_audit/
├── __init__.py
├── cli.py            # argparse surface; orchestrates discovery → parsing → resolution → report; owns exit codes
├── discovery.py       # runs `git ls-files`, filters to *.md, surfaces exit-2 errors for git failures
├── links.py           # extracts inline [text](target) links from Markdown source, with source line numbers; excludes fenced code block content (FR-014)
├── anchors.py          # extracts headings from Markdown source and slugifies them (GitHub convention, FR-005); excludes fenced code block content (FR-014)
├── resolver.py         # percent-decodes + strips query strings (FR-011), classifies scheme (FR-003), resolves file/anchor targets — a leading-slash target resolves against the repository root (FR-015) — applies FR-009/FR-010/FR-013
└── report.py           # Finding record (source, target, reason) and stdout rendering (FR-006)

tests/
├── test_discovery.py
├── test_links.py
├── test_anchors.py
├── test_resolver.py
├── test_report.py
└── test_cli.py          # end-to-end: builds a temp git repo, runs the CLI, asserts exit code + output
```

**Structure Decision**: One package, one module per pipeline stage, mirroring
the FR groupings in the spec so each test file exercises exactly one module.
No shared `utils` module — the slug helper stays in `anchors.py` next to its
only caller, and percent-decoding stays in `resolver.py` next to the file
resolution it protects (FR-011). This keeps every module small enough that
its `pytest` file can cover 100% of its branches without cross-module
mocking.

## Execution Strategy

### TDD Requirements

- [ ] `anchors.py`: GitHub slugification (lowercase, hyphenation, char-stripping, duplicate-suffix `-1`/`-2`) is a precise, easy-to-get-subtly-wrong algorithm (FR-005) that needs a pinning test per rule.
- [ ] `resolver.py`: the FR-009/FR-010/FR-013 precedence rules (missing-file vs. missing-anchor, bare anchors, non-Markdown targets) are the highest-risk logic for silent false negatives and need one test per rule.
- [ ] `discovery.py`: the exit-2 paths (git failure, unreadable tracked file) are safety-critical per Principle II and need explicit failure-path tests, not just the happy path.
- [ ] `links.py`/`anchors.py`: fenced-code-block exclusion (FR-014) is a state machine that is easy to get wrong at fence boundaries and needs a pinning test.
- [ ] `resolver.py`: root-relative link resolution (FR-015) needs a pinning test to prevent `pathlib`'s absolute-path-overrides-join behavior from silently resolving a leading-slash target against the OS filesystem root instead of the repository root.

### Independent Work Streams

- [ ] `links.py` (link extraction) and `anchors.py` (heading slugification) share no file and no runtime dependency on each other, so they run together.
- [ ] `discovery.py` (git scoping) is independent of both `links.py` and `anchors.py` and can run in the same wave.
- [ ] `resolver.py` and `report.py` depend on the three modules above and run in a later wave once their interfaces are fixed.
- [ ] `cli.py` and `test_cli.py` (end-to-end) run last, once every unit module is complete.

### Human Checkpoints

1. After the foundational phase (`discovery.py`, `links.py`, `anchors.py` scaffolding), check the module layout against the structure above.
2. After User Story 1 (`resolver.py` file-existence + `cli.py` exit 0/1), check the report format against the P1 acceptance scenarios.
3. After User Story 2 (anchor resolution), check anchor findings against the P2 acceptance scenarios, in particular the FR-009 precedence rule.
4. After every story lands, run `pytest -q` before the polish phase.
5. Before merge, review the work against spec.md's Traceability table — every FR/SC row must have a passing, named test.

### Review Gates

- [ ] `report.Finding`: review the record shape (fields, ordering) before `cli.py` consumes it for stdout rendering.
- [ ] `resolver.py` precedence logic (FR-009, FR-010, FR-013): review before it is wired into `cli.py`, since it is the module most likely to hide a false negative.
- [ ] `discovery.py` exit-2 paths: review before merge, since Principle II treats exit-code semantics as a stability contract.

## Justified constitution violations

> **Fill in this table only when the Constitution Check flags a violation to justify**

No violation. The table stays empty.
