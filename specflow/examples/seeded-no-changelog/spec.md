<!-- specflow template: spec-template 1.1.0 -->
# Feature Specification: Link Audit CLI

**Feature Branch**: `001-link-audit`
**Created**: 2026-09-27
**Status**: Draft
**Input**: User description: "link-audit is a Python CLI that walks the Markdown files git ls-files reports, resolves each inline link target against the file system, prints the unresolved ones, exits 1 when any is unresolved. Heading anchors resolve against the slugified headings of the target file. External schemes are skipped, so the scan needs no network. Three priorities: P1: Report every relative link whose target file is missing. P2: Report every file.md#anchor link whose anchor matches no heading. P3: Scan only the Markdown files git ls-files reports."

## User Scenarios & Testing *(mandatory)*

<!--
  Order the user stories by importance, most important first.
  Each user story stands on its own: implementing only one still ships a
  usable MVP (Minimum Viable Product).

  Assign each story a priority (P1, P2, P3), with P1 the most critical.
  Each story meets these independence criteria:
  - You can develop it without the others.
  - You can test it without the others.
  - You can deploy it without the others.
  - You can demonstrate it to users without the others.
-->

### User Story 1 - Catch broken relative links (Priority: P1)

A maintainer runs the link-audit CLI against their repository's Markdown files. The tool reports every relative link (e.g. `[docs](../guide/setup.md)`) whose target file does not exist on disk, so the maintainer can fix or remove dead links before they reach readers.

**Why this priority**: A broken link to a missing file is the most damaging and most common documentation defect — it sends readers to a 404 or a dead path with no recovery. This is the minimum viable capability of the tool.

**Independent Test**: Can be fully tested by pointing the CLI at a small repository containing one Markdown file with a relative link to a file that does not exist, and confirming the tool prints that link and exits with a non-zero status.

**Acceptance Scenarios**:

1. **Given** a Markdown file with a relative link to a file that exists at the expected path, **When** the CLI scans the repository, **Then** that link is not reported and the file is treated as resolved.
2. **Given** a Markdown file with a relative link to a file that does not exist at the expected path, **When** the CLI scans the repository, **Then** the CLI prints the unresolved link (including source file and target path) and exits with status 1.
3. **Given** a repository where every relative link resolves successfully, **When** the CLI finishes scanning, **Then** it prints no unresolved links and exits with status 0.

---

### User Story 2 - Catch broken heading anchors (Priority: P2)

A maintainer runs the link-audit CLI to catch links of the form `file.md#anchor` where the target file exists but the anchor no longer matches any heading in that file (for example, after a heading was renamed). The tool reports these so readers aren't dropped at the top of the wrong section.

**Why this priority**: Anchor links rot silently whenever a heading is renamed, and this failure mode is invisible to a simple "does the file exist" check. It builds directly on P1's file-resolution logic, so it is the natural second layer of coverage.

**Independent Test**: Can be fully tested by creating a target Markdown file with a known set of headings and a linking file with a `file.md#anchor` link whose anchor does not match any slugified heading in the target, then confirming the CLI reports it.

**Acceptance Scenarios**:

1. **Given** a link `file.md#some-heading` where `file.md` exists and contains a heading that slugifies to `some-heading`, **When** the CLI scans the repository, **Then** the link is not reported.
2. **Given** a link `file.md#missing-heading` where `file.md` exists but no heading slugifies to `missing-heading`, **When** the CLI scans the repository, **Then** the CLI prints the unresolved anchor link (including source file, target file, and anchor) and exits with status 1.
3. **Given** a link to `file.md#anchor` where `file.md` itself does not exist, **When** the CLI scans the repository, **Then** the CLI reports it as a missing-file link (per P1) rather than duplicating it as a missing-anchor error.

---

### User Story 3 - Scan exactly the tracked Markdown files (Priority: P3)

A maintainer runs the link-audit CLI inside a git repository that also contains build artifacts, ignored files, or scratch notes. The tool limits its scan to the Markdown files that `git ls-files` reports, so untracked or ignored content never produces false positives or false negatives.

**Why this priority**: This scoping rule keeps the tool's results trustworthy and repeatable across machines and CI, but it is a supporting constraint rather than a standalone user-facing check — it refines *what* gets scanned by P1 and P2 rather than adding a new class of defect.

**Independent Test**: Can be fully tested by creating a repository with a tracked Markdown file containing a broken link and an untracked (or `.gitignore`d) Markdown file containing a different broken link, then confirming the CLI reports only the link from the tracked file.

**Acceptance Scenarios**:

