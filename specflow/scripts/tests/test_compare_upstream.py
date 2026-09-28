#!/usr/bin/env python3
"""Tests for compare-upstream.sh, the T592-T594 fork-vs-upstream probe runner.

compare-upstream.sh (see improvements/roadmap.md's G-59 group) is configured
by the environment variables E2E_DRY_RUN, E2E_MODEL, E2E_MAX_BUDGET_USD,
E2E_MAX_TURNS, COMPARE_PROBES, COMPARE_RUNS, COMPARE_UPSTREAM_CHECKOUT, and
COMPARE_RESULTS. Two further behaviors these tests check directly:

  - Before each printed prompt, in a dry run, the script prints a bracket
    pipeline label, `[specflow]` or `[superspec]`, mirroring the `[Stage N]`
    convention scripts/e2e-stages.sh already uses. Tests use this label to
    tell a superspec prompt block apart from a specflow one.
  - `--spec-hit-for-score <score|error>` is a public, documented flag exposing
    the spec-probe score-to-hit rule directly (T593's Scenario Outline),
    printing `true`, `false`, or `null` and exiting 0. `error` stands for a
    spec-probe entry with status error and no score.
"""

import json
import os
import re
import stat
import subprocess
from pathlib import Path

import pytest

SPECFLOW_DIR = Path(__file__).resolve().parents[2]
REPO_ROOT = Path(__file__).resolve().parents[3]
SCRIPT = Path(__file__).resolve().parents[1] / "compare-upstream.sh"

PINNED_UPSTREAM_URL = "https://github.com/WangX0111/superspec"
PINNED_UPSTREAM_COMMIT = "c20ac6c1ba069cc9a72dacb8044b7b193d3dde81"

PIPELINE_LABELS = {"specflow": "[specflow]", "superspec": "[superspec]"}

# Environment variables a test must clear before layering its own, so a
# variable already set in the caller's shell never leaks into a case that
# means to test it unset.
OPTIONAL_ENV_VARS = (
    "E2E_DRY_RUN",
    "E2E_MODEL",
    "E2E_MAX_BUDGET_USD",
    "E2E_MAX_TURNS",
    "COMPARE_PROBES",
    "COMPARE_RUNS",
    "COMPARE_UPSTREAM_CHECKOUT",
    "COMPARE_RESULTS",
)


def write_stub(bin_dir, name, body):
    """Write an executable shell stub named name into bin_dir, running body."""
    path = bin_dir / name
    path.write_text(f"#!/usr/bin/env bash\n{body}\n")
    path.chmod(path.stat().st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)
    return path


def recording_stub(bin_dir, name, exit_code=0):
    """Write a stub that appends every call's arguments to a log file and exits exit_code."""
    log = bin_dir / f"{name}.calls"
    write_stub(bin_dir, name, f'printf "%s\\n" "$*" >> "{log}"\nexit {exit_code}\n')
    return log


def git_checkout(root):
    """Create a git repository at root, standing in for an upstream checkout."""
    subprocess.run(["git", "init", "-q", str(root)], check=True)
    (root / "README.md").write_text("stand-in upstream checkout\n")
    subprocess.run(["git", "-C", str(root), "add", "-A"], check=True)
    subprocess.run(
        [
            "git", "-C", str(root),
            "-c", "user.email=t@t", "-c", "user.name=t",
            "commit", "-q", "-m", "init",
        ],
        check=True,
    )
    return root


def run_compare(env_overrides, bin_dir=None, cwd=None):
    """Run compare-upstream.sh from cwd (default specflow/) with env_overrides applied.

    Clears every OPTIONAL_ENV_VARS entry first, so a host-set value never
    leaks into a case that means to test that variable unset. A value of
    None in env_overrides means "leave it unset".
    """
    environment = dict(os.environ)
    for key in OPTIONAL_ENV_VARS:
        environment.pop(key, None)
    if bin_dir is not None:
        environment["PATH"] = f"{bin_dir}:{environment['PATH']}"
    for key, value in env_overrides.items():
        if value is None:
            environment.pop(key, None)
        else:
            environment[key] = str(value)
    return subprocess.run(
        ["bash", str(SCRIPT)],
        capture_output=True,
        text=True,
        cwd=str(cwd or SPECFLOW_DIR),
        env=environment,
    )


def load_results(path):
    return json.loads(Path(path).read_text(encoding="utf-8"))


