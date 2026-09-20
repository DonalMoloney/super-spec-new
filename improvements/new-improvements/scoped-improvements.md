# Scoped improvements, second wave

This file lists changes that make specflow better as a product and, where
marked, move it further from upstream superspec. It holds only work that
`roadmap.md` does not: every finding the roadmap already covers is mapped to
its item in the table under "Already on the roadmap" and not repeated. Read it
beside `roadmap.md` when picking the next group; as of 2026-09-20, D-01, D-05,
and G-20 to G-42 have merged, leaving G-19, G-26, and G-43 open there. Every
number below was measured on 2026-09-20 at commit `ff774c2`, except the
"Measured state" table, refreshed the same day against `4404835`.

Each item is one outcome. It carries a Move tag from `reference.md` (Tighten,
Extend, Add, Replace, Remove), an effort, its dependencies, whether it changes
a shipped file (Diverges: yes) or only repository tooling (Diverges: no), and
a `Verify:` line. No claim or checkbox lives here (ADR-0017): claiming an item
means turning it into a `roadmap.md` group numbered G-24 or later, and the
group carries the claim.

## Measured state

| Check | Result at `4404835` |
|-------|---------------------|
| `validate-extension-metadata.py` | OK |
| `validate-release-archive.py` | within every limit, 26 entries |
| `.claude/hooks/tests/run.sh` | 223 passed, 0 failed, 8 skipped; the eight are `mutation-gate.sh` cases, now skipped rather than failed when mutmut is absent, closed as G-44 |
| `pytest` over the four test dirs | 113 passed |
| `lint-standards.py` | 67 files, 0 findings |
| `shellcheck -S warning` | 0 findings |
| `E2E_DRY_RUN=1 e2e-agent-claude.sh` | 30 assertions against the snapshot |
| `e2e-smoke.sh` | 55/55 passed |
| `ruff check` | not run locally, `ruff` not installed here; CI runs it |

The first wave, G-01 to G-18, and the cleanup wave, Q-01 to Q-28, are merged.
`roadmap.md` now carries D-01, D-05, G-20 to G-25, G-28 to G-42, and G-44 as
merged, G-19, G-26, and G-43 as open, C-01 to C-09 as closed hygiene, and a
scoped backlog of items 23, 25 to 28, and 31 to 36 (24, 29, and 30 promoted
to G-36, G-37, and G-38 and merged).

`reference.md` carries the per-file divergence table measured for PR #72.
Re-measured at `ff774c2` the numbers match. Three shipped files stay at 0%
real change (`extension.yml`, `CHANGELOG.md`, `commands/hooks/after-tasks.md`),
`README.md` stands at 100%, and seven files plus one example directory have no
upstream counterpart: `references/copilot-cli.md`, `scripts/lint-standards.py`,
`scripts/score-artifacts.py`, four test files, and `examples/seeded-bug/`.
Upstream `HEAD` is still `c20ac6c` of 2026-08-13.

### What moved underneath

Upstream targets spec-kit 0.x and superpowers 6.0. Both dependencies moved,
and upstream cannot follow because it is frozen. Every item in the first two
sections below is divergence by construction.

| Dependency | Upstream assumes | Today |
|------------|------------------|-------|
| spec-kit version | 0.x | 1.0.9.dev0 at `d4229c0`, 2026-09-18 |
| Core commands | 8 | 10, adding `converge` and `taskstoissues` |
| Hook events fired by core commands | 3 used | 20 available, `before_` and `after_` for every core command |
| Template resolution | copy into `.specify/templates/` | runtime stack: overrides, presets, `.specify/extensions/<id>/templates/`, core |
| Manifest fields | schema 1.0 basics | adds `category`, `effect`, `aliases`, `provides.scripts[].runtimes`, hook `priority`, hook lists |
| Packaging | extension only | extensions, presets with `append`/`prepend`/`wrap`, workflows with 12 step types, bundles |
| superpowers | 6.0, 6 skills mapped | 6.3.0, 14 skills; 6 that apply to this workflow are unmapped |

