# Decisions

## ADR-0001: GitHub-style heading-anchor slugification with duplicate suffixing

- Date: 2026-09-27
- Status: accepted
- Context: Q1 (specs/001-link-audit/spec.md) asked whether the slugification algorithm should match a specific Markdown renderer's heading-anchor convention. Left unresolved, this would produce a genuinely ambiguous implementation and untestable acceptance criteria for FR-005.
- Decision: Slugify headings using GitHub's convention — lowercase, spaces to hyphens, strip characters that aren't alphanumeric/hyphen/underscore — and append `-1`, `-2`, ... to duplicate slugs in order of appearance.
- Consequences: FR-005 and the Assumptions section now state this explicitly, so `test_reports_missing_heading_anchor` has an unambiguous convention to implement against. Any future support for a different renderer's convention would need a new ADR and a constitution-compatible flag, since Principle I forbids new runtime dependencies for a renderer-specific library.

## ADR-0002: Abort the scan on an unreadable tracked file

- Date: 2026-09-27
- Status: accepted
- Context: Q2 asked how the CLI should handle a `git ls-files`-tracked Markdown file that cannot be opened or read (permissions, deletion mid-scan, bad encoding). Silently skipping it risks a false-clean (exit 0) result.
- Decision: Abort the scan, print an actionable error naming the file and reason, and exit with status 2, reusing the constitution's existing "scan cannot complete" exit code (Principle II).
- Consequences: Added FR-012. A single unreadable file blocks the whole scan rather than yielding a partial report; this favors trustworthiness of the exit-code contract (SC-003) over best-effort partial results.

## ADR-0003: Bare anchors resolve against the linking file itself

- Date: 2026-09-27
- Status: accepted
- Context: Q3 asked how a bare anchor link (`#some-heading`, no file part) should resolve, since FR-005 as originally written only covered `file.md#anchor`.
- Decision: Treat the linking file as its own target file and reuse the same slugification/reporting logic as `file.md#anchor` links.
- Consequences: Added FR-010 and a matching edge case. No new slugification code path is needed — the existing anchor-resolution logic is reused with the source file as target.

## ADR-0004: Anchor validation is skipped for non-Markdown targets

- Date: 2026-09-27
- Status: accepted
- Context: Q4 asked whether `image.png#section`-style links should undergo heading-anchor validation, given a non-Markdown file has no headings to slugify.
- Decision: Only the file-existence check (FR-004) applies to non-`.md` targets; any anchor fragment present is ignored rather than reported or validated.
- Consequences: Added FR-013 and a matching edge case. Avoids a class of false positives where a legitimate link to a non-Markdown asset with a fragment (e.g., a PDF viewer's `#page=3`) would otherwise be incorrectly flagged.

## ADR-0005: Percent-decode link targets and strip query strings before file-system resolution

- Date: 2026-09-27
- Status: accepted
- Context: Q5 asked whether link targets containing percent-encoding (e.g. `%20`) or query strings should be decoded/stripped before checking the file system, since link targets in this tool are file paths, not URLs.
- Decision: Percent-decode the path, then strip any query string, before checking existence.
- Consequences: Added FR-011 and a matching edge case, plus `test_percent_encoded_targets_are_decoded`. Prevents false missing-file reports for filenames containing spaces or other characters commonly percent-encoded by Markdown authors/editors.
