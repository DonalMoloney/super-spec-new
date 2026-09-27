from __future__ import annotations

import re
from dataclasses import dataclass

_HEADING_PATTERN = re.compile(r"^#{1,6}\s+(.*?)\s*#*\s*$")
_STRIP_PATTERN = re.compile(r"[^\w\s-]")
_WHITESPACE_PATTERN = re.compile(r"\s+")
_FENCE_PATTERN = re.compile(r"^(?:```|~~~)")


@dataclass(frozen=True)
class HeadingAnchor:
    slug: str
    source_line: int


def _slugify(heading_text: str) -> str:
    """GitHub-convention slug: lowercase, strip non [alnum/space/hyphen/underscore], spaces to hyphens."""
    text = heading_text.strip().lower()
    text = _STRIP_PATTERN.sub("", text)
    text = _WHITESPACE_PATTERN.sub("-", text)
    return text


def slugify_headings(source: str) -> list[HeadingAnchor]:
    """Extract every Markdown heading and slugify it, suffixing duplicates in order of appearance."""
    seen_counts: dict[str, int] = {}
    anchors: list[HeadingAnchor] = []
    in_fence = False
    for line_number, line in enumerate(source.splitlines(), start=1):
        if _FENCE_PATTERN.match(line.strip()):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        match = _HEADING_PATTERN.match(line)
        if not match:
            continue
        base_slug = _slugify(match.group(1))
        count = seen_counts.get(base_slug, 0)
        slug = base_slug if count == 0 else f"{base_slug}-{count}"
        seen_counts[base_slug] = count + 1
        anchors.append(HeadingAnchor(slug=slug, source_line=line_number))
    return anchors
