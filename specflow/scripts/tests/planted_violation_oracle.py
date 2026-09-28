"""Assert resolve_file raises LinkAuditError on an undecodable anchor target, per FR-012.

Importable module, not collected by plain pytest: its file name carries no
`test_` prefix, so the shipped `python_files = test_*.py` convention skips it
in an ordinary `pytest` run.

Reads `LINK_AUDIT_SRC` from the environment: a path to a `src/link_audit/`
directory. Run via `python3 -m pytest -q <path-to-this-file>` with
`LINK_AUDIT_SRC` set. It fails when `LINK_AUDIT_SRC` points at
`seeded-review-bug/src/link_audit` and passes when it points at
`link-audit/src/link_audit`.
"""

from __future__ import annotations

import os
import sys
from pathlib import Path

import pytest


class MissingLinkAuditSrcError(Exception):
    """Raised when the LINK_AUDIT_SRC environment variable is unset."""


def _load_link_audit_src() -> Path:
    """Return the `link_audit` package directory named by `LINK_AUDIT_SRC`.

    Raises `MissingLinkAuditSrcError` when the variable is unset, so a caller
    that forgets to set it sees a named error instead of a bare `KeyError`.
    """
    raw = os.environ.get("LINK_AUDIT_SRC")
    if raw is None:
        raise MissingLinkAuditSrcError(
            "LINK_AUDIT_SRC is unset; expected a path to a src/link_audit/ "
            "directory. Set it before running this module."
        )
    return Path(raw).resolve()


def test_unreadable_anchor_target_with_invalid_utf8_raises_link_audit_error(tmp_path):
    link_audit_src = _load_link_audit_src()
    package_parent = str(link_audit_src.parent)
    if package_parent not in sys.path:
        sys.path.insert(0, package_parent)

    from link_audit import resolver
    from link_audit.errors import LinkAuditError
    from link_audit.links import Link

    target = tmp_path / "guide.md"
    target.write_bytes(b"# Setup\n\xff\xfe not valid utf-8\n")

    link = Link(source_file=Path("index.md"), line_number=1, text="g", target_raw="guide.md#setup")
    parsed = resolver.classify_and_decode("guide.md#setup")

    with pytest.raises(LinkAuditError) as excinfo:
        resolver.resolve_file(link, parsed, tmp_path)
    assert excinfo.value.file == target
