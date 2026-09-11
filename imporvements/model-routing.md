# Model and effort per open group

Read this before starting a roadmap group from `tasks.md`. It names the model and
the reasoning effort to run each remaining group at, and why. Groups G-01 through
G-05, G-08, G-13, G-14, G-17, and G-18 are merged and are not listed.

`tasks.md` already carries a `Model:` line per group under ADR-0003, which routes
the subagent. Effort is the second dial and ADR-0003 does not cover it. Where the
two disagree, the `Model:` line in `tasks.md` wins for the subagent and this file
sets the effort of the session that dispatches it.

## How to read the effort column

| Effort | Use when |
|---|---|
| low | Every `Verify:` line in the group is mechanical: a `jq` key, a `grep` count, a YAML parse. Thinking longer changes nothing. |
| medium | The group ports or composes an existing design and at least one decision has no stated answer. |
| high | The group invents the design. The `Verify:` line checks that a section exists, not that it is right. |

## Routing

| Group | Open tasks | Executor | Model | Effort |
|---|---|---|---|---|
| G-06 risk classifier and merge gate | T061, T062, T063 | `bdd-orchestrator` | opus | medium |
| G-07 observability Stop hook | T071, T072, T073 | `bdd-orchestrator` | sonnet | low |
| G-09 CI merge-gate workflow | T091, T092, T093, T094 | `bdd-orchestrator` | opus | medium |
| G-10 STRIDE and traceability in templates | T101, T102, T103, T104 | `general-purpose` | sonnet | low |
| G-11 spec change management | T111, T112, T113, T114 | `bdd-orchestrator` | opus | medium |
| G-12 resumable sessions | T121, T122, T123 | `bdd-orchestrator` | opus | medium |
| G-15 differential implementation | T151, T152, T153 | `bdd-orchestrator` | opus | high |
| G-16 cost governance | T161, T162 | `documentation-scribe` | haiku | low |

## Dispatched now

Claim a group here and in `tasks.md` before creating its worktree, so a second
session does not start the same group.

- **G-06** runs in `~/PycharmProjects/worktrees/g-06-merge-gate` on branch
  `g-06-merge-gate`, dispatched 2026-09-11.
- **G-11** runs in `~/PycharmProjects/worktrees/g-11-spec-change` on branch
  `g-11-spec-change-management`, dispatched 2026-09-11.
- **G-12** carries `(working on)` in `tasks.md` from an earlier session.

G-09 depends on G-06, so it opens once G-06 merges. G-07, G-10, G-15, and G-16
are free to start.

## Why each group sits where it does

- **G-06, medium.** Part 4.10 ships the classifier in a form that uses `bc`.
  Rewriting it in pure bash arithmetic and deciding what a rebutted Important
  finding does to the exit code are both judgment calls against the G-05 schema.
  Three tasks, all covered by hook tests.
- **G-07, low.** Transcribe Part 4.5, correct the paths to `.claude/`, add one
  test case. `jq .hooks.Stop .claude/settings.json` passes or fails the same way
  at any effort.
- **G-09, medium.** The workflow composes G-05 and G-06, and T092 depends on
  flag names that must come from `claude-code-guide` rather than from memory.
  Two conditionals must gate the right steps.
- **G-10, low.** Markdown sections written against `standards/documentation.md`.
  The shape of a STRIDE section is settled before the work starts.
- **G-11, medium.** T112 changes a behavior contract inside
  `specflow/commands/tasks.md`: stable `TNNN` IDs must survive regeneration, and
  T114 lints that they did. Read the Process steps in full first.
- **G-12, medium.** The hook is short. Choosing what a resumed session needs on
  screen is the work, and the `compact|resume` matcher must be confirmed against
  current documentation.
- **G-15, high.** Two worktrees, a cross-test step, and a trigger rule that no
  source states. The least specified group in `tasks.md`.
- **G-16, low.** A table of per-phase ceilings plus one line in
  `bdd-orchestrator.md`. Already routed to haiku by ADR-0003.

## Applying it

Set the session model and effort before dispatching the group's agent, then
create the worktree as `AGENTS.md` describes. A subagent with an explicit model
in `tasks.md` keeps that model; effort comes from the dispatching session.
