#!/usr/bin/env python3
"""Check Markdown and the extension manifest against the documentation standard.

Usage:
    python3 scripts/lint-standards.py [path ...]

Three rules run: em-dashes, the banned words the standard tables, and, on the
shipped contracts under WORD_CHOICE_PATHS, the "Not" column of the standard's
word-choice table.

A path that is a directory is walked through `git ls-files`, so only tracked
Markdown and a tracked `extension.yml` are checked. A path that is a file is
checked whether or not it is tracked. Either way a file under one of
EXCLUDED_DIRS, or named in EXCLUDED_FILES, relative to the git top level, is
skipped. A manifest is checked field by field, so only the strings a catalog
user reads count and its ids do not. With no path the current directory is
walked. Exit 0 with no findings, 1 with findings, 2 when a path is missing or
an exclusion is stale.
"""

from __future__ import annotations

import re
import subprocess
import sys
from collections.abc import Iterator
from pathlib import Path
from typing import NamedTuple

REPO_ROOT = Path(__file__).resolve().parents[2]
STANDARD = REPO_ROOT / "standards" / "documentation.md"
BANNED_HEADING = "## Banned words and phrases"
WORD_CHOICE_HEADING = "## Word choice"
EXCLUSIONS = Path(__file__).resolve().parent / "word-choice-exclusions.txt"

EM_DASH = "—"

# Examples, the roadmap, and the standards themselves quote the banned words.
EXCLUDED_DIRS = ("specflow/examples", "improvements", "standards")

# Research notes quote their sources verbatim, banned words and em-dashes included.
EXCLUDED_FILES = ("docs/review-research.md",)

FENCE = re.compile(r"^\s*(```|~~~)")

MANIFEST_NAME = "extension.yml"

# The spec-kit catalog shows these fields to a user choosing an extension.
USER_FACING_KEYS = ("description", "prompt")

# `name` holds a command or template id everywhere else in the manifest.
USER_FACING_PATHS = ("extension.name",)

# The word-choice rule runs on the contracts a consuming agent reads every run
# and on the manifest a catalog user reads. The rest of the repository still
# carries findings the table would report.
WORD_CHOICE_PATHS = ("specflow/commands", "specflow/extension.yml")


class StaleExclusionError(Exception):
    """An exclusion names an entry the word-choice table does not check."""


class WordChoice(NamedTuple):
    """The word-choice pattern and the word to write for each entry it matches."""

    pattern: re.Pattern[str]
    replacement: dict[str, str]


def table_rows(standard_text: str, heading: str, header: str) -> Iterator[tuple[str, list[str]]]:
    """Yield the first cell and the unqualified second-cell entries of each row under `heading`.

    An entry followed by a parenthetical qualifier names a judgment call the
    reader makes, so it is left out of the mechanical check.
    """
    section = standard_text.partition(heading)[2]
    for line in section.splitlines():
        if line.startswith("## "):
            break
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) != 2 or cells[0] in (header, "") or set(cells[1]) <= {"-"}:
            continue
        entries: list[str] = []
        for raw in cells[1].split(","):
            entry = raw.strip().strip('"').strip().lower()
            if entry and "(" not in entry:
                entries.append(entry)
        if entries:
            yield cells[0], entries


def banned_entries(standard_text: str) -> list[str]:
    """Return the unqualified entries of the banned table in the standard."""
    entries: list[str] = []
    for _, row in table_rows(standard_text, BANNED_HEADING, "Category"):
        entries.extend(row)
    return entries


def word_choice_exclusions(exclusions_text: str) -> set[str]:
    """Return the entries the exclusions file leaves to a reader.

    Raises `StaleExclusionError` when a line states no reason.
    """
    entries: set[str] = set()
    for line in exclusions_text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        entry, separator, reason = stripped.partition(":")
        if not separator or not reason.strip():
            raise StaleExclusionError(
                f"the word-choice exclusion '{stripped}' states no reason; "
                f"expected 'entry: reason'. Edit {EXCLUSIONS.name}."
            )
        entries.add(entry.strip().lower())
    return entries


def word_choice_rule(standard_text: str, exclusions_text: str) -> WordChoice:
    """Build the word-choice rule from the standard's table and the exclusions file.

    Raises `StaleExclusionError` when an exclusion names an entry the table does
    not carry, or carries only with a qualifier.
    """
    excluded = word_choice_exclusions(exclusions_text)
    table: dict[str, str] = {}
    for write, entries in table_rows(standard_text, WORD_CHOICE_HEADING, "Write"):
        for entry in entries:
            table[entry] = write
    stale = sorted(excluded - set(table))
    if stale:
        raise StaleExclusionError(
            f"the word-choice exclusions name {', '.join(stale)}; the Word choice "
            f"table in {STANDARD.name} does not check that entry. Edit {EXCLUSIONS.name}."
        )
    banned = set(banned_entries(standard_text))
    # An entry in both tables is reported once, by the banned rule.
    replacement = {
        entry: write
        for entry, write in table.items()
        if entry not in excluded and entry not in banned
    }
    return WordChoice(entry_pattern(sorted(replacement)), replacement)


def entry_pattern(entries: list[str]) -> re.Pattern[str]:
    """Compile one pattern that matches any entry as a whole word or phrase."""
    alternatives = [re.escape(entry).replace(r"\ ", r"\s+") for entry in entries]
    return re.compile(
        r"(?<![\w-])(" + "|".join(alternatives) + r")(?![\w-])",
        re.IGNORECASE,
    )


