# Roadmap

Every piece of open work on this repository, ranked. Read it to pick the next
thing to build. It is the only file that holds a claim or a checkbox
(ADR-0017). `reference.md` holds the divergence option space each group draws
from and the measured distance to upstream; `docs/review-research.md` holds the
evidence behind the review stack.

A group leaves this file the day its PR merges; git history holds its statement
and its ticked tasks. G-01 to G-18 merged between PR #8 and PR #53, the Q-01 to
Q-28 cleanup wave in PR #53, and G-19 to G-56, G-58, and G-60 by 2026-09-28.

## How to use this file

- **One item = one git worktree = one PR.** Items are independent unless a
  `Depends on:` line says otherwise.
- Tasks inside a group run in order. Each is singular and ends with a `Verify:`
  line that proves it done. Tick the box when that line passes.
- Before creating a worktree, append `(working on)` to the item header and
  commit that to `main`, so a second session does not start the same item.
  `block-main-commit.sh` refuses a commit whose working directory sits on
  `main` (ADR-0004), so commit the marker on the branch and fast-forward:
  `git -C <main checkout> merge --ff-only <branch>`. Main gains the commit and
  the hook never fires.
- After merge: remove the worktree, mark the header `(merged: PR #N)`, and
  record any non-obvious choice in `decisions.md`.
- A shipped file under `specflow/` runs on the Copilot CLI as well as Claude
  Code. A group that adds a step to a command needs a fallback that works with
  no hooks, no subagents, and no `model:` frontmatter.
- A `(working on)` marker is a claim on a file, not a reservation forever. If
  its worktree has no commits and no open PR, clear the marker.
- Pick the item whose `Verify:` line you can run before you start. An item
  whose check you cannot run today is a design task, not a roadmap task.

## Executors

| Label | What it is | When to use |
|---|---|---|
| `bdd-orchestrator` | Full BDD squad, ends with `work-verifier` | Any item that adds or changes a script, hook, or CI job |
| `general-purpose` | Single Claude agent, all tools | Command, template, and reference edits with no runnable test beyond the validators and the smoke test |
| `prose-rephraser` | Rewrites one shipped file's wording | An item whose only move is wording |
| `script-refactorer` | Refactors one script to `standards/code.md` | An item whose only move is script structure |
| `divergence-renamer` | Renames one file, string, or identifier everywhere it is cited | An item that moves a name across more than one file |
| `work-verifier` | Adversarial re-check of a completion claim | Final step of every item before opening the PR |

## Effort

| Effort | Use when |
|---|---|
| low | Every `Verify:` line is mechanical: a grep count, a YAML key, a test name. |
| medium | The item ports an existing design and at least one choice has no stated answer. |
| high | The item invents the design. The `Verify:` line checks that a section exists, not that it is right. |

## Order of work

1. G-57's second structural pass. `v1.1.0` is tagged, so its dependency is met.
2. Backlog item 26, the upgrade path, now that a release exists to upgrade from.
3. G-59, the upstream comparison. Its result ranks every later divergence item:
   a gap it finds outranks a heading rename.

## G-57 — Move the shape, not the wording (first pass merged 2026-09-27)

The first pass took six renames and rejected the rest, including the
strongest candidate on wording: `plan-template.md`'s `## Summary`, which
`standards/documentation.md` bans outright but
`specflow/gates/bash/artifact-lint.sh` requires as a literal section and
`.claude/hooks/tests/run.sh` asserts by exact string. Taking it means moving a
shipped gate's required section, which is a behavior change, not a heading
pass.

The pass missed its own Verify line, and the line was wrong rather than the
work. Three of the four measured files did not move at whole-number
precision: `plan-template.md` 22.56% to 23.31%, `workflow-guide.md` 70.51% to
70.75%, and `SKILL.md` not at all, because the line touched there already
differed from upstream. Only `tasks-template.md` moved a printed point, 51% to
53%. A heading is one line, so a single rename cannot move a file of 133 or
841 lines by a whole point. ADR-0043 already treats the measure as a side
effect, so a future pass states its Verify line as the renames taken and the
rules they cleared, not as a higher Real column.

All four goldens score byte-identically to the pre-pass run, and the 14
golden files carrying a renamed heading were updated in the same commit.

The remaining candidate inventory is in `reference.md`.

### Original statement

Every file with an upstream counterpart has had its `prose-rephraser` pass, so
the low numbers in `reference.md`'s Real column are a floor, not a gap. A
template's scaffolding is frozen by ADR-0013, and scaffolding is most of what
is left: `constitution-template.md` has 3 free prose lines among the 65 it
still shares with upstream, and `tasks-template.md` carries 64 blank lines
among its 115. Only `divergence-renamer` (ADR-0018) moves a heading.

The headroom is in the Named units shared column: `plan-template.md` keeps 12
of 13 headings, `tasks-template.md` 19 of 20, and every command file keeps
upstream's `## Usage`, `## Process`, `## Output`, and `## Human Checkpoints`.

Four contracts name these headings and move in the same change:
`e2e-smoke.sh`'s `EXPECTED_PROCESS_STEPS` and `MIRRORED_PHASES`,
`score-artifacts.py`'s `spec_sections` dimension against both goldens, and
`validate-extension-metadata.py`. Verify: `bash verify.sh` reports 0 failed,
both goldens score no lower, and `measure-divergence.py` reports a higher Real
column for each renamed file. Effort: high. Depends on: none. `v1.1.0` is tagged.

## Backlog item 26 — An upgrade path the smoke test walks

