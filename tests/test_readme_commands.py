#!/usr/bin/env python3
"""Tests that every shell command specflow/README.md prints exits 0.

`standards/documentation.md` says to run every command a document contains
before handing it off. The README's fenced bash blocks are the install,
verify, upgrade, and remove commands a reader types, so each one runs here in
a throwaway spec-kit project.

Three rules leave a block unrun: its first line is a slash command, which an
agent reads rather than a shell; it names a value the reader substitutes; or
it reaches something this run cannot reach, in which case UNREACHABLE records
the reason. Every UNREACHABLE key is matched against the README, so renaming
one of those commands fails the stale check rather than dropping out of the
suite unnoticed.
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[1]
README = REPO_ROOT / "specflow" / "README.md"
EXTENSION_DIR = REPO_ROOT / "specflow"
SPEC_KIT_GIT_URL = "https://github.com/github/spec-kit.git"

README_TEXT = README.read_text(encoding="utf-8")

BASH_BLOCK = re.compile(r"^```bash\n(.*?)^```", re.MULTILINE | re.DOTALL)
PLACEHOLDER = re.compile(r"<[A-Za-z][A-Za-z ]+>")
INTEGRATION = re.compile(r"--integration (\w+)")

COMMAND_TIMEOUT_SECONDS = 600

# A README line this run cannot reach, and the reason it cannot.
UNREACHABLE = {
    "specify extension add specflow": "the spec-kit catalog does not list specflow yet",
    "git clone https://github.com/DonalMoloney/super-spec-new.git":
        "the clone needs a second checkout of this repository",
    'ln -sf "$(pwd)/specflow" ~/.claude/skills/specflow':
        "the symlink writes into the reader's home directory",
}

pytestmark = pytest.mark.skipif(
    shutil.which("specify") is None and shutil.which("uvx") is None,
    reason="the README's commands need spec-kit's specify, on PATH or through uvx",
)


def bash_blocks(readme_text: str) -> list[str]:
    """Return the body of every fenced bash block, in document order."""
    return [match.group(1) for match in BASH_BLOCK.finditer(readme_text)]


def skip_reason(block: str) -> str | None:
    """Return why `block` is not run in a shell, or None when it is run."""
    lines = [line for line in block.splitlines() if line.strip()]
    if lines[0].startswith("/"):
        return "the block is a slash command and runs inside an agent"
    if PLACEHOLDER.search(block):
        return "the block names a value the reader substitutes"
    for line in lines:
        if line in UNREACHABLE:
            return UNREACHABLE[line]
    return None


def runnable_blocks(readme_text: str) -> list[str]:
    """Return every bash block of `readme_text` that runs in a shell."""
    return [block for block in bash_blocks(readme_text) if skip_reason(block) is None]


def agents_named_by(block: str) -> list[str]:
    """Return the agent command-line program each `--integration` flag in `block` needs."""
    return INTEGRATION.findall(block)


def run_in(block: str, workdir: Path, path: str) -> subprocess.CompletedProcess[str]:
    """Run `block` under bash in `workdir` with `path` as PATH.

    Stdin is closed so a command that asks for confirmation stops instead of
    waiting for an answer that never comes.
    """
    return subprocess.run(
        ["bash", "-c", block],
        cwd=workdir,
        env={**os.environ, "PATH": path},
        stdin=subprocess.DEVNULL,
        capture_output=True,
        text=True,
        timeout=COMMAND_TIMEOUT_SECONDS,
    )


@pytest.fixture(scope="session")
def path_with_specify(tmp_path_factory) -> str:
    """Return a PATH that resolves `specify`, through uvx when spec-kit is not installed."""
    if shutil.which("specify") is not None:
        return os.environ["PATH"]
    shim_dir = tmp_path_factory.mktemp("bin")
    shim = shim_dir / "specify"
    shim.write_text(f'#!/bin/sh\nexec uvx --from "git+{SPEC_KIT_GIT_URL}" specify "$@"\n')
    shim.chmod(0o755)
    return os.pathsep.join([str(shim_dir), os.environ["PATH"]])


@pytest.fixture
def installed_project(tmp_path_factory, path_with_specify) -> Path:
    """Return a fresh spec-kit project with specflow installed from this checkout.

    The Verify, Upgrade, and Remove sections all address a reader who already
    ran the Installation section, so their blocks start from this state.
    """
    project = tmp_path_factory.mktemp("installed")
    for command in (
        "specify init --here --integration claude --ignore-agent-tools --force",
        f"specify extension add {EXTENSION_DIR} --dev",
    ):
        setup = run_in(command, project, path_with_specify)
        if setup.returncode != 0:
            pytest.fail(f"setup command failed: {command}\n{setup.stdout}\n{setup.stderr}")
    return project


def test_every_unreachable_reason_names_a_line_the_readme_carries():
    carried = {line for block in bash_blocks(README_TEXT) for line in block.splitlines()}
    assert sorted(set(UNREACHABLE) - carried) == []


def test_the_readme_carries_a_command_this_suite_runs():
    assert runnable_blocks(README_TEXT) != []


def test_a_slash_command_block_is_left_to_the_agent():
    reason = skip_reason("/speckit.specflow.status\n")
    assert reason == "the block is a slash command and runs inside an agent"


@pytest.mark.parametrize("block", runnable_blocks(README_TEXT), ids=lambda b: b.splitlines()[0])
def test_readme_command_exits_zero(block, tmp_path, path_with_specify, request):
    for agent in agents_named_by(block):
        if shutil.which(agent) is None:
            pytest.skip(f"spec-kit's init for this block needs the {agent} command line")
    if block.startswith("specify init"):
        workdir = tmp_path
    else:
        workdir = request.getfixturevalue("installed_project")
    result = run_in(block, workdir, path_with_specify)
    assert result.returncode == 0, f"{block}exited {result.returncode}\n{result.stdout}\n{result.stderr}"
