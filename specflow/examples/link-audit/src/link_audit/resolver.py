from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from urllib.parse import unquote, urlsplit

from link_audit import anchors
from link_audit.links import Link


@dataclass(frozen=True)
class ParsedTarget:
    scheme: str | None
    file_part: str | None
    anchor: str | None


@dataclass(frozen=True)
class ResolvedTarget:
    link: Link
    resolved_path: Path | None
    file_exists: bool
    anchor_checked: bool
    anchor_resolved: bool | None


def classify_and_decode(target_raw: str) -> ParsedTarget:
    """Classify a link target's scheme and, for a relative target, percent-decode
    the path and strip any query string (FR-003, FR-011)."""
    split = urlsplit(target_raw)
    scheme = split.scheme or None
    if scheme:
        return ParsedTarget(scheme=scheme, file_part=None, anchor=None)

    decoded_path = unquote(split.path)
    file_part = decoded_path if decoded_path else None
    anchor = split.fragment if split.fragment else None
    return ParsedTarget(scheme=None, file_part=file_part, anchor=anchor)


def resolve_file(link: Link, parsed: ParsedTarget, root: Path) -> ResolvedTarget:
    """Resolve a non-external target against the file system and, if
    applicable, against the target file's heading anchors."""
    if parsed.file_part is None:
        # Bare anchor (FR-010): resolves against the linking file itself.
        target_file = root / link.source_file
        file_exists = target_file.exists()
        anchor_checked, anchor_resolved = _check_anchor(parsed.anchor, target_file, file_exists, is_markdown=True)
        return ResolvedTarget(
            link=link,
            resolved_path=None,
            file_exists=file_exists,
            anchor_checked=anchor_checked,
            anchor_resolved=anchor_resolved,
        )

    base_dir = (root / link.source_file).parent
    candidate = base_dir / parsed.file_part
    file_exists = candidate.exists()

    is_markdown = candidate.suffix == ".md"
    anchor_checked, anchor_resolved = _check_anchor(parsed.anchor, candidate, file_exists, is_markdown)

    return ResolvedTarget(
        link=link,
        resolved_path=candidate,
        file_exists=file_exists,
        anchor_checked=anchor_checked,
        anchor_resolved=anchor_resolved,
    )


def _check_anchor(
    anchor: str | None, target_file: Path, file_exists: bool, is_markdown: bool
) -> tuple[bool, bool | None]:
    # FR-009: a missing target file never proceeds to anchor checking.
    # FR-013: anchor validation is skipped for non-Markdown targets.
    if anchor is None or not file_exists or not is_markdown:
        return False, None
    source = target_file.read_text()
    slugs = {heading.slug for heading in anchors.slugify_headings(source)}
    return True, anchor in slugs
