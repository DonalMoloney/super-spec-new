# Model and effort per open group

Read this before starting a roadmap group from `tasks.md`. It names the model and
the reasoning effort to run each remaining group at, and why. Groups G-01 through
G-05, G-06, G-08, G-11, G-12, G-13, G-14, G-16, G-17, and G-18 are merged and
are not listed. Status was checked against `main` on 2026-09-11.

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

| Group | Open tasks | Executor | Model | Effort | Status |
|---|---|---|---|---|---|
| G-07 observability Stop hook | T071, T072, T073 | `bdd-orchestrator` | sonnet | low | claimed |
| G-09 CI merge-gate workflow | T091, T092, T093, T094 | `bdd-orchestrator` | opus | medium | free |
| G-10 STRIDE and traceability in templates | T101, T102, T103, T104 | `general-purpose` | sonnet | low | claimed |
| G-15 differential implementation | T151, T152, T153 | `bdd-orchestrator` | opus | high | free |

A claimed group has a worktree and a `(working on)` marker in `tasks.md`. A free
group has no unmet dependency. No group is part-finished on `main`: every open
task in the table is at task 1.

## Merged

| Group | PR | Check that proves it |
|---|---|---|
| G-06 risk classifier and merge gate | #30 | `.claude/hooks/risk-classifier.sh` and `.claude/hooks/merge-gate.sh` exist; `git check-ignore .claude/review/claude.json` prints the path |
| G-11 spec change management | #32 | `## Changelog` in `specflow/templates/spec-template.md`; `## Hotfix path` in `specflow/references/workflow-guide.md` |
| G-12 resumable sessions | #22 | `.claude/hooks/session-start.sh` exists; `jq .hooks.SessionStart .claude/settings.json` prints the `resume` and `compact` entries |
| G-13 golden-run scorer | #20 | `specflow/scripts/score-artifacts.py`, `specflow/examples/seeded-bug/`, and `specflow/.github/workflows/score-artifacts.yml` exist |
| G-14 Agent Teams | #17 | `jq .env .claude/settings.json` prints `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` |
| G-16 cost governance | #27 | `## Budgets` in `specflow/references/workflow-guide.md`; `.claude/agents/bdd-orchestrator.md` cites that table |

## Dispatched now

Claim a group here and in `tasks.md` before creating its worktree, so a second
session does not start the same group.

- **G-07** runs on branch `g-07-observability-hook`.
- **G-10** runs on branch `g-10-stride-traceability`.

G-06 merged in PR #30, so G-09 has no unmet dependency. G-09 and G-15 are free
to start.

## Why each group sits where it does

- **G-07, low.** Transcribe Part 4.5, correct the paths to `.claude/`, add one
  test case. `jq .hooks.Stop .claude/settings.json` passes or fails the same way
  at any effort.
- **G-09, medium.** The workflow composes G-05 and G-06, and T092 depends on
  flag names that must come from `claude-code-guide` rather than from memory.
  Two conditionals must gate the right steps.
- **G-10, low.** Markdown sections written against `standards/documentation.md`.
  The shape of a STRIDE section is settled before the work starts.
- **G-15, high.** Two worktrees, a cross-test step, and a trigger rule that no
  source states. The least specified group in `tasks.md`.

## Applying it

Set the session model and effort before dispatching the group's agent, then
create the worktree as `AGENTS.md` describes. A subagent with an explicit model
in `tasks.md` keeps that model; effort comes from the dispatching session.
