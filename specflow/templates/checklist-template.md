<!-- specflow template: checklist-template 1.1.0 -->
# [CHECKLIST TYPE] Checklist: [FEATURE NAME]

**Purpose**: [Brief description of what this checklist covers]
**Created**: [DATE]
**Feature**: [Link to spec.md or relevant documentation]

<!--
  ============================================================================
  These sample items show the format only.

  The /speckit.checklist command replaces these sample items with ones from:
  - The user's specific checklist request
  - Feature requirements from spec.md
  - Technical context from plan.md
  - Implementation details from tasks.md

  Delete these sample items before shipping the generated checklist file.
  ============================================================================
-->

## Spec Compliance

<!--
  Check that the code implements and passes each acceptance scenario from the spec.
  This category draws its items from spec.md's user stories and acceptance scenarios.
-->

- [ ] CHK001 US1 Scenario 1: the code implements and tests [Given/When/Then from spec]
- [ ] CHK002 US1 Scenario 2: the code implements and tests [Given/When/Then from spec]
- [ ] CHK003 US2 Scenario 1: the code implements and tests [Given/When/Then from spec]
- [ ] CHK004 Edge case: the code handles [Edge case from spec]

## Code Review

<!--
  These checks apply to most features.
  Adjust each one against the constitution's quality gates.
-->

### Correctness

- [ ] CHK010 The logic passes every acceptance scenario
- [ ] CHK011 The implementation covers every edge case from brainstorming
- [ ] CHK012 Error handling covers every failure path (no silent failures)
- [ ] CHK013 The system validates data at every boundary

### Security

- [ ] CHK020 The code carries no SQL, XSS, or command injection vulnerability
- [ ] CHK021 The code checks authentication and authorization
- [ ] CHK022 The code never logs or exposes sensitive data
- [ ] CHK023 Every entry point sanitizes its input
- [ ] CHK024 The review fills the STRIDE table, or marks each row N/A

### Performance

- [ ] CHK030 The code avoids N+1 queries and unnecessary database calls
- [ ] CHK031 The code caches where caching pays off
- [ ] CHK032 Critical paths run no blocking operation
- [ ] CHK033 The code closes every connection and file handle it opens

### Code Quality

- [ ] CHK040 The code follows the constitution's conventions
- [ ] CHK041 Each function covers one responsibility and stays small
- [ ] CHK042 Duplicate code stays under the project's limit
- [ ] CHK043 Names stay clear and consistent

## Constitution Compliance

<!--
  Check that the feature respects each constitution principle.
  This category draws its items from the principles in .specify/memory/constitution.md.
-->

- [ ] CHK050 [Principle 1]: [Specific verification for this feature]
- [ ] CHK051 [Principle 2]: [Specific verification for this feature]
- [ ] CHK052 [Principle 3]: [Specific verification for this feature]

## Test Coverage

<!--
  Check that tests cover the critical logic and pass.
-->

- [ ] CHK060 Unit tests cover core business logic
- [ ] CHK061 Integration tests cover user flows
- [ ] CHK062 All tests pass in the CI environment
- [ ] CHK063 Every [TDD] task followed the RED-GREEN-REFACTOR discipline
- [ ] CHK064 Every criterion lists a test in Traceability

## [Custom Category]

<!--
  Add domain-specific checklist categories here.
  Examples: Accessibility, Internationalization, Data Migration, API Compatibility
-->

- [ ] CHK070 [Custom checklist item]
- [ ] CHK071 [Custom checklist item]

## Review Findings

<!--
  Join a failed checklist item to the review finding that reported it.
  review-findings.json holds the R-NNN ids, and the review command writes that file.
-->

| CHK ID | R-NNN | Status |
|--------|-------|--------|
| CHK012 | R-001 | open |
| CHK021 | R-004 | fixed |

## Notes

- Check off a completed item with `[x]`.
- Add an inline comment for a finding or an exception.
- Link to the code, tests, or documentation the item covers.
- Number items in sequence with the CHK### prefix, so a reader can reference one directly.
- Score each finding from 0 to 100 for confidence; report only scores at or above 80.
