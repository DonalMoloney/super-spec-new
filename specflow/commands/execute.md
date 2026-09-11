# speckit.specflow.execute

Orchestrate implementation with TDD, subagents, and review gates.

## Usage

```
/speckit.specflow.execute [spec-number|spec-path]
```

## Process

1. **Constitution gate**: Verify `.specify/memory/constitution.md` exists. If
   missing, stop with `CONSTITUTION_REQUIRED` and instruct the user to run
   `/speckit.constitution`.
2. **Analyze gate**: Resolve the target feature under the project root's
   `specs/NNN-feature-name/` using the supplied spec number or path. If the target
   is ambiguous, ask the user to select it. Require a regular file named
   `.analyzed` in that directory. If missing, stop with `ANALYZE_REQUIRED`, name
   the missing path, and direct the user to run `/speckit.analyze` for this feature.
   Follow the Gate markers protocol in `references/workflow-guide.md` to record
   zero critical inconsistencies before retrying. Check this gate on resumed runs
   too, before implementation or progress updates.
3. Read the tasks file for the target feature
4. Read the plan and constitution for context
5. **Superpowers detection**: Check for `executing-plans`, `subagent-driven-development`,
   and `test-driven-development` skills
6. Walk through tasks phase by phase:

   **For `[TDD]` tasks**:
   - If TDD skill found, follow its RED-GREEN-REFACTOR process
   - Otherwise: write test → verify it fails → implement → verify it passes → refactor

   **For `[SUBAGENT]` tasks**:
   - If subagent-driven-development skill found, follow its dispatch protocol
   - Otherwise: implement sequentially in-session

   **For `[P]` tasks**:
   - If the Agent Teams feature is available and
     `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is set: dispatch one teammate per
     `[P]` task in the batch, each in its own worktree, with the task's file
     scope (from `task-decomposer`'s existing output) stated in the teammate's
     brief so no two teammates touch the same file. Do not nest teams — a
     teammate never dispatches its own team.
   - Otherwise: launch parallel tasks where possible using the Task tool
   - If neither is available: fall back to sequential execution, identical to
     the non-parallel task path

   **For `[REVIEW]` tasks**:
   - Pause and run review protocol (see `commands/review.md`)

7. At each **phase checkpoint**:
   - Summarize completed work
   - Run tests if applicable
   - Ask user for approval before proceeding to next phase

8. Update task checkboxes in `tasks.md` as each task completes
9. Update the target feature's `progress.yml` with current execution state

## Output

Code changes in the project, updated task checkboxes in `tasks.md`.

## Human Checkpoints

The agent MUST pause at every phase boundary and wait for explicit user approval.
Never skip a checkpoint.

## Superpowers Adaptation

| Skill | Adaptation |
|-------|------------|
| `executing-plans` | Follow its batch processing protocol with human checkpoints |
| `subagent-driven-development` | Follow its dispatch protocol for `[SUBAGENT]` tasks |
| `test-driven-development` | Follow its RED-GREEN-REFACTOR discipline for `[TDD]` tasks |

If no superpowers are available, all three fall back to built-in sequential execution
with manual confirmation. See `references/superpowers-bridge.md` for full details.
