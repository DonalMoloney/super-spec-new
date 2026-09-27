from pathlib import Path

from link_audit.links import Link
from link_audit.report import build_finding
from link_audit.resolver import ResolvedTarget


def test_report_includes_source_and_target():
    link = Link(source_file=Path("docs/index.md"), line_number=5, text="g", target_raw="missing.md")
    resolved = ResolvedTarget(
        link=link,
        resolved_path=Path("docs/missing.md"),
        file_exists=False,
        anchor_checked=False,
        anchor_resolved=None,
    )
    finding = build_finding(resolved)
    assert finding is not None
    assert finding.source_file == Path("docs/index.md")
    assert finding.line_number == 5
    assert finding.target == "missing.md"
    assert finding.reason == "missing-file"


def test_missing_file_not_double_reported_as_anchor_issue():
    link = Link(source_file=Path("docs/index.md"), line_number=5, text="g", target_raw="missing.md#x")
    resolved = ResolvedTarget(
        link=link,
        resolved_path=Path("docs/missing.md"),
        file_exists=False,
        anchor_checked=False,
        anchor_resolved=None,
    )
    finding = build_finding(resolved)
    assert finding.reason == "missing-file"


def test_missing_anchor_produces_finding():
    link = Link(source_file=Path("index.md"), line_number=3, text="g", target_raw="guide.md#missing")
    resolved = ResolvedTarget(
        link=link,
        resolved_path=Path("guide.md"),
        file_exists=True,
        anchor_checked=True,
        anchor_resolved=False,
    )
    finding = build_finding(resolved)
    assert finding.reason == "missing-anchor"


def test_render_is_deterministic():
    from link_audit.report import Finding, render

    finding = Finding(source_file=Path("docs/index.md"), line_number=5, target="missing.md", reason="missing-file")
    assert render(finding) == render(finding)
    assert "docs/index.md" in render(finding)
    assert "missing.md" in render(finding)


def test_no_finding_when_target_resolves_cleanly():
    link = Link(source_file=Path("docs/index.md"), line_number=5, text="g", target_raw="ok.md")
    resolved = ResolvedTarget(
        link=link,
        resolved_path=Path("docs/ok.md"),
        file_exists=True,
        anchor_checked=False,
        anchor_resolved=None,
    )
    assert build_finding(resolved) is None
