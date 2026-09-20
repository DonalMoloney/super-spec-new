# Review Checklist: Broken Link Audit

**Purpose**: Check the implementation against the spec, the constitution, the code standards
**Created**: 2026-09-15
**Feature**: [spec.md](../spec.md)

## Spec Compliance

- [x] CHK001 US1 Scenario 1: implemented by T017 through T019, covered by `reports_missing_target`
- [x] CHK002 US1 Scenario 2: implemented by T020, covered by `exits_0_on_clean_repository`
- [x] CHK003 US1 Scenario 3: a directory target resolves, covered by `accepts_existing_target`
- [x] CHK004 US2 Scenario 1: implemented by T024, covered by `rejects_missing_heading_anchor`
- [x] CHK005 US2 Scenario 2: implemented by T023, covered by `accepts_slugified_heading_anchor`
- [x] CHK006 US3 Scenario 1: implemented by T026, covered by `skips_http_target`
- [x] CHK007 US3 Scenario 2: implemented by T028, covered by `honours_ignore_glob`

## Code Review

### Correctness

- [x] CHK010 Every acceptance scenario has a passing test
- [x] CHK011 Every edge case from the brainstorm session is handled
- [x] CHK012 Error handling covers each failure path, with no silent failure
- [x] CHK013 The scan root containment check runs before any file is read

### Security

- [x] CHK020 No injection vector exists: `git ls-files` runs with an argument list, never a shell string
- [x] CHK021 N/A: the audit has no authentication surface
- [x] CHK022 The report quotes repository-relative paths, never the absolute scan root
- [x] CHK023 Every link target passes through the containment check in `scanner.py`
- [x] CHK024 The STRIDE table fills every row, marking four N/A with a reason

### Performance

- [x] CHK030 Each target file's headings are slugged once per scan, not once per link
- [x] CHK031 The file cap stops a runaway scan at 5000 files
- [x] CHK032 The scan makes no network call, so no request blocks it

### Code Quality

- [x] CHK040 Each module owns one stage of the pipeline, per the structure decision
- [x] CHK041 No `utils` module exists; the slug helper sits in `anchors.py`
- [ ] CHK042 The JSON report carries a version the consumer can branch on
- [x] CHK043 Names follow the domain vocabulary: `MarkdownFile`, `Link`, `BrokenLink`

## Constitution Compliance

- [x] CHK050 Principle I Test-First: every implementation task follows a `[TDD]` test task
- [x] CHK051 Principle II One Command, One Job: the audit writes no file
- [x] CHK052 Principle III Exit Codes: `cli.py` returns 0, 1, or 2, nothing else
- [x] CHK053 Principle IV No Network: no HTTP client is imported
- [x] CHK054 Principle V Errors Name The Fix: `LinkAuditError` states expected, found, next step

## Test Coverage

- [x] CHK060 Unit tests cover discovery, parsing, anchors, resolution
- [x] CHK061 Integration tests drive the CLI end to end, per `test_cli.py`
- [x] CHK062 `pytest -q` reports 47 passed in CI
- [x] CHK063 Every `[TDD]` task recorded a failing run before its implementation
- [x] CHK064 Every criterion lists a test in Traceability

## Review Findings

| CHK ID | R-NNN | Status |
|--------|-------|--------|
| CHK064 | R-001 | fixed |
| CHK042 | R-002 | open |

## Notes

- CHK042 stays unchecked: R-002 is a Minor finding, which does not block the merge gate.
- Findings below 80 confidence were dropped before this checklist was filled.
