# speckit.specflow.status

Print the project's progress, each feature's phase, and the superpowers detection result.

## Usage

```
/speckit.specflow.status [spec-number|all]
```

## Process

1. Scan the `.specify/` directory tree.
2. Check whether `constitution.md` exists.
3. **Run superpowers detection**: Check for all superpowers skills at
   `.agents/skills/` and `~/.agents/skills/`. Write the result to
   `.specify/superpowers.yml`.
4. Read `progress.yml` in each spec directory, or infer the phase from the files
   present. Record which of `.clarified` and `.analyzed` exist beside `spec.md`.
5. Print a status summary:

```
Specflow Project Status
========================
Constitution: Done (2026-04-22)
Superpowers:  brainstorming (detected), writing-plans (not found)

Features:
  001-user-auth    [####------] execute (Phase 5/6), gates: clarified, analyzed, T012/T019 tasks done
  002-photo-upload [##--------] brainstorm (Phase 2/6), gates: none, 2 open questions
  003-settings     [#---------] specify (Phase 1/6), gates: none, draft

Suggested next step: /speckit.specflow.execute 001
```

6. Pick the suggested next step from the gates: a feature with `tasks.md` and no
   `.analyzed` gets `/speckit.analyze NNN`; a feature with `spec.md` and no
   `.clarified` gets `/speckit.clarify NNN`; otherwise the next workflow command
   for its phase. Suggest the step for the feature furthest along.
7. If no `.specify/` directory exists, print: "No specflow project found. Run
   `/speckit.constitution` to get started."

## File Inference Fallback

If `progress.yml` is missing, infer the phase from the files present:
- If `spec.md` exists, specify is done.
- If `spec.md` has Brainstorm Log entries, brainstorm ran.
- If `.clarified` exists beside `spec.md`, clarify is done; if `.analyzed` exists, analyze is done.
- If `plan.md` exists, plan is done.
- If `tasks.md` exists, tasks is done.
- If `tasks.md` has `[x]` checkboxes, execute is in progress. Count the checked boxes against the total.

## Superpowers Detection

Check for skills at these paths:
1. Check `.agents/skills/{skill-name}/SKILL.md` first, the project-local path.
2. Check `~/.agents/skills/{skill-name}/SKILL.md` second, the user-global path.

The command writes the result to `.specify/superpowers.yml`. Read
`references/superpowers-mapping.md` for the detection and adaptation rules.
