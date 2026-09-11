# speckit.specflow.review

Run code review against spec requirements using review skills.

## Usage

```
/speckit.specflow.review [scope]
```

**Scope**: Optional file paths, spec number, or "all changes". Defaults to the latest feature.

## Process

1. Read the spec and plan for the feature being reviewed
2. **Superpowers detection**: Check for `requesting-code-review` skill
   - **If found**: Read the skill and follow its pre-evaluation checklist and review
     dispatch protocol
   - **If not found**: Use the built-in review protocol below
3. Built-in review protocol:
   - **Spec compliance**: Verify each acceptance scenario from the spec is implemented
   - **Edge case coverage**: Verify brainstormed edge cases are handled
   - **Constitution compliance**: Check all governance principles are respected
   - **Code quality**: Check for bugs, security issues, error handling
   - **Test coverage**: Verify tests exist for critical paths
4. Report findings with confidence scores (0-100, only report issues >= 80)
5. Group findings by severity: Critical > Important > Suggestion
6. Append spec gaps back to the spec: for each Critical or Important finding that
   reports a missing, ambiguous, or contradicted requirement, add a row to the
   `## Open Questions` table in `specs/NNN-feature-name/spec.md` whose Question
   column opens with the finding ID

## Output

Review findings reported to user. Optionally written to
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

## Superpowers Adaptation

When using the `requesting-code-review` skill, adapt its outputs:
- Add specflow-specific review dimensions: spec compliance, constitution compliance,
  brainstorm coverage
- Output location → report to user, optionally write to checklist file

See `references/superpowers-bridge.md` for full adaptation rules.
