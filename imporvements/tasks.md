# Roadmap task groups

The first wave, G-01 to G-18, merged between PR #8 and PR #53 on 2026-09-11.
This file holds the second wave. `divergence-by-part.md` holds the option
space each group draws from and the D-items other sessions hold right now;
`cleanup.md` holds hygiene debt that needs no design. Status was checked
against `main` at `0206c59`.

## How to use this file

- **One group = one git worktree = one PR.** Groups are independent unless a
  `Depends on:` line says otherwise.
- Tasks inside a group are sequential. Each task is singular and ends with a
  `Verify:` line that proves it done. Task IDs are `T<group><n>`, so `T191` is
  group 19 task 1. Tick the box when its Verify line passes.
- Every group names its executor, model, and effort. The model routes the
  subagent under ADR-0003 and ADR-0014; the effort sets the dispatching session.
- Before creating a worktree, append `(working on)` to the group header and
  commit that to `main`, so a second session does not start the same group.
- After merge: remove the worktree, mark the header `(merged: PR #N)`, and
  record any non-obvious choice in `decisions.md`.
- A shipped file under `specflow/` runs on the Copilot CLI as well as Claude
  Code. A group that adds a step to a command needs a fallback that works with
  no hooks, no subagents, and no `model:` frontmatter.
- Do not touch a file a D-item holds. The Claimed now table in
  `divergence-by-part.md` lists them; D-01 and D-05 have live worktrees.
- `imporvements2.md` Part 9 holds items 23 to 36, scoped but not yet
  decomposed. A new group for one of them starts at G-24.

## Executor legend

| Label | What it is | When to use |
|---|---|---|
| `bdd-orchestrator` | Full BDD squad, ends with `work-verifier` | Any group that adds or changes a script, hook, or CI job |
| `general-purpose` | Single Claude agent, all tools | Command, template, and reference edits with no runnable test beyond the validators and the smoke test |
| `prose-rephraser` | Rewrites one shipped file's wording | A group whose only move is wording |
| `work-verifier` | Adversarial re-check of a completion claim | Final step of every group before opening the PR |

## Effort

| Effort | Use when |
|---|---|
| low | Every `Verify:` line is mechanical: a grep count, a YAML key, a test name. |
| medium | The group ports an existing design and at least one choice has no stated answer. |
| high | The group invents the design. The `Verify:` line checks that a section exists, not that it is right. |

## G-19 — Examples produced by this fork, not upstream

Source: `divergence-by-part.md`, examples/. Executor: `bdd-orchestrator`.
Model: opus. Effort: high. Depends on: none. D-06 and D-07 merged, so the
snapshot will show the marker column and the compound-task stop.

`examples/static-landing-page/` is upstream's snapshot and predates every gate
marker, the Threat Model and Traceability sections, and the Changelog section.
`sample-workflow.md` is upstream's prose walkthrough of a feature no snapshot
contains. The scorer's golden is the upstream snapshot.

- [ ] T191 Record a fresh run of the current pipeline

Drive `e2e-agent-claude.sh` live on a feature of this fork's choosing, not a
landing page, and snapshot it under `examples/<feature>/`. Verify: the
snapshot carries `.clarified`, `.analyzed`, `## Threat Model`,
`## Traceability`, and `## Changelog`.

- [ ] T192 Point the scorer golden at the new snapshot

Verify: `score-artifacts.py` passes on the new snapshot and
`score-artifacts.yml` replays it.

- [ ] T193 Add a failing-gate snapshot

Record a run that stops with `ANALYZE_REQUIRED` and the rerun that clears it.
Verify: the snapshot contains the stop code and the rerun.

- [ ] T194 Delete `static-landing-page/` and `sample-workflow.md`

Update `README.md` and the dry run, which copies the snapshot. Verify:
`E2E_DRY_RUN=1 e2e-agent-claude.sh` exits 0 and `grep -r static-landing-page
specflow/` prints nothing.

## G-20 — Brainstorm writes decisions

Source: `divergence-by-part.md`, commands/. Executor: `general-purpose`.
Model: sonnet. Effort: medium. Depends on: none.

G-17 made `brainstorm.md` read `decisions.md`. Nothing writes to it.

- [ ] T201 Write a resolved question as an ADR-lite entry

