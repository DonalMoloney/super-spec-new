#!/usr/bin/env python3
"""Judge whether a review run's output names a planted fault.

A review probe plants one known fault at a file and a line, runs a review
agent against it, and checks whether the agent's output names that location.
``is_hit`` recognizes these location forms: ``<file>:<n>``, ``<file> line
<n>`` on the same text line, a ``<a>-<b>`` range overlapping the accepted
window, a JSON object carrying ``file`` and ``line`` keys, and a path that
merely ends in the planted file's relative path. ``judge`` counts a hit only
from a changed file's contents or the agent's final text; a match sitting
only in a baseline file, one the review run neither wrote nor touched,
proves nothing about what the run found.

The filename carries a hyphen so it cannot be imported with a normal
``import`` statement; a caller loads it with ``importlib.util`` instead, the
convention this repository already uses for ``lint-standards.py`` and
``score-artifacts.py``.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

DEFAULT_WINDOW = 3


def _file_matches(candidate: str, planted_file: str) -> bool:
    """Return True when candidate is planted_file or a path ending in it."""
    return candidate == planted_file or candidate.endswith("/" + planted_file)


def _within_window(candidate_line: int, planted_line: int, window: int) -> bool:
    """Return True when candidate_line sits within window lines of planted_line."""
    return abs(candidate_line - planted_line) <= window


def _range_overlaps(start: int, end: int, planted_line: int, window: int) -> bool:
    """Return True when [start, end] overlaps the accepted window around planted_line."""
    window_start = planted_line - window
    window_end = planted_line + window
    return start <= window_end and end >= window_start


def _json_object_hit(line: str, planted_file: str, planted_line: int, window: int) -> bool:
    """Return True when line is a JSON object naming planted_file within window.

    The object must carry a string "file" key and an integer "line" key;
    any other shape is not a match.
    """
    try:
        payload = json.loads(line)
    except (json.JSONDecodeError, TypeError):
        return False
    if not isinstance(payload, dict):
        return False
    file_value = payload.get("file")
    line_value = payload.get("line")
    if not isinstance(file_value, str) or not isinstance(line_value, int):
        return False
    if not _file_matches(file_value, planted_file):
        return False
    return _within_window(line_value, planted_line, window)


def _path_reference_hit(line: str, planted_file: str, planted_line: int, window: int) -> bool:
    """Return True when line names planted_file at a line or range within window.

    Recognizes "<file>:<n>", "<file>:<a>-<b>", and "<file> line <n>", all on
    this text line. A bare mention of planted_file with no line number is
    not a match.
    """
    pattern = re.compile(
        r"(?<![\w])"
        + re.escape(planted_file)
        + r"(?::(?P<single>\d+)(?:-(?P<range_end>\d+))?|\s+line\s+(?P<phrase>\d+))?"
    )
    for match in pattern.finditer(line):
        if match.group("range_end"):
            start = int(match.group("single"))
            end = int(match.group("range_end"))
            if _range_overlaps(start, end, planted_line, window):
                return True
        elif match.group("single"):
            if _within_window(int(match.group("single")), planted_line, window):
                return True
        elif match.group("phrase"):
            if _within_window(int(match.group("phrase")), planted_line, window):
                return True
    return False


def is_hit(content: str, planted_file: str, planted_line: int, window: int) -> bool:
    """Return True when content names planted_file at a line within window of planted_line.

    Checks each text line of content in turn, since a location phrase and
    the fault text it names must sit on the same text line to count.
    """
    if not content:
        return False
    for line in content.splitlines():
        if _json_object_hit(line, planted_file, planted_line, window):
            return True
        if _path_reference_hit(line, planted_file, planted_line, window):
            return True
    return False


def judge(
    planted_file: str,
    planted_line: int,
    window: int = DEFAULT_WINDOW,
    changed_contents=(),
    final_text: str = "",
    baseline_contents=(),
) -> bool:
    """Return True when a changed file or the final text names the planted fault.

    baseline_contents is accepted but never inspected: a baseline file
    predates the review run and the run did not touch it, so a match there
    shows nothing about what the run found.
    """
    del baseline_contents
    for content in changed_contents:
        if is_hit(content, planted_file, planted_line, window):
            return True
    return is_hit(final_text, planted_file, planted_line, window)


def read_text(path: str) -> str:
    """Read path as UTF-8 text, replacing an undecodable byte."""
    return Path(path).read_text(encoding="utf-8", errors="replace")


def build_parser() -> argparse.ArgumentParser:
    """Build the argument parser for the review-probe hit check."""
    parser = argparse.ArgumentParser(
        description="Judge whether a review run's output names a planted fault.",
    )
    parser.add_argument(
        "--planted-file",
        required=True,
        help="Relative path of the planted fault, such as src/link_audit/resolver.py.",
    )
    parser.add_argument(
        "--planted-line",
        required=True,
        type=int,
        help="Line number of the planted fault.",
    )
    parser.add_argument(
        "--changed-file",
        action="append",
        default=[],
        metavar="PATH",
        help="Path to a file the review run wrote or changed. Repeatable.",
    )
    parser.add_argument(
        "--final-text-file",
        metavar="PATH",
        help="Path to a file holding the review agent's final text.",
    )
    parser.add_argument(
        "--baseline-file",
        action="append",
        default=[],
        metavar="PATH",
        help="Path to a file present before the review run. Read but never matched. Repeatable.",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    """Parse argv, judge the probe result, print it, and return the exit code.

    Returns 0 on a hit and 1 on a miss.
    """
    args = build_parser().parse_args(argv)
    changed_contents = [read_text(path) for path in args.changed_file]
    baseline_contents = [read_text(path) for path in args.baseline_file]
    final_text = read_text(args.final_text_file) if args.final_text_file else ""
    hit = judge(
        args.planted_file,
        args.planted_line,
        changed_contents=changed_contents,
        final_text=final_text,
        baseline_contents=baseline_contents,
    )
    print("hit" if hit else "miss")
    return 0 if hit else 1


if __name__ == "__main__":
    sys.exit(main())
