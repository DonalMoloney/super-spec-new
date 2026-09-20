# Scoped improvements, second wave

This file lists changes that make specflow better as a product and, where
marked, move it further from upstream superspec. It holds only work that
`roadmap.md` does not: every finding the roadmap already covers is mapped to
its item in the table under "Already on the roadmap" and not repeated. Read it
beside `roadmap.md` when picking the next group after D-01, D-05, and G-19 to
G-23. Every number below was measured on 2026-09-20 at commit `ff774c2`.

Each item is one outcome. It carries a Move tag from `reference.md` (Tighten,
Extend, Add, Replace, Remove), an effort, its dependencies, whether it changes
a shipped file (Diverges: yes) or only repository tooling (Diverges: no), and
a `Verify:` line. No claim or checkbox lives here (ADR-0017): claiming an item
means turning it into a `roadmap.md` group numbered G-24 or later, and the
group carries the claim.

## Measured state

| Check | Result at `ff774c2` |
|-------|---------------------|
| `validate-extension-metadata.py` | OK |
| `validate-release-archive.py` | within every limit, 26 entries |
| `.claude/hooks/tests/run.sh` | 159 passed, 8 failed; all eight are `mutation-gate.sh` cases and fail only because mutmut is not installed here, see N-23 |
| `pytest` over the four test dirs | 103 passed |
| `lint-standards.py` | 19 files, 0 findings |
| `shellcheck -S warning` | 0 findings |
| `E2E_DRY_RUN=1 e2e-agent-claude.sh` | 28 assertions against the snapshot |
| `e2e-smoke.sh` | not run locally; CI runs it |
| `ruff check` | not run locally; CI runs it |

The first wave, G-01 to G-18, and the cleanup wave, Q-01 to Q-28, are merged.
`roadmap.md` defines the second wave: D-01 and D-05 unclaimed, G-19 to G-23
defined, C-01 to C-06 hygiene, and a scoped backlog numbered 23 to 36. The
zero-commit worktrees for D-01 and D-05 were removed on 2026-09-20.

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
| A `before_tasks` hook on open questions | Deferred; N-10 removes the cost it was deferred on |
| Gate hooks on the Copilot CLI | Backlog 28; N-03 ships the scripts it would register |
| A reviewer scorecard | Backlog 31 |
| Cost per feature against the Budgets table | Backlog 32; it reads `.specify/telemetry.jsonl`, which N-21 corrects |
| The mutation step in `merge-gate.yml` uses a mutmut 2 flag | Deferred |

## N-01 to N-10: follow spec-kit 1.0

- **N-01** Add one command, `speckit.specflow.gate`, that writes a gate
  marker: `.clarified` when the spec holds no `NEEDS CLARIFICATION` marker,
  `.analyzed` when the analysis reported zero critical inconsistencies.
  Register it on `after_clarify` and `after_analyze` with `optional: false`.
  Today the markers exist only as a prose rule in the workflow guide that the
  agent has to remember; spec-kit fires both events and nothing listens.
  Move: Add. Effort: medium. Depends on: N-10. Diverges: yes.
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
- **N-04** Ship the findings contract. Shipped: the file moved to
  `specflow/references/findings-schema.json`, not the name proposed here.
  Move `.claude/review/schema.json` to
  `specflow/references/findings-schema.json`, make `review.md` and the
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
- **N-07** Decide whether the five templates become a preset. Core
  `spec-template.md` is 131 lines and ours is 196; core `tasks-template.md`
  carries an Implementation Strategy section and a parallel example that ours
  lacks, because ours forks an older core. An extension template always
  replaces core, so every core template change is lost. A preset with
  `strategy: append` would add only the specflow sections (Open Questions,
  Threat Model, Traceability, Brainstorm Log, Changelog, Code Review Rules,
  Execution Strategy, Superpowers Execution) on top of whatever core ships.
  The cost: `provides.templates` leaves the manifest, the archive validator
  and `e2e-smoke.sh` lose five assertions, and the golden must be regenerated.
  Backlog item 25 is the alternative: keep replacing and report drift in
  status. Record the answer as an ADR before any file moves. Move: Replace.
  Effort: high. Depends on: N-05. Diverges: yes. Verify: the ADR exists; if
  adopted, `specify preset resolve spec-template` names the core file plus
  the addendum and the golden scores 100 on sections.
- **N-08** Ship `specflow/bundle.yml` composing the extension, the workflow
  from N-06, and the preset from N-07 if adopted, with `role: developer`. Add
  `specify bundle validate --path specflow --offline` and
  `specify bundle build` to CI, and check the built ZIP against
  `validate-release-archive.py`'s limits. Move: Add. Effort: low. Depends on:
  N-06, backlog 24. Diverges: yes. Verify: both bundle commands exit 0 in CI
  and the artifact stays under 50 MiB.
- **N-09** Register `after_converge` on `speckit.specflow.tasks`, optional.
  Spec-kit's `converge` command appends unbuilt work to `tasks.md`; the
  singular-task rule at step 6 and the stable-ID rule at steps 8 and 9 of
  `tasks.md` then apply to the appended lines. Without it a Copilot run gets
  unchecked compound tasks after every converge. Move: Extend. Effort: low.
  Depends on: N-10. Diverges: yes. Verify: a fixture `tasks.md` with one
  converge-appended compound line is split by the dry-run tasks stage.

