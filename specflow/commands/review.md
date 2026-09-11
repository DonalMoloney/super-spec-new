# speckit.specflow.review

Run code review against spec requirements using review skills.

## Usage

```
/speckit.specflow.review [scope]
```

**Scope**: Optional file paths, spec number, or "all changes". Defaults to the files listed in the feature's `review-scope.md` when that file exists, otherwise to the latest feature.

## Process

1. Read the spec and plan for the feature being reviewed. If
   `specs/NNN-feature-name/review-scope.md` exists and the user gave no scope,
   read it and review the files it lists
2. **Superpowers detection**: Check for `requesting-code-review` skill
   - **If found**: Read the skill and follow its pre-evaluation checklist and review
     dispatch protocol
   - **If not found**: Use the built-in review protocol below
3. **Risk tier**: Classify the change before reviewing. Run
   `git diff --numstat main...HEAD` and sum the lines and count the files. The
   tier is HIGH when more than 400 lines or more than 15 files changed, when
   any changed path has a directory named `auth`, `payments`, `billing`,
   `migrations`, `infra`, `secrets`, or `crypto`, or when any changed file is a
   dependency lock file (`package-lock.json`, `yarn.lock`, `Cargo.lock`,
   `poetry.lock`, `go.sum`, or a `requirements*.txt`). Otherwise the tier is
   STANDARD. When `.claude/hooks/risk-classifier.sh` exists in the repository,
   run it and take its answer instead. A HIGH tier runs every dimension in
   step 4 and then a second pass that audits each finding for a `file:line`
   reference and evidence, dropping any finding without both. A STANDARD tier
   runs step 4 once.
4. Built-in review protocol:
   - **Spec compliance**: Verify each acceptance scenario from the spec is implemented
   - **Edge case coverage**: Verify brainstormed edge cases are handled
   - **Constitution compliance**: Check all governance principles are respected
   - **Code quality**: Check for bugs, security issues, error handling
   - **Test coverage**: Verify tests exist for critical paths
5. Report findings with confidence scores (0-100, only report issues >= 80)
6. Group findings by severity: Critical > Important > Suggestion
7. Append spec gaps back to the spec: for each Critical or Important finding that
   reports a missing, ambiguous, or contradicted requirement, add a row to the
   `## Open Questions` table in `specs/NNN-feature-name/spec.md` whose Question
   column opens with the finding ID
7. **Write the findings file**: Write every reported finding to
   `specs/NNN-feature-name/review-findings.json` in the shape under Findings
   File below. Overwrite the file on each run. A run with no findings writes
   the file with an empty `findings` array and the verdict `CLEAN`

## Output

Review findings reported to user and written to
`specs/NNN-feature-name/review-findings.json`. Optionally also written to
`specs/NNN-feature-name/checklist-review.md`.

Spec gaps among the Critical and Important findings are also added to the
`## Open Questions` table in `specs/NNN-feature-name/spec.md`.

## Finding Format

Each finding includes:
- Clear description with confidence score
- File path and line reference
- Specific recommendation or fix suggestion
- A finding ID of the form `R-NNN`, unique within the review run

Findings below 80 confidence are suppressed to reduce noise.

## Findings File

`review-findings.json` is one object. `verdict` is `BLOCK` when any Critical
finding is open, `CONCERNS` when only Important or Suggestion findings are
open, and `CLEAN` otherwise. Each finding's `status` starts as `open`; a later
run or a human sets it to `fixed` or `rebutted`. The severity `Suggestion` in
the report maps to `Minor` in the file.

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

A merge gate that reads this file blocks while any Critical or Important
finding is still `open`.

## Superpowers Adaptation

When using the `requesting-code-review` skill, adapt its outputs:
- Add specflow-specific review dimensions: spec compliance, constitution compliance,
  brainstorm coverage
- Output location → report to user, optionally write to checklist file

See `references/superpowers-bridge.md` for full adaptation rules.
