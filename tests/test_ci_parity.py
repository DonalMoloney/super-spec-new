#!/usr/bin/env python3
"""Tests that verify.sh runs the commands .github/workflows/ci.yml runs."""

from __future__ import annotations

import re
from pathlib import Path
from typing import Callable

import yaml

REPO_ROOT = Path(__file__).resolve().parents[1]
WORKFLOW = REPO_ROOT / ".github" / "workflows" / "ci.yml"
SCRIPT = REPO_ROOT / "verify.sh"

WORKFLOW_TEXT = WORKFLOW.read_text(encoding="utf-8")
SCRIPT_TEXT = SCRIPT.read_text(encoding="utf-8")


def ci_run_steps(workflow_text: str) -> list[tuple[str, str, str]]:
    """Return a (name, working directory, command) triple per `run:` step, in CI order."""
    workflow = yaml.safe_load(workflow_text)
    return [
        (step["name"], step.get("working-directory", "."), step["run"].strip())
        for step in workflow["jobs"]["validate"]["steps"]
        if "run" in step
    ]


def ci_python_version(workflow_text: str) -> str:
    """Return the interpreter version the workflow's setup-python step pins."""
    workflow = yaml.safe_load(workflow_text)
    for step in workflow["jobs"]["validate"]["steps"]:
        if str(step.get("uses", "")).startswith("actions/setup-python"):
            return str(step["with"]["python-version"])
    raise AssertionError(f"{WORKFLOW} has no actions/setup-python step")


def bash_array(script_text: str, name: str) -> list[str]:
    """Return the quoted entries of the bash array `name`.

    Raises `AssertionError` when the script declares no such array.
    """
    block = re.search(rf"^{name}=\(\n(.*?)^\)$", script_text, re.MULTILINE | re.DOTALL)
    if block is None:
        raise AssertionError(f"{SCRIPT} declares no {name} array")
    return [line.strip().strip('"') for line in block.group(1).splitlines() if line.strip()]


def script_steps(script_text: str) -> list[tuple[str, str]]:
    """Return a (working directory, command) pair per step verify.sh carries, in its order."""
    pairs = []
    for entry in bash_array(script_text, "STEPS"):
        _name, _tool, workdir, command = entry.split("|", 3)
        pairs.append((workdir, command))
    return pairs


def script_tool_gated_steps(script_text: str) -> list[tuple[str, str]]:
    """Return a (tool, command) pair per step verify.sh runs only when that tool is installed."""
    pairs = []
    for entry in bash_array(script_text, "STEPS"):
        _name, tool, _workdir, command = entry.split("|", 3)
        if tool:
            pairs.append((tool, command))
    return pairs


def script_skip_names(script_text: str) -> set[str]:
    """Return the CI step names verify.sh declares it leaves to CI."""
    return {entry.split("|", 1)[0] for entry in bash_array(script_text, "SKIPPED")}


def divergences(workflow_text: str, script_text: str) -> list[str]:
    """Return one line per way verify.sh and the workflow disagree.

    Steps are matched on their working directory and command, so renaming a step
    CI runs changes nothing. A step verify.sh gates on a tool is matched the same
    way, so gating one does not exempt it. A skipped step is matched on its name,
    because the reason recorded beside it is written about that name.
    """
    ci_steps = ci_run_steps(workflow_text)
    skipped = script_skip_names(script_text)
    reports = []

    unknown = skipped - {name for name, _workdir, _command in ci_steps}
    for name in sorted(unknown):
        reports.append(f"verify.sh skips '{name}', which ci.yml does not run")

    expected = [
        (workdir, command)
        for name, workdir, command in ci_steps
        if name not in skipped
    ]
    found = script_steps(script_text)
    if expected != found:
        reports.append(
            "ci.yml runs\n  "
            + "\n  ".join(f"(cd {w} && {c})" for w, c in expected)
            + "\nverify.sh runs\n  "
            + "\n  ".join(f"(cd {w} && {c})" for w, c in found)
        )
    return reports


