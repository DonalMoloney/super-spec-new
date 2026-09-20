# Requirements Checklist: Broken Link Audit

**Purpose**: Check the spec before planning starts, so an ambiguity is found while it is cheap
**Created**: 2026-09-14
**Feature**: [spec.md](../spec.md)

## Spec Compliance

- [x] CHK001 US1 Scenario 1: a missing target names its file, its line, its target
- [x] CHK002 US1 Scenario 2: a clean tree reports nothing, exits 0
- [x] CHK003 US1 Scenario 3: a directory target counts as resolved
- [x] CHK004 US2 Scenario 1: a fragment matching no heading is reported
- [x] CHK005 US2 Scenario 2: a fragment matching a slugified heading resolves
- [x] CHK006 US3 Scenario 1: an `https://` target is skipped without a network call
- [x] CHK007 US3 Scenario 2: `--ignore 'vendor/**'` keeps vendored files out of the scan
- [x] CHK008 Edge case: a query string on a target resolves against the path alone
- [x] CHK009 Edge case: a link inside a fenced code block is skipped

## Requirement Quality

- [x] CHK010 Every FR states one capability, testable without a follow-up question
- [x] CHK011 No requirement names an implementation detail the plan should own
- [x] CHK012 Every SC carries a number a reader can measure
- [x] CHK013 No unresolved clarification marker survives the clarify gate
- [x] CHK014 Every FR appears in the Traceability table
- [x] CHK015 Every SC appears in the Traceability table

## Constitution Compliance

- [x] CHK020 Principle I Test-First: every behavior FR has a named test
- [x] CHK021 Principle II One Command, One Job: no FR asks the audit to edit a file
- [x] CHK022 Principle III Exit Codes: FR-009, FR-011, FR-012 map to 1, 2, 2
- [x] CHK023 Principle IV No Network: FR-007 skips external schemes
- [x] CHK024 Principle V Errors Name The Fix: FR-011 names `LinkAuditError`

## Scope

- [x] CHK030 Reference-style links are stated as out of scope in Assumptions
- [x] CHK031 reStructuredText is stated as out of scope in Assumptions
- [x] CHK032 The STRIDE table fills every row, or marks it N/A with a reason

## Review Findings

| CHK ID | R-NNN | Status |
|--------|-------|--------|

## Notes

- This checklist ran before `/speckit.plan`, so no implementation item appears here.
- The review checklist in `review.md` covers the implementation.
