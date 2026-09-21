# Hook: after_tasks

The hook fires once `/speckit.tasks` completes. It checks that the task plan
covers the spec and looks for a superpowers skill that could improve the breakdown.

## Preconditions

1. **Coverage check**: Check that every user story in the spec has matching tasks
2. **Superpowers enhancement**: If the hook finds the `writing-plans` skill, it
   suggests rerunning `/speckit.specflow.tasks` for a deeper breakdown
3. **TDD readiness**: If the constitution requires TDD, check that `[TDD]` markers
   appear on the matching tasks
4. **Review gates**: If the constitution requires code review, check that `[REVIEW]`
   markers appear on the matching tasks
5. **Progress state**: Read `progress.yml` for what an earlier run recorded, if one
   exists. Warn when the new breakdown drops a task the file marks complete.

## Output

The hook prints a warning to the user for each failed check. It modifies no file.
