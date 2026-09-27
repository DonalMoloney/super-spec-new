# Phase 0 Research: Link Audit CLI

spec.md carries no `NEEDS CLARIFICATION` markers — its five Open Questions
(Q1–Q5) were already resolved during brainstorming. This document covers the
implementation-level decisions the spec leaves to the plan: how to invoke
git, how to parse links, and how to keep the tool inside Constitution
Principle I (standard library only).

## D1: How to obtain the tracked-file list (FR-001)

- **Decision**: Shell out to `git ls-files -- '*.md'` via `subprocess.run`,
  capturing stdout, and treat a non-zero return code or a `FileNotFoundError`
  (git not on PATH) as a scan-abort (exit 2), matching User Story 3
  Scenario 3.
- **Rationale**: `git ls-files` is the spec's explicit source of truth
  (FR-001); re-implementing gitignore/index semantics in Python would
  duplicate git's own logic and risk drifting from it. `subprocess` is
  standard library, satisfying Principle I.
- **Alternatives considered**: A git Python binding (e.g. GitPython) —
  rejected, it is a third-party runtime dependency and violates Principle I.
  Walking the filesystem and re-parsing `.gitignore` — rejected, it
  duplicates git's own file-selection logic and is more likely to diverge
  from what `git ls-files` actually reports.

## D2: How to extract inline links (FR-002)

- **Decision**: A single compiled regular expression matching Markdown
  inline link syntax `[text](target)`, applied per line so each match keeps
  its source line number for FR-006's reporting requirement. No Markdown
  AST parser is used.
- **Rationale**: The spec (Assumptions) scopes the feature to standard
  inline link syntax only — reference-style links and `<a href>` are
  explicitly out of scope. A full CommonMark parser is unnecessary
  complexity for a single, well-bounded syntax and would add a
  non-standard-library dependency, violating Principle I.
- **Alternatives considered**: `markdown`/`mistune`/`commonmark` third-party
  parsers — rejected, all are runtime dependencies outside the standard
  library. A single whole-file regex without line tracking — rejected,
  FR-006 requires the report to identify "the line or link text."
- **Note on scope**: The spec does not ask for fenced-code-block exclusion
  (a link written inside a ```` ``` ```` block is still extracted and
  checked like any other). This is intentional minimalism, not an oversight
  — adding it would be scope beyond FR-002 unless a future spec revision
  asks for it.

## D3: How to slugify headings (FR-005, Q1)

- **Decision**: Implement GitHub's slug algorithm directly: lowercase,
  strip characters outside `[a-z0-9 _-]`, convert spaces to hyphens, then
  append `-1`, `-2`, ... to the 2nd+ occurrence of an identical slug within
  the same file, in document order.
- **Rationale**: Q1 already resolved the convention to use; this decision
  only fixes the implementation, which is small enough (~10 lines) that no
  library is justified and Principle I forbids adding one.
- **Alternatives considered**: A `slugify` PyPI package — rejected, third-
  party runtime dependency. Rejected in favor of the direct, testable
  implementation.

## D4: How to percent-decode and strip query strings (FR-011)

- **Decision**: `urllib.parse.urlsplit` to separate the path from any query
  string, then `urllib.parse.unquote` to percent-decode the path component,
  before resolving it against the file system.
- **Rationale**: Both are standard library (`urllib.parse`), satisfying
  Principle I, and are the canonical stdlib tools for this exact
  transformation.
- **Alternatives considered**: Hand-rolled percent-decoding via `str.replace`
  — rejected, reinventing a well-covered stdlib function risks subtle
  decoding bugs (e.g. multi-byte UTF-8 sequences).

## D5: How to classify external schemes (FR-003)

- **Decision**: `urllib.parse.urlsplit(target).scheme` — if non-empty (e.g.
  `http`, `https`, `mailto`, `ftp`), skip the link entirely before any file
  system or network call.
- **Rationale**: Matches how browsers and Markdown renderers distinguish a
  URL from a relative path, using only the standard library.
- **Alternatives considered**: A fixed prefix list (`("http://", "https://",
  "mailto:")`) — rejected, brittle against schemes not enumerated in the
  spec's examples (e.g. `ftp://`, `tel:`); `urlsplit` generalizes correctly
  without maintaining a list.

## D6: Unreadable-file handling (FR-012, Q2)

- **Decision**: Wrap each tracked file's read in a `try`/`except` over
  `OSError` and `UnicodeDecodeError`; on either, abort the scan immediately,
  print an error naming the file and the underlying reason (from the
  caught exception), and exit 2.
- **Rationale**: Q2 resolved the abort-vs-skip question in favor of abort;
  this decision only fixes which exception types to catch, matching the
  three named causes in the Edge Cases section (permission denied, deleted
  mid-scan, undecodable bytes).
- **Alternatives considered**: Skip the unreadable file and continue —
  rejected by Q2's resolution (risks a false-clean report).

## D7: Test strategy for "no network access" (FR-008, SC-002)

- **Decision**: A `pytest` test monkeypatches `socket.socket.connect` (and
  `socket.create_connection`) to raise if invoked during a full CLI run
  against a fixture repo containing every link category (external, missing
  file, missing anchor, valid).
- **Rationale**: SC-002 requires this to be "verifiable via network-activity
  monitoring during the scan" — patching the stdlib socket entry point is a
  standard-library-only way to make a negative claim ("no network call
  occurred") into an executable assertion, satisfying Principle V.
- **Alternatives considered**: Running the test in a network-namespace-
  isolated sandbox — rejected as environment-dependent and not portable to
  every CI runner the constitution targets.
