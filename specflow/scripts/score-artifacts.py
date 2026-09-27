#!/usr/bin/env python3
"""Score one ``specs/NNN-slug/`` feature directory and print the report as JSON.

A golden run is only useful if regressions in its artifacts are measurable, so
this script grades nine dimensions a reviewer would otherwise check by hand:
mandatory spec sections, criterion traceability, threat model mitigation,
open question resolution, a seeded ambiguity raised as an open question,
changelog entries, traceability test resolution, stable task ids, and leftover
clarification markers. Traceability grades
whether each criterion has a filled test cell, not whether the reference in
that cell resolves; test_exists grades the resolution itself. The report goes
to stdout as a single JSON object; every failure path writes a ``FAIL:`` line
to stderr and exits 1 with stdout empty. The reported ``feature_dir`` echoes
the argument as given and is not a scored field.
"""

from __future__ import annotations

import json
import re
import subprocess
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
THREAT_MODEL_SECTION = "Threat Model"
THREAT_MODEL_CATEGORIES = (
    "Spoofing",
    "Tampering",
    "Repudiation",
    "Information disclosure",
    "Denial of service",
    "Elevation of privilege",
)
OPEN_QUESTIONS_SECTION = "Open Questions"
OPEN_QUESTIONS_HEADER_CELL = "#"
RESOLVED_STATUS = "Resolved"
CLARIFIED_MARKER_FILENAME = ".clarified"
SEEDED_AMBIGUITY_FILENAME = ".seeded-ambiguity"
CHANGELOG_SECTION = "Changelog"
CHANGELOG_HEADER_CELL = "Version"
MINIMUM_CHANGELOG_ROWS = 1
SECTION_LEVEL = 2
UNTRACED_CELL = "-"
PERCENT = 100
SCORE_DECIMALS = 1
FULL_SCORE = float(PERCENT)

ATX_HEADING = re.compile(r"^(#{1,6})\s+(.*?)\s*$")
MANDATORY_SUFFIX = re.compile(r"\s*\*\(mandatory\)\*$")
CRITERION_DECLARATION = re.compile(r"^- \*\*((?:FR|SC)-\d+)\*\*:")
CRITERION_ID = re.compile(r"\b(?:FR|SC)-\d+\b")
TABLE_ROW = re.compile(r"^\|(.+)\|\s*$")
TABLE_SEPARATOR = re.compile(r"^[\s:|-]+$")
TASK_LINE = re.compile(r"^\s*- \[[ xX]\]\s*(.*?)\s*$")
STABLE_TASK_ID = re.compile(r"^T\d+")
TEST_CELL_REFERENCE = re.compile(r"^`([^`:]+)::([^`]+)`$")


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

    A cell counts as traced when it holds any text other than ``-``, so the
    placeholder ``TBD`` scores exactly as a real reference does. Nothing here
    opens the file a ``file::anchor`` cell names or checks that the anchor
    exists. A ``traceability.score`` of 100.0 therefore means every criterion
    has a filled cell, not that every criterion has a test behind it.

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


def score_threat_model(spec_lines: list[str]) -> dict:
    """Score how many Threat Model rows carry a filled Mitigation cell.

    A row counts as mitigated when its Mitigation cell holds any text,
    including a bare or reasoned ``N/A``. Only an empty cell fails a row.
    """
    rows = 0
    mitigated = 0
    missing = []
    in_section = False
    for line in spec_lines:
        parsed = heading(line)
        if parsed is not None and parsed[0] <= SECTION_LEVEL:
            level, name = parsed
            in_section = level == SECTION_LEVEL and name == THREAT_MODEL_SECTION
            continue
        if not in_section:
            continue
        row = TABLE_ROW.match(line)
        if not row or TABLE_SEPARATOR.match(row.group(1)):
            continue
        cells = [cell.strip() for cell in row.group(1).split("|")]
        if len(cells) < 3 or cells[0] not in THREAT_MODEL_CATEGORIES:
            continue
        rows += 1
        if cells[2]:
            mitigated += 1
        else:
            missing.append(cells[0])
    return {
        "rows": rows,
        "mitigated": mitigated,
        "missing_mitigation": sorted(missing),
        "score": percentage(mitigated, rows),
    }


def score_open_questions(spec_lines: list[str], feature_dir: Path) -> dict:
    """Score how many Open Questions rows read Resolved once clarified.

    Scores 100 when ``.clarified`` is absent from feature_dir: the spec has
    not gone through ``/speckit.clarify`` yet, so an open row is expected.
    """
    clarified = (feature_dir / CLARIFIED_MARKER_FILENAME).is_file()
    questions = 0
    resolved = 0
    unresolved = []
    in_section = False
    for line in spec_lines:
        parsed = heading(line)
        if parsed is not None and parsed[0] <= SECTION_LEVEL:
            level, name = parsed
            in_section = level == SECTION_LEVEL and name == OPEN_QUESTIONS_SECTION
            continue
        if not in_section:
            continue
        row = TABLE_ROW.match(line)
        if not row or TABLE_SEPARATOR.match(row.group(1)):
            continue
        cells = [cell.strip() for cell in row.group(1).split("|")]
        if len(cells) < 3 or cells[0] == OPEN_QUESTIONS_HEADER_CELL:
            continue
        questions += 1
        if cells[2] == RESOLVED_STATUS:
            resolved += 1
        else:
            unresolved.append(cells[0])
    if not clarified:
        return {
            "clarified": False,
            "questions": questions,
            "resolved": resolved,
            "unresolved": sorted(unresolved),
            "score": FULL_SCORE,
        }
    return {
        "clarified": True,
        "questions": questions,
        "resolved": resolved,
        "unresolved": sorted(unresolved),
        "score": percentage(resolved, questions),
    }


