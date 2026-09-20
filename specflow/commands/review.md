# speckit.specflow.review

Run code review against spec requirements using review skills.

## Usage

```
/speckit.specflow.review [scope]
```

**Scope**: an optional list of file paths, a spec number, or "all changes". It defaults to the files listed in the feature's `review-scope.md` when that file exists, and otherwise to the latest feature.

## Process

1. Read the spec and the plan for the feature under review. If
   `specs/NNN-feature-name/review-scope.md` exists and the user gave no scope,
   read it and review the files it lists
2. **Superpowers detection**: Check for the `requesting-code-review` skill
   - **If found**: Read the skill and follow its pre-evaluation checklist and
     review dispatch protocol
   - **If not found**: Follow the built-in review protocol below
3. **Risk tier**: Classify the change before the review starts. Run
   `git diff --numstat main...HEAD` and sum the changed lines and files. The
   tier is HIGH when the diff changes more than 400 lines or more than 15
   files, when any changed path has a directory named `auth`, `payments`,
   `billing`, `migrations`, `infra`, `secrets`, or `crypto`, or when any
   changed file is a dependency lock file (`package-lock.json`, `yarn.lock`,
   `Cargo.lock`, `poetry.lock`, `go.sum`, or a `requirements*.txt`). Otherwise
   the tier is STANDARD. When `.claude/hooks/risk-classifier.sh` exists in the
   repository, run it and use its answer instead. A HIGH tier runs every
   dimension in step 4, then a second pass that checks each finding for a
   `file:line` reference and evidence and drops any finding missing either. A
   STANDARD tier runs step 4 once.
4. Built-in review protocol:
   - **Spec compliance**: Check that each acceptance scenario in the spec is implemented
   - **Edge case coverage**: Check that the brainstormed edge cases are handled
   - **Constitution compliance**: Check that the code follows every governance principle
   - **Code quality**: Check for bugs, security flaws, and missing error handling
   - **Test coverage**: Check that tests cover the critical paths
5. Report each finding with a confidence score from 0-100, and report only findings that score 80 or higher
6. Group findings by severity: Critical > Important > Suggestion
7. Append each spec gap to the spec: for each Critical or Important finding
   that reports a missing, ambiguous, or contradicted requirement, add a row
   to the `## Open Questions` table in `specs/NNN-feature-name/spec.md` and
   open its Question column with the finding ID
8. **Write the findings file**: Write every reported finding to
   `specs/NNN-feature-name/review-findings.json` in the shape the Findings
   File section defines below. Overwrite the file on each run. A run with no
   findings writes an empty `findings` array and the verdict `CLEAN`
9. **Join each finding to its checklist item**: for each checklist the feature
   has, under `specs/NNN-feature-name/checklists/` or in the
   `checklist-review.md` this run writes, fill the `## Review Findings` table.
   Add one row per finding that fails an item in that checklist: the `CHK` id
   of the item, the finding's `R-NNN` id, and the finding's status. Skip a
   checklist that carries no `## Review Findings` table, and skip the step
   when the feature has no checklist

## Output

The command reports findings to the user and writes them to
`specs/NNN-feature-name/review-findings.json`. It can also write them to
`specs/NNN-feature-name/checklist-review.md`.

The command also adds spec gaps among the Critical and Important findings to
the `## Open Questions` table in `specs/NNN-feature-name/spec.md`.

It fills the `## Review Findings` table in each checklist the feature has,
joining a failed `CHK` id to the `R-NNN` id that reported it.

## Finding Format

Each finding includes:
- A clear description and a confidence score
- A file path and a line reference
- A specific recommendation or fix
- A finding ID of the form `R-NNN`, unique within the review run

The review drops any finding below 80 confidence to cut the noise.

## Findings File

`review-findings.json` holds one object. Its `verdict` is `BLOCK` when a
Critical finding is open, `CONCERNS` when only Important or Suggestion
findings are open, and `CLEAN` otherwise. Each finding's `status` starts as
`open`, and a later run or a person sets it to `fixed` or `rebutted`. The
report's `Suggestion` severity maps to `Minor` in the file.

```json
{
  "schema_version": "1.0",
  "reviewer": "speckit.specflow.review",
  "verdict": "BLOCK",
  "findings": [
    {
      "id": "R-001",
      "severity": "Critical",
      "category": "spec-compliance",
      "location": "src/auth/login.py:42",
      "evidence": "Acceptance scenario 2 in spec.md has no passing test",
      "fix": "Add a test for the locked-account path and make it pass",
      "status": "open"
    }
  ]
}
```

A merge gate reading this file blocks while a Critical or Important finding
stays `open`.

## Superpowers Adaptation

When the command uses the `requesting-code-review` skill, it adapts the
skill's outputs:
- Add review dimensions specific to specflow: spec compliance, constitution
  compliance, and brainstorm coverage
- Output location → report to the user, and optionally write it to the
  checklist file

See `references/superpowers-bridge.md` for the full adaptation rules.
