from __future__ import annotations

import subprocess
from pathlib import Path

from link_audit.errors import LinkAuditError


def list_markdown_files(root: Path) -> list[Path]:
    """Return the .md paths `git ls-files` reports, relative to `root`.

    Raises LinkAuditError when git is unavailable, `root` is not inside a
    git repository, or the `git ls-files` invocation otherwise fails.
    """
    try:
        result = subprocess.run(
            ["git", "ls-files", "--", "*.md"],
            cwd=root,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as exc:
        raise LinkAuditError(reason=f"git is not on PATH: {exc}") from None

    if result.returncode != 0:
        reason = result.stderr.strip() or "git ls-files failed"
        raise LinkAuditError(reason=reason)

    paths = [Path(line) for line in result.stdout.splitlines() if line]
    return paths
