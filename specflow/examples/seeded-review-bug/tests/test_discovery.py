from pathlib import Path

import pytest

from link_audit import discovery
from link_audit.errors import LinkAuditError


def test_scans_only_git_ls_files_output(make_repo):
    repo = make_repo(
        files={"a.md": "# A\n", "b.md": "# B\n", "c.txt": "not markdown\n"},
    )
    result = discovery.list_markdown_files(repo)
    assert sorted(result) == [Path("a.md"), Path("b.md")]


def test_untracked_markdown_file_excluded(make_repo):
    repo = make_repo(
        files={"tracked.md": "# Tracked\n"},
        untracked={"scratch.md": "# Scratch\n"},
    )
    result = discovery.list_markdown_files(repo)
    assert result == [Path("tracked.md")]


def test_git_failure_raises_link_audit_error(tmp_path):
    with pytest.raises(LinkAuditError):
        discovery.list_markdown_files(tmp_path)


def test_zero_tracked_markdown_files_returns_empty_list(git_repo):
    (git_repo / "README.txt").write_text("no markdown here\n")
    import subprocess

    subprocess.run(["git", "add", "-A"], cwd=git_repo, check=True)
    subprocess.run(["git", "commit", "-q", "-m", "init"], cwd=git_repo, check=True)
    result = discovery.list_markdown_files(git_repo)
    assert result == []
