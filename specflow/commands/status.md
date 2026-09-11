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
4. Read `progress.yml` in each spec directory, or infer the phase from the files present.
5. Print a status summary:

```
Specflow Project Status
========================
Constitution: Done (2026-04-22)
Superpowers:  brainstorming (detected), writing-plans (not found)

Features:
  001-user-auth    [####------] execute (Phase 5/6) — T012/T019 tasks done
  002-photo-upload [##--------] brainstorm (Phase 2/6) — 2 open questions
  003-settings     [#---------] specify (Phase 1/6) — draft

Suggested next step: /speckit.specflow.execute 001
```

6. If no `.specify/` directory exists, print: "No specflow project found. Run
   `/speckit.constitution` to get started."

## File Inference Fallback

If `progress.yml` is missing, infer the phase from the files present:
- If `spec.md` exists, specify is done.
- If `spec.md` has Brainstorm Log entries, brainstorm ran.
- If `plan.md` exists, plan is done.
- If `tasks.md` exists, tasks is done.
- If `tasks.md` has `[x]` checkboxes, execute is in progress. Count the checked boxes against the total.

## Superpowers Detection

Check for skills at these paths:
1. Check `.agents/skills/{skill-name}/SKILL.md` first, the project-local path.
2. Check `~/.agents/skills/{skill-name}/SKILL.md` second, the user-global path.

The command writes the result to `.specify/superpowers.yml`. Read
`references/superpowers-bridge.md` for the detection and adaptation rules.
