#!/usr/bin/env python3
"""Score one ``specs/NNN-slug/`` feature directory and print the report as JSON.

A golden run is only useful if regressions in its artifacts are measurable, so
this script grades four dimensions a reviewer would otherwise check by hand:
mandatory spec sections, criterion traceability, stable task ids, and leftover
clarification markers. The report goes to stdout as a single JSON object; every
failure path writes a ``FAIL:`` line to stderr and exits 1 with stdout empty.
The reported ``feature_dir`` echoes the argument as given and is not a scored
field.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


SPEC_FILENAME = "spec.md"
TASKS_FILENAME = "tasks.md"
MARKDOWN_GLOB = "*.md"
CLARIFICATION_MARKER = "NEEDS CLARIFICATION"
MANDATORY_SPEC_SECTIONS = (
    "User Scenarios & Testing",
    "Requirements",
    "Success Criteria",
)
TRACEABILITY_SECTION = "Traceability"
SECTION_LEVEL = 2
UNTRACED_CELL = "-"
PERCENT = 100
SCORE_DECIMALS = 1

ATX_HEADING = re.compile(r"^(#{1,6})\s+(.*?)\s*$")
MANDATORY_SUFFIX = re.compile(r"\s*\*\(mandatory\)\*$")
CRITERION_DECLARATION = re.compile(r"^- \*\*((?:FR|SC)-\d+)\*\*:")
CRITERION_ID = re.compile(r"\b(?:FR|SC)-\d+\b")
TABLE_ROW = re.compile(r"^\|(.+)\|\s*$")
TABLE_SEPARATOR = re.compile(r"^[\s:|-]+$")
TASK_LINE = re.compile(r"^\s*- \[[ xX]\]\s*(.*?)\s*$")
STABLE_TASK_ID = re.compile(r"^T\d+")


def fail(message: str) -> None:
    """Write a ``FAIL:`` line to stderr and exit 1, leaving stdout untouched."""
    print(f"FAIL: {message}", file=sys.stderr)
    sys.exit(1)


def read_lines(path: Path) -> list[str]:
    """Read path as UTF-8 text and return its lines without line endings.

    Undecodable bytes become the replacement character, so a stray byte costs
    the file nothing beyond the characters it sits on.
    """
    return path.read_text(encoding="utf-8", errors="replace").splitlines()


def percentage(part: int, whole: int) -> float | None:
    """Return part of whole as a percentage, or None when whole is zero."""
    if whole == 0:
        return None
    return round(part * PERCENT / whole, SCORE_DECIMALS)


def heading(line: str) -> tuple[int, str] | None:
    """Return the ATX level and title on line, or None when line is not a heading.

    The title has any ``*(mandatory)*`` marker removed.
    """
    match = ATX_HEADING.match(line)
    if not match:
        return None
    return len(match.group(1)), MANDATORY_SUFFIX.sub("", match.group(2))


def heading_name(line: str) -> str | None:
    """Return the H2 title on line, or None when line is not an H2 heading."""
    parsed = heading(line)
    if parsed is None or parsed[0] != SECTION_LEVEL:
        return None
    return parsed[1]


def score_spec_sections(spec_lines: list[str]) -> dict:
    """Score how many of the mandatory spec.md H2 sections are present."""
    headings = {heading_name(line) for line in spec_lines}
    missing = [name for name in MANDATORY_SPEC_SECTIONS if name not in headings]
    required = len(MANDATORY_SPEC_SECTIONS)
    present = required - len(missing)
    return {
        "required": required,
        "present": present,
        "missing": sorted(missing),
        "score": percentage(present, required),
    }


def declared_criteria(spec_lines: list[str]) -> set[str]:
    """Return the FR/SC ids spec.md declares as ``- **ID**:`` bullets."""
    ids = set()
    for line in spec_lines:
        match = CRITERION_DECLARATION.match(line)
        if match:
            ids.add(match.group(1))
    return ids


def traced_criteria(spec_lines: list[str]) -> set[str]:
    """Return the ids the Traceability table maps to a non-empty test cell.

    Ids the table names but spec.md never declares are the caller's problem to
    filter; this function reports what the table claims.
    """
    traced = set()
    in_section = False
    for line in spec_lines:
        parsed = heading(line)
        if parsed is not None and parsed[0] <= SECTION_LEVEL:
            level, name = parsed
            in_section = level == SECTION_LEVEL and name == TRACEABILITY_SECTION
            continue
        if not in_section:
            continue
        row = TABLE_ROW.match(line)
        if not row or TABLE_SEPARATOR.match(row.group(1)):
            continue
        cells = [cell.strip() for cell in row.group(1).split("|")]
        if len(cells) < 2:
            continue
        identifier = CRITERION_ID.search(cells[0])
        if identifier and cells[1] and cells[1] != UNTRACED_CELL:
            traced.add(identifier.group(0))
    return traced


def score_traceability(spec_lines: list[str]) -> dict:
    """Score how many declared FR/SC criteria the Traceability table covers."""
    criteria = declared_criteria(spec_lines)
    traced = criteria & traced_criteria(spec_lines)
    return {
        "criteria": len(criteria),
        "traced": len(traced),
        "untraced": sorted(criteria - traced),
        "score": percentage(len(traced), len(criteria)),
    }


def score_task_ids(tasks_path: Path) -> dict:
    """Score how many tasks.md checkbox lines start with a ``TNNN`` id.

    A missing tasks.md counts as zero tasks, which scores the dimension null.
    """
    texts = []
    if tasks_path.is_file():
        for line in read_lines(tasks_path):
            match = TASK_LINE.match(line)
            if match:
                texts.append(match.group(1))
    without_id = [text for text in texts if not STABLE_TASK_ID.match(text)]
    with_id = len(texts) - len(without_id)
    return {
        "tasks": len(texts),
        "with_id": with_id,
        "without_id": sorted(without_id),
        "score": percentage(with_id, len(texts)),
    }


def find_clarification_markers(feature_dir: Path) -> dict:
    """Locate every Markdown line under feature_dir holding the marker.

    Locations name the file relative to feature_dir and a 1-based line number.
    """
    locations = []
    for path in feature_dir.rglob(MARKDOWN_GLOB):
        if not path.is_file():
            continue
        relative = path.relative_to(feature_dir).as_posix()
        for number, line in enumerate(read_lines(path), start=1):
            if CLARIFICATION_MARKER in line:
                locations.append({"file": relative, "line": number})
    locations.sort(key=lambda location: (location["file"], location["line"]))
    return {"count": len(locations), "locations": locations}


def build_report(feature_dir: Path) -> dict:
    """Score every dimension for feature_dir and return the whole report."""
    spec_lines = read_lines(feature_dir / SPEC_FILENAME)
    return {
        "feature_dir": str(feature_dir),
        "spec_sections": score_spec_sections(spec_lines),
        "traceability": score_traceability(spec_lines),
        "task_ids": score_task_ids(feature_dir / TASKS_FILENAME),
        "needs_clarification": find_clarification_markers(feature_dir),
    }


def main() -> None:
    if len(sys.argv) != 2:
        fail("usage: score-artifacts.py <specs/NNN-slug feature directory>")

    given_path = sys.argv[1]
    feature_dir = Path(given_path)
    if not feature_dir.exists():
        fail(f"feature directory not found: {given_path}")
    if not feature_dir.is_dir():
        fail(f"expected a feature directory, found a file: {given_path}")
    if not (feature_dir / SPEC_FILENAME).is_file():
        fail(f"feature directory has no {SPEC_FILENAME}: {given_path}")

    report = build_report(feature_dir)
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