The community catalog lists a competing `speckit-superpowers-bridge` (v1.2.0),
a `bdd` extension, a `pipeline` workflow that chains specify, clarify, plan,
tasks, analyze, implement, and converge, and two governance bundles
(`sicario-spec` with threat modeling, `specassay` with durable IDs). Specflow is
in none of the catalogs; backlog item 23 covers the entry.

### Already on the roadmap

Findings from this survey that `roadmap.md` already carries. Work them there.

| Finding | Roadmap item |
|---------|--------------|
| `after-tasks.md` never reads `progress.yml` | D-01 |
| Manifest strings, schema title, dead validator branch, no CHANGELOG Unreleased section | D-05a to D-05d |
| The snapshot predates the gates and `sample-workflow.md` walks the upstream flow | G-19 |
| The bridge does not name the review personas | G-22 T222 |
| The smoke test misses a dropped Process step | G-23 T231 |
| A `before_tasks` hook on open questions | Deferred; N-10 closed as G-24 T241, so the cost it was deferred on is gone |
| Gate hooks on the Copilot CLI | Backlog 28; N-03 ships the scripts it would register |
| A reviewer scorecard | Backlog 31 |
| Cost per feature against the Budgets table | Backlog 32; it reads `.specify/telemetry.jsonl`, which N-21 already corrected (G-24 T247) |
| The mutation step in `merge-gate.yml` uses a mutmut 2 flag | Deferred |
| Command and hook counts hard-coded in four files | N-10, closed as G-24 T241 |
| Two install-time breaks in `SKILL.md` (a stripped asset link, `description_zh`) | N-19, closed as G-24 T248 |
| `SKILL.md` and `workflow-guide.md` describe copying templates into `.specify/templates/` | N-20, closed as G-24 T242 to T244 |
| The Budgets section of `workflow-guide.md` names a TBD flag and the wrong telemetry path | N-21, closed as G-24 T247 |
| `.github/copilot-instructions.md` states the wrong agent count | N-22, closed as G-24 T249 |
| Mutation-gate hook cases fail rather than skip without mutmut | N-23, closed as G-44 |

## N-01 to N-10: follow spec-kit 1.0

- **N-01** Add one command, `speckit.specflow.gate`, that writes a gate
  marker: `.clarified` when the spec holds no `NEEDS CLARIFICATION` marker,
  `.analyzed` when the analysis reported zero critical inconsistencies.
  Register it on `after_clarify` and `after_analyze` with `optional: false`.
  Today the markers exist only as a prose rule in the workflow guide that the
  agent has to remember; spec-kit fires both events and nothing listens.
  Move: Add. Effort: medium. Depends on: N-10 (done). Diverges: yes.
  Verify: `e2e-smoke.sh` installs the command on both surfaces and the manifest
  lists five hooks.
- **N-02** Register the same command on `before_tasks` so it stops with
  `OPEN_QUESTIONS` while the spec's Open Questions table has a row whose Status
  is `Open`. `roadmap.md` defers this hook on the cost of the count
  assertions, which N-10 removes. Move: Extend. Effort: low. Depends on: N-01.
  Diverges: yes. Verify: a fixture spec with one open row fails the dry-run
  e2e stage for tasks.
- **N-03** Ship the gate scripts inside the extension as `provides.scripts`
  under `gates/bash/`, with `runtimes: [bash]`: `risk-classifier`,
  `merge-gate`, and a `write-marker` script for N-01. The `git` extension
  bundled with spec-kit ships bash, PowerShell, and Python variants this way,
  and spec-kit's core commands name theirs in a `scripts:` frontmatter block
  the agent runs first. Today `review.md` line 29 says "when
  `.claude/hooks/risk-classifier.sh` exists", which is never true on the
  Copilot CLI. The `.claude/hooks/` copies stay for this repository's own
  hooks and call the shipped scripts; backlog item 28 then has scripts to
  register on the Copilot side. Move: Add. Effort: medium. Depends on: none.
  Diverges: yes. Verify: `git archive HEAD:specflow | tar -t` lists
  `gates/bash/risk-classifier.sh`; the Copilot leg of `e2e-smoke.sh` finds it
  under `.specify/extensions/specflow/gates/`.