def as_tabled(matched: str) -> str:
    """Return a matched entry as the table spells it: lower case, one space between words."""
    return re.sub(r"\s+", " ", matched.lower())


def findings_in(
    text: str, place: str, banned: re.Pattern[str], word_choice: WordChoice | None
) -> Iterator[str]:
    """Yield one line per banned-word and word-choice finding in `text`, prefixed by `place`.

    `word_choice` is None for a file the word-choice rule does not cover.
    """
    for match in banned.finditer(text):
        yield f"{place}: banned word '{as_tabled(match.group(1))}'"
    if word_choice is None:
        return
    for match in word_choice.pattern.finditer(text):
        entry = as_tabled(match.group(1))
        yield f"{place}: word choice '{entry}'; write '{word_choice.replacement[entry]}'"


def findings_for(
    path: Path, banned: re.Pattern[str], word_choice: WordChoice | None
) -> list[str]:
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
        lines.extend(findings_in(line, f"{path}:{number}", banned, word_choice))
    return lines


def user_facing_strings(node: object, key_path: str = "") -> Iterator[tuple[str, str]]:
    """Yield the key path and the text of every user-facing string in a parsed manifest.

    A string under an identifier key, such as `id` or a command's `name`, is left
    out: the catalog matches that value against a namespace, so its wording is
    fixed by the command it names.
    """
    if isinstance(node, dict):
        for key, value in node.items():
            child = f"{key_path}.{key}" if key_path else str(key)
            yield from user_facing_strings(value, child)
    elif isinstance(node, list):
        for index, value in enumerate(node):
            yield from user_facing_strings(value, f"{key_path}[{index}]")
    elif isinstance(node, str) and (
        key_path in USER_FACING_PATHS or key_path.rsplit(".", 1)[-1] in USER_FACING_KEYS
    ):
        yield key_path, node


def manifest_findings(
    path: Path, banned: re.Pattern[str], word_choice: WordChoice | None
) -> list[str]:
    """Return one line per finding in the user-facing fields of the manifest `path`.

    Raises `ModuleNotFoundError` when PyYAML is absent.
    """
    # Deferred so a run over Markdown alone keeps working without PyYAML.
    try:
        import yaml
    except ModuleNotFoundError as absent:
        raise ModuleNotFoundError(
            f"lint-standards reads {MANIFEST_NAME} with PyYAML, which is not installed. "
            "Run 'python3 -m pip install --requirement requirements-dev.txt'."
        ) from absent
    document = yaml.safe_load(path.read_text(encoding="utf-8"))
    lines: list[str] = []
    for key_path, text in user_facing_strings(document):
        if EM_DASH in text:
            lines.append(f"{path}:{key_path}: em-dash")
        lines.extend(findings_in(text, f"{path}:{key_path}", banned, word_choice))
    return lines


def repo_relative(path: Path) -> str | None:
    """Return `path` relative to the top level of its git checkout, or None outside one."""
    toplevel = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        cwd=path.resolve().parent,
        capture_output=True,
        text=True,
    )
    if toplevel.returncode != 0:
        return None
    return path.resolve().relative_to(Path(toplevel.stdout.strip()).resolve()).as_posix()


def is_excluded(path: Path) -> bool:
    """Return whether `path` is excluded in its git checkout.

    A file outside any git checkout is never excluded.
    """
    relative = repo_relative(path)
    if relative is None:
        return False
    if relative in EXCLUDED_FILES:
        return True
    return any(relative.startswith(prefix + "/") for prefix in EXCLUDED_DIRS)


def in_word_choice_scope(path: Path) -> bool:
    """Return whether the word-choice rule covers `path` in its git checkout.

    A file outside any git checkout is covered: it was named on the command line.
    """
    relative = repo_relative(path)
    if relative is None:
        return True
    return any(
        relative == prefix or relative.startswith(prefix + "/") for prefix in WORD_CHOICE_PATHS
    )


def tracked_files(directory: Path) -> list[Path]:
    """Return the tracked Markdown and manifests under `directory`, minus the excluded dirs."""
    listing = subprocess.run(
        ["git", "ls-files", "-z", "--", "."],
        cwd=directory,
        capture_output=True,
        check=True,
    ).stdout.decode("utf-8")
    return [
        directory / name
        for name in listing.split("\0")
        if (name.endswith(".md") or Path(name).name == MANIFEST_NAME)
        and not is_excluded(directory / name)
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
            files.extend(tracked_files(path))
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
    standard_text = STANDARD.read_text(encoding="utf-8")
    banned = entry_pattern(banned_entries(standard_text))
    try:
        word_choice = word_choice_rule(standard_text, EXCLUSIONS.read_text(encoding="utf-8"))
    except StaleExclusionError as stale:
        print(f"lint-standards: {stale}", file=sys.stderr)
        return 2
    findings: list[str] = []
    for path in files:
        rule = word_choice if in_word_choice_scope(path) else None
        if path.name == MANIFEST_NAME:
            findings.extend(manifest_findings(path, banned, rule))
        else:
            findings.extend(findings_for(path, banned, rule))
    for finding in findings:
        print(finding)
    noun = "file" if len(files) == 1 else "files"
    status = "OK" if not findings else "FAIL"
    print(f"{status}: {len(files)} {noun} checked, {len(findings)} findings")
    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
