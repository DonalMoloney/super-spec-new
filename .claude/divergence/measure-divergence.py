#!/usr/bin/env python3
"""Measure how far files under specflow/ have diverged from their upstream counterparts.

Prints one line per file: the raw changed-line rate and the real rate, where real
maps the rebrand tokens back to upstream's names before diffing. The method is the
one improvements/roadmap.md records for its measured state.
"""

import argparse
import difflib
import sys
from pathlib import Path

REBRAND_TO_UPSTREAM = (
    ("DonalMoloney/super-spec-new", "WangX0111/superspec"),
    ("Specflow Contributors", "Superspec Contributors"),
    ("SpecFlow", "SuperSpec"),
    ("Specflow", "Superspec"),
    ("specflow", "superspec"),
)

USAGE_ERROR = 2


class CounterpartError(Exception):
    """A path has no readable file on one side of the comparison."""


def normalize_rebrand(text):
    """Return text with every rebrand token replaced by upstream's spelling."""
    for local_token, upstream_token in REBRAND_TO_UPSTREAM:
        text = text.replace(local_token, upstream_token)
    return text


def changed_line_percent(local_lines, upstream_lines):
    """Return changed lines over the longer file, as a whole-number percent."""
    longer = max(len(local_lines), len(upstream_lines))
    if longer == 0:
        return 0
    matcher = difflib.SequenceMatcher(a=upstream_lines, b=local_lines, autojunk=False)
    changed = sum(
        max(i2 - i1, j2 - j1)
        for tag, i1, i2, j1, j2 in matcher.get_opcodes()
        if tag != "equal"
    )
    return round(changed * 100 / longer)


def measure(local_root, upstream_root, relative_path):
    """Return (raw, real) percents for one file relative to both roots.

    Raises `CounterpartError` when either side lacks the file.
    """
    local_file = local_root / relative_path
    upstream_file = upstream_root / relative_path
    if not local_file.is_file():
        raise CounterpartError(f"{relative_path}: no local file at {local_file}")
    if not upstream_file.is_file():
        raise CounterpartError(
            f"{relative_path}: no upstream counterpart at {upstream_file}. "
            "Only files upstream ships can be measured."
        )
    local_text = local_file.read_text()
    upstream_lines = upstream_file.read_text().splitlines()
    raw = changed_line_percent(local_text.splitlines(), upstream_lines)
    real = changed_line_percent(normalize_rebrand(local_text).splitlines(), upstream_lines)
    return raw, real


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--local", type=Path, default=Path("specflow"), help="root of the local extension")
    parser.add_argument("--upstream", type=Path, required=True, help="root of an upstream checkout")
    parser.add_argument("paths", nargs="+", help="file paths relative to both roots")
    args = parser.parse_args(argv)
    for relative_path in args.paths:
        try:
            raw, real = measure(args.local, args.upstream, relative_path)
        except CounterpartError as error:
            print(error, file=sys.stderr)
            return USAGE_ERROR
        print(f"{relative_path} raw={raw}% real={real}%")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
