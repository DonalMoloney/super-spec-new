# Implementation Review: Link Audit CLI

**Purpose**: Review `src/link_audit/` against `specs/001-link-audit/spec.md`, `plan.md`, and `tasks.md`
**Reviewed**: 2026-09-27
**Reviewer**: speckit.specflow.review (built-in protocol — `requesting-code-review` not detected at `.agents/skills/` project-local or user-global path)
**Risk tier**: STANDARD (implementation is 7 small modules, no auth/payments/migrations/infra paths, no lockfile changes)
**Verdict**: **CLEAN** (all 4 prior Critical/Important findings verified fixed; no new finding at ≥80 confidence)

## Verification performed

- [x] Ran `pytest -q` against the full suite: 37 passed, 0 failed (up from 29 in the prior run — 8 new tests from Phase 7 remediation)
- [x] Re-read every module under `src/link_audit/` (`cli.py`, `discovery.py`, `links.py`, `anchors.py`, `resolver.py`, `report.py`, `errors.py`) against spec.md's FRs and plan.md's module boundaries
- [x] Confirmed `anchors.slugify_headings()` now tracks fenced-code-block state (`_FENCE_PATTERN`, `in_fence` toggle) and skips heading matching while inside a fence (R-001 fix, `anchors.py:30-36`)
- [x] Confirmed `links.extract_links()` mirrors the same fence-state tracking and skips link matching while inside a fence (R-002 fix, `links.py:22-28`)
- [x] Confirmed `resolver._check_anchor()` now wraps `target_file.read_text()` in `try`/`except (OSError, UnicodeDecodeError)`, raising `LinkAuditError(file=target_file, ...)` (R-003 fix, `resolver.py:85-88`), and traced that this exception propagates uncaught through `resolve_file()` → `cli._scan()` → `cli.main()`'s existing `except LinkAuditError` handler, producing exit 2 with an actionable message — no new exit-code path was introduced
- [x] Confirmed `resolver.resolve_file()` now branches on `parsed.file_part.startswith("/")` and resolves against `root` (repository root) instead of `base_dir` for root-relative targets (R-004 fix, `resolver.py:58-63`), and that the non-root-relative branch (`base_dir / parsed.file_part`) is unchanged
- [x] Confirmed each fix has a dedicated pinning test: `test_heading_like_line_inside_fenced_code_block_is_not_extracted` (test_anchors.py), `test_link_like_text_inside_fenced_code_block_is_not_extracted` (test_links.py), `test_unreadable_anchor_target_raises_link_audit_error` + `test_unreadable_anchor_target_exits_2_and_names_file` (test_resolver.py / test_cli.py), `test_root_relative_link_resolves_against_repository_root` + `test_root_relative_link_to_missing_file_is_reported` + `test_root_relative_link_end_to_end` (test_resolver.py / test_cli.py)

## Spec Compliance (User Stories 1–3)

- [x] US1 (P1, missing relative link → exit 1): acceptance scenarios 1–3 covered and passing
- [x] US2 (P2, missing heading anchor → exit 1): acceptance scenarios 1–3 covered and passing; no longer undermined by R-001 — fenced-code-block headings no longer pollute duplicate-slug numbering or mask real anchors
- [x] US3 (P3, scan scoped to `git ls-files`): acceptance scenarios 1–4 covered and passing
- [x] SC-001's "zero false positives" guarantee: R-002 (code-fence link false positives) and R-004 (root-relative link false positives) both fixed and pinned

## Edge Case Coverage

- [x] External-scheme links skipped without I/O (FR-003)
- [x] Bare anchor resolves against source file itself (FR-010)
- [x] Non-Markdown target skips anchor validation (FR-013)
- [x] Duplicate heading slugs get `-1`, `-2`, ... suffixes in document order (FR-005)
- [x] Percent-encoding and query strings stripped before resolution (FR-011)
- [x] Zero tracked Markdown files exits 0 cleanly (US3 Scenario 4)
- [x] Unreadable *linking* file aborts with exit 2 (FR-012)
- [x] Unreadable *anchor-target* file now aborts with exit 2 via the same `LinkAuditError` contract (R-003 closed)
- [x] Fenced code blocks are now excluded from both heading and link extraction (FR-014; R-001, R-002 closed)
- [x] A leading-slash ("root-relative") link target now resolves against the repository root (FR-015; R-004 closed)

## Constitution Compliance

- [x] Principle I (Standard Library Only): confirmed — only `argparse`, `pathlib`, `re`, `subprocess`, `urllib.parse`, `dataclasses`, `typing` imported under `src/link_audit/`
- [x] Principle II (CI-First Exit Codes): confirmed — the R-003 fix routes the anchor-target read failure through the existing `LinkAuditError` → exit-2 path; no exception can escape `cli.main()` uncaught in the paths exercised by the test suite
- [x] Principle III (No Network Access): confirmed — external schemes are classified and skipped before any I/O; `tests/test_cli.py` monkeypatches socket calls to raise if invoked
- [x] Principle IV (Actionable Errors): confirmed — the R-003 fix produces `f"{target_file}: {reason}"`, naming the specific unreadable file, consistent with the linking-file error format
- [x] Principle V (Test-Driven Development): `tasks.md` Phase 7 shows `[TDD]` tasks (T043–T057) completed RED→GREEN in sequence; `pytest -q` passes for all named tests

## Code Quality

- [x] R-001 closed: `anchors.slugify_headings()` tracks fence state and skips heading matching inside a fence
- [x] R-002 closed: `links.extract_links()` tracks fence state and skips link matching inside a fence
- [x] R-003 closed: `resolver._check_anchor()`'s target-file read is now guarded identically to the linking-file read in `cli.py`
- [x] R-004 closed: `resolver.resolve_file()` no longer lets `base_dir / parsed.file_part` silently discard `base_dir` for a leading-slash target; it now explicitly branches and joins against `root`

## Test Coverage

- [x] Every FR/SC row in spec.md's Traceability table names a test, and every named test passes (`pytest -q`: 37 passed)
- [x] `tests/test_anchors.py` and `tests/test_links.py` each now exercise a fenced code block
- [x] `tests/test_resolver.py` and `tests/test_cli.py` each now exercise an unreadable anchor-target file
- [x] `tests/test_resolver.py` and `tests/test_cli.py` each now exercise a leading-slash link target

## Review Findings

No open findings from this run. The four findings below are inherited from the prior review run and are recorded here as closed, per the join-to-checklist-item convention.

| CHK | Finding | Status |
|-----|---------|--------|
| Edge Case Coverage — fenced code blocks (headings) | R-001 | fixed |
| Edge Case Coverage — fenced code blocks (links) | R-002 | fixed |
| Edge Case Coverage — unreadable anchor-target file | R-003 | fixed |
| Edge Case Coverage — leading-slash link target | R-004 | fixed |
| Constitution Compliance — Principle II | R-003 | fixed |
| Constitution Compliance — Principle IV | R-003 | fixed |
| Code Quality — anchors.py fenced-code-block awareness | R-001 | fixed |
| Code Quality — links.py fenced-code-block awareness | R-002 | fixed |
| Code Quality — resolver.py unguarded target read | R-003 | fixed |
| Code Quality — resolver.py leading-slash join | R-004 | fixed |

See `specs/001-link-audit/review-findings.json` for the full findings record (all `status: "fixed"`, `verdict: "CLEAN"`).
