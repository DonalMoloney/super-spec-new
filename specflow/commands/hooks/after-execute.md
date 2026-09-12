# Hook: after_implement

The hook fires once `/speckit.implement` finishes a phase or the full run. It
rejects a completion claim that carries no evidence.

## Checks

1. **Check the evidence**: For each completed task, confirm the expected output
   exists: passing tests, created files, or another named artifact.
2. **Check the test results**: If tests ran, confirm they pass.
3. **Update progress**: Write the completed tasks and the current phase status
   to `specs/NNN/progress.yml`.
4. **Hand off to review**: When every task in a phase is complete, write
   `specs/NNN-feature-name/review-scope.md` and suggest `/speckit.specflow.review`
   before the next phase starts. The file holds four lines: the phase name, the
   completed task IDs, the files this phase changed, and the test command with
   its result. Each phase completion overwrites the file. The review
   command reads it as its default scope.

## Gate

The hook blocks a task completion mark that carries no evidence. It blocks phase
advancement until a human explicitly approves the checkpoint.