def pipeline_blocks(stdout, label):
    """Return every stdout slice from label up to the next pipeline label or end of string."""
    other_labels = [value for value in PIPELINE_LABELS.values() if value != label]
    boundary = "|".join(re.escape(other) for other in other_labels)
    pattern = re.escape(label) + r"(.*?)(?=" + boundary + r"|\Z)"
    return re.findall(pattern, stdout, re.DOTALL)


# --- Rule: compare-upstream.sh installs both pipelines before probing them (T592) ---


def test_dry_run_prints_the_forks_install_command():
    result = run_compare({"E2E_DRY_RUN": "1"})
    assert result.returncode == 0, result.stdout + result.stderr
    assert f"specify extension add {REPO_ROOT}/specflow --dev" in result.stdout


def test_dry_run_prints_upstreams_install_command():
    result = run_compare({"E2E_DRY_RUN": "1"})
    assert result.returncode == 0, result.stdout + result.stderr
    assert re.search(r"specify extension add \S+ --dev", result.stdout)
    assert "superspec" in result.stdout


def test_dry_run_never_calls_claude(tmp_path):
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    calls_log = recording_stub(bin_dir, "claude")
    result = run_compare({"E2E_DRY_RUN": "1"}, bin_dir=bin_dir)
    assert result.returncode == 0, result.stdout + result.stderr
    assert not calls_log.exists() or calls_log.read_text() == ""


def test_dry_run_exits_clean():
    result = run_compare({"E2E_DRY_RUN": "1"})
    assert result.returncode == 0, result.stdout + result.stderr


def test_given_upstream_checkout_path_skips_the_clone_and_names_its_own_install_command(tmp_path):
    upstream = git_checkout(tmp_path / "superspec")
    result = run_compare({"E2E_DRY_RUN": "1", "COMPARE_UPSTREAM_CHECKOUT": str(upstream)})
    assert result.returncode == 0, result.stdout + result.stderr
    assert f"specify extension add {upstream} --dev" in result.stdout
    assert "git clone" not in result.stdout


def test_dry_run_prints_the_git_clone_line_with_the_pinned_commit_when_no_checkout_given():
    result = run_compare({"E2E_DRY_RUN": "1", "COMPARE_UPSTREAM_CHECKOUT": None})
    assert result.returncode == 0, result.stdout + result.stderr
    assert "git clone" in result.stdout
    assert PINNED_UPSTREAM_URL in result.stdout
    assert PINNED_UPSTREAM_COMMIT in result.stdout


def test_a_pipeline_label_precedes_each_printed_prompt():
    result = run_compare({"E2E_DRY_RUN": "1"})
    assert result.returncode == 0, result.stdout + result.stderr
    assert result.stdout.count(PIPELINE_LABELS["specflow"]) > 0
    assert result.stdout.count(PIPELINE_LABELS["superspec"]) > 0


def test_every_printed_superspec_prompt_names_only_the_superspec_namespace():
    result = run_compare({"E2E_DRY_RUN": "1"})
    assert result.returncode == 0, result.stdout + result.stderr
    blocks = pipeline_blocks(result.stdout, PIPELINE_LABELS["superspec"])
    assert blocks, "no [superspec] labeled block found in dry-run output"
    for block in blocks:
        assert "/speckit.superspec." in block
        assert "/speckit.specflow." not in block


def test_dry_run_prints_claude_flags_with_the_adr_0033_allowlist_never_bypass_permissions():
    result = run_compare(
        {
            "E2E_DRY_RUN": "1",
            "E2E_MAX_BUDGET_USD": "0.50",
            "E2E_MAX_TURNS": "40",
            "E2E_MODEL": "claude-sonnet-x",
        }
    )
    assert result.returncode == 0, result.stdout + result.stderr
    invocation_count = result.stdout.count("claude -p")
    assert invocation_count > 0, "no `claude -p` invocation printed"
    assert result.stdout.count("--allowedTools") == invocation_count
    assert result.stdout.count("--max-budget-usd 0.50") == invocation_count
    assert result.stdout.count("--max-turns 40") == invocation_count
    assert result.stdout.count("--model claude-sonnet-x") == invocation_count
    assert result.stdout.count("--output-format json") == invocation_count
    assert "bypassPermissions" not in result.stdout
    assert "gates/bash" in result.stdout, "--allowedTools names no gate script (ADR-0033)"


