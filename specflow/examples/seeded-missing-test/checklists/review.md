# Implementation Review: Link Audit CLI

**Purpose**: Review `src/link_audit/` against `specs/001-link-audit/spec.md`, `plan.md`, and `tasks.md`
**Reviewed**: 2026-09-27
**Reviewer**: speckit.specflow.review (built-in protocol — `requesting-code-review` not detected at `.agents/skills/` project-local or user-global path)
**Risk tier**: STANDARD (implementation is 7 small modules, no auth/payments/migrations/infra paths, no lockfile changes)
**Verdict**: **BLOCK** (3 open Critical findings)

## Verification performed

- [x] Ran `pytest -q` against the full suite: 29 passed, 0 failed
- [x] Read every module under `src/link_audit/` (`cli.py`, `discovery.py`, `links.py`, `anchors.py`, `resolver.py`, `report.py`, `errors.py`) against spec.md's FRs and plan.md's module boundaries
- [x] Reproduced `git ls-files -- '*.md'` pathspec behavior empirically to confirm it recurses into subdirectories (FR-001 — confirmed correct, not a finding)
- [x] Reproduced fenced-code-block heading pollution in `anchors.slugify_headings()` (R-001)
- [x] Reproduced fenced-code-block link false-positive in `links.extract_links()` (R-002)
- [x] Reproduced an uncaught `PermissionError` crash when an anchor-target file is unreadable (R-003)
- [x] Reproduced pathlib's absolute-path-overrides-join behavior for a leading-slash link target (R-004)

## Spec Compliance (User Stories 1–3)

- [x] US1 (P1, missing relative link → exit 1): acceptance scenarios 1–3 all covered by `tests/test_cli.py`, `tests/test_resolver.py`; verified passing
- [x] US2 (P2, missing heading anchor → exit 1): acceptance scenarios 1–3 covered by `tests/test_resolver.py`, `tests/test_report.py`, `tests/test_cli.py`; verified passing
- [ ] US2 anchor resolution is undermined by R-001 for any target file containing a fenced code block
- [x] US3 (P3, scan scoped to `git ls-files`): acceptance scenarios 1, 2, 4 covered; scenario 3 (git failure → exit 2) covered by `tests/test_discovery.py`, `tests/test_cli.py`
- [ ] US1/US3's "zero false positives" guarantee (SC-001) is undermined by R-002 (code-fence link false positives) and R-004 (root-relative link false positives)

## Edge Case Coverage

- [x] External-scheme links skipped without I/O (FR-003) — verified in `resolver.classify_and_decode`
- [x] Bare anchor resolves against source file itself (FR-010) — verified in `resolver.resolve_file`
- [x] Non-Markdown target skips anchor validation (FR-013) — verified in `resolver._check_anchor`
- [x] Duplicate heading slugs get `-1`, `-2`, ... suffixes in document order (FR-005) — verified in `anchors.slugify_headings`
- [x] Percent-encoding and query strings stripped before resolution (FR-011) — verified in `resolver.classify_and_decode`
- [x] Zero tracked Markdown files exits 0 cleanly (US3 Scenario 4) — verified in `tests/test_discovery.py`
- [x] Unreadable *linking* file aborts with exit 2 (FR-012) — verified in `cli.main`/`tests/test_cli.py`
- [ ] Unreadable *anchor-target* file is **not** covered by FR-012's exit-2 path — crashes uncaught (R-003)
- [ ] Fenced code blocks are not excluded from heading or link extraction — not mentioned anywhere in spec.md's Edge Cases, and not handled by the implementation (R-001, R-002)
- [ ] A leading-slash ("root-relative") link target is not addressed by spec.md's Assumptions or Edge Cases, and the implementation's behavior for it is surprising and untested (R-004)

## Constitution Compliance

- [x] Principle I (Standard Library Only): confirmed — only `argparse`, `pathlib`, `re`, `subprocess`, `urllib.parse`, `dataclasses`, `typing` imported under `src/link_audit/`
- [ ] Principle II (CI-First Exit Codes — "No other exit code may be used"): **violated** by R-003 — an uncaught `PermissionError` produces an exit status that is neither 0, 1, nor 2 by design (it is whatever Python's default traceback handler emits)
- [x] Principle III (No Network Access): confirmed — external schemes are classified and skipped before any I/O; `tests/test_cli.py` monkeypatches socket calls to raise if invoked
- [ ] Principle IV (Actionable Errors): **violated** by R-003 — a raw traceback does not name the fix
- [x] Principle V (Test-Driven Development): tasks.md shows `[TDD]` tasks completed in sequence; `pytest -q` passes for all named tests

## Code Quality

- [ ] R-001: `anchors.slugify_headings()` has no fenced-code-block awareness — reproduced misclassification of a `# bash comment` inside a ` ```bash ` block as a real heading
- [ ] R-002: `links.extract_links()` has no fenced-code-block awareness — reproduced false-positive extraction of `[example](nonexistent-file.md)` from inside a ` ```markdown ` example block
- [ ] R-003: `resolver._check_anchor()`'s `target_file.read_text()` (resolver.py:80) is unguarded, unlike the linking-file read in `cli.py`, which is wrapped — inconsistent error handling between the two file reads in the same pipeline
- [ ] R-004: `resolver.resolve_file()`'s `base_dir / parsed.file_part` (resolver.py:58) silently discards `base_dir` for any target beginning with `/`, per pathlib's absolute-path-join semantics

## Test Coverage

- [x] Every FR/SC row in spec.md's Traceability table names a test, and every named test passes (`pytest -q`: 29 passed)
- [ ] No test in `tests/test_anchors.py` or `tests/test_links.py` exercises a fenced code block (gap tied to R-001, R-002)
- [ ] No test in `tests/test_cli.py` or `tests/test_resolver.py` exercises an unreadable anchor-target file, only an unreadable linking file (gap tied to R-003)
- [ ] No test exercises a leading-slash link target (gap tied to R-004)

## Review Findings

| CHK | Finding | Status |
|-----|---------|--------|
| Edge Case Coverage — fenced code blocks (headings) | R-001 | open |
| Edge Case Coverage — fenced code blocks (links) | R-002 | open |
| Edge Case Coverage — unreadable anchor-target file | R-003 | open |
| Edge Case Coverage — leading-slash link target | R-004 | open |
| Constitution Compliance — Principle II | R-003 | open |
| Constitution Compliance — Principle IV | R-003 | open |
| Code Quality — anchors.py fenced-code-block awareness | R-001 | open |
| Code Quality — links.py fenced-code-block awareness | R-002 | open |
| Code Quality — resolver.py unguarded target read | R-003 | open |
| Code Quality — resolver.py leading-slash join | R-004 | open |

See `specs/001-link-audit/review-findings.json` for full evidence and fix recommendations per finding, and `spec.md`'s Open Questions table (Q6, Q7) for the spec gaps these findings surfaced.
