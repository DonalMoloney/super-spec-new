from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass
class LinkAuditError(Exception):
    """Raised when the scan cannot complete (exit code 2)."""

    reason: str
    file: Path | None = None

    def __str__(self) -> str:
        return self.reason
