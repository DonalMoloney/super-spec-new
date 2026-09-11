# Hook: before_implement

Runs before `/speckit.implement` starts. Suggests `/speckit.specflow.execute`
for TDD discipline and prerequisite verification.

## Checks

1. **Constitution gate**: Verify `.specify/memory/constitution.md` exists. If
   missing, stop with `CONSTITUTION_REQUIRED` and instruct the user to run
   `/speckit.constitution`.
2. **Analyze gate**: Resolve the feature targeted by `/speckit.implement` under
   the project root's `specs/NNN-feature-name/`. If the target is ambiguous, ask
   the user to select it. Require a regular file named `.analyzed` in that
   directory. If missing, stop with `ANALYZE_REQUIRED`, name the missing path,
   and direct the user to run `/speckit.analyze` for this feature. Follow the
   Gate markers protocol in `references/workflow-guide.md` to record zero
   critical inconsistencies before retrying. Enforce this check on resumed runs.
3. **Prerequisites**: Verify `tasks.md`, `plan.md`, and `spec.md` all exist
4. **TDD enforcement**: If constitution requires TDD and any `[TDD]` task exists,
   enforce RED-GREEN-REFACTOR discipline for those tasks
5. **Superpowers detection**: Check for `executing-plans`, `subagent-driven-development`,
   and `test-driven-development` skills; update `.specify/superpowers.yml`
6. **Progress state**: Read `progress.yml` to determine resume point (if any)

## Gate

If any prerequisite is missing, abort with guidance on which command to run first.
