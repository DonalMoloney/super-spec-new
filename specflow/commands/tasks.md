# speckit.specflow.tasks

Generate a phased task breakdown using writing-plans skills.

## Usage

```
/speckit.specflow.tasks [spec-number|spec-path]
```

## Process

1. Read the spec, plan, and constitution for the target feature
2. Read the template at `.specify/templates/tasks-template.md`
3. **Superpowers detection**: Check for `writing-plans` skill
   - **If found**: Read the writing-plans SKILL.md and follow its task decomposition
     process, adapting outputs to the tasks template structure
   - **If not found**: Decompose directly from the plan using the template
4. Organize tasks by phase: Setup → Foundational → User Stories (by priority) → Polish
5. Apply execution markers to each task:
   - `[P]`: runs in parallel with other `[P]` tasks (different files, no dependencies)
   - `[TDD]`: follows RED-GREEN-REFACTOR discipline
   - `[REVIEW]`: needs code review before the next task starts
   - `[SUBAGENT]`: may be delegated to a subagent
6. **Keep each task singular**: one outcome per task line. A description that
   needs "and" to state its outcome is two tasks; split it. A reader must be
   able to check that a task is done without asking a follow-up question. A
   fix, a refactor, and a test are three tasks even when they touch one file
7. Define phase dependencies and checkpoint gates
8. **Preserve stable IDs**: if `specs/NNN-feature-name/tasks.md` already exists,
   read every `TNNN` ID in it before writing. Match each regenerated task to an
   existing task by the outcome it names, not by its wording and not by its
   position in the list. A matched task keeps its existing ID. A task with no
   match gets the next ID above the highest ID the file has ever used. A retired
   ID is never handed to a different task.
9. **Print a diff summary** of the regeneration before writing: the IDs added,
   the IDs removed, and the IDs renumbered. If `specs/NNN-feature-name/progress.yml`
   records a removed or renumbered ID as complete, stop and ask the user to
   confirm; otherwise write the file. When `.claude/hooks/artifact-lint.sh`
   exists in the repository, it rejects the same case after the write.
10. Write to `specs/NNN-feature-name/tasks.md`

## Output

`specs/NNN-feature-name/tasks.md` with phased task breakdown.

## Execution Markers

| Marker | Meaning | Behavior |
|--------|---------|----------|
| `[P]` | Parallel | Can run concurrently with other `[P]` tasks |
| `[TDD]` | Test-Driven | Must follow RED-GREEN-REFACTOR: write test → fail → implement → pass |
| `[REVIEW]` | Review Gate | Pause for human code review before proceeding |
| `[SUBAGENT]` | Subagent | Can be dispatched to a parallel subagent |

## Superpowers Adaptation

When using the `writing-plans` skill, adapt its outputs:
- Implementation blueprints → merge into `specs/NNN/tasks.md` using template structure
- Task dependencies → map to the Dependencies section
- Parallel opportunities → mark with `[P]` and `[SUBAGENT]`

See `references/superpowers-bridge.md` for full adaptation rules.