- **N-04** Ship the findings contract. Move `.claude/review/schema.json` to
  `specflow/references/review-findings.schema.json`, make `review.md` and the
  eight reviewer agents cite that path, and add a `validate-findings` Python
  script to `provides.scripts` with `runtimes: [python]`. A Copilot user today
  has a command that writes a JSON shape with no schema to check it against.
  Move: Add. Effort: low. Depends on: D-05a, N-03. Diverges: yes. Verify:
  `grep -rl 'claude/review/schema.json' specflow/` prints nothing;
  `.claude/review/tests` pass against the moved file.
- **N-05** Bring `extension.yml` to the current manifest schema: add
  `category: "process"` and `effect: "read-write"`, raise `speckit_version`
  to `>=0.14.4` (the release that made template resolution a runtime stack,
  the behavior N-20 documents), give each hook a `priority`, and add
  `copilot` and `claude-code` to `tags`. D-05d owns the wording of the
  strings; this item owns the fields. Move: Tighten. Effort: low. Depends on:
  D-05d. Diverges: yes. Verify: both validators pass and
  `specify extension info specflow` prints the category.
- **N-06** Ship the seven-stage flow as a spec-kit workflow at
  `specflow/workflow/workflow.yml`, id `specflow`: command steps for
  constitution, specify, clarify, brainstorm, plan, tasks, analyze, execute,
  and review; a `gate` step after specify (spec approval) and after review
  (merge approval); a `shell` step that runs the shipped merge gate; a
  `while` loop capped at three iterations around review for the critic
  rounds; a `fan-out` step over `[P]` tasks. The engine persists state per
  step and runs shell steps on every integration, so the gates that today run
  only as Claude Code hooks run on the Copilot CLI too. Upstream ships no
  workflow. Move: Add. Effort: medium. Depends on: N-03. Diverges: yes.
  Verify: `specify workflow add ./specflow/workflow --dev` then
  `specify workflow validate specflow` exit 0 in CI.
- **N-07** Settled as G-25 (merged: `41b33e5`). ADR-0021 keeps the five
  templates full replacements; the preset was measured and rejected. Backlog
  item 25 is the standing alternative, reporting drift instead of ending it.
- **N-08** Ship `specflow/bundle.yml` composing the extension and the workflow
  from N-06, with `role: developer`. No preset to compose: ADR-0021 (N-07)
  rejected it. Add `specify bundle validate --path specflow --offline` and
  `specify bundle build` to CI, and check the built ZIP against
  `validate-release-archive.py`'s limits. Move: Add. Effort: low. Depends on:
  N-06, G-36 (merged, formerly backlog item 24). Diverges: yes. Verify: both
  bundle commands exit 0 in CI and the artifact stays under 50 MiB.
- **N-09** Register `after_converge` on `speckit.specflow.tasks`, optional.
  Spec-kit's `converge` command appends unbuilt work to `tasks.md`; the
  singular-task rule at step 6 and the stable-ID rule at steps 8 and 9 of
  `tasks.md` then apply to the appended lines. Without it a Copilot run gets
  unchecked compound tasks after every converge. Move: Extend. Effort: low.
  Depends on: N-10 (done). Diverges: yes. Verify: a fixture `tasks.md` with one
  converge-appended compound line is split by the dry-run tasks stage.

- **N-10** Closed as G-24 T241 (merged, `f68f45c`). `e2e-smoke.sh` and
  `ci.yml` now read `extension.yml` instead of repeating its counts.

## N-11 to N-14: follow superpowers 6.3

