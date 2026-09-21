---
description: Generate phased task breakdown using writing-plans skills
scripts:
  sh: ../../scripts/bash/resolve-template.sh tasks-template --json
  ps: ../../scripts/powershell/resolve-template.ps1 tasks-template -Json
  py: ../../scripts/python/resolve_template.py tasks-template --json
---

# speckit.specflow.tasks

The command builds a phased task breakdown with the writing-plans skill.

## Usage

```
/speckit.specflow.tasks [spec-number|spec-path]
```

## Process

1. **Constitution gate**: Check that `.specify/memory/constitution.md` exists. If
   it is missing, stop with `CONSTITUTION_REQUIRED`, name the missing path, and
   tell the user to run `/speckit.constitution`.
2. **Open questions gate**: Read the `## Open Questions` table in the target
   feature's `spec.md` and count the rows whose Status cell is not `Resolved`.
   If the count is above zero, stop with `OPEN_QUESTIONS`, print the count
   found, print `0` as the count expected, and tell the user to run
   `/speckit.specflow.brainstorm` for this feature. A spec with no
   `## Open Questions` table counts zero rows and passes.
3. Read the spec, plan, and constitution for the target feature
4. Resolve `tasks-template` with the resolver spec-kit installed under
   `.specify/scripts/`, then parse `TEMPLATE_CONTENT`. One variant exists per
   project: `.specify/scripts/bash/resolve-template.sh tasks-template --json`,
   `.specify/scripts/powershell/resolve-template.ps1 tasks-template -Json`, or
   `.specify/scripts/python/resolve_template.py tasks-template --json`. Stop with
   `RESOLVER_REQUIRED` when the resolver fails, name the variant that failed, and
   tell the user to reinstall spec-kit 0.16.2 or newer; reading
   `.specify/templates/tasks-template.md` returns only the core layer.
5. **Superpowers detection**: Check for the `writing-plans` skill
   - **If found**: Read `SKILL.md` for `writing-plans` and follow its task
     decomposition process. Adapt the output to the tasks template structure
   - **If not found**: Build the tasks directly from the plan with the template
6. Organize tasks by phase: Setup → Foundational → User Stories (by priority) → Polish
7. Apply execution markers to each task:
   - `[P]`: runs in parallel with other `[P]` tasks. The tasks touch different
     files and share no dependency
   - `[TDD]`: follows RED-GREEN-REFACTOR discipline
   - `[REVIEW]`: needs a code review before the next task starts
   - `[SUBAGENT]`: may be handed to a subagent
8. **Keep each task singular and checkable**: one outcome per task line. When a
   description needs "and" to state its outcome, split it into two tasks. A
   reader must be able to check whether a task is done without asking a
   follow-up question. A fix, a refactor, and a test count as three tasks, even
   when they touch one file. Give every task a row in the template's
   `## Task Verification` table, whose Verify cell names the command or the
   observation that proves the task is done
9. Define phase dependencies and checkpoint gates
10. **Preserve stable IDs**: if `specs/NNN-feature-name/tasks.md` already exists,
   read every `TNNN` ID in it before writing. Match each regenerated task to an
   existing task by the outcome it names, not by its wording and not by its
   position in the list. A matched task keeps its existing ID. A task with no
   match gets the next ID above the highest ID the file has ever used. A retired
   ID is never handed to a different task.
11. **Print a diff summary** of the regeneration before writing: list the IDs
    added, the IDs removed, and the IDs renumbered. If
    `specs/NNN-feature-name/progress.yml` marks a removed or renumbered ID as
    complete, stop and ask the user to confirm; otherwise write the file. The
    `artifact-lint.sh` hook, in this repository only, rejects the same case
    after the write.
12. Write to `specs/NNN-feature-name/tasks.md`

## Output

The command writes the phased task breakdown to `specs/NNN-feature-name/tasks.md`.

## Execution Markers

| Marker | Meaning | Behavior |
|--------|---------|----------|
| `[P]` | Parallel | Can run at the same time as other `[P]` tasks |
| `[TDD]` | Test-Driven | Must follow RED-GREEN-REFACTOR: write test → fail → implement → pass |
| `[REVIEW]` | Review Gate | Pauses for a human code review before the next task starts |
| `[SUBAGENT]` | Subagent | May be dispatched to a parallel subagent |

## Skill Mode Behavior

Adapt the output of the `writing-plans` skill this way:
- Implementation blueprints go into `specs/NNN/tasks.md`, in the template structure
- Task dependencies map to the Dependencies section
- Parallel opportunities get the `[P]` and `[SUBAGENT]` markers

See `references/superpowers-mapping.md` for the full adaptation rules.