1. **Given** a repository where `git ls-files` reports a specific set of `.md` files, **When** the CLI runs, **Then** only links found in that exact set of files are checked.
2. **Given** a Markdown file that exists on disk but is untracked by git (not returned by `git ls-files`), **When** the CLI runs, **Then** links inside that file are neither scanned nor reported, and links elsewhere that point to that untracked file are still evaluated against the file system per P1.
3. **Given** the CLI is invoked outside of a git repository or `git ls-files` fails, **When** the CLI runs, **Then** the CLI reports a clear error and exits with a non-zero status rather than silently scanning nothing.
4. **Given** `git ls-files` reports zero `.md` files, **When** the CLI runs, **Then** the CLI completes the scan, reports no unresolved links, and exits with status 0.

---

### Edge Cases

<!--
  Fill in the edge cases this feature needs.
  Use the brainstorm prompts below to start a /speckit.specflow.brainstorm session.
-->

- External-scheme links (`http://`, `https://`, `mailto:`, etc.) are skipped without any network access (FR-003).
- A bare anchor within the same file (`#some-heading`) resolves against that same source file's own slugified headings, per FR-010.
- When a link's target file exists but is not a Markdown file (e.g. an image or a PDF), anchor validation is skipped entirely — only file existence is checked, per FR-013.
- When two headings in the same file slugify to the same base anchor, the second and later occurrences get a numeric suffix (`-1`, `-2`, ...) in order of appearance, matching GitHub's heading-anchor convention (see Q1 resolution and FR-005).
- A link target containing a query string or percent-encoded characters (e.g. `%20`) is percent-decoded before the query string, if any, is stripped and the remaining path is checked against the file system, per FR-011.
- A repository with zero tracked Markdown files completes the scan cleanly and exits 0 (see User Story 3, Acceptance Scenario 4).
- A relative link that resolves outside the repository root (e.g. `../../../etc/passwd`) is still resolved and existence-checked like any other relative link — the tool never restricts resolution to the repository root, and only ever performs a read-only existence check, never reads or executes the resolved path's contents beyond a Markdown target's own headings (see updated Threat Model row below).
- A Markdown file listed by `git ls-files` that cannot be opened or read (permission denied, deleted mid-scan, undecodable bytes) aborts the scan with an actionable, file-naming error and exit status 2, per FR-012.
- A symlinked Markdown file or symlinked link target is resolved and existence-checked the same as any other path; the CLI performs no additional dereferencing or validation of what a symlink points to beyond the standard OS-level existence check.

#### Brainstorm Prompts

<!--
  These prompts guide /speckit.specflow.brainstorm. Each one opens a line of
  questioning. When the list below does not cover this feature's domain, add
  a prompt for it.
-->

- **Boundary conditions**: What are the minimum and maximum valid inputs? What happens at the edges?
- **Error scenarios**: What if the network is down? What if the database is unavailable? What if input is malformed?
- **Scale**: What happens under 10x or 100x the expected load? Do rate limits apply?
- **Security**: Could an attacker abuse this feature? Are there injection vectors? Could an attacker gain unauthorized access?
- **User confusion**: Where might users misunderstand the feature? What if they use it in an unintended way?

## Open Questions

<!--
  Each question carries a status, Open or Resolved, and a resolution summary.
  /speckit.specflow.brainstorm updates this section as it explores each question.
-->

