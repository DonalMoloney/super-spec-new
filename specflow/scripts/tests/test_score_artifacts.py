#!/usr/bin/env python3
"""Tests for score-artifacts.py, the feature-directory artifact scorer."""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "score-artifacts.py"
GOLDEN_FEATURE_DIR = (
    Path(__file__).resolve().parents[2]
    / "examples"
    / "static-landing-page"
    / "specs"
    / "001-static-landing-page"
)

SEEDED_BUG_FEATURE_DIR = (
    Path(__file__).resolve().parents[2] / "examples" / "seeded-bug"
)

SPECFLOW_DIR = Path(__file__).resolve().parents[2]
REPO_ROOT = Path(__file__).resolve().parents[3]

SPEC_WITH_MARKERS = """# Feature

## User Scenarios & Testing *(mandatory)*

Scenario text.

## Requirements *(mandatory)*

- **FR-001**: The page loads.

## Success Criteria *(mandatory)*

- **SC-001**: The page loads under one second.

## Traceability

| Criterion | Test |
|---|---|
| FR-001 | `checklists/review.md::FR-001` |
| SC-001 | `checklists/review.md::SC-001` |
"""


def score(feature_dir):
    """Run the scorer on feature_dir and return the completed subprocess."""
    return subprocess.run(
        [sys.executable, str(SCRIPT), str(feature_dir)],
        capture_output=True,
        text=True,
    )


def score_from(working_directory, argument):
    """Run the scorer on argument from working_directory and return the subprocess."""
    return subprocess.run(
        [sys.executable, str(SCRIPT), str(argument)],
        capture_output=True,
        text=True,
        cwd=str(working_directory),
    )


def scored_content(stdout):
    """Parse stdout as a report and return it without the unscored feature_dir."""
    report = json.loads(stdout)
    del report["feature_dir"]
    return report


def score_json(feature_dir):
    """Run the scorer on feature_dir, assert success, and return the parsed report."""
    result = score(feature_dir)
    assert result.returncode == 0, result.stderr
    return json.loads(result.stdout)


def write_feature(directory, spec_text, tasks_text=None):
    """Write spec.md, and optionally tasks.md, into directory and return its Path."""
    feature_dir = Path(directory)
    (feature_dir / "spec.md").write_text(spec_text)
    if tasks_text is not None:
        (feature_dir / "tasks.md").write_text(tasks_text)
    return feature_dir


HASH_SEEDS = ("0", "1", "2", "3", "4", "5", "6", "7")

SPEC_WITH_FOUR_UNTRACED = """# Feature

## User Scenarios & Testing *(mandatory)*

Scenario text.

## Requirements *(mandatory)*

- **SC-002**: The page prints.
- **FR-003**: The page caches its assets.
- **SC-001**: The page loads under one second.
- **FR-002**: The page paginates.
- **FR-001**: The page loads.

## Success Criteria *(mandatory)*

Criteria are declared above.

## Traceability

| Criterion | Test |
|---|---|
| FR-001 | `checklists/review.md::FR-001` |
"""

TASKS_WITH_THREE_MISSING_IDS = """# Tasks

- [ ] Write the landing page copy
- [x] T001 Create the output directory
- [ ] Archive the previous build
- [X] Measure the first paint
"""


def score_under_hash_seed(feature_dir, seed):
    """Run the scorer on feature_dir with PYTHONHASHSEED set to seed."""
    environment = dict(os.environ)
    environment["PYTHONHASHSEED"] = seed
    return subprocess.run(
        [sys.executable, str(SCRIPT), str(feature_dir)],
        capture_output=True,
        text=True,
        env=environment,
    )


def score_json_under_hash_seed(feature_dir, seed):
    """Run the scorer under seed, assert success, and return the parsed report."""
    result = score_under_hash_seed(feature_dir, seed)
    assert result.returncode == 0, result.stderr
    return json.loads(result.stdout)


def test_golden_run_exits_zero_and_prints_one_json_object():
    result = score(GOLDEN_FEATURE_DIR)
    assert result.returncode == 0, result.stderr
    assert result.stdout.endswith("\n")
    report = json.loads(result.stdout)
    assert isinstance(report, dict)
    assert report["feature_dir"] == str(GOLDEN_FEATURE_DIR)


def test_golden_run_has_all_three_mandatory_sections():
    report = score_json(GOLDEN_FEATURE_DIR)
    assert report["spec_sections"] == {
        "required": 3,
        "present": 3,
        "missing": [],
        "score": 100.0,
    }


