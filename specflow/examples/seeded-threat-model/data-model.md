# Phase 1 Data Model: Link Audit CLI

All entities are in-process Python values (dataclasses) — there is no
persistence layer (Storage: N/A). This document maps the spec's Key
Entities section to concrete shapes used across `src/link_audit/` modules.

## TrackedFile

The unit of scanning; one entry per `git ls-files`-reported `.md` path.

| Field | Type | Notes |
|-------|------|-------|
| `path` | `pathlib.Path` | Repository-relative path, as reported by `git ls-files` (FR-001). |

Produced by `discovery.py`. Not a dataclass in code — `git ls-files` already
yields clean relative paths, so this is represented as a plain `Path` rather
than a wrapping type.

## Link

An inline link extracted from a `TrackedFile`.

| Field | Type | Notes |
|-------|------|-------|
| `source_file` | `pathlib.Path` | The tracked file the link was found in. |
| `line_number` | `int` | 1-based line the link starts on, for FR-006 reporting. |
| `text` | `str` | The link's display text (inside `[...]`). |
| `target_raw` | `str` | The raw target string exactly as written (inside `(...)`), before any decoding. |

Produced by `links.py` (D2). Immutable — a `@dataclass(frozen=True)`.

## ParsedTarget

The result of classifying and decoding a `Link.target_raw` (FR-003, FR-011),
before file-system resolution.

| Field | Type | Notes |
|-------|------|-------|
| `scheme` | `str \| None` | External scheme (`"http"`, `"mailto"`, ...) or `None` for a relative/local target. |
| `file_part` | `str \| None` | The path portion before `#`, percent-decoded and query-stripped; `None` for a bare anchor (`#anchor`, FR-010). |
| `anchor` | `str \| None` | The fragment after `#`, if any. |

Produced by `resolver.py` (D4, D5). A link with a non-`None` `scheme` is
skipped before any further resolution (FR-003) and never becomes a
`ResolvedTarget` or a `Finding`.

## HeadingAnchor

A slug derived from one Markdown heading in a target file (FR-005).

| Field | Type | Notes |
|-------|------|-------|
| `slug` | `str` | GitHub-convention slug, with `-1`/`-2`... suffix applied for duplicates within the same file, in document order (D3). |
| `source_line` | `int` | Line of the originating heading — carried for debugging/error messages, not required by any FR. |

Produced by `anchors.py`. A target file's full `HeadingAnchor` set is
computed once per file and used to validate every `Link` whose `file_part`
resolves to that file.

## ResolvedTarget

The outcome of resolving one `Link` against the file system and, if
applicable, a target file's heading anchors.

| Field | Type | Notes |
|-------|------|-------|
| `link` | `Link` | The originating link. |
| `resolved_path` | `pathlib.Path \| None` | The file-system path checked, `None` if `file_part` was empty (bare anchor case, FR-010 — resolves against `link.source_file` instead). |
| `file_exists` | `bool` | Result of the FR-004 existence check. |
| `anchor_checked` | `bool` | `True` only when `anchor` is present, `file_exists` is `True`, and the resolved file is `.md` (FR-013 excludes non-Markdown targets from this). |
| `anchor_resolved` | `bool \| None` | `None` when `anchor_checked` is `False`; otherwise whether the anchor matched a `HeadingAnchor.slug`. |

Produced by `resolver.py`. This is the internal decision record; `report.py`
turns a `ResolvedTarget` that failed either check into a `Finding` — FR-009
guarantees a `ResolvedTarget` with `file_exists = False` never proceeds to
anchor checking, so at most one `Finding` is emitted per `Link`.

## Finding

A single reported issue (the spec's "Unresolved Link Report").

| Field | Type | Notes |
|-------|------|-------|
| `source_file` | `pathlib.Path` | Matches `Link.source_file`. |
| `line_number` | `int` | Matches `Link.line_number`. |
| `target` | `str` | The original `target_raw`, printed verbatim so the maintainer can search for it in the source file. |
| `reason` | `Literal["missing-file", "missing-anchor"]` | Which check failed (FR-004 vs. FR-005), so CI logs can be grepped by failure class. |

Produced by `report.py` from a `ResolvedTarget`. The full list of `Finding`s
for a scan is what `cli.py` prints (FR-006) and whose non-emptiness decides
exit 0 vs. 1 (FR-007).

## ScanError

A scan-abort condition (exit 2) — not a `Finding`, since the scan did not
complete.

| Field | Type | Notes |
|-------|------|-------|
| `file` | `pathlib.Path \| None` | The file that could not be read, or `None` for a git-level failure (e.g. `git ls-files` itself failed). |
| `reason` | `str` | Human-readable cause (permission denied, decode error, git error), always naming the specific problem per Constitution Principle IV. |

Produced by `discovery.py` (git failure) or the file-read step in `cli.py`
(FR-012). Raised as a `LinkAuditError(ScanError)` exception that `cli.main()`
catches at the top level to print to stderr and return exit code 2.

## State / Flow Summary

```text
TrackedFile* --(links.py)--> Link*
Link --(resolver.py: scheme classify)--> skip (external) | ParsedTarget
ParsedTarget --(resolver.py: fs + anchors.py)--> ResolvedTarget
ResolvedTarget --(report.py)--> Finding (0 or 1 per Link)
Finding* --(cli.py)--> stdout + exit code {0,1}
ScanError (any stage) --(cli.py)--> stderr + exit code 2
```

No entity is mutated after creation; every stage is a pure transformation,
which keeps each module unit-testable in isolation per the plan's
Independent Work Streams.
