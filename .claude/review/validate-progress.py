#!/usr/bin/env python3
"""Validate a feature's progress.yml against the resumability contract.

progress.yml is the only per-feature state a specflow command reads to resume a
run, so an unrecognized key or a phase number with no phase behind it resumes at
the wrong step with no message. Reads the block-mapping subset progress.yml uses
without a third-party YAML parser, and refuses a construct outside that subset
rather than guessing at it, so the reviewer agents and this hook need no
dependency a consuming project may lack.
"""

import re
import sys
from collections import namedtuple
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
GUIDE_PATHS = (
    REPO_ROOT / "specflow" / "references" / "workflow-guide.md",
    REPO_ROOT / ".specify" / "extensions" / "specflow" / "references" / "workflow-guide.md",
)
GATE_SECTION = "### Gate markers"
GATE_MARKER = re.compile(r"`[^`]*/\.([a-z_]+)`")
COUNTER_SUFFIX = "_attempts"

KEY_LINE = re.compile(
    r"^(?P<indent> *)(?P<dash>- )?(?P<key>[A-Za-z_][A-Za-z0-9_]*):(?:[ ]+(?P<value>\S.*))?$"
)
UNSUPPORTED_OPENERS = "|>[{&*!"
INTEGER = re.compile(r"-?[0-9]+$")
TASK_ID = re.compile(r"T[0-9]{3,}$")
TASK_LINE = re.compile(r"^- \[[ xX]\] (T[0-9]{3,})(?![0-9])")

TOP_LEVEL = {
    "spec": str,
    "status": str,
    "current_phase": int,
    "phases": list,
    "brainstorm": dict,
    "gates": dict,
}
TOP_LEVEL_REQUIRED = ("spec", "status", "current_phase", "phases")
STATUS_VALUES = ("pending", "in_progress", "complete", "skipped")
BRAINSTORM = {"sessions": int, "last_session": str}
PHASE = {"phase": int, "name": str, "status": str, "tasks": dict}
PHASE_REQUIRED = ("phase", "name", "status")

Line = namedtuple("Line", "number indent starts_item key value")


class ProgressError(Exception):
    """A progress file breaks the contract. The message names the failing key."""


class ContractUnavailable(Exception):
    """The workflow guide that defines the gate names cannot be read."""


def strip_comment(value):
    """Return a plain scalar with its trailing comment and any wrapping quotes removed."""
    position = value.find(" #")
    if position != -1:
        value = value[:position]
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in "'\"":
        value = value[1:-1]
    return value


def scalar(value):
    """Return an int for a whole-number scalar, otherwise the string."""
    return int(value) if INTEGER.match(value) else value


def read_lines(text):
    """Return one Line per key in text, raising ProgressError on a construct outside the subset."""
    lines = []
    for number, raw in enumerate(text.splitlines(), start=1):
        stripped = raw.strip()
        if not stripped or stripped.startswith("#") or stripped == "---":
            continue
        if "\t" in raw:
            raise ProgressError(f"line {number}: a tab is not YAML indentation. Use spaces.")
        match = KEY_LINE.match(raw)
        if not match:
            raise ProgressError(f"line {number}: {stripped!r} is not a 'key: value' line")
        value = match.group("value")
        if value is not None:
            value = strip_comment(value)
            if value[:1] in UNSUPPORTED_OPENERS:
                raise ProgressError(
                    f"line {number}: {value[0]!r} opens a YAML construct progress.yml "
                    f"does not use. Write the value as a nested block."
                )
        indent = len(match.group("indent"))
        starts_item = match.group("dash") is not None
        lines.append(
            Line(number, indent + 2 if starts_item else indent, starts_item, match.group("key"), value)
        )
    return lines


def parse_mapping(lines, index, indent, in_item=False):
    """Read the consecutive key lines at indent into a dict, with the next index."""
    mapping = {}
    while index < len(lines):
        line = lines[index]
        if line.indent != indent or (line.starts_item and not (in_item and not mapping)):
            break
        if line.key in mapping:
            raise ProgressError(f"line {line.number}: duplicate key {line.key!r}")
        if line.value is None:
            mapping[line.key], index = parse_block(lines, index + 1, line)
        else:
            mapping[line.key] = scalar(line.value)
            index += 1
    return mapping, index


def parse_block(lines, index, parent):
    """Read the sequence or mapping nested under a key line that carried no value."""
    if index >= len(lines) or lines[index].indent <= parent.indent:
        raise ProgressError(
            f"line {parent.number}: {parent.key!r} carries no value and opens no nested block"
        )
    child_indent = lines[index].indent
    if lines[index].starts_item:
        return parse_sequence(lines, index, child_indent)
    return parse_mapping(lines, index, child_indent)


def parse_sequence(lines, index, indent):
    """Read the consecutive '- ' items at indent into a list of dicts, with the next index."""
    items = []
    while index < len(lines) and lines[index].indent == indent and lines[index].starts_item:
        item, index = parse_mapping(lines, index, indent, in_item=True)
        items.append(item)
    return items, index


def parse(text):
    """Return the progress document as nested dicts and lists."""
    lines = read_lines(text)
    if not lines:
        raise ProgressError("the file holds no keys")
    document, index = parse_mapping(lines, 0, 0)
    if index != len(lines):
        line = lines[index]
        raise ProgressError(f"line {line.number}: {line.key!r} nests under no key at this indent")
    return document