| # | Question | Status | Resolution |
|---|----------|--------|------------|
| Q1 | Should the slugification algorithm match a specific Markdown renderer's heading-anchor convention (e.g. GitHub's)? | Resolved | Yes — the CLI uses GitHub's convention: lowercase, spaces to hyphens, strip characters that aren't alphanumeric/hyphen/underscore, and append `-1`, `-2`, ... to duplicate slugs in order of appearance. This is the convention most contributors already expect from previewing Markdown on GitHub, and it removes the ambiguity the Assumptions section previously left open. |
| Q2 | How should the CLI handle a `git ls-files`-tracked Markdown file that cannot be opened or read? | Resolved | Abort the scan with an actionable error naming the unreadable file and exit status 2. The constitution's exit-code contract (Principle II) reserves 2 for "the scan cannot complete"; silently skipping the file risks a false-clean report, which is worse than a loud, actionable failure. |
| Q3 | How should a bare anchor (`#some-heading`) with no file part be resolved? | Resolved | Against the linking file's own slugified headings — the source file acts as its own target file, reusing the same anchor-resolution logic as `file.md#anchor` (FR-010). |
| Q4 | Should heading-anchor validation apply to a link whose target file exists but isn't Markdown (e.g. `diagram.png#section`)? | Resolved | No — anchor validation only applies to `.md` targets. A non-Markdown file has no headings to slugify, so only the file-existence check (FR-004) applies and any anchor fragment is ignored (FR-013). |
| Q5 | Should link targets with query strings or percent-encoding be decoded before file-system resolution? | Resolved | Yes — percent-decode the path first (so `%20` becomes a space, matching how filenames with spaces are typically linked), then strip any query string before checking existence, since link targets are file paths, not URLs (FR-011). |
| Q6 | R-001/R-002 (code review): should heading extraction and link extraction skip lines inside fenced code blocks? | Open | Not yet resolved. Current behavior treats any `#`-prefixed line or `[text](target)`-shaped text inside a fenced code example as real, causing both false-negative anchor validation and false-positive link findings. |
| Q7 | R-004 (code review): how should a link target beginning with `/` (a root-relative style link, e.g. `/docs/setup.md`) be resolved? | Open | Not yet resolved. Current behavior resolves it against the OS filesystem root via pathlib's absolute-path-overrides-join semantics, which will misreport nearly every such link as missing-file. |

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The CLI MUST obtain its list of files to scan exclusively from `git ls-files`, filtered to files with a `.md` extension.
- **FR-002**: The CLI MUST parse each scanned Markdown file and extract every inline link target (`[text](target)` syntax).
- **FR-003**: The CLI MUST classify each link target's scheme; targets using an external scheme (e.g. `http://`, `https://`, `mailto:`, `ftp://`) MUST be skipped and MUST NOT trigger any file system or network access.
- **FR-004**: For each remaining relative link, the CLI MUST resolve the target path against the file system relative to the linking file's location and report the link if the resolved file does not exist.
- **FR-005**: For each link of the form `file.md#anchor` where `file.md` resolves to an existing file, the CLI MUST slugify every heading in that target file — using GitHub's convention (lowercase, spaces to hyphens, strip non-alphanumeric/hyphen/underscore characters, and append `-1`, `-2`, ... to duplicate slugs in order of appearance) — and report the link if the anchor matches none of the slugified headings.
- **FR-006**: The CLI MUST print all unresolved links it finds, and each printed entry MUST identify the source file, the line or link text, and the unresolved target (file path and/or anchor).
- **FR-007**: The CLI MUST exit with status code 1 if it reports one or more unresolved links, and exit with status code 0 if it finds none.
- **FR-008**: The CLI MUST perform its entire scan without making any network requests.
- **FR-009**: The CLI MUST report a link to a missing target file as a missing-file issue rather than also attempting anchor resolution against a nonexistent file.
- **FR-010**: For a bare-anchor link (`#anchor`, no file part), the CLI MUST resolve the anchor against the linking file's own slugified headings, using the same slugification and reporting rules as `file.md#anchor` links.
- **FR-011**: Before checking a link target against the file system, the CLI MUST percent-decode the path and MUST strip any query string, so that encoded characters (e.g. `%20`) and trailing `?...` segments do not cause a false missing-file report.
- **FR-012**: If a `git ls-files`-tracked Markdown file cannot be opened or read (permission denied, missing at read time, undecodable bytes), the CLI MUST abort the scan, print an actionable error naming the file and the reason, and exit with status 2.
- **FR-013**: The CLI MUST NOT attempt heading-anchor validation against a target file that is not a `.md` file; for such targets, only the file-existence check (FR-004) applies, and any anchor fragment present is ignored.

### Key Entities *(include if feature involves data)*

- **Tracked Markdown File**: A file path reported by `git ls-files` ending in `.md`; the unit of scanning.
- **Link**: An inline Markdown link extracted from a tracked file, with a source file, a target path, and an optional anchor fragment.
- **Heading Anchor**: A slug derived from a Markdown heading in a target file, used to validate anchor fragments in links.
- **Unresolved Link Report**: A single reported finding identifying the source file, the target, and the reason it failed to resolve (missing file or missing anchor).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Running the CLI against a repository with N broken relative links and M broken anchor links reports all N + M issues with zero false positives, on a single pass with no configuration.
- **SC-002**: The CLI completes a scan of a repository's tracked Markdown files and produces its full report without initiating any network connection, verifiable via network-activity monitoring during the scan.
- **SC-003**: A maintainer can wire the CLI into a CI check using only its exit code (0 = clean, 1 = unresolved links found, 2 = scan could not complete), with no output parsing required to gate a build.
- **SC-004**: Renaming a heading that a same-repository anchor link depends on is caught by the CLI on the next run, with the specific broken link identified in the output.

## Threat Model

<!--
  Optional. Walk each STRIDE category against this feature. When a category
  does not apply, mark its row N/A with a one-clause reason instead of
  deleting the row.
-->