def test_golden_run_traces_all_twenty_three_criteria():
    report = score_json(GOLDEN_FEATURE_DIR)
    assert report["traceability"]["criteria"] == 23
    assert report["traceability"]["traced"] == 23
    assert report["traceability"]["untraced"] == []
    assert report["traceability"]["score"] == 100.0


def test_golden_run_tasks_all_carry_stable_ids():
    report = score_json(GOLDEN_FEATURE_DIR)
    assert report["task_ids"]["tasks"] == 29
    assert report["task_ids"]["with_id"] == 29
    assert report["task_ids"]["without_id"] == []
    assert report["task_ids"]["score"] == 100.0


def test_golden_run_finds_one_needs_clarification_marker():
    report = score_json(GOLDEN_FEATURE_DIR)
    assert report["needs_clarification"]["count"] == 1
    assert report["needs_clarification"]["locations"] == [
        {"file": "checklists/requirements.md", "line": 16}
    ]


def test_output_is_byte_identical_under_different_hash_seeds():
    with tempfile.TemporaryDirectory() as directory:
        feature_dir = write_feature(
            directory, SPEC_WITH_FOUR_UNTRACED, TASKS_WITH_THREE_MISSING_IDS
        )
        first = score_under_hash_seed(feature_dir, "0")
        second = score_under_hash_seed(feature_dir, "12345")
    assert first.returncode == 0, first.stderr
    assert second.returncode == 0, second.stderr
    assert first.stdout == second.stdout


def test_relative_and_absolute_arguments_score_identical_content():
    relative = score_from(REPO_ROOT, GOLDEN_FEATURE_DIR.relative_to(REPO_ROOT))
    absolute = score_from(REPO_ROOT, GOLDEN_FEATURE_DIR)
    assert relative.returncode == 0, relative.stderr
    assert absolute.returncode == 0, absolute.stderr
    assert scored_content(relative.stdout) == scored_content(absolute.stdout)


def test_two_working_directories_score_identical_content():
    from_root = score_from(REPO_ROOT, GOLDEN_FEATURE_DIR.relative_to(REPO_ROOT))
    from_specflow = score_from(
        SPECFLOW_DIR, GOLDEN_FEATURE_DIR.relative_to(SPECFLOW_DIR)
    )
    assert from_root.returncode == 0, from_root.stderr
    assert from_specflow.returncode == 0, from_specflow.stderr
    assert scored_content(from_root.stdout) == scored_content(from_specflow.stdout)


def test_feature_dir_echoes_the_relative_argument_as_given():
    argument = GOLDEN_FEATURE_DIR.relative_to(REPO_ROOT)
    result = score_from(REPO_ROOT, argument)
    assert result.returncode == 0, result.stderr
    assert json.loads(result.stdout)["feature_dir"] == str(argument)


def test_missing_success_criteria_section_scores_sixty_six_point_seven():
    spec = """# Feature

## User Scenarios & Testing *(mandatory)*

## Requirements *(mandatory)*
"""
    with tempfile.TemporaryDirectory() as directory:
        report = score_json(write_feature(directory, spec))
    assert report["spec_sections"]["present"] == 2
    assert report["spec_sections"]["missing"] == ["Success Criteria"]
    assert report["spec_sections"]["score"] == 66.7


def test_heading_without_mandatory_marker_counts_as_present():
    spec = """# Feature

## User Scenarios & Testing

## Requirements

## Success Criteria
"""
    with tempfile.TemporaryDirectory() as directory:
        report = score_json(write_feature(directory, spec))
    assert report["spec_sections"]["present"] == 3
    assert report["spec_sections"]["missing"] == []


def test_traceability_row_with_empty_test_cell_leaves_criterion_untraced():
    spec = """# Feature

## Requirements

- **FR-001**: The page loads.
- **FR-002**: The page prints.

## Traceability

| Criterion | Test |
|---|---|
| FR-001 | `checklists/review.md::FR-001` |
| FR-002 |  |
"""
    with tempfile.TemporaryDirectory() as directory:
        report = score_json(write_feature(directory, spec))
    assert report["traceability"]["criteria"] == 2
    assert report["traceability"]["traced"] == 1
    assert report["traceability"]["untraced"] == ["FR-002"]
    assert report["traceability"]["score"] == 50.0


