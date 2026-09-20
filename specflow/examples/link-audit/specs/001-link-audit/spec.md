# Feature Specification: Broken Link Audit

**Feature Branch**: `001-link-audit`
**Created**: 2026-09-14
**Status**: Implemented
**Input**: User description: "A command that tells me which relative links in our Markdown docs point at nothing, so CI fails on a broken link instead of a reader finding it."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Find the broken file links (Priority: P1)

A maintainer runs `link-audit` at the repository root. The command lists every
relative Markdown link whose target file is missing, naming the file that holds
the link, the line it sits on, the target it names. The command exits 1 so CI
fails the build.

**Why this priority**: A link to a file that does not exist is the failure
readers hit most, so this story alone pays for the feature.

**Independent Test**: Delete a file that another document links to, run
`link-audit`, confirm the report names that link, confirm the exit code is 1.

**Acceptance Scenarios**:

1. **Given** `docs/setup.md` links to `docs/install.md`, **When** `docs/install.md` is absent, **Then** the report names `docs/setup.md`, the link's line number, the target `docs/install.md`.
2. **Given** every relative target resolves, **When** the audit runs, **Then** the report is empty, **And** the exit code is 0.
3. **Given** a link target resolves to a directory, **When** the audit runs, **Then** the target counts as resolved.

---

### User Story 2 - Catch the stale heading anchors (Priority: P2)

A maintainer renames a heading. Links elsewhere still point at the old anchor.
The audit resolves each `file.md#anchor` target against the headings of the
target file, then reports an anchor that matches none of them.

**Why this priority**: A stale anchor lands the reader on the wrong part of the
right page, which is quieter than a missing file but still wrong.

**Independent Test**: Rename a heading in one file, run `link-audit`, confirm
the report names the link that still cites the old anchor.

**Acceptance Scenarios**:

1. **Given** `guide.md` has no heading slugging to `setup-steps`, **When** another file links to `guide.md#setup-steps`, **Then** the report names that anchor.
2. **Given** `guide.md` carries the heading `## Setup Steps`, **When** another file links to `guide.md#setup-steps`, **Then** the anchor counts as resolved.

---

### User Story 3 - Keep the scan to what the team owns (Priority: P3)

A maintainer excludes vendored documentation with `--ignore`, and the audit
never touches an external URL.

**Why this priority**: Without exclusion the report fills with links the team
cannot fix, which trains readers to skip it.

**Independent Test**: Run the audit against a tree holding a vendored folder,
pass `--ignore 'vendor/**'`, confirm no vendored path appears in the report.

**Acceptance Scenarios**:

1. **Given** a link target starts with `https://`, **When** the audit runs, **Then** the target is skipped without a network call.
2. **Given** `--ignore 'vendor/**'` is passed, **When** the audit runs, **Then** no file under `vendor/` is scanned.

---

### Edge Cases

- A link target carrying a query string, such as `page.md?raw=1`, resolves against the path alone.
- Two headings slug to the same anchor, so the first match wins, matching the GitHub renderer.
- A link inside a fenced code block is documentation of syntax, so the scan skips it.
- A symlinked Markdown file is scanned once, under the path `git ls-files` reports.
- A target that resolves outside the repository root is reported as broken rather than followed.

#### Brainstorm Prompts

- **Boundary conditions**: What is the largest tree worth scanning in one run?
- **Error scenarios**: What happens when the scan root sits outside a git checkout?
- **Scale**: What does a 100x repository cost in wall-clock time?
- **Security**: Can a crafted link target read a file outside the repository?
- **User confusion**: Does an empty report read as success or as a failed run?
- **Data integrity**: What happens when a file changes mid-scan?
- **Backwards compatibility**: Does the JSON shape have consumers already?

## Open Questions

| # | Question | Status | Resolution |
|---|----------|--------|------------|
| Q1 | Should a link to a directory count as resolved? | Resolved | Yes. A directory target is how the docs cite a folder of examples, so `scanner` treats a directory as a resolved target. |
| Q2 | Should the audit follow `http` targets to catch dead external links? | Resolved | No. Principle IV keeps the scan offline, so an external target is skipped. A separate feature can fetch them. |
| Q3 | What is the cap above which a scan stops? | Resolved | 5000 files. A tree that large has a build system, so the audit stops with exit 2 rather than running for minutes. |
| Q4 | R-001: SC-002 has no row in the Traceability table. Which test proves it? | Resolved | `tests/test_scanner.py::reports_missing_target` asserts the file, the line, the target, so SC-002 cites it. |

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST scan every Markdown file `git ls-files` reports under the scan root
- **FR-002**: System MUST extract each inline Markdown link target from a scanned file
- **FR-003**: System MUST resolve a relative target against the directory of the file that holds the link
- **FR-004**: System MUST report an unresolved target with the source file, the 1-based line number, the target text
- **FR-005**: System MUST report a `#anchor` fragment that matches no heading in the target file
- **FR-006**: System MUST treat a fragment matching a slugified heading as resolved
- **FR-007**: System MUST skip a target carrying an `http`, `https`, `mailto` scheme
- **FR-008**: Users MUST be able to exclude paths with a repeatable `--ignore GLOB` option
- **FR-009**: System MUST exit 1 when the report holds at least one broken link
- **FR-010**: System MUST print the report as JSON under `--format json`
- **FR-011**: System MUST stop with `LinkAuditError` when the scan root sits outside a git checkout
- **FR-012**: System MUST stop when the scan reaches 5000 files