def test_dry_run_with_e2e_model_unset_prints_no_model_flag():
    result = run_compare({"E2E_DRY_RUN": "1", "E2E_MODEL": None})
    assert result.returncode == 0, result.stdout + result.stderr
    assert "--model" not in result.stdout


def test_every_probe_prompt_tells_the_agent_no_user_will_answer():
    result = run_compare({"E2E_DRY_RUN": "1"})
    assert result.returncode == 0, result.stdout + result.stderr
    assert "no user will answer" in result.stdout.lower()


# --- Rule: a dry run never touches the committed results.json ---


def test_dry_run_leaves_the_committed_results_json_untouched_by_default():
    committed = SPECFLOW_DIR / "examples" / "upstream-comparison" / "results.json"
    existed_before = committed.exists()
    snapshot = committed.read_bytes() if existed_before else None
    result = run_compare({"E2E_DRY_RUN": "1", "COMPARE_RESULTS": None})
    assert result.returncode == 0, result.stdout + result.stderr
    if existed_before:
        assert committed.exists()
        assert committed.read_bytes() == snapshot
    else:
        assert not committed.exists()


def test_dry_run_pointed_at_the_committed_results_json_refuses_to_run():
    committed = SPECFLOW_DIR / "examples" / "upstream-comparison" / "results.json"
    existed_before = committed.exists()
    snapshot = committed.read_bytes() if existed_before else None
    result = run_compare({"E2E_DRY_RUN": "1", "COMPARE_RESULTS": str(committed)})
    assert result.returncode == 1, result.stdout + result.stderr
    if existed_before:
        assert committed.read_bytes() == snapshot
    else:
        assert not committed.exists()


# --- Rule: the spec probe scores brainstorm output for seeded ambiguity (T593) ---


def test_dry_runs_spec_probe_writes_six_entries(tmp_path):
    results_path = tmp_path / "results.json"
    result = run_compare(
        {"E2E_DRY_RUN": "1", "COMPARE_PROBES": "spec", "COMPARE_RESULTS": str(results_path)}
    )
    assert result.returncode == 0, result.stdout + result.stderr
    data = load_results(results_path)
    entries = [entry for entry in data["entries"] if entry["probe"] == "spec"]
    assert len(entries) == 6


def test_every_dry_run_spec_probe_entry_is_marked_dry_run(tmp_path):
    results_path = tmp_path / "results.json"
    result = run_compare(
        {"E2E_DRY_RUN": "1", "COMPARE_PROBES": "spec", "COMPARE_RESULTS": str(results_path)}
    )
    assert result.returncode == 0, result.stdout + result.stderr
    data = load_results(results_path)
    assert all(entry["status"] == "dry-run" for entry in data["entries"])


def test_spec_probe_entries_split_evenly_across_pipelines(tmp_path):
    results_path = tmp_path / "results.json"
    result = run_compare(
        {"E2E_DRY_RUN": "1", "COMPARE_PROBES": "spec", "COMPARE_RESULTS": str(results_path)}
    )
    assert result.returncode == 0, result.stdout + result.stderr
    data = load_results(results_path)
    assert sum(1 for e in data["entries"] if e["pipeline"] == "specflow") == 3
    assert sum(1 for e in data["entries"] if e["pipeline"] == "superspec") == 3


SPEC_HIT_CASES = [("100", "true"), ("87", "false"), ("0", "false")]


@pytest.mark.parametrize("score,expected", SPEC_HIT_CASES)
def test_spec_probe_hit_follows_its_score(score, expected):
    result = subprocess.run(
        ["bash", str(SCRIPT), "--spec-hit-for-score", score],
        capture_output=True,
        text=True,
        cwd=str(SPECFLOW_DIR),
    )
    assert result.returncode == 0, result.stdout + result.stderr
    assert result.stdout.strip() == expected


def test_spec_probe_entry_with_status_error_and_no_score_has_hit_null():
    result = subprocess.run(
        ["bash", str(SCRIPT), "--spec-hit-for-score", "error"],
        capture_output=True,
        text=True,
        cwd=str(SPECFLOW_DIR),
    )
    assert result.returncode == 0, result.stdout + result.stderr
    assert result.stdout.strip() == "null"


# --- Rule: the review probe checks whether review output names the planted fault (T594) ---


