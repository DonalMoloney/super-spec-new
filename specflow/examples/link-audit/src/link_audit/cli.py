from __future__ import annotations

import argparse
import sys
from pathlib import Path

from link_audit import discovery, report, resolver
from link_audit.errors import LinkAuditError
from link_audit.links import extract_links


def _parse_args(argv: list[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="link-audit")
    parser.add_argument("path", nargs="?", default=".", help="Directory to scan (must be inside a git repository).")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv)
    root = Path(args.path).resolve()

    try:
        markdown_files = discovery.list_markdown_files(root)
        findings = _scan(root, markdown_files)
    except LinkAuditError as error:
        name = error.file if error.file is not None else "git"
        print(f"{name}: {error.reason}", file=sys.stderr)
        return 2

    for finding in findings:
        print(report.render(finding))

    return 1 if findings else 0


def _scan(root: Path, markdown_files: list[Path]) -> list[report.Finding]:
    findings: list[report.Finding] = []
    for relative_path in markdown_files:
        full_path = root / relative_path
        try:
            source = full_path.read_text()
        except (OSError, UnicodeDecodeError) as exc:
            raise LinkAuditError(file=relative_path, reason=str(exc)) from None

        for link in extract_links(relative_path, source):
            parsed = resolver.classify_and_decode(link.target_raw)
            if parsed.scheme is not None:
                continue
            resolved = resolver.resolve_file(link, parsed, root)
            finding = report.build_finding(resolved)
            if finding is not None:
                findings.append(finding)
    return findings


if __name__ == "__main__":
    sys.exit(main())
