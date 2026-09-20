#!/usr/bin/env python3
"""Check Markdown files for em-dashes and the banned words in the documentation standard.

Usage:
    python3 scripts/lint-standards.py [path ...]

A path that is a directory is walked through `git ls-files`, so only tracked
Markdown is checked. A path that is a file is checked whether or not it is
tracked. Either way a file under one of EXCLUDED_DIRS, or named in
EXCLUDED_FILES, relative to the git top level, is skipped. With no path the current directory is walked. Exit 0
with no findings, 1 with findings, 2 when a path is missing.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
STANDARD = REPO_ROOT / "standards" / "documentation.md"
BANNED_HEADING = "## Banned words and phrases"

EM_DASH = "—"

# Examples, the roadmap, and the standards themselves quote the banned words.
EXCLUDED_DIRS = ("specflow/examples", "imporvements", "standards")

# Research notes quote their sources verbatim, banned words and em-dashes included.
EXCLUDED_FILES = ("docs/review-research.md",)

FENCE = re.compile(r"^\s*(```|~~~)")


def banned_entries(standard_text: str) -> list[str]:
    """Return the unqualified entries of the banned table in the standard.

    An entry followed by a parenthetical qualifier names a judgment call the
    reader makes, so it is left out of the mechanical check.
    """
    section = standard_text.partition(BANNED_HEADING)[2]
    entries: list[str] = []
    for line in section.splitlines():
        if line.startswith("## "):
            break
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) != 2 or cells[0] in ("Category", "") or set(cells[1]) <= {"-"}:
            continue
        for raw in cells[1].split(","):
            entry = raw.strip().strip('"').strip().lower()
            if entry and "(" not in entry:
                entries.append(entry)
    return entries


def banned_pattern(entries: list[str]) -> re.Pattern[str]:
    """Compile one pattern that matches any entry as a whole word or phrase."""
    alternatives = [re.escape(entry).replace(r"\ ", r"\s+") for entry in entries]
    return re.compile(
        r"(?<![\w-])(" + "|".join(alternatives) + r")(?![\w-])",
        re.IGNORECASE,
    )


def findings_for(path: Path, pattern: re.Pattern[str]) -> list[str]:
    """Return one line per finding in `path`."""
    lines: list[str] = []
    in_fence = False
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if EM_DASH in line:
            lines.append(f"{path}:{number}: em-dash")
        if FENCE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        for match in pattern.finditer(line):
            lines.append(f"{path}:{number}: banned word '{match.group(1).lower()}'")
    return lines


def is_excluded(path: Path) -> bool:
    """Return whether `path` is excluded in its git checkout.

    A file outside any git checkout is never excluded.
    """
    toplevel = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        cwd=path.resolve().parent,
        capture_output=True,
        text=True,
    )
    if toplevel.returncode != 0:
        return False
    relative = path.resolve().relative_to(Path(toplevel.stdout.strip()).resolve()).as_posix()
    if relative in EXCLUDED_FILES:
        return True
    return any(relative.startswith(prefix + "/") for prefix in EXCLUDED_DIRS)


def tracked_markdown(directory: Path) -> list[Path]:
    """Return tracked Markdown files under `directory`, minus the excluded dirs."""
    listing = subprocess.run(
        ["git", "ls-files", "-z", "--", "."],
        cwd=directory,
        capture_output=True,
        check=True,
    ).stdout.decode("utf-8")
    return [
        directory / name
        for name in listing.split("\0")
        if name.endswith(".md") and not is_excluded(directory / name)
    ]


def collect(arguments: list[str]) -> list[Path]:
    """Resolve arguments to the files to check.

    Raises `FileNotFoundError` when an argument names nothing on disk.
    """
    files: list[Path] = []
    for argument in arguments or ["."]:
        path = Path(argument)
        if path.is_file():
            if not is_excluded(path):
                files.append(path)
        elif path.is_dir():
            files.extend(tracked_markdown(path))
        else:
            raise FileNotFoundError(argument)
    return files


def main(arguments: list[str]) -> int:
    """Check every argument and return the exit code."""
    try:
        files = collect(arguments)
    except FileNotFoundError as missing:
        print(
            f"lint-standards: path '{missing}' does not exist; expected a Markdown file "
            "or a directory inside a git checkout.",
            file=sys.stderr,
        )
        return 2
    pattern = banned_pattern(banned_entries(STANDARD.read_text(encoding="utf-8")))
    findings: list[str] = []
    for path in files:
        findings.extend(findings_for(path, pattern))
    for finding in findings:
        print(finding)
    noun = "file" if len(files) == 1 else "files"
    status = "OK" if not findings else "FAIL"
    print(f"{status}: {len(files)} {noun} checked, {len(findings)} findings")
    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
