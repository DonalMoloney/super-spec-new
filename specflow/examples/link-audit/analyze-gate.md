# The analyze gate, stopped then cleared

This file records the `ANALYZE_REQUIRED` stop that `link-audit` hit before
execution, then the rerun that cleared it. Like the rest of this directory it
was constructed from `commands/hooks/before-execute.md` and the Gate markers
protocol in `references/workflow-guide.md`, not captured from a live agent run.
It shows the stop the gate is defined to produce.

`progress.yml` records the outcome as `gates.analyze_attempts: 2`.

## Attempt 1: the gate stops execution

The first `/speckit.analyze` run reported a critical inconsistency, so it left
`.analyzed` absent, per the Gate markers rule that a report with critical
inconsistencies must not write the marker.

```text
$ /speckit.analyze

ANALYZE: specs/001-link-audit

Critical inconsistencies: 1
  C1  FR-012 declares "System MUST stop when the scan reaches 5000 files".
      No task in tasks.md implements it, so the requirement ships untested.
      Fix: add the test task, add the implementation task, rerun analysis.

Zero critical inconsistencies are required before .analyzed is written.
Marker not written: specs/001-link-audit/.analyzed
```

`/speckit.specflow.execute` ran next. Its `before_implement` hook checked the
constitution first, which was present, then the target feature's `.analyzed`
marker, which was not.

```text
$ /speckit.specflow.execute

ANALYZE_REQUIRED
  Feature: specs/001-link-audit
  Missing: specs/001-link-audit/.analyzed
  Run /speckit.analyze for this feature. The analysis must report zero
  critical inconsistencies before the marker is written. Then rerun
  /speckit.specflow.execute.

Execution stopped. No task was started.
```

Nothing was implemented. The gate holds on a resumed run too, so restarting the
session would have produced the same stop.

## Between the attempts: the fix

C1 named one requirement with no task. Two tasks were added to Phase 6 of
`tasks.md`, which is why the phase runs from T029 to T035 rather than T029 to
T033:

- `T031 [P] [TDD] Write tests/test_scanner.py::stops_above_file_cap`
- `T032 [REVIEW] Stop the scan at the 5000-file cap plan.md names`

The spec's Traceability table gained its FR-012 row in the same edit, citing
`tests/test_scanner.py::stops_above_file_cap`.

## Attempt 2: the gate clears

```text
$ /speckit.analyze

ANALYZE: specs/001-link-audit

Critical inconsistencies: 0
Warnings: 1
  W1  R-002 leaves the JSON report unversioned. Minor; does not block.

Coverage: 12 of 12 FR mapped to a task. 4 of 4 SC mapped to a test.
Marker written: specs/001-link-audit/.analyzed
```

```text
$ /speckit.specflow.execute

Gates: constitution present, .analyzed present.
Superpowers: executing-plans found, test-driven-development found,
             subagent-driven-development found.
Resume point: progress.yml absent, starting at Phase 1.

Phase 1 complete. Proceed to Phase 2?
```

Execution then ran the six phases to completion, which is the state
`progress.yml` holds.

## The rule this records

A missing `.analyzed` stops both execution entry points with
`ANALYZE_REQUIRED`, naming the feature path plus the command to run. The marker
is written only by an analyze run that reports zero critical inconsistencies.
It is never inferred from the artifacts already on disk. Removing the marker is
the way to force a rerun after the spec, the plan, the tasks, or the
constitution changes.
