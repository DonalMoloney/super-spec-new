---
description: Orchestrate implementation with TDD, subagents, and review gates
---

# speckit.specflow.execute

The command drives implementation through TDD, subagent dispatch, and review gates.

## Usage

```
/speckit.specflow.execute [spec-number|spec-path]
```

## Process

1. **Constitution gate**: Check that `.specify/memory/constitution.md` exists. If it
   is missing, stop with `CONSTITUTION_REQUIRED`, name the missing path, and tell
   the user to run `/speckit.constitution`.
2. **Analyze gate**: Find the target feature under the project root's
   `specs/NNN-feature-name/` from the supplied spec number or path. If the target
   is ambiguous, ask the user to pick one. Check for a regular file named
   `.analyzed` in that directory. If it is missing, stop with `ANALYZE_REQUIRED`,
   name the missing path, and tell the user to run `/speckit.analyze` for this
   feature. Follow the Gate markers protocol in `references/workflow-guide.md`
   to record zero critical inconsistencies before the retry. Check this gate on
   a resumed run too, before implementation or a progress update.
3. Read the target feature's tasks file.
4. Read the plan and the constitution for context.
5. **Superpowers detection**: Look for the `executing-plans`,
   `subagent-driven-development`, and `test-driven-development` skills.
6. Work through the tasks phase by phase:

   **For `[TDD]` tasks**:
   - If the TDD skill is found, follow its RED-GREEN-REFACTOR process
   - Otherwise: write test → check it fails → implement → check it passes → refactor

   **For `[SUBAGENT]` tasks**:
   - On Claude Code with the subagent-driven-development skill found, follow
     its dispatch protocol
   - On Claude Code without the skill, dispatch one subagent per task with the
     Task tool and check each result before the next dispatch
   - On the Copilot CLI, implement the tasks in sequence, in the same session
   - Two reviews run whatever the skill version says: `code-reviewer` reviews
     each finished task, and `/speckit.specflow.review` reviews the whole
     branch once the phase ends. Both run on all three paths above

   **For `[P]` tasks**:
   - On Claude Code with Agent Teams available and
     `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` set: dispatch one teammate per
     `[P]` task in the batch, each in its own worktree, with the file paths the
     task line names stated in the teammate's brief so no two teammates touch
     the same file. Do not nest teams. A teammate never dispatches its own team.
   - On Claude Code without Agent Teams: run the batch in parallel with the
     Task tool
   - On the Copilot CLI: run the batch in order, the same as the non-parallel
     task path

   **For `[REVIEW]` tasks**:
   - Pause and run the review protocol (see `commands/review.md`)

7. At each **phase checkpoint**:
   - Summarize the completed work
   - Run the tests, if any apply
   - Ask the user to approve before the next phase
   - Write `specs/NNN/handoff.md`, capped at 5 lines, so a resumed session picks
     up the checkpoint state without reading the full task history

8. Mark each task's checkbox in `tasks.md` complete as the task finishes
9. Update the target feature's `progress.yml` with the current execution state

## Output

The command changes code in the project and updates the task checkboxes in `tasks.md`.

## Human Checkpoints

The agent MUST pause at every phase boundary and wait for explicit user approval.
Never skip a checkpoint.

## Skill Mode Behavior

| Skill | Adaptation |
|-------|------------|
| `executing-plans` | Follows its batch processing protocol with human checkpoints |
| `subagent-driven-development` | Follows its dispatch protocol for `[SUBAGENT]` tasks |
| `test-driven-development` | Follows its RED-GREEN-REFACTOR discipline for `[TDD]` tasks |

If no superpowers are available, all three fall back to built-in sequential execution
with manual confirmation. See `references/superpowers-mapping.md` for details.