def gate_names():
    """Return the marker names the Gate markers table in workflow-guide.md defines.

    Raises ContractUnavailable when the guide is missing or its table names no marker,
    because an empty set would accept every gate name.
    """
    guide = next((path for path in GUIDE_PATHS if path.is_file()), None)
    if guide is None:
        searched = " or ".join(str(path) for path in GUIDE_PATHS)
        raise ContractUnavailable(f"workflow-guide.md was not found at {searched}")
    text = guide.read_text()
    start = text.find(GATE_SECTION)
    if start == -1:
        raise ContractUnavailable(f"{guide}: no '{GATE_SECTION}' section")
    names = set()
    for line in text[start:].splitlines()[1:]:
        if line.startswith("#"):
            break
        if not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        marker = GATE_MARKER.search(cells[1]) if len(cells) > 1 else None
        if marker:
            names.add(marker.group(1))
    if not names:
        raise ContractUnavailable(f"{guide}: the '{GATE_SECTION}' table names no marker file")
    return names


def check_gates(gates, names):
    """Check each key of the gates block against the workflow guide's marker names."""
    for key in gates:
        if key in names:
            continue
        # A retry counter is named for the command (analyze), the marker for the
        # command's result (.analyzed), so the counter matches its marker by prefix.
        stem = key[: -len(COUNTER_SUFFIX)] if key.endswith(COUNTER_SUFFIX) else ""
        if stem and any(name.startswith(stem) for name in names):
            continue
        allowed = ", ".join(sorted(names))
        raise ProgressError(
            f"gates.{key}: not a gate marker. The workflow guide names {allowed}. "
            f"Fix the spelling or drop the entry."
        )


def check_status(state, where):
    """Check one status field against the four values the workflow guide names."""
    if state not in STATUS_VALUES:
        allowed = ", ".join(STATUS_VALUES)
        raise ProgressError(
            f"{where}: {state!r} is not a status. The workflow guide names {allowed}. "
            f"A task the run cannot automate is 'skipped'; its tasks.md line says why."
        )


def check_mapping(mapping, contract, required, where):
    """Check a mapping's keys and scalar types against contract, naming the first failure."""
    for key in required:
        if key not in mapping:
            raise ProgressError(f"{where}{key}: required key is missing")
    for key, value in mapping.items():
        if key not in contract:
            allowed = ", ".join(sorted(contract))
            raise ProgressError(f"{where}{key}: unknown key. progress.yml holds {allowed}.")
        expected = contract[key]
        if not isinstance(value, expected):
            found = type(value).__name__
            raise ProgressError(f"{where}{key}: expected {expected.__name__}, found {found}")


def task_ids_in(tasks_path):
    """Return the task IDs tasks.md carries on a checkbox line."""
    ids = set()
    for line in tasks_path.read_text().splitlines():
        match = TASK_LINE.match(line)
        if match:
            ids.add(match.group(1))
    return ids


def check_completed(completed, tasks_path):
    """Check every task ID marked complete against the tasks.md beside progress.yml.

    Raises ProgressError when tasks.md is absent while a task is marked complete; a
    feature that has not reached task decomposition marks nothing complete.
    """
    if not completed:
        return
    if not tasks_path.is_file():
        first = min(completed)
        raise ProgressError(
            f"{completed[first]}: marked complete, but no {tasks_path.name} sits beside "
            f"progress.yml. Restore {tasks_path.name} or clear the entry."
        )
    known = task_ids_in(tasks_path)
    for task_id in sorted(completed):
        if task_id not in known:
            raise ProgressError(
                f"{completed[task_id]}: marked complete, but {task_id} is absent from "
                f"{tasks_path.name}. Restore the id or clear the entry."
            )


def check(document, tasks_path):
    """Check a parsed progress document against the contract, raising on the first failure."""
    check_mapping(document, TOP_LEVEL, TOP_LEVEL_REQUIRED, "")
    check_status(document["status"], "status")
    if "brainstorm" in document:
        check_mapping(document["brainstorm"], BRAINSTORM, (), "brainstorm.")
    if "gates" in document:
        check_gates(document["gates"], gate_names())

    numbers = []
    completed = {}
    for index, phase in enumerate(document["phases"]):
        where = f"phases[{index}]."
        if not isinstance(phase, dict):
            raise ProgressError(f"phases[{index}]: expected a mapping of phase keys")
        check_mapping(phase, PHASE, PHASE_REQUIRED, where)
        check_status(phase["status"], f"{where}status")
        numbers.append(phase["phase"])
        for task_id, state in phase.get("tasks", {}).items():
            if not TASK_ID.match(task_id):
                raise ProgressError(f"{where}tasks.{task_id}: not a task ID. Expected T001.")
            check_status(state, f"{where}tasks.{task_id}")
            if state == "complete":
                completed.setdefault(task_id, f"{where}tasks.{task_id}")

    current = document["current_phase"]
    if current not in numbers:
        listed = ", ".join(str(number) for number in numbers) or "no phase"
        raise ProgressError(
            f"current_phase: {current} has no phase behind it. phases lists {listed}."
        )
    check_completed(completed, tasks_path)


def main(argv):
    if len(argv) != 2:
        print(f"usage: {Path(argv[0]).name} <progress.yml>", file=sys.stderr)
        return 2
    path = Path(argv[1])
    try:
        check(parse(path.read_text()), path.parent / "tasks.md")
    except ProgressError as error:
        print(f"{argv[1]}: {error}", file=sys.stderr)
        return 1
    except ContractUnavailable as error:
        print(f"{argv[1]}: {error}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
