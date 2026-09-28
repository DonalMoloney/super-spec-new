import sys
from pathlib import Path

import pytest

from link_audit import resolver
from link_audit.errors import LinkAuditError
from link_audit.links import Link


def test_skips_external_scheme_links():
    parsed = resolver.classify_and_decode("https://example.com/page")
    assert parsed.scheme == "https"

    parsed = resolver.classify_and_decode("mailto:a@b.com")
    assert parsed.scheme == "mailto"

    parsed = resolver.classify_and_decode("guide.md")
    assert parsed.scheme is None


def test_percent_encoded_targets_are_decoded():
    parsed = resolver.classify_and_decode("my%20file.md?query=1")
    assert parsed.file_part == "my file.md"
    assert parsed.anchor is None


def test_reports_missing_relative_link_target(tmp_path):
    (tmp_path / "guide.md").write_text("# Guide\n")
    link_exists = Link(source_file=Path("docs/index.md"), line_number=1, text="g", target_raw="../guide.md")
    (tmp_path / "docs").mkdir()
    parsed = resolver.classify_and_decode("../guide.md")
    resolved = resolver.resolve_file(link_exists, parsed, tmp_path)
    assert resolved.file_exists is True

    link_missing = Link(source_file=Path("docs/index.md"), line_number=1, text="g", target_raw="missing.md")
    parsed_missing = resolver.classify_and_decode("missing.md")
    resolved_missing = resolver.resolve_file(link_missing, parsed_missing, tmp_path)
    assert resolved_missing.file_exists is False


def test_anchor_resolves_against_target_heading(tmp_path):
    (tmp_path / "guide.md").write_text("# Setup\n")
    link = Link(source_file=Path("index.md"), line_number=1, text="g", target_raw="guide.md#setup")
    parsed = resolver.classify_and_decode("guide.md#setup")
    resolved = resolver.resolve_file(link, parsed, tmp_path)
    assert resolved.anchor_checked is True
    assert resolved.anchor_resolved is True

    parsed_bad = resolver.classify_and_decode("guide.md#missing-heading")
    link_bad = Link(source_file=Path("index.md"), line_number=1, text="g", target_raw="guide.md#missing-heading")
    resolved_bad = resolver.resolve_file(link_bad, parsed_bad, tmp_path)
    assert resolved_bad.anchor_resolved is False


def test_missing_file_never_evaluated_for_anchor(tmp_path):
    link = Link(source_file=Path("index.md"), line_number=1, text="g", target_raw="missing.md#x")
    parsed = resolver.classify_and_decode("missing.md#x")
    resolved = resolver.resolve_file(link, parsed, tmp_path)
    assert resolved.file_exists is False
    assert resolved.anchor_checked is False


def test_bare_anchor_resolves_against_same_file(tmp_path):
    (tmp_path / "index.md").write_text("# Setup\n")
    link = Link(source_file=Path("index.md"), line_number=1, text="g", target_raw="#setup")
    parsed = resolver.classify_and_decode("#setup")
    assert parsed.file_part is None
    resolved = resolver.resolve_file(link, parsed, tmp_path)
    assert resolved.resolved_path is None
    assert resolved.anchor_checked is True
    assert resolved.anchor_resolved is True


def test_anchor_ignored_for_non_markdown_targets(tmp_path):
    (tmp_path / "diagram.png").write_bytes(b"fake png")
    link = Link(source_file=Path("index.md"), line_number=1, text="g", target_raw="diagram.png#section")
    parsed = resolver.classify_and_decode("diagram.png#section")
    resolved = resolver.resolve_file(link, parsed, tmp_path)
    assert resolved.file_exists is True
    assert resolved.anchor_checked is False
    assert resolved.anchor_resolved is None


def test_root_relative_link_resolves_against_repository_root(tmp_path):
    (tmp_path / "docs").mkdir()
    (tmp_path / "docs" / "setup.md").write_text("# Setup\n")
    link = Link(source_file=Path("nested/index.md"), line_number=1, text="g", target_raw="/docs/setup.md")
    (tmp_path / "nested").mkdir()
    parsed = resolver.classify_and_decode("/docs/setup.md")
    resolved = resolver.resolve_file(link, parsed, tmp_path)
    assert resolved.file_exists is True
    assert resolved.resolved_path == tmp_path / "docs" / "setup.md"


def test_root_relative_link_to_missing_file_is_reported(tmp_path):
    (tmp_path / "nested").mkdir()
    link = Link(source_file=Path("nested/index.md"), line_number=1, text="g", target_raw="/docs/missing.md")
    parsed = resolver.classify_and_decode("/docs/missing.md")
    resolved = resolver.resolve_file(link, parsed, tmp_path)
    assert resolved.file_exists is False


@pytest.mark.skipif(sys.platform == "win32", reason="POSIX permission bits")
def test_unreadable_anchor_target_raises_link_audit_error(tmp_path):
    target = tmp_path / "guide.md"
    target.write_text("# Setup\n")
    target.chmod(0o000)
    try:
        link = Link(source_file=Path("index.md"), line_number=1, text="g", target_raw="guide.md#setup")
        parsed = resolver.classify_and_decode("guide.md#setup")
        with pytest.raises(LinkAuditError) as excinfo:
            resolver.resolve_file(link, parsed, tmp_path)
        assert excinfo.value.file == target
    finally:
        target.chmod(0o644)
