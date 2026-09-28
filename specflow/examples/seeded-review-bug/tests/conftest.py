import subprocess
from pathlib import Path

import pytest


def _init_repo(path: Path) -> None:
    subprocess.run(["git", "init", "-q"], cwd=path, check=True)
    subprocess.run(["git", "config", "user.email", "test@example.com"], cwd=path, check=True)
    subprocess.run(["git", "config", "user.name", "Test"], cwd=path, check=True)


def _commit_all(path: Path) -> None:
    subprocess.run(["git", "add", "-A"], cwd=path, check=True)
    subprocess.run(["git", "commit", "-q", "-m", "test commit"], cwd=path, check=True)


@pytest.fixture
def git_repo(tmp_path):
    """An initialized, empty git repository."""
    _init_repo(tmp_path)
    return tmp_path


@pytest.fixture
def make_repo(tmp_path):
    """Factory: write files (dict of relative path -> content), git-add and commit them."""

    def _make(files: dict[str, str], untracked: dict[str, str] | None = None) -> Path:
        _init_repo(tmp_path)
        for rel_path, content in files.items():
            full = tmp_path / rel_path
            full.parent.mkdir(parents=True, exist_ok=True)
            full.write_text(content)
        _commit_all(tmp_path)
        for rel_path, content in (untracked or {}).items():
            full = tmp_path / rel_path
            full.parent.mkdir(parents=True, exist_ok=True)
            full.write_text(content)
        return tmp_path

    return _make