def test_dry_runs_review_probe_writes_six_dry_run_entries(tmp_path):
    results_path = tmp_path / "results.json"
    result = run_compare(
        {"E2E_DRY_RUN": "1", "COMPARE_PROBES": "review", "COMPARE_RESULTS": str(results_path)}
    )
    assert result.returncode == 0, result.stdout + result.stderr
    data = load_results(results_path)
    entries = [entry for entry in data["entries"] if entry["probe"] == "review"]
    assert len(entries) == 6
    assert all(entry["status"] == "dry-run" for entry in entries)


# --- Rule: an upstream failure is recorded, never patched around ---


def install_failure_results(tmp_path):
    """Run compare-upstream.sh with a uvx stub that fails installing upstream. Returns (result, path)."""
    upstream = git_checkout(tmp_path / "superspec")
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    write_stub(
        bin_dir,
        "uvx",
        f'case "$*" in\n'
        f'  *"specify extension add {upstream}"*) echo boom >&2; exit 1 ;;\n'
        f"esac\n"
        f"exit 0\n",
    )
    write_stub(bin_dir, "claude", "exit 0\n")
    results_path = tmp_path / "results.json"
    result = run_compare(
        {"COMPARE_UPSTREAM_CHECKOUT": str(upstream), "COMPARE_RESULTS": str(results_path)},
        bin_dir=bin_dir,
    )
    return result, results_path


def test_install_failure_for_upstream_is_recorded_as_an_error_entry(tmp_path):
    result, results_path = install_failure_results(tmp_path)
    assert result.returncode == 0, result.stdout + result.stderr
    data = load_results(results_path)
    superspec_entries = [entry for entry in data["entries"] if entry["pipeline"] == "superspec"]
    assert superspec_entries
    for entry in superspec_entries:
        assert entry["status"] == "error"
        assert entry["hit"] is None
        assert "boom" in entry["error"]


def test_an_error_entry_never_counts_toward_the_superspec_hit_count(tmp_path):
    result, results_path = install_failure_results(tmp_path)
    assert result.returncode == 0, result.stdout + result.stderr
    data = load_results(results_path)
    assert all(
        entry["hit"] is not True
        for entry in data["entries"]
        if entry["pipeline"] == "superspec" and entry["status"] == "error"
    )