- **N-10** Derive the command and hook counts from the manifest instead of
  literals. `e2e-smoke.sh` line 26 and line 126, `ci.yml` line 85, and the
  tuple at `validate-extension-metadata.py` line 86 each hard-code the
  counts, so N-01, N-02, and N-09 would each pay the same four-file edit, and
  G-23 T231 is about to add a fifth literal table. Read `extension.yml` once
  in each script and assert against what it declares. Move: Tighten. Effort:
  low. Depends on: none. Diverges: no. Verify: adding a hook to a scratch copy
  of the manifest changes every assertion without a script edit.

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

- **N-19** Fix the two install-time breaks in `SKILL.md`: line 25 links
  `assets/workflow-overview-en.png`, which the archive strips, and line 11
  still carries `description_zh` against the English-only rule. Replace the
  image with the README's Mermaid block and delete the field. PR #70 rewrote
  the prose and kept both. Move: Remove. Effort: low. Depends on: none.
  Diverges: yes. Verify: `git archive HEAD:specflow | tar -t` lists every
  path `SKILL.md` links and `grep -c '_zh' specflow/SKILL.md` prints 0.

- **N-20** Rewrite Phase 0 in `SKILL.md` (line 238) and `workflow-guide.md`
  (lines 23 and 24). Both say the constitution command copies the templates
  into `.specify/templates/`. Spec-kit resolves templates at command time
  through the stack, and an extension's templates live at
  `.specify/extensions/specflow/templates/`. The Project Structure trees in
  both files show the old layout, and backlog item 25 builds on the same
  wrong premise. Move: Tighten. Effort: low. Depends on: none. Diverges: yes.
  Verify: `e2e-smoke.sh` asserts
  `.specify/extensions/specflow/templates/spec-template.md` and neither file
  says "Copy" in Phase 0.
- **N-21** Fix the Budgets section of `workflow-guide.md`. Line 436 says the
  budget flag's "name [is] not yet confirmed; see G-09 T092" while
  `merge-gate.yml` passes `--max-budget-usd`; line 448 carries
  `[budget-flag-TBD]`; line 450 names `.specify/telemetry.jsonl` while the
  hook writes `.claude/telemetry.jsonl`. Move: Tighten. Effort: low. Depends
  on: none. Diverges: yes. Verify: this grep prints 0.

  ```bash
  grep -c 'TBD\|not yet confirmed\|specify/telemetry' specflow/references/workflow-guide.md
  ```

- **N-22** Fix the agent count in `.github/copilot-instructions.md` line 64,
  which says 17 agents; `.claude/agents/` holds 28 across the BDD squad, the
  review panel, and the three rewrite agents. Move: Tighten. Effort: low.
  Depends on: none. Diverges: no. Verify: the count in the file equals
  `ls .claude/agents/*.md | wc -l`.

## N-23 to N-25: repository hygiene

- **N-23** Skip the mutation-gate cases with a named reason when mutmut is
  absent. `run.sh` reports 8 failures on a checkout that has not installed
  `requirements-dev.txt`, and the hooks README does not say the suite needs
  it. Keep the one case that asserts exit 2 when mutmut is missing from
  `PATH`. Move: Tighten. Effort: low. Depends on: none. Diverges: no. Verify:
  `PATH=/usr/bin:/bin bash .claude/hooks/tests/run.sh` reports 0 failed and
  names the skipped cases.
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
   script. Changes the hook contract, so N-10 goes first.
3. **N-07, templates as a preset.** The one Replace. It ends the drift between
   our forked templates and spec-kit's core templates, at the cost of the
   template half of the manifest. Needs an ADR first.

## Decisions this file needs

Promote any of these to `open-questions.md` once an item is claimed.

- Whether N-07 is adopted, or the templates stay full replacements and
  backlog item 25 reports drift instead.
- Whether the `.clarified` marker stays, or the clarify gate reads spec-kit's
  own `checklists/requirements.md` checkbox state, which `implement` already
  treats as a gate. Reading it would remove one bespoke file per feature.
- Whether the shipped scripts in N-03 live under a new `gates/` directory or
  `scripts/` stops being export-ignored and the development tooling moves to
  `tools/`. The second is cleaner and touches `AGENTS.md`, `CLAUDE.md`, both
  CI workflows, and the hooks README.

## Suggested order

These slot in after step 1 of the order in `roadmap.md`, since N-04 and N-05
wait on D-05.

1. N-10, N-19, N-20, N-21, N-22, N-23. Each is one short session and none
   changes behavior.
2. N-05, N-03, N-04, N-01, N-02, N-09. The manifest, the shipped scripts,
   then the hooks that call them.
3. N-11, N-12, N-13, N-14 in one worktree; they touch the bridge file and the
   three commands it describes. Run G-22 first, since it holds the bridge.
4. N-15, N-16, N-17, N-18. Tooling and measurement, no shipped change except
   the reviewer agents' schema path.
5. N-06 after G-19, so the workflow has a snapshot to assert against.
6. N-07 after its ADR, then N-08 after backlog item 24.
7. N-24 and N-25 whenever a session is short.

Run every `Verify:` line before starting an item. A line you cannot run today
marks a design task and belongs in `roadmap.md` with its own group.