def test_criterion_with_no_traceability_row_is_untraced():
    spec = """# Feature

## Requirements

- **FR-001**: The page loads.
- **SC-001**: The page loads under one second.

## Traceability

| Criterion | Test |
|---|---|
| FR-001 | `checklists/review.md::FR-001` |
"""
    with tempfile.TemporaryDirectory() as directory:
        report = score_json(write_feature(directory, spec))
    assert report["traceability"]["untraced"] == ["SC-001"]
    assert report["traceability"]["traced"] == 1


def test_traceability_row_for_undeclared_id_is_ignored():
    spec_with_extra_row = SPEC_WITH_MARKERS + "| FR-999 | `checklists/review.md::FR-999` |\n"
    with tempfile.TemporaryDirectory() as directory:
        baseline = score_json(write_feature(directory, SPEC_WITH_MARKERS))
    with tempfile.TemporaryDirectory() as directory:
        with_extra_row = score_json(write_feature(directory, spec_with_extra_row))
    baseline.pop("feature_dir")
    with_extra_row.pop("feature_dir")
    assert with_extra_row == baseline


def test_spec_without_criteria_scores_traceability_as_null():
    spec = """# Feature

## Requirements

No criteria are declared yet.
"""
    with tempfile.TemporaryDirectory() as directory:
        report = score_json(write_feature(directory, spec))
    assert report["traceability"]["criteria"] == 0
    assert report["traceability"]["traced"] == 0
    assert report["traceability"]["score"] is None


def test_task_line_without_id_prefix_is_listed_in_without_id():
    tasks = """# Tasks

- [x] T001 Create the output directory
- [ ] Write the landing page copy
"""
    with tempfile.TemporaryDirectory() as directory:
        report = score_json(write_feature(directory, SPEC_WITH_MARKERS, tasks))
    assert report["task_ids"]["tasks"] == 2
    assert report["task_ids"]["with_id"] == 1
    assert report["task_ids"]["without_id"] == ["Write the landing page copy"]
    assert report["task_ids"]["score"] == 50.0


def test_uppercase_ticked_task_line_without_id_is_listed_in_without_id():
    tasks = """# Tasks

- [X] Uppercase check with no id
"""
    with tempfile.TemporaryDirectory() as directory:
        report = score_json(write_feature(directory, SPEC_WITH_MARKERS, tasks))
    assert report["task_ids"]["tasks"] == 1
    assert report["task_ids"]["with_id"] == 0
    assert report["task_ids"]["without_id"] == ["Uppercase check with no id"]
    assert report["task_ids"]["score"] == 0.0


def test_indented_task_line_without_id_is_listed_in_without_id():
    tasks = """# Tasks

  - [ ] Indented check with no id
"""
    with tempfile.TemporaryDirectory() as directory:
        report = score_json(write_feature(directory, SPEC_WITH_MARKERS, tasks))
    assert report["task_ids"]["tasks"] == 1
    assert report["task_ids"]["with_id"] == 0
    assert report["task_ids"]["without_id"] == ["Indented check with no id"]
    assert report["task_ids"]["score"] == 0.0


def test_uppercase_ticked_task_line_with_id_counts_toward_with_id():
    tasks = """# Tasks

- [X] T001 Create the output directory
"""
    with tempfile.TemporaryDirectory() as directory:
        report = score_json(write_feature(directory, SPEC_WITH_MARKERS, tasks))
    assert report["task_ids"]["tasks"] == 1
    assert report["task_ids"]["with_id"] == 1
    assert report["task_ids"]["without_id"] == []
    assert report["task_ids"]["score"] == 100.0


def test_feature_dir_without_tasks_file_scores_task_ids_as_null():
    with tempfile.TemporaryDirectory() as directory:
        result = score(write_feature(directory, SPEC_WITH_MARKERS))
        report = json.loads(result.stdout)
    assert result.returncode == 0
    assert report["task_ids"]["tasks"] == 0
    assert report["task_ids"]["without_id"] == []
    assert report["task_ids"]["score"] is None


def test_nonexistent_path_fails_with_empty_stdout():
    with tempfile.TemporaryDirectory() as directory:
        result = score(Path(directory) / "no-such-feature")
    assert result.returncode == 1
    assert result.stdout == ""
    assert result.stderr.startswith("FAIL:")