- **N-11** Route execute by surface in `superpowers-mapping.md`. Superpowers
  6.x reserves `executing-plans` for a runtime without subagents and requires
  `subagent-driven-development` where subagents exist. The mapping table
  lists both for execute with no rule. Add a surface column: Claude Code takes
  `subagent-driven-development`, the Copilot CLI takes `executing-plans`.
  Move: Tighten. Effort: low. Depends on: none. Diverges: yes. Verify: the
  execute rows name one skill per surface and `copilot-cli.md` agrees.

- **N-12** Classify the request in `brainstorm.md` before questioning:
  spike, bounded, or architectural, as superpowers 6.3 brainstorming does.
  A spike records the question and the answer in the Brainstorm Log and asks
  nothing else; bounded runs the five categories once; architectural runs
  them all and may loop. Record the class in the log entry. The dispatcher
  skill already says a spike skips brainstorming; the command does not know
  the word. Move: Extend. Effort: low. Depends on: none. Diverges: yes.
  Verify: `grep -c 'spike' specflow/commands/brainstorm.md` prints at least 1
  and the dry-run e2e passes.
- **N-13** Map the six unmapped skills that apply: `systematic-debugging` to
  the hotfix path, `verification-before-completion` to every execute
  checkpoint and to review step 5, `using-git-worktrees` to `[P]` dispatch
  and to differential implementation, `dispatching-parallel-agents` to a
  `[P]` batch, `receiving-code-review` to the fix loop after a findings file,
  and `finishing-a-development-branch` to a `CLEAN` verdict. Each row names a
  built-in fallback. Grow the detection list in `status.md` step 3 and the
  `superpowers.yml` example from 6 skills to 12. Move: Extend. Effort:
  medium. Depends on: none. Diverges: yes. Verify: the skill names in the
  bridge table and in `status.md` are the same set of 12 by grep.
- **N-14** Make the `[SUBAGENT]` path in `execute.md` name the two reviews
  superpowers 6.x adds: a task reviewer after each task (spec compliance and
  code quality) and a whole-branch reviewer at the end, both writing findings
  in the `review-findings.json` shape. Today line 36 says "follow its
  dispatch protocol", so a 6.0 run and a 6.3 run produce different evidence.
  Backlog item 35 records which superpowers range was tested; this item
  makes the command's expectation explicit. Move: Tighten. Effort: low.
  Depends on: none. Diverges: yes. Verify: `execute.md` names both reviewers
  and the dry-run e2e passes.

## N-15 to N-18: gates and measurements that exist only in prose

- **N-15** Read the test command from the constitution. `test-gate.sh`
  defaults to this repository's metadata validator, so a consuming project
  gets a gate that tests nothing unless it sets `SPECFLOW_TEST_CMD`. Parse the
  `Test command` line of the Code Review Rules section first, then the
  variable, then the default. Move: Tighten. Effort: low. Depends on: none.
  Diverges: no. Verify: a hook test with a fixture constitution runs the
  command the constitution names.
- **N-16** Read the phase from `progress.yml`. `log-phase.sh` reads
  `.claude/.current-phase`, which no command writes; 97 of the 97 telemetry
  lines on this machine say `unknown`, so backlog item 32 would sum cost
  against a phase it cannot see. Fall back to `current_phase` in the newest
  `specs/*/progress.yml`, the same file `session-start.sh` already picks.
  Move: Tighten. Effort: low. Depends on: none. Diverges: no. Verify: a hook
  test with a fixture `progress.yml` logs its phase name.
- **N-17** Score the sections the scorer ignores. `score-artifacts.py`
  grades three mandatory sections, traceability, task IDs, and markers. Add
  three dimensions: every Threat Model row filled or marked N/A, every Open
  Questions row `Resolved` when `.clarified` exists, and at least one
  Changelog row. Add the expectation rows to `score-artifacts.yml`. Backlog
  items 33 and 34 add a fourth and fifth dimension and can share the change.
  Move: Extend. Effort: medium. Depends on: none. Diverges: no. Verify: the
  golden scores 100 on the three new dimensions and a seeded variant with one
  empty STRIDE row scores below 100.