def test_superspec_command_failure_on_current_speckit_is_recorded(tmp_path):
    upstream = git_checkout(tmp_path / "superspec")
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    write_stub(bin_dir, "uvx", "exit 0\n")
    write_stub(
        bin_dir,
        "claude",
        'case "$*" in\n'
        '  *"speckit.superspec"*) echo boom >&2; exit 1 ;;\n'
        "esac\n"
        "echo '{\"total_cost_usd\": 0.01}'\n"
        "exit 0\n",
    )
    results_path = tmp_path / "results.json"
    result = run_compare(
        {"COMPARE_UPSTREAM_CHECKOUT": str(upstream), "COMPARE_RESULTS": str(results_path)},
        bin_dir=bin_dir,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    data = load_results(results_path)
    failed = [
        entry
        for entry in data["entries"]
        if entry["pipeline"] == "superspec" and entry["status"] == "error"
    ]
    assert failed
    for entry in failed:
        assert entry["hit"] is None
        assert "boom" in entry["error"]


def test_upstreams_checkout_is_never_modified_after_a_failure(tmp_path):
    upstream = git_checkout(tmp_path / "superspec")
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    uvx_log = recording_stub(bin_dir, "uvx", exit_code=1)
    write_stub(bin_dir, "claude", "exit 0\n")
    results_path = tmp_path / "results.json"
    run_compare(
        {"COMPARE_UPSTREAM_CHECKOUT": str(upstream), "COMPARE_RESULTS": str(results_path)},
        bin_dir=bin_dir,
    )
    assert uvx_log.exists(), "compare-upstream.sh never invoked uvx"
    status = subprocess.run(
        ["git", "-C", str(upstream), "status", "--porcelain"],
        capture_output=True,
        text=True,
    )
    assert status.stdout == ""


# --- Rule: a live `specify init` runs non-interactively ---


def test_live_runs_init_call_carries_non_interactive(tmp_path):
    upstream = git_checkout(tmp_path / "superspec")
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    uvx_log = recording_stub(bin_dir, "uvx")
    write_stub(bin_dir, "claude", "exit 0\n")
    results_path = tmp_path / "results.json"
    result = run_compare(
        {
            "COMPARE_UPSTREAM_CHECKOUT": str(upstream),
            "COMPARE_RESULTS": str(results_path),
            "COMPARE_PROBES": "spec",
            "COMPARE_RUNS": "1",
        },
        bin_dir=bin_dir,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    calls = uvx_log.read_text().splitlines()
    init_calls = [call for call in calls if "specify init" in call]
    assert init_calls, "uvx was never called with specify init"
    assert all("--non-interactive" in call for call in init_calls)


# --- Rule: results.json carries a fixed shape ---


def test_dry_run_with_compare_probes_unset_writes_twelve_entries_split_by_probe(tmp_path):
    results_path = tmp_path / "results.json"
    result = run_compare(
        {"E2E_DRY_RUN": "1", "COMPARE_PROBES": None, "COMPARE_RESULTS": str(results_path)}
    )
    assert result.returncode == 0, result.stdout + result.stderr
    data = load_results(results_path)
    assert len(data["entries"]) == 12
    assert sum(1 for e in data["entries"] if e["probe"] == "spec") == 6
    assert sum(1 for e in data["entries"] if e["probe"] == "review") == 6


def test_dry_runs_results_json_names_the_model_used(tmp_path):
    results_path = tmp_path / "results.json"
    result = run_compare({"E2E_DRY_RUN": "1", "COMPARE_RESULTS": str(results_path)})
    assert result.returncode == 0, result.stdout + result.stderr
    data = load_results(results_path)
    assert "model" in data


def test_dry_runs_results_json_names_both_commit_hashes(tmp_path):
    results_path = tmp_path / "results.json"
    result = run_compare({"E2E_DRY_RUN": "1", "COMPARE_RESULTS": str(results_path)})
    assert result.returncode == 0, result.stdout + result.stderr
    data = load_results(results_path)
    fork_head = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=str(REPO_ROOT),
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()
    assert data["fork_commit"] == fork_head
    assert data["upstream_commit"] == PINNED_UPSTREAM_COMMIT


def test_every_entry_names_pipeline_probe_run_index_and_hit(tmp_path):
    results_path = tmp_path / "results.json"
    result = run_compare({"E2E_DRY_RUN": "1", "COMPARE_RESULTS": str(results_path)})
    assert result.returncode == 0, result.stdout + result.stderr
    data = load_results(results_path)
    groups = {}
    for entry in data["entries"]:
        assert {"pipeline", "probe", "run", "hit"} <= entry.keys()
        groups.setdefault((entry["pipeline"], entry["probe"]), []).append(entry["run"])
    for key, runs in groups.items():
        assert sorted(runs) == [1, 2, 3], f"{key} has run indexes {runs}"


COST_CASES = [('{"total_cost_usd": 0.12}', "0.12"), ("{}", "null")]


@pytest.mark.parametrize("claude_json,expected_cost", COST_CASES)
def test_entrys_cost_reflects_claudes_reported_json(tmp_path, claude_json, expected_cost):
    upstream = git_checkout(tmp_path / "superspec")
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    write_stub(bin_dir, "uvx", "exit 0\n")
    write_stub(bin_dir, "claude", f"echo '{claude_json}'\nexit 0\n")
    results_path = tmp_path / "results.json"
    result = run_compare(
        {"COMPARE_UPSTREAM_CHECKOUT": str(upstream), "COMPARE_RESULTS": str(results_path)},
        bin_dir=bin_dir,
    )
    assert result.returncode == 0, result.stdout + result.stderr
    data = load_results(results_path)
    assert data["entries"], "no entries written"
    if expected_cost == "null":
        assert all(entry["cost_usd"] is None for entry in data["entries"])
    else:
        assert any(entry["cost_usd"] == float(expected_cost) for entry in data["entries"])


# --- Rule: specflow/README.md links to the comparison, and standards lint passes (T597) ---


def test_specflow_readme_links_to_the_comparison_readme_and_it_resolves():
    readme = (SPECFLOW_DIR / "README.md").read_text(encoding="utf-8")
    comparison_url = (
        "https://github.com/DonalMoloney/super-spec-new/blob/main/"
        "specflow/examples/upstream-comparison/README.md"
    )
    assert f"]({comparison_url})" in readme, (
        f"specflow/README.md has no Markdown link to {comparison_url}"
    )
    target = SPECFLOW_DIR / "examples" / "upstream-comparison" / "README.md"
    assert target.exists(), f"{target} does not exist"
