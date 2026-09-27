import socket
import sys

import pytest

from link_audit.cli import main


def test_exit_code_reflects_unresolved_links(make_repo, capsys):
    repo = make_repo(files={"index.md": "# Index\n\n[broken](missing.md)\n"})
    code = main([str(repo)])
    out = capsys.readouterr().out
    assert code == 1
    assert "index.md" in out
    assert "missing.md" in out


def test_exit_code_zero_on_clean_repo(make_repo, capsys):
    repo = make_repo(files={"index.md": "# Index\n", "other.md": "# Other\n[ok](other.md)\n"})
    code = main([str(repo)])
    assert code == 0


def test_reports_missing_heading_anchor(make_repo, capsys):
    repo = make_repo(
        files={
            "index.md": "# Index\n\n[ref](guide.md#old-heading)\n",
            "guide.md": "# New Heading\n",
        }
    )
    code = main([str(repo)])
    out = capsys.readouterr().out
    assert code == 1
    assert "missing-anchor" in out
    assert "old-heading" in out


def test_no_finding_for_matching_anchor(make_repo, capsys):
    repo = make_repo(
        files={
            "index.md": "# Index\n\n[ref](guide.md#setup)\n",
            "guide.md": "# Setup\n",
        }
    )
    code = main([str(repo)])
    out = capsys.readouterr().out
    assert code == 0
    assert out == ""


def test_cli_exits_2_outside_git_repo(tmp_path, capsys):
    code = main([str(tmp_path)])
    err = capsys.readouterr().err
    assert code == 2
    assert err.strip() != ""
    assert len(err.strip().splitlines()) == 1


def test_unreadable_file_exits_with_status_2(make_repo, capsys):
    repo = make_repo(files={"index.md": "# placeholder\n"})
    # Overwrite with undecodable bytes after the commit, simulating a file
    # that cannot be read as UTF-8 text (FR-012).
    (repo / "index.md").write_bytes(b"\xff\xfe\x00bad")
    code = main([str(repo)])
    captured = capsys.readouterr()
    out, err = captured.out, captured.err
    assert code == 2
    assert out == ""
    assert "index.md" in err
    assert len(err.strip().splitlines()) == 1


def test_no_network_access_during_scan(make_repo, capsys, monkeypatch):
    repo = make_repo(
        files={
            "index.md": (
                "# Index\n\n"
                "[missing](missing.md)\n"
                "[ext](https://example.com)\n"
                "[anchor](guide.md#nope)\n"
            ),
            "guide.md": "# Setup\n",
        }
    )

    def _blocked(*args, **kwargs):
        raise AssertionError("network access attempted during scan")

    monkeypatch.setattr(socket.socket, "connect", _blocked)
    monkeypatch.setattr(socket, "create_connection", _blocked)

    code = main([str(repo)])
    assert code == 1


def test_reports_all_broken_links_no_false_positives(make_repo, capsys):
    repo = make_repo(
        files={
            "index.md": (
                "# Index\n\n"
                "[a](missing1.md)\n"
                "[b](missing2.md)\n"
                "[c](guide.md#bad-anchor)\n"
                "[d](guide.md#setup)\n"
            ),
            "guide.md": "# Setup\n",
        }
    )
    code = main([str(repo)])
    out = capsys.readouterr().out
    lines = [line for line in out.splitlines() if line]
    assert code == 1
    assert len(lines) == 3
    assert sum(1 for line in lines if "missing-file" in line) == 2
    assert sum(1 for line in lines if "missing-anchor" in line) == 1


def test_output_is_deterministic_across_runs(make_repo, capsys):
    repo = make_repo(
        files={
            "index.md": "# Index\n\n[a](missing1.md)\n[b](missing2.md)\n",
        }
    )
    main([str(repo)])
    first = capsys.readouterr().out
    main([str(repo)])
    second = capsys.readouterr().out
    assert first == second


def test_fenced_code_block_content_produces_no_findings(make_repo, capsys):
    repo = make_repo(
        files={
            "index.md": (
                "# Index\n"
                "\n"
                "```markdown\n"
                "# Not A Real Heading\n"
                "See [example](nonexistent-file.md) for a sample link.\n"
                "```\n"
            ),
        }
    )
    code = main([str(repo)])
    out = capsys.readouterr().out
    assert code == 0
    assert out == ""


def test_root_relative_link_end_to_end(make_repo, capsys):
    repo = make_repo(
        files={
            "docs/setup.md": "# Setup\n",
            "nested/index.md": (
                "# Index\n\n[good](/docs/setup.md)\n[bad](/docs/missing.md)\n"
            ),
        }
    )
    code = main([str(repo)])
    out = capsys.readouterr().out
    lines = [line for line in out.splitlines() if line]
    assert code == 1
    assert len(lines) == 1
    assert "missing.md" in lines[0]
    assert "setup.md" not in lines[0]


@pytest.mark.skipif(sys.platform == "win32", reason="POSIX permission bits")
def test_unreadable_anchor_target_exits_2_and_names_file(make_repo, capsys):
    # guide.md is untracked so it is never scanned as a linking file itself
    # (which would hit the already-handled OSError path in cli._scan);
    # this isolates the anchor-target read path in resolver._check_anchor.
    repo = make_repo(
        files={"index.md": "# Index\n\n[ref](guide.md#setup)\n"},
        untracked={"guide.md": "# Setup\n"},
    )
    target = repo / "guide.md"
    target.chmod(0o000)
    try:
        code = main([str(repo)])
        captured = capsys.readouterr()
        out, err = captured.out, captured.err
        assert code == 2
        assert out == ""
        assert "guide.md" in err
        assert len(err.strip().splitlines()) == 1
    finally:
        target.chmod(0o644)