def test_file_argument_instead_of_directory_fails_with_empty_stdout():
    with tempfile.TemporaryDirectory() as directory:
        spec_file = Path(directory) / "spec.md"
        spec_file.write_text(SPEC_WITH_MARKERS)
        result = score(spec_file)
    assert result.returncode == 1
    assert result.stdout == ""
    assert result.stderr.startswith("FAIL:")


def test_directory_without_spec_file_fails_naming_spec_md():
    with tempfile.TemporaryDirectory() as directory:
        result = score(directory)
    assert result.returncode == 1
    assert result.stdout == ""
    assert result.stderr.startswith("FAIL:")
    assert "spec.md" in result.stderr


def test_zero_arguments_fails_with_empty_stdout():
    result = subprocess.run(
        [sys.executable, str(SCRIPT)],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 1
    assert result.stdout == ""
    assert result.stderr.strip() != ""


def test_two_arguments_fails_with_empty_stdout():
    result = subprocess.run(
        [sys.executable, str(SCRIPT), str(GOLDEN_FEATURE_DIR), str(GOLDEN_FEATURE_DIR)],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 1
    assert result.stdout == ""
    assert result.stderr.strip() != ""


def test_seeded_bug_leaves_sc_003_untraced():
    report = score_json(SEEDED_BUG_FEATURE_DIR)
    assert report["traceability"]["criteria"] == 23
    assert report["traceability"]["traced"] == 22
    assert report["traceability"]["untraced"] == ["SC-003"]


def test_seeded_bug_matches_the_golden_on_every_other_dimension():
    golden = score_json(GOLDEN_FEATURE_DIR)
    report = score_json(SEEDED_BUG_FEATURE_DIR)
    assert report["spec_sections"]["score"] == 100.0
    assert report["task_ids"]["score"] == 100.0
    assert (
        report["needs_clarification"]["count"]
        == golden["needs_clarification"]["count"]
    )


def test_four_untraced_criteria_are_listed_in_sorted_order():
    with tempfile.TemporaryDirectory() as directory:
        feature_dir = write_feature(directory, SPEC_WITH_FOUR_UNTRACED)
        untraced = [
            score_json_under_hash_seed(feature_dir, seed)["traceability"]["untraced"]
            for seed in HASH_SEEDS
        ]
    assert untraced == [["FR-002", "FR-003", "SC-001", "SC-002"]] * len(HASH_SEEDS)


def test_untraced_criteria_count_is_independent_of_declaration_order():
    with tempfile.TemporaryDirectory() as directory:
        report = score_json(write_feature(directory, SPEC_WITH_FOUR_UNTRACED))
    assert report["traceability"]["criteria"] == 5
    assert report["traceability"]["traced"] == 1
    assert report["traceability"]["score"] == 20.0


def test_traceability_row_with_dash_test_cell_leaves_criterion_untraced():
    spec = """# Feature

## Requirements

- **FR-001**: The page loads.
- **FR-002**: The page prints.

## Traceability

| Criterion | Test |
|---|---|
| FR-001 | `checklists/review.md::FR-001` |
| FR-002 | - |
"""
    with tempfile.TemporaryDirectory() as directory:
        report = score_json(write_feature(directory, spec))
    assert report["traceability"]["traced"] == 1
    assert report["traceability"]["untraced"] == ["FR-002"]
    assert report["traceability"]["score"] == 50.0


def test_three_tasks_without_ids_are_listed_in_sorted_order():
    with tempfile.TemporaryDirectory() as directory:
        report = score_json(
            write_feature(
                directory, SPEC_WITH_FOUR_UNTRACED, TASKS_WITH_THREE_MISSING_IDS
            )
        )
    assert report["task_ids"]["tasks"] == 4
    assert report["task_ids"]["with_id"] == 1
    assert report["task_ids"]["without_id"] == [
        "Archive the previous build",
        "Measure the first paint",
        "Write the landing page copy",
    ]
    assert report["task_ids"]["score"] == 25.0


def test_two_missing_sections_are_listed_in_sorted_not_template_order():
    spec = """# Feature

## Success Criteria *(mandatory)*

- **SC-001**: The page loads under one second.
"""
    with tempfile.TemporaryDirectory() as directory:
        report = score_json(write_feature(directory, spec))
    assert report["spec_sections"]["present"] == 1
    assert report["spec_sections"]["missing"] == [
        "Requirements",
        "User Scenarios & Testing",
    ]
    assert report["spec_sections"]["score"] == 33.3


def test_markers_across_files_are_listed_by_file_then_line():
    nested_marker_file = """Nested notes.

A line holding NEEDS CLARIFICATION about the nested file.
"""
    top_marker_file = """A line holding NEEDS CLARIFICATION about the top file.

Another line holding NEEDS CLARIFICATION about the top file.
"""
    with tempfile.TemporaryDirectory() as directory:
        feature_dir = write_feature(directory, SPEC_WITH_FOUR_UNTRACED)
        (feature_dir / "alpha").mkdir()
        (feature_dir / "alpha" / "nested.md").write_text(nested_marker_file)
        (feature_dir / "zz-notes.md").write_text(top_marker_file)
        report = score_json(feature_dir)
    assert report["needs_clarification"]["count"] == 3
    assert report["needs_clarification"]["locations"] == [
        {"file": "alpha/nested.md", "line": 3},
        {"file": "zz-notes.md", "line": 1},
        {"file": "zz-notes.md", "line": 3},
    ]


def test_stdout_is_the_report_indented_by_two_with_sorted_keys():
    with tempfile.TemporaryDirectory() as directory:
        result = score(
            write_feature(
                directory, SPEC_WITH_FOUR_UNTRACED, TASKS_WITH_THREE_MISSING_IDS
            )
        )
    assert result.returncode == 0, result.stderr
    expected = json.dumps(json.loads(result.stdout), indent=2, sort_keys=True) + "\n"
    assert result.stdout == expected


def test_traceability_table_under_a_later_h1_does_not_trace_a_criterion():
    spec = """# Feature

## Requirements

- **FR-001**: The page loads.
- **FR-002**: The page prints.

## Traceability

| Criterion | Test |
|---|---|
| FR-001 | `checklists/review.md::FR-001` |

# Appendix

| FR-002 | anything at all |
"""
    with tempfile.TemporaryDirectory() as directory:
        report = score_json(write_feature(directory, spec))
    assert report["traceability"]["untraced"] == ["FR-002"]
    assert report["traceability"]["traced"] == 1


def test_mandatory_section_written_as_h1_is_still_missing():
    spec = """# Feature

## User Scenarios & Testing *(mandatory)*

# Requirements *(mandatory)*

## Success Criteria *(mandatory)*
"""
    with tempfile.TemporaryDirectory() as directory:
        report = score_json(write_feature(directory, spec))
    assert report["spec_sections"]["missing"] == ["Requirements"]
    assert report["spec_sections"]["present"] == 2


def test_h3_subheading_inside_traceability_keeps_the_rows_below_it_traced():
    spec = """# Feature

## Requirements

- **FR-001**: The page loads.
- **FR-002**: The page prints.

## Traceability

| Criterion | Test |
|---|---|
| FR-001 | `checklists/review.md::FR-001` |

### Success criteria

| FR-002 | `checklists/review.md::FR-002` |
"""
    with tempfile.TemporaryDirectory() as directory:
        report = score_json(write_feature(directory, spec))
    assert report["traceability"]["untraced"] == []
    assert report["traceability"]["traced"] == 2


def test_non_utf8_markdown_file_still_scores_every_dimension():
    with tempfile.TemporaryDirectory() as directory:
        feature_dir = write_feature(
            directory, SPEC_WITH_FOUR_UNTRACED, TASKS_WITH_THREE_MISSING_IDS
        )
        (feature_dir / "notes.md").write_bytes("Caf\xe9 notes".encode("latin-1"))
        result = score(feature_dir)
    assert result.returncode == 0, result.stderr
    report = json.loads(result.stdout)
    assert report["spec_sections"]["score"] == 100.0
    assert report["traceability"]["score"] == 20.0
    assert report["task_ids"]["score"] == 25.0
    assert report["needs_clarification"]["count"] == 0


def test_marker_in_a_non_utf8_file_is_still_located():
    notes = "Caf\xe9 notes\nA line holding NEEDS CLARIFICATION about the beans.\n"
    with tempfile.TemporaryDirectory() as directory:
        feature_dir = write_feature(directory, SPEC_WITH_FOUR_UNTRACED)
        (feature_dir / "notes.md").write_bytes(notes.encode("latin-1"))
        result = score(feature_dir)
    assert result.returncode == 0, result.stderr
    report = json.loads(result.stdout)
    assert report["needs_clarification"]["count"] == 1
    assert report["needs_clarification"]["locations"] == [
        {"file": "notes.md", "line": 2}
    ]
