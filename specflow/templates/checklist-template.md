<!-- specflow template: checklist-template 1.0.2 -->
# [CHECKLIST TYPE] Checklist: [FEATURE NAME]

**Purpose**: [Brief description of what this checklist covers]
**Created**: [DATE]
**Feature**: [Link to spec.md or relevant documentation]

<!--
  ============================================================================
  The checklist items below are sample items for illustration only.

  The /speckit.checklist command must replace these with actual items based on:
  - User's specific checklist request
  - Feature requirements from spec.md
  - Technical context from plan.md
  - Implementation details from tasks.md

  Delete these sample items before shipping the generated checklist file.
  ============================================================================
-->

## Spec Compliance

<!--
  Check that each acceptance scenario from the spec is implemented and passing.
  These items come from spec.md's user stories and acceptance scenarios.
-->

- [ ] CHK001 US1 Scenario 1: [Given/When/Then from spec], implemented and tested
- [ ] CHK002 US1 Scenario 2: [Given/When/Then from spec], implemented and tested
- [ ] CHK003 US2 Scenario 1: [Given/When/Then from spec], implemented and tested
- [ ] CHK004 Edge case: [Edge case from spec], handled

## Code Review

<!--
  These checks apply to most features.
  Adjust them against the constitution's quality gates.
-->

### Correctness

- [ ] CHK010 The logic passes every acceptance scenario
- [ ] CHK011 The implementation covers every edge case from brainstorming
- [ ] CHK012 Error handling covers every failure path (no silent failures)
- [ ] CHK013 The system validates data at every boundary

### Security

- [ ] CHK020 No injection vulnerability exists (SQL, XSS, command injection)
- [ ] CHK021 Authentication and authorization checks exist
- [ ] CHK022 The code never logs or exposes sensitive data
- [ ] CHK023 Every entry point sanitizes its input
- [ ] CHK024 The review fills the STRIDE table, or marks each row N/A

### Performance

- [ ] CHK030 The code makes no N+1 query or unnecessary database call
- [ ] CHK031 The code caches where caching pays off
- [ ] CHK032 Critical paths run no blocking operation
- [ ] CHK033 The code closes every connection and file handle it opens

### Code Quality

- [ ] CHK040 The code follows the constitution's conventions
- [ ] CHK041 Each function does one thing and stays small
- [ ] CHK042 Duplicate code stays under the project's limit
- [ ] CHK043 Names stay clear and consistent

## Constitution Compliance

<!--
  Check that the feature respects each constitution principle.
  These items come from the principles in .specify/memory/constitution.md.
-->

- [ ] CHK050 [Principle 1]: [Specific verification for this feature]
- [ ] CHK051 [Principle 2]: [Specific verification for this feature]
- [ ] CHK052 [Principle 3]: [Specific verification for this feature]

## Test Coverage

<!--
  Check that tests exist and pass for critical functionality.
-->

- [ ] CHK060 Unit tests cover core business logic
- [ ] CHK061 Integration tests cover user flows
- [ ] CHK062 All tests pass in the CI environment
- [ ] CHK063 [TDD] tasks followed RED-GREEN-REFACTOR discipline
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
  R-NNN ids come from the review-findings.json the review command writes.
-->

| CHK ID | R-NNN | Status |
|--------|-------|--------|
| CHK012 | R-001 | open |
| CHK021 | R-004 | fixed |

## Notes

- Check items off as completed: `[x]`
- Add inline comments for findings or exceptions
- Link to relevant code, tests, or documentation
- Number items sequentially (CHK###) for easy reference
- Report issues with a confidence score (0-100); flag only scores at or above 80
