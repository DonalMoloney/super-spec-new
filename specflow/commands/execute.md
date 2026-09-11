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
   - On Claude Code with the subagent-driven-development skill found, follow
     its dispatch protocol
   - On Claude Code without the skill, dispatch one subagent per task with the
     Task tool and review each result before the next dispatch
   - On the Copilot CLI, implement sequentially in-session

   **For `[P]` tasks**:
   - On Claude Code with Agent Teams available and
     `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` set: dispatch one teammate per
     `[P]` task in the batch, each in its own worktree, with the file paths the
     task line names stated in the teammate's brief so no two teammates touch
     the same file. Do not nest teams. A teammate never dispatches its own team.
   - On Claude Code without Agent Teams: launch the batch in parallel with the
     Task tool
   - On the Copilot CLI: run the batch in order, identical to the non-parallel
     task path

   **For `[REVIEW]` tasks**:
   - Pause and run review protocol (see `commands/review.md`)

7. At each **phase checkpoint**:
   - Summarize completed work
   - Run tests if applicable
   - Ask user for approval before proceeding to next phase
   - Write `specs/NNN/handoff.md`, capped at 5 lines, so a resumed session can
     pick up the checkpoint state without re-reading the full task history

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
