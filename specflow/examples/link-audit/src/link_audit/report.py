from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Literal

from link_audit.resolver import ResolvedTarget


@dataclass(frozen=True)
class Finding:
    source_file: Path
    line_number: int
    target: str
    reason: Literal["missing-file", "missing-anchor"]


def build_finding(resolved: ResolvedTarget) -> Finding | None:
    """Convert a ResolvedTarget into at most one Finding (FR-006, FR-009)."""
    if not resolved.file_exists:
        reason = "missing-file"
    elif resolved.anchor_checked and resolved.anchor_resolved is False:
        reason = "missing-anchor"
    else:
        return None

    return Finding(
        source_file=resolved.link.source_file,
        line_number=resolved.link.line_number,
        target=resolved.link.target_raw,
        reason=reason,
    )


def render(finding: Finding) -> str:
    return f"{finding.source_file}:{finding.line_number}: {finding.reason} '{finding.target}'"