Add a Process step that appends a Context, Decision, Consequences entry to
`decisions.md` for each Open Questions row the run marks Resolved, numbered
after the highest existing ADR. Verify: the step names the file and the shape,
and `e2e-smoke.sh` passes.

- [ ] T202 Assert the write in the dry run

Verify: the brainstorm stage assertion checks that a resolved fixture row
lands in `decisions.md`.

## G-21 — Templates carry their own checks

Source: `divergence-by-part.md`, templates/. Executor: `general-purpose`.
Model: sonnet. Effort: medium. Depends on: none.

- [ ] T211 Add a Verify column to `tasks-template.md`

Match the shape this file uses. Verify: the template's task table header
carries the column and `score-artifacts.py` still parses the golden.

- [ ] T212 Add a review-stage table to `constitution-template.md`

Three rows (pre-mortem, single reviewer, panel) and a model class per row
(fast, standard, strongest). No agent alias, per constraint 3 in
`divergence-by-part.md`. Verify: `grep -E 'opus|sonnet|haiku'` on the
template prints nothing.

- [ ] T213 Add an `R-NNN` column to `checklist-template.md`

Joins the `CHK` row ids to review finding ids. Verify: the column exists and
the dry run's checklist assertion passes.

## G-22 — SKILL.md and the bridge reference name the gates and the personas

Source: `divergence-by-part.md`, SKILL.md and references/. Executor:
`general-purpose`, then `prose-rephraser`. Model: sonnet. Effort: low.
Depends on: none. D-03 (PR #59) added the Target surface section to `SKILL.md`.

`SKILL.md` is the largest behavior contract in the extension and is
byte-identical to upstream.

- [ ] T221 Name the gate marker each phase produces

Add the marker to each phase line under `## Unified Workflow` in `SKILL.md`.
Verify: every marker in the Gate markers table of `workflow-guide.md` appears
in `SKILL.md` by grep.

- [ ] T222 Map the review personas in `superpowers-bridge.md`

One row per `.claude/agents/*-reviewer.md` file, naming the
`requesting-code-review` step it replaces on Claude Code and the skill step
Copilot runs instead. Verify: eight rows.

- [ ] T223 Rewrite `SKILL.md` prose to `standards/documentation.md`

Verify: `divergence-auditor` reports a higher real percent and every guard
green.

## G-23 — The smoke test catches a dropped step and upstream drift

Source: `divergence-by-part.md`, scripts/. Executor: `bdd-orchestrator`.
Model: sonnet. Effort: low. Depends on: none. The Copilot install layout is
already asserted (PR #59).

- [ ] T231 Assert the Process-step count of each command file

Read the count from a table at the top of `e2e-smoke.sh`. Verify: deleting
one step from any command fails the smoke test.

- [ ] T232 Add `.claude/divergence/check-upstream.sh`

Print the vendored commit, `git ls-remote` upstream `HEAD`, and exit 1 when
they differ. Upstream `HEAD` was still `c20ac6c` on 2026-09-11. Verify: a
hook test stubs `git ls-remote` and checks both exits.

- [ ] T233 Run the drift check weekly in CI

A scheduled workflow that opens one issue when the script exits 1 and none
when an open issue already exists. Verify: the workflow file exists and is
`schedule`-triggered.

## Deferred (no steps yet)

- **Multi-feature concurrency** (first-wave item 11): revisit after G-14's
  `[P]` dispatch has run on three features. None has run yet.
- **Mutation-testing gate** (first-wave Item 16): PR #64 added
  `.claude/hooks/mutation-gate.sh` and a sample project under
  `specflow/examples/mutation-gate-sample/` to run it on. Still open: the
  `merge-gate.yml` mutation step uses a mutmut 2 flag that mutmut 3 rejects;
  replace its run line with `bash .claude/hooks/mutation-gate.sh <project-dir>`
  in the CI wave.
- **Replace `execute.md` with a squad dispatcher**: the one Replace move worth
  taking, and only after G-19 gives it a snapshot to assert against on both
  runtimes.
- **A `before_tasks` hook** that stops on unresolved Open Questions: same
  cost class as a sixth command, because three files assert the hook count.
- **Copilot CLI run snapshot** under `examples/`: needs the Copilot e2e
  script, playbook Part 9 item 27.

## Suggested order

1. G-20, G-21, G-22, and G-23 now, in parallel worktrees. None touches a file
   D-01 or D-05 holds.
2. G-19 last, so its snapshot records every gate the other groups add.
