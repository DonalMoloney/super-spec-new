from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

_LINK_PATTERN = re.compile(r"\[([^\]]*)\]\(([^)]*)\)")


@dataclass(frozen=True)
class Link:
    source_file: Path
    line_number: int
    text: str
    target_raw: str


def extract_links(source_file: Path, source: str) -> list[Link]:
    """Extract every inline `[text](target)` link from Markdown source."""
    links: list[Link] = []
    for line_number, line in enumerate(source.splitlines(), start=1):
        for match in _LINK_PATTERN.finditer(line):
            links.append(
                Link(
                    source_file=source_file,
                    line_number=line_number,
                    text=match.group(1),
                    target_raw=match.group(2),
                )
            )
    return links
