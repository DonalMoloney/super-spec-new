# Hook: after_implement

Runs after `/speckit.implement` completes a phase or the entire execution. Requires
evidence before completion claims are accepted.

## Checks

1. **Evidence verification**: For each completed task, verify that the expected output
   exists (tests pass, files created, etc.)
2. **Test results**: If tests were run, verify they pass
3. **Progress update**: Update `specs/NNN/progress.yml` with completed tasks
   and current phase status
4. **Review hand-off**: If all tasks in a phase are complete, write
   `specs/NNN-feature-name/review-scope.md` and then suggest running
   `/speckit.specflow.review` before proceeding to the next phase. The file
   holds four lines: the phase name, the completed task IDs, the files changed
   in this phase, and the test command run with its result. Overwrite the file
   on each phase completion; the review command reads it as its default scope.

## Gate

Cannot mark a task as complete without evidence. Cannot advance to the next phase
without explicit human approval at the checkpoint.