def score_seeded_ambiguity(spec_lines: list[str], feature_dir: Path) -> dict:
    """Score whether an Open Questions row names the ambiguity seeded in feature_dir.

    ``.seeded-ambiguity`` holds the planted phrase on its first line. A feature
    directory without that file has nothing seeded and scores 100. The phrase
    matches a row case-insensitively.
    """
    marker = feature_dir / SEEDED_AMBIGUITY_FILENAME
    if not marker.is_file():
        return {"seeded": None, "surfaced": False, "score": FULL_SCORE}
    lines = read_lines(marker)
    phrase = lines[0].strip() if lines else ""
    if not phrase:
        fail(
            f"{marker} is empty; expected the seeded phrase on its first line. "
            "Write the phrase or delete the file."
        )
    surfaced = False
    in_section = False
    for line in spec_lines:
        parsed = heading(line)
        if parsed is not None and parsed[0] <= SECTION_LEVEL:
            level, name = parsed
            in_section = level == SECTION_LEVEL and name == OPEN_QUESTIONS_SECTION
            continue
        if in_section and TABLE_ROW.match(line) and phrase.lower() in line.lower():
            surfaced = True
    return {
        "seeded": phrase,
        "surfaced": surfaced,
        "score": FULL_SCORE if surfaced else 0.0,
    }


def score_changelog(spec_lines: list[str]) -> dict:
    """Score whether the Changelog table records at least one entry.

    A spec.md with no Changelog heading has not started a changelog yet and
    scores 100. A spec.md with the heading and zero rows below it scores 0.
    """
    present = CHANGELOG_SECTION in {heading_name(line) for line in spec_lines}
    if not present:
        return {"present": False, "rows": 0, "score": FULL_SCORE}
    rows = 0
    in_section = False
    for line in spec_lines:
        parsed = heading(line)
        if parsed is not None and parsed[0] <= SECTION_LEVEL:
            level, name = parsed
            in_section = level == SECTION_LEVEL and name == CHANGELOG_SECTION
            continue
        if not in_section:
            continue
        row = TABLE_ROW.match(line)
        if not row or TABLE_SEPARATOR.match(row.group(1)):
            continue
        cells = [cell.strip() for cell in row.group(1).split("|")]
        if cells and cells[0] == CHANGELOG_HEADER_CELL:
            continue
        rows += 1
    return {
        "present": True,
        "rows": rows,
        "score": percentage(min(rows, MINIMUM_CHANGELOG_ROWS), MINIMUM_CHANGELOG_ROWS),
    }


def traceability_test_references(spec_lines: list[str]) -> list[tuple[str, str, str]]:
    """Return each Traceability row's criterion id, file path, and anchor.

    Only a Test cell shaped like ``` `path::anchor` ``` counts; an empty
    cell, a ``-``, or free text is not a resolvable test reference.
    """
    references = []
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
        if not identifier:
            continue
        match = TEST_CELL_REFERENCE.match(cells[1])
        if match:
            references.append((identifier.group(0), match.group(1), match.group(2)))
    return references


def score_test_exists(spec_lines: list[str], feature_dir: Path) -> dict:
    """Score how many Traceability test references resolve under feature_dir.

    A reference resolves when ``grep -rl`` finds its anchor inside the file
    the Test cell names, resolved relative to feature_dir. A row the
    Traceability table names for an undeclared FR/SC id is the caller's
    problem to filter, so it is excluded here the same way
    ``score_traceability`` excludes it.

    The Test cell is author-supplied text, so a path leaving feature_dir
    counts as missing rather than reading the file it names.
    """
    declared = declared_criteria(spec_lines)
    references = [
        reference
        for reference in traceability_test_references(spec_lines)
        if reference[0] in declared
    ]
    root = feature_dir.resolve()
    found = 0
    missing = []
    for identifier, file_path, anchor in references:
        target = (feature_dir / file_path).resolve()
        if target != root and root not in target.parents:
            missing.append(identifier)
            continue
        result = subprocess.run(
            ["grep", "-rl", "-F", anchor, str(target)],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0 and result.stdout.strip():
            found += 1
        else:
            missing.append(identifier)
    return {
        "tests": len(references),
        "found": found,
        "missing": sorted(missing),
        "score": percentage(found, len(references)),
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
        "threat_model": score_threat_model(spec_lines),
        "open_questions": score_open_questions(spec_lines, feature_dir),
        "seeded_ambiguity": score_seeded_ambiguity(spec_lines, feature_dir),
        "changelog": score_changelog(spec_lines),
        "test_exists": score_test_exists(spec_lines, feature_dir),
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
