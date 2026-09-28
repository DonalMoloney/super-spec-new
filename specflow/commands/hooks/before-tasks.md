# Hook: before_tasks

The hook fires before `/speckit.tasks` starts. It points the user at
`/speckit.specflow.tasks` for the constitution and open-questions checks core
`/speckit.tasks` does not run.

## Preconditions

1. **Constitution gate**: Check that `.specify/memory/constitution.md` exists. If
   it is missing, the hook stops with `CONSTITUTION_REQUIRED`, names the missing
   path, and tells the user to run `/speckit.constitution`. See
   `references/workflow-guide.md`'s Stop codes table for the expected and found
   values this code reports.
2. **Open questions gate**: Read the `## Open Questions` table in the target
   feature's `spec.md` and count the rows whose Status cell is not `Resolved`.
   If the count is above zero, the hook stops with `OPEN_QUESTIONS` and tells
   the user to run `/speckit.specflow.brainstorm` for this feature. A spec with
   no `## Open Questions` table counts zero rows and passes. See
   `references/workflow-guide.md`'s Stop codes table for the expected and
   found values this code reports.

## Gate

If a precondition fails, the hook stops and names which command to run first.