- **N-18** Give the eight reviewer agents a body. `critic.md` is 8 lines and
  `spec-red-team-reviewer.md` is 11, against 55 to 77 for the BDD squad.
  Each reviewer gets the When to invoke, Process, and Output format headings,
  the findings schema path from N-04, the two standards paths, and the rule
  that a finding without `file:line` and evidence is dropped. Move: Tighten.
  Effort: medium. Depends on: N-04. Diverges: no. Verify: every
  `*-reviewer.md` and `critic.md` has the three headings and
  `lint-standards.py .claude/agents` exits 0.

## N-19 to N-22: docs that state something false

All four closed as G-24 tasks, merged. See the "Already on the roadmap" table.

- **N-19** Closed as G-24 T248 (`4d9d3f1`).
- **N-20** Closed as G-24 T242 to T244 (`0f60186`).
- **N-21** Closed as G-24 T247 (`0c7ff4a`).
- **N-22** Closed as G-24 T249 (`9509fa8`).

## N-24 to N-25: repository hygiene

N-23 closed as G-44 (merged: `5745362`, `2c80922`, `c816aec`).

- **N-24** Pin `@anthropic-ai/claude-code` in `merge-gate.yml`, which
  installs `latest` on every run while the action beside it is pinned to a
  commit. Move: Tighten. Effort: low. Depends on: none. Diverges: no. Verify:
  the `npm install -g` line carries a version.
- **N-25** Replace `pipx run semgrep ci`, which needs a Semgrep app token
  the repository does not hold, with `semgrep scan --config auto`, and drop
  `continue-on-error` from the step so a scanner failure shows. Move:
  Tighten. Effort: low. Depends on: none. Diverges: no. Verify: a pull request
  run shows Semgrep findings or a clean scan, not a skipped step.

## The three moves that diverge most

Pick by blast radius, as `reference.md` says. These three change what a
consuming project receives, and upstream has no counterpart for any of them.

1. **N-06, the workflow.** One new file that nothing asserts against, and the
   first place the gates run on the Copilot CLI without a person remembering
   them. Cheapest large move in the list.
2. **N-01 with N-03, deterministic gate markers.** Turns the marker protocol
   from a paragraph in a reference file into a registered hook plus a shipped
   script. Changes the hook contract; N-10, which it needed first, is done.
3. **N-07, templates as a preset.** Settled, not taken: ADR-0021 keeps the
   templates full replacements. Backlog item 25 reports the drift instead.

## Decisions this file needs

Promote any of these to `open-questions.md` once an item is claimed.

- N-07 is settled: ADR-0021 keeps the templates full replacements, so backlog
  item 25 is the standing alternative, reporting drift instead of ending it.
- Whether the `.clarified` marker stays, or the clarify gate reads spec-kit's
  own `checklists/requirements.md` checkbox state, which `implement` already
  treats as a gate. Reading it would remove one bespoke file per feature.
- Whether the shipped scripts in N-03 live under a new `gates/` directory or
  `scripts/` stops being export-ignored and the development tooling moves to
  `tools/`. The second is cleaner and touches `AGENTS.md`, `CLAUDE.md`, both
  CI workflows, and the hooks README.

## Suggested order

D-05 is merged, so N-04 and N-05 no longer wait on it, and N-10 and N-19
through N-23 are all closed.

1. N-05, N-03, N-04, N-01, N-02, N-09. The manifest, the shipped scripts,
   then the hooks that call them.
2. N-11, N-12, N-13, N-14 in one worktree; they touch the bridge file and the
   three commands it describes. G-22, which held the bridge, is merged.
3. N-15, N-16, N-17, N-18. Tooling and measurement, no shipped change except
   the reviewer agents' schema path.
4. N-06 after G-19, so the workflow has a snapshot to assert against.
5. N-08 after N-06; N-07's ADR is already recorded (ADR-0021, via G-25) and
   its dependency on backlog item 24 is satisfied (G-36, merged).
6. N-24 and N-25 whenever a session is short.

Run every `Verify:` line before starting an item. A line you cannot run today
marks a design task and belongs in `roadmap.md` with its own group.