`e2e-smoke.sh` installs the published release ZIP, installs the checkout over
it with `--dev`, and asserts no stale command file or `extensions.yml` entry
remains. Every user who installs a release upgrades through this path and it
has never run. Unblocked on 2026-09-28: `v1.1.0` is tagged and its release
carries `specflow-v1.1.0.zip`. Verify: the smoke test reports the upgrade
assertions and passes. Effort: low. Depends on: none.

## G-59 — Run upstream and this fork on the same seeded input, and record which catches the flaw

Executor: `bdd-orchestrator`. Effort: medium. Depends on: none.

No recorded run compares this fork with upstream. Every golden under
`specflow/examples/` scores this fork's output against itself, so the claim
that the fork is better rests on the divergence percentage, which counts
changed lines and says nothing about outcomes. G-57 showed the percentage has
stopped moving. This group replaces it with a measure of results: give both
pipelines the same flawed input and record which one reports the flaw.

Two probes, one per phase where the fork claims to add the most:

- **Spec probe.** Both brainstorm commands run on
  `examples/seeded-ambiguity/spec.md`, whose duplicate-heading suffix order is
  unstated. `score-artifacts.py`'s `seeded_ambiguity` dimension scores the
  resulting spec: 100 if an Open Questions row raises the order, 0 if not.
- **Review probe.** Both review commands run on a copy of
  `examples/link-audit/src/link_audit/` carrying one planted off-by-one bug.
  A run catches the bug when a finding names the planted file and line.

Upstream installs as `superspec` (`extension.id` at `c20ac6c`), so its
commands are `/speckit.superspec.*`. The e2e stages hardcode
`/speckit.specflow.*` and assert this fork's artifacts, so the probes live in
their own script instead of the e2e stages. LLM output varies, so each probe
runs 3 times per pipeline and the result records the hit count, not one
verdict.

- [ ] T591 Add `examples/seeded-review-bug/`, a copy of `link-audit/src/` with one planted off-by-one. Verify: `pytest` in the copy fails exactly one test, and its README names the file, line, and fault.
- [ ] T592 Add `scripts/compare-upstream.sh`, which installs one extension into a fresh `specify init` project given a checkout path plus a command namespace. Verify: `E2E_DRY_RUN=1` prints both install commands with no agent call.
- [ ] T593 Run the spec probe through `compare-upstream.sh`, writing each run's `seeded_ambiguity` score to a JSON result file. Verify: the dry run writes a result file with 6 entries marked `dry-run`.
- [ ] T594 Run the review probe through `compare-upstream.sh`, writing whether each run's findings name the planted file and line. Verify: the dry run writes 6 entries marked `dry-run`.
- [ ] T595 Record one live run as `examples/upstream-comparison/results.json`. Verify: the file holds 12 entries with no `dry-run` value.
- [ ] T596 Add `examples/upstream-comparison/README.md` stating the hit counts, the model, and both commits compared. Verify: every number in it matches `results.json`.
- [ ] T597 Link the comparison from `specflow/README.md`. Verify: `lint-standards.py` passes on the changed README.

Verify for the group: `bash verify.sh` reports 0 failed, and
`examples/upstream-comparison/results.json` exists from a live run. Either
outcome counts as done: a probe where upstream matches the fork is a finding,
and it goes into `reference.md` as a gap to close before any further
divergence pass.

## Deferred

- **Multi-feature concurrency** (first-wave item 11): revisit after G-14's
  `[P]` dispatch has run on three features. None has run yet.
- **Replace `execute.md` with a squad dispatcher**: the one Replace move worth
  taking. G-19 (PR #81) has since recorded the snapshot it needs to assert
  against on both runtimes, so the block is price, not evidence.
- **A Copilot CLI run snapshot** under `examples/`: the Copilot e2e script
  (backlog item 27) is merged; only the live run remains.
- **A spec-kit workflow file** (was N-06): deferred on 2026-09-20. Most of its
  stated value was running the gates on the Copilot CLI, which the `events:`
  block bought for less (G-26, ADR-0034). Reprice it before claiming.
- **A spec-kit bundle** (was N-08): deferred on 2026-09-20. It composes the
  workflow above with a preset, and ADR-0021 ruled a preset out, so it cannot
  start until both are worth reopening.

## Ready to release

Run every line on `main` the day of the tag. One false line means the release
is not ready, whatever the order above says.

- A tag exists, `release.yml` ran green for it, and the release carries the ZIP
  and the validator report. Done for `v1.1.0` on 2026-09-27: the run published
  `specflow-v1.1.0.zip` at 88869 bytes and its validator report.
- `specify extension add specflow --from <release zip>` installs in a fresh
  project on both surfaces, and `specify extension list` prints the command and
  hook counts `extension.yml` declares. Checked for `v1.1.0` against the
  published asset, fetched with `gh` and served over localhost: both surfaces
  install and print `Commands: 7 | Hooks: 6`. Over the network the same command
  answers 404, because the repository is private and spec-kit downloads an
  asset anonymously. `catalog.json`'s `download_url` and `catalog_url` are
  unreachable for the same reason. Both clear when the repository goes public;
  neither is a payload defect.
- The root `README.md` exists, and every command in `specflow/README.md` ran in
  CI on this commit.
- `examples/` holds one recorded run of this fork's pipeline, and the README
  links it.
- `bash verify.sh` reports 0 failed and 0 skipped with Ruff installed.
- `bash .claude/hooks/tests/run.sh` reports 0 failed.
- Both e2e dry runs exit 0.
- `open-questions.md` lists nothing.
- `git status --porcelain` prints nothing on `main`.
- `CHANGELOG.md` has no `[Unreleased]` entries left; each one moved under the
  tag's heading with the version the rule in that file picks.