### Key Entities

- **MarkdownFile**: one tracked document, holding its repository-relative path, its lines, its heading slugs.
- **Link**: one inline link found in a `MarkdownFile`, holding the line number, the raw target, the parsed path, the parsed fragment.
- **BrokenLink**: one failed resolution, holding the source path, the line number, the target, the reason, the suggested fix.

## Threat Model

| Threat | Abuse case | Mitigation (or N/A + reason) |
|--------|------------|-------------------------------|
| Spoofing | N/A: the audit has no identity, no caller, no credential to present. | N/A |
| Tampering | A link target such as `../../../../etc/passwd` steers a resolution outside the repository. | `scanner` rejects a resolved path outside the scan root, reporting it broken rather than reading it. |
| Repudiation | N/A: the audit writes no record a user could later deny; CI holds the log. | N/A |
| Information disclosure | The report quotes a path from a file the runner can read, exposing a private tree name in a public CI log. | The report quotes repository-relative paths only, never the absolute scan root. |
| Denial of service | A repository of millions of files holds the runner for hours. | `scanner` stops at 5000 files with exit 2, per FR-012. |
| Elevation of privilege | N/A: the audit runs as the caller, spawns no subprocess beyond `git ls-files`, writes nothing. | N/A |

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: An audit of 500 Markdown files finishes in under 5 s
- **SC-002**: Every reported row names the source file, the line number, the target
- **SC-003**: A repository with no broken link exits 0 with an empty report
- **SC-004**: The `--format json` output parses as one JSON object per broken link

## Traceability

Every FR and SC criterion needs at least one named test before the conformance review runs.
Automated scoring reads only the Test name column. Status is for a human reader.

| Criterion ID | Test name | Status |
|--------------|-----------|--------|
| FR-001 | `tests/test_discovery.py::lists_tracked_markdown_only` | Passing |
| FR-002 | `tests/test_parser.py::extracts_inline_link_targets` | Passing |
| FR-003 | `tests/test_scanner.py::accepts_existing_target` | Passing |
| FR-004 | `tests/test_scanner.py::reports_missing_target` | Passing |
| FR-005 | `tests/test_anchors.py::rejects_missing_heading_anchor` | Passing |
| FR-006 | `tests/test_anchors.py::accepts_slugified_heading_anchor` | Passing |
| FR-007 | `tests/test_scanner.py::skips_http_target` | Passing |
| FR-008 | `tests/test_cli.py::honours_ignore_glob` | Passing |
| FR-009 | `tests/test_cli.py::exits_1_on_broken_link` | Passing |
| FR-010 | `tests/test_cli.py::prints_json_report` | Passing |
| FR-011 | `tests/test_discovery.py::rejects_root_outside_git` | Passing |
| FR-012 | `tests/test_scanner.py::stops_above_file_cap` | Passing |
| SC-001 | `tests/test_performance.py::audits_500_files_under_5s` | Passing |
| SC-002 | `tests/test_scanner.py::reports_missing_target` | Passing |
| SC-003 | `tests/test_cli.py::exits_0_on_clean_repository` | Passing |
| SC-004 | `tests/test_cli.py::prints_json_report` | Passing |

## Assumptions

- Readers run the audit from inside the repository they want scanned.
- The documentation set is Markdown; reStructuredText is out of scope.
- Reference-style links (`[text][ref]`) are rare enough in this tree to defer to a later feature.
- CI already runs Python 3.11, so the audit needs no new runtime.

## Brainstorm Log

### Session 2026-09-14

**Focus**: Scope boundaries, abuse of relative targets

**Key insights**:

- A directory target is idiomatic in this tree, so resolving it as broken would produce noise on day one.
- Fetching external URLs would make the audit non-reproducible offline, which conflicts with Principle IV.
- `../../../../etc/passwd` resolves cleanly on most systems, so the scan needs a root containment check rather than trusting resolution.
- An unbounded scan is the only way this command hangs, which turned into FR-012.

**Spec updates**: Added FR-007, FR-012, the Tampering row of the Threat Model, Q1 through Q3.

## Changelog

| Version | Date | Summary |
|---------|------|---------|
| 0.1.0 | 2026-09-14 | Initial draft. |
| 0.2.0 | 2026-09-14 | Brainstorm session added FR-007, FR-012, the Tampering mitigation. |
| 0.3.0 | 2026-09-15 | Review finding R-001 added SC-002 to Traceability. |
