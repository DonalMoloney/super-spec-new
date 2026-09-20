# Implementation Plan: Broken Link Audit

**Branch**: `001-link-audit` | **Date**: 2026-09-14 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/001-link-audit/spec.md`

## Summary

Ship a `link-audit` console command that walks the Markdown files `git ls-files`
reports, resolves each inline link target against the file system, prints the
unresolved ones, exits 1 when any is unresolved. Anchors resolve against the
slugified headings of the target file. External schemes are skipped, so the scan
stays offline.

## Technical Context

**Language/Version**: Python 3.11
**Primary Dependencies**: standard library only (`argparse`, `pathlib`, `re`, `subprocess`, `json`)
**Storage**: N/A, the audit reads the working tree, writes nothing
**Testing**: pytest 8, run as `pytest -q`
**Target Platform**: Linux CI runner, macOS laptop
**Project Type**: CLI
**Performance Goals**: 500 Markdown files in under 5 s on a laptop, per SC-001
**Constraints**: no network call during a scan; scan stops at 5000 files

## Constitution Check

*GATE: The plan must pass this check before it proceeds. Re-check it after the design phase.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Test-First | PASS | Every behavior task in tasks.md is preceded by its `[TDD]` test task. |
| II. One Command, One Job | PASS | The command reports; it never edits a file. Fixing is a later feature. |
| III. Exit Codes Are The Contract | PASS | `cli` returns 0, 1, or 2. FR-011 and FR-012 both map to 2. |
| IV. No Network During A Scan | PASS | FR-007 skips external schemes. No HTTP client is imported. |
| V. Errors Name The Fix | PASS | `LinkAuditError` carries expected, found, next step; `cli` prints it to stderr. |

## Project Structure

### Documentation (this feature)

```text
specs/001-link-audit/
├── spec.md              # Feature specification
├── plan.md              # This file
├── tasks.md             # Task breakdown (/speckit.specflow.tasks output)
├── progress.yml         # Execution state
├── review-findings.json # /speckit.specflow.review output
└── checklists/          # requirements.md, review.md
```

### Source Code (repository root)

```text
src/link_audit/
├── __init__.py
├── cli.py               # argparse surface, exit codes
├── discovery.py         # git ls-files walk, root containment
├── parser.py            # inline link extraction, code-fence skipping
├── anchors.py           # heading slugs
├── scanner.py           # resolution, the 5000-file cap
└── report.py            # BrokenLink record, text and JSON rendering

tests/
├── test_cli.py
├── test_discovery.py
├── test_parser.py
├── test_anchors.py
├── test_scanner.py
└── test_performance.py
```

**Structure Decision**: One package, one module per stage of the pipeline, so a
test names the module it exercises. No `utils` module: the slug helper lives in
`anchors.py` beside its only caller.

## Execution Strategy

### TDD Requirements

- [x] `parser.py`: fenced code blocks, query strings, fragments give the link grammar many edge cases
- [x] `anchors.py`: slugging rules follow the GitHub renderer, which only a test pins down
- [x] `scanner.py`: root containment is a security control, so it needs a test that tries to escape

### Parallel Execution Opportunities

- [x] `parser.py` work shares no file with `anchors.py` work, so the two run together
- [x] Every `[TDD]` test task in a phase runs in parallel; each writes its own test file
- [x] The README task runs independently once the CLI surface is frozen

### Human Checkpoints

1. After the foundational phase, check the module layout against the structure above
2. After User Story 1, check the report format against the acceptance scenarios
3. After all stories, run `pytest -q` before the polish phase
4. Before the merge, review the work against the spec

### Review Gates

- [x] `report.BrokenLink`: review the record shape before any renderer consumes it
- [x] The 5000-file cap: review the stop path before it ships, since it changes the exit code

## Complexity Tracking

> **Fill in this table only when the Constitution Check lists a violation to justify**

No violation. The table stays empty.
