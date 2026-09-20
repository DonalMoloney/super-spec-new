#!/usr/bin/env python3
"""Check Markdown and the extension manifest for em-dashes and the banned words in the documentation standard.

Usage:
    python3 scripts/lint-standards.py [path ...]

A path that is a directory is walked through `git ls-files`, so only tracked
Markdown and a tracked `extension.yml` are checked. A path that is a file is
checked whether or not it is tracked. Either way a file under one of
EXCLUDED_DIRS, or named in EXCLUDED_FILES, relative to the git top level, is
skipped. A manifest is checked field by field, so only the strings a catalog
user reads count and its ids do not. With no path the current directory is
walked. Exit 0 with no findings, 1 with findings, 2 when a path is missing.
"""

from __future__ import annotations

import re
import subprocess
import sys
from collections.abc import Iterator
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

MANIFEST_NAME = "extension.yml"

# The spec-kit catalog shows these fields to a user choosing an extension.
USER_FACING_KEYS = ("description", "prompt")

# `name` holds a command or template id everywhere else in the manifest.
USER_FACING_PATHS = ("extension.name",)


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


def manifest_findings(path: Path, pattern: re.Pattern[str]) -> list[str]:
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
        for match in pattern.finditer(text):
            lines.append(f"{path}:{key_path}: banned word '{match.group(1).lower()}'")
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
    pattern = banned_pattern(banned_entries(STANDARD.read_text(encoding="utf-8")))
    findings: list[str] = []
    for path in files:
        if path.name == MANIFEST_NAME:
            findings.extend(manifest_findings(path, pattern))
        else:
            findings.extend(findings_for(path, pattern))
    for finding in findings:
        print(finding)
    noun = "file" if len(files) == 1 else "files"
    status = "OK" if not findings else "FAIL"
    print(f"{status}: {len(files)} {noun} checked, {len(findings)} findings")
    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
