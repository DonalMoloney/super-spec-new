# Model and effort per open group

Read this before starting a roadmap group from `tasks.md`. It names the model and
the reasoning effort to run each remaining group at, and why. Only G-09 and
G-15 are open; every other group is merged. Status was checked against `main`
on 2026-09-11.

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
| G-09 CI merge-gate workflow | T091, T092, T093, T094 | `bdd-orchestrator` | opus | medium | claimed |
| G-15 differential implementation | T153 only | `bdd-orchestrator` | opus | high | blocked |

A claimed group has a worktree and a `(working on)` marker in `tasks.md`.
Neither open group is part-finished on `main`: both are at task 1.

## Merged

| Group | PR | Check that proves it |
|---|---|---|
| G-06 risk classifier and merge gate | #30 | `.claude/hooks/risk-classifier.sh` and `.claude/hooks/merge-gate.sh` exist; `git check-ignore .claude/review/claude.json` prints the path |
| G-07 observability Stop hook | #31 | `.claude/hooks/log-phase.sh` exists; `jq .hooks.Stop .claude/settings.json` calls it |
| G-10 STRIDE and traceability in templates | #33 | `## Threat Model` and `## Traceability` in `specflow/templates/spec-template.md`; CHK024 and CHK064 in `checklist-template.md` |
| G-11 spec change management | #32 | `## Changelog` in `specflow/templates/spec-template.md`; `## Hotfix path` in `specflow/references/workflow-guide.md` |
| G-12 resumable sessions | #22 | `.claude/hooks/session-start.sh` exists; `jq .hooks.SessionStart .claude/settings.json` prints the `resume` and `compact` entries |
| G-13 golden-run scorer | #20 | `specflow/scripts/score-artifacts.py`, `specflow/examples/seeded-bug/`, and `specflow/.github/workflows/score-artifacts.yml` exist |
| G-14 Agent Teams | #17 | `jq .env .claude/settings.json` prints `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` |
| G-16 cost governance | #27 | `## Budgets` in `specflow/references/workflow-guide.md`; `.claude/agents/bdd-orchestrator.md` cites that table |

## Dispatched now

Claim a group here and in `tasks.md` before creating its worktree, so a second
session does not start the same group.

- **G-09** runs in `~/PycharmProjects/worktrees/g-09-merge-gate-ci` on branch
  `g-09-merge-gate-ci`, dispatched 2026-09-11.
- **G-15** merged its script and protocol in PR #44. T153 is blocked on a Codex
  account usage limit, so the group has no worktree now.

## Why each group sits where it does

- **G-09, medium.** The workflow composes G-05 and G-06, and T092 depends on
  flag names that must come from `claude-code-guide` rather than from memory.
  Two conditionals must gate the right steps.
- **G-15, high.** The script and the protocol merged in PR #44. T153 needs a
  live Codex run, so it waits on the account limit, not on effort.

## Applying it

Set the session model and effort before dispatching the group's agent, then
create the worktree as `AGENTS.md` describes. A subagent with an explicit model
in `tasks.md` keeps that model; effort comes from the dispatching session.