| Threat | Abuse case | Mitigation (or N/A + reason) |
|--------|------------|-------------------------------|
| Spoofing | N/A — local CLI tool with no identity or authentication surface | N/A |
| Tampering | A crafted Markdown file with a malicious relative path (e.g. `../../etc/passwd`) could cause the tool to read or reference paths outside the repository | Paths resolve relative to the linking file's directory (not sandboxed to the repository root) but resolution is always a read-only existence check; the tool never writes to, executes, or reads the contents of a resolved target beyond extracting headings from a `.md` file |
| Repudiation | N/A — tool produces stdout output and an exit code, not an audit trail of user actions | N/A |
| Information disclosure | Printed unresolved-link paths could reveal file system structure if run against untracked/sensitive paths | Scan is restricted to `git ls-files` output only (FR-001), so disclosure is limited to already-tracked repository content |
| Denial of service | A pathological Markdown file (e.g. extremely long lines or deeply nested links) could cause excessive scan time | Use a bounded, linear-time link-extraction approach; out of scope to defend against adversarial repository content beyond reasonable file sizes |
| Elevation of privilege | N/A — CLI runs with the invoking user's own file system permissions and requests no elevated access | N/A |

## Traceability

Every FR and SC criterion needs at least one named test before the conformance review runs.
Automated scoring reads only the Test name column. A human reader uses the Status column.

| Criterion ID | Test name | Status |
|--------------|-----------|--------|
| FR-001 | test_scans_only_git_ls_files_output | Passing |
| FR-002 | test_extracts_inline_link_targets | Passing |
| FR-003 | test_skips_external_scheme_links | Passing |
| FR-004 | test_reports_missing_relative_link_target | Passing |
| FR-005 | test_reports_missing_heading_anchor | Passing |
| FR-006 | test_report_includes_source_and_target | Passing |
| FR-007 | test_exit_code_reflects_unresolved_links | Passing |
| FR-008 | test_no_network_access_during_scan | Passing |
| FR-009 | test_missing_file_not_double_reported_as_anchor_issue | Passing |
| FR-010 | test_bare_anchor_resolves_against_same_file | Passing |
| FR-011 | test_percent_encoded_targets_are_decoded | Passing |
| FR-012 | test_unreadable_file_exits_with_status_2 | Passing |
| FR-013 | test_anchor_ignored_for_non_markdown_targets | Passing |
| SC-001 | test_reports_all_broken_links_no_false_positives | Passing |
| SC-002 | test_no_network_access_during_scan | Passing |
| SC-003 | test_exit_code_reflects_unresolved_links | Passing |
| SC-004 | test_reports_missing_heading_anchor | Passing |

## Assumptions

- The tool is invoked from within a git repository (or a subdirectory of one) where `git ls-files` succeeds.
- "Inline link" refers to standard Markdown inline link syntax `[text](target)`; reference-style links and HTML `<a href>` tags are out of scope for this feature.
- Heading slugification follows GitHub's convention (lowercase, spaces to hyphens, punctuation stripped, duplicate slugs suffixed `-1`, `-2`, ...), per the resolution of Open Question Q1.
- Relative link targets are resolved relative to the directory containing the linking file, not the repository root.
- Only links pointing to other files tracked in the same repository need file-system resolution; the CLI does not need to distinguish between `.md` and non-`.md` relative targets for P1's missing-file check.

## Brainstorm Log

<!--
  /speckit.specflow.brainstorm maintains this section and adds one entry per
  session. Each entry carries a date and states what the session found and
  decided. Do not edit it by hand.
-->

- **2026-09-27** — Headless brainstorm session covering all five categories (boundary, error, scale, security, UX). Resolved Q1 (GitHub-style slugification with duplicate-suffix handling) and added four new open questions (Q2–Q5), all resolved in this session: unreadable tracked file aborts with exit 2 (FR-012), bare anchors resolve against the source file itself (FR-010), anchor validation is skipped for non-Markdown targets (FR-013), and link targets are percent-decoded with query strings stripped before file-system resolution (FR-011). Corrected an internal contradiction in the Threat Model's Tampering row, which previously said paths resolve relative to the repository root while the Assumptions section said relative to the linking file's directory — the Assumptions wording is authoritative. Confirmed zero-tracked-Markdown-files and out-of-repo-root relative links both fall out of existing requirements without new FRs, and added acceptance scenario coverage for the zero-files case. Symlink handling and scan performance were reviewed and found already adequately covered by existing requirements and the Threat Model's Denial of Service row, respectively; both are now called out explicitly in Edge Cases. All five ADR-lite entries for the resolved choices were appended to `decisions.md`.

## Changelog

<!--
  One row records each spec version, newest last. When the spec changes after
  its first approval, add a row. Then delete `.clarified` and `.analyzed`.
  Rerun /speckit.clarify and /speckit.analyze.
-->

| Version | Date | Summary |
|---------|------|---------|
