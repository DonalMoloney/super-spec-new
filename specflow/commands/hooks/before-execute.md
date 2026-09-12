# Hook: before_implement

The hook fires before `/speckit.implement` starts. It points the user at
`/speckit.specflow.execute` for TDD discipline and prerequisite checks.

## Checks

1. **Constitution gate**: Check that `.specify/memory/constitution.md` exists. If
   it is missing, the hook stops with `CONSTITUTION_REQUIRED` and tells the user
   to run `/speckit.constitution`.
2. **Analyze gate**: Find the feature `/speckit.implement` targets, under
   the project root's `specs/NNN-feature-name/`. If the target is ambiguous, ask
   the user to pick one. That directory needs a regular file named `.analyzed`.
   If the file is missing, the hook stops with `ANALYZE_REQUIRED`, names the
   missing path, and tells the user to run `/speckit.analyze` for this feature.
   Before a retry, follow the Gate markers protocol in `references/workflow-guide.md`
   to record zero critical inconsistencies. This check also applies to a resumed run.
3. **Prerequisites**: Check that `tasks.md`, `plan.md`, and `spec.md` all exist
4. **TDD enforcement**: If the constitution requires TDD and a `[TDD]` task exists,
   the hook enforces RED-GREEN-REFACTOR discipline on those tasks
5. **Superpowers detection**: Look for the `executing-plans`, `subagent-driven-development`,
   and `test-driven-development` skills, then update `.specify/superpowers.yml`
6. **Progress state**: Read `progress.yml` for a resume point, if one exists

## Gate

If a prerequisite is missing, the hook stops and names which command to run first.
