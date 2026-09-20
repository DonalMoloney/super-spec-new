# speckit.specflow.tasks

The command builds a phased task breakdown with the writing-plans skill.

## Usage

```
/speckit.specflow.tasks [spec-number|spec-path]
```

## Process

1. Read the spec, plan, and constitution for the target feature
2. Resolve `tasks-template` by running `.specify/scripts/bash/resolve-template.sh tasks-template --json` and parsing `TEMPLATE_CONTENT`
3. **Superpowers detection**: Check for the `writing-plans` skill
   - **If found**: Read `SKILL.md` for `writing-plans` and follow its task
     decomposition process. Adapt the output to the tasks template structure
   - **If not found**: Build the tasks directly from the plan with the template
4. Organize tasks by phase: Setup → Foundational → User Stories (by priority) → Polish
5. Apply execution markers to each task:
   - `[P]`: runs in parallel with other `[P]` tasks. The tasks touch different
     files and share no dependency
   - `[TDD]`: follows RED-GREEN-REFACTOR discipline
   - `[REVIEW]`: needs a code review before the next task starts
   - `[SUBAGENT]`: may be handed to a subagent
6. **Keep each task singular**: one outcome per task line. When a description
   needs "and" to state its outcome, split it into two tasks. A reader must be
   able to check whether a task is done without asking a follow-up question. A
   fix, a refactor, and a test count as three tasks, even when they touch one
   file
7. Define phase dependencies and checkpoint gates
8. **Preserve stable IDs**: if `specs/NNN-feature-name/tasks.md` already exists,
   read every `TNNN` ID in it before writing. Match each regenerated task to an
   existing task by the outcome it names, not by its wording and not by its
   position in the list. A matched task keeps its existing ID. A task with no
   match gets the next ID above the highest ID the file has ever used. A retired
   ID is never handed to a different task.
9. **Print a diff summary** of the regeneration before writing: list the IDs
   added, the IDs removed, and the IDs renumbered. If
   `specs/NNN-feature-name/progress.yml` marks a removed or renumbered ID as
   complete, stop and ask the user to confirm; otherwise write the file. When
   `.claude/hooks/artifact-lint.sh` exists in the repository, it rejects the
   same case after the write.
10. Write to `specs/NNN-feature-name/tasks.md`

## Output

The command writes the phased task breakdown to `specs/NNN-feature-name/tasks.md`.

## Execution Markers

| Marker | Meaning | Behavior |
|--------|---------|----------|
| `[P]` | Parallel | Can run at the same time as other `[P]` tasks |
| `[TDD]` | Test-Driven | Must follow RED-GREEN-REFACTOR: write test → fail → implement → pass |
| `[REVIEW]` | Review Gate | Pauses for a human code review before the next task starts |
| `[SUBAGENT]` | Subagent | May be dispatched to a parallel subagent |

## Superpowers Adaptation

Adapt the output of the `writing-plans` skill this way:
- Implementation blueprints go into `specs/NNN/tasks.md`, in the template structure
- Task dependencies map to the Dependencies section
- Parallel opportunities get the `[P]` and `[SUBAGENT]` markers

See `references/superpowers-bridge.md` for the full adaptation rules.
