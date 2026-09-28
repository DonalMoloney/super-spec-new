<!--
Sync Impact Report
Version change: [none] → 1.0.0 (initial ratification)
Modified principles: n/a (new document)
Added sections:
  - Core Principles: I. Standard Library Only, II. CI-First Exit Codes, III. No Network Access,
    IV. Actionable Errors, V. Test-Driven Development
  - Quality Standards
  - Constraints
  - Governance
Removed sections: n/a
Deferred placeholders: none — all template tokens resolved from user input.
Templates requiring follow-up: none checked in this run (constitution-only scope); verify
  .specify/templates/plan-template.md and tasks-template.md align with these principles the next
  time either is touched.
-->

# link-audit Constitution

## Core Principles

### I. Standard Library Only
link-audit MUST run using only the Python 3.11 standard library. No third-party runtime
dependencies may be added to `src/link_audit/`. `pytest` is permitted, but only as a
development/test dependency — it MUST NOT be imported by any code under `src/link_audit/`.

**Rationale**: Maintainers run this tool in CI across many repositories with varying dependency
policies. A zero-runtime-dependency tool installs instantly, has no supply-chain surface, and
never breaks due to an upstream package change.

### II. CI-First Exit Codes
The CLI MUST use exit codes as its primary machine-readable contract: `0` when the scan
completes and finds no broken link, `1` when the scan completes and finds at least one broken
link, `2` when the scan cannot complete (e.g., invalid arguments, unreadable path, internal
error). No other exit code may be used. Exit code semantics MUST NOT change between versions
without a MAJOR constitution amendment.

**Rationale**: CI systems branch on exit codes, not output text. A stable, three-way contract
lets maintainers wire this into pipelines without parsing stdout.

### III. No Network Access During a Scan
A scan MUST NOT perform any network I/O (no HTTP requests, no DNS resolution, no socket
connections) while evaluating links. Link validity is determined by local, offline means only
(e.g., filesystem existence checks for relative links, syntactic checks for anchors/URLs).

**Rationale**: Network calls in CI are slow, flaky, and can leak information or hang pipelines.
An offline-only tool is deterministic and safe to run in sandboxed or air-gapped CI runners.

### IV. Actionable Errors
Every error the tool emits — whether a broken-link finding or a scan-level failure — MUST name
the specific fix (e.g., the correct path, the missing file, the malformed syntax to correct). A
message that only states "broken" or "failed" without pointing to a remedy is a defect.

**Rationale**: The audience is maintainers triaging CI failures, often without deep context on
the tool. Actionable messages let them fix the problem without re-reading source code.

### V. Test-Driven Development
New behavior MUST be introduced via a failing pytest test written first, then the minimal code
to pass it. Every exit-code path (0, 1, 2) and every category of error message MUST have a
corresponding test under the project's pytest suite before it ships.

**Rationale**: The tool's entire value is a trustworthy pass/fail signal in CI; regressions in
exit-code behavior or error accuracy are high-cost and easy to miss without enforced test-first
discipline.

## Quality Standards

- Exit code contract (Principle II) is verified by an automated test for each of the three
  codes (0, 1, 2) before any release.
- Every user-facing error and finding message MUST be reviewed for Principle IV compliance
  (names the fix) as part of code review.
- `pytest` MUST pass with zero failures before any change is merged.
- Output MUST be deterministic: identical input documentation MUST always yield identical exit
  codes and findings, run to run.

## Constraints

- Language/runtime: Python 3.11, standard library only (Principle I).
- Test framework: `pytest`, used only as a development/test dependency.
- Source layout: all importable code lives under `src/link_audit/`.
- Network: zero network access during a scan (Principle III).
- Distribution: no build step may introduce a runtime dependency not present in the standard
  library.

## Governance

This constitution supersedes any conflicting project practice, README guidance, or ad hoc
convention. All pull requests and code reviews MUST verify compliance with the Core Principles
above; any deviation MUST be justified in the PR description or rejected.

**Amendment procedure**: Amendments are proposed via a PR that edits this file, includes an
updated Sync Impact Report, and states the semantic version bump with rationale. A MAJOR bump
requires removing or redefining a principle in a backward-incompatible way; a MINOR bump adds a
principle or materially expands guidance; a PATCH bump is wording/clarification only.

**Compliance review**: Any PR that adds a runtime dependency, performs network I/O during a
scan, changes exit-code semantics, or ships an error message without a named fix MUST be
rejected until it complies with this constitution or the constitution is amended first.

**Version**: 1.0.0 | **Ratified**: 2026-09-27 | **Last Amended**: 2026-09-27