def workflow_with(mutate: Callable[[list], None]) -> str:
    """Return the workflow re-serialized after `mutate` changed its step list."""
    workflow = yaml.safe_load(WORKFLOW_TEXT)
    mutate(workflow["jobs"]["validate"]["steps"])
    return yaml.safe_dump(workflow)


def index_of(steps: list, name: str) -> int:
    """Return the position of the step called `name`.

    Raises `AssertionError` when the workflow has no step under that name.
    """
    for position, step in enumerate(steps):
        if step.get("name") == name:
            return position
    raise AssertionError(f"ci.yml has no step named '{name}'; this test needs one")


def test_shipped_script_runs_what_the_shipped_workflow_runs():
    assert divergences(WORKFLOW_TEXT, SCRIPT_TEXT) == []


def test_deleting_a_ci_step_is_reported():
    mutated = workflow_with(lambda steps: steps.pop(index_of(steps, "Hook tests")))
    assert divergences(mutated, SCRIPT_TEXT) != []


def test_adding_a_ci_step_is_reported():
    def add(steps):
        steps.append({"name": "Type check", "run": "python3 -m mypy specflow/scripts"})

    assert divergences(workflow_with(add), SCRIPT_TEXT) != []


def test_changing_a_ci_command_is_reported():
    def retarget(steps):
        steps[index_of(steps, "Script tests")]["run"] = "python3 -m pytest scripts -q"

    assert divergences(workflow_with(retarget), SCRIPT_TEXT) != []


def test_changing_a_ci_working_directory_is_reported():
    def relocate(steps):
        steps[index_of(steps, "Structural smoke test")]["working-directory"] = "."

    assert divergences(workflow_with(relocate), SCRIPT_TEXT) != []


def test_reordering_two_ci_steps_is_reported():
    def swap(steps):
        first = index_of(steps, "Hook tests")
        second = index_of(steps, "Script tests")
        steps[first], steps[second] = steps[second], steps[first]

    assert divergences(workflow_with(swap), SCRIPT_TEXT) != []


def test_changing_the_command_of_a_tool_gated_ci_step_is_reported():
    def retarget(steps):
        steps[index_of(steps, "Ruff")]["run"] = "ruff check specflow/scripts"

    assert divergences(workflow_with(retarget), SCRIPT_TEXT) != []


def test_changing_the_working_directory_of_a_tool_gated_ci_step_is_reported():
    def relocate(steps):
        steps[index_of(steps, "Shellcheck")]["working-directory"] = "specflow"

    assert divergences(workflow_with(relocate), SCRIPT_TEXT) != []


def test_reordering_two_tool_gated_ci_steps_is_reported():
    def swap(steps):
        first = index_of(steps, "Shellcheck")
        second = index_of(steps, "Ruff")
        steps[first], steps[second] = steps[second], steps[first]

    assert divergences(workflow_with(swap), SCRIPT_TEXT) != []


def test_each_tool_gated_step_probes_the_program_its_command_runs():
    mismatched = [
        (tool, command)
        for tool, command in script_tool_gated_steps(SCRIPT_TEXT)
        if command.split()[0] != tool
    ]
    assert mismatched == []


def test_deleting_a_skipped_ci_step_is_reported():
    mutated = workflow_with(lambda steps: steps.pop(index_of(steps, "Ruff")))
    assert divergences(mutated, SCRIPT_TEXT) != []


def test_renaming_a_ci_step_verify_runs_is_not_reported():
    def rename(steps):
        steps[index_of(steps, "Script tests")]["name"] = "Extension script tests"

    assert divergences(workflow_with(rename), SCRIPT_TEXT) == []


def test_script_names_the_interpreter_version_ci_pins():
    pinned = ci_python_version(WORKFLOW_TEXT)
    assert f'CI_PYTHON_VERSION="{pinned}"' in SCRIPT_TEXT
