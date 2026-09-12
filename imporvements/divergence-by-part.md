# How specflow/ can diverge from upstream, by part

This file lists, for each part of the extension, the ways it can diverge from
upstream superspec without breaking spec-kit's install contract. Read it when
choosing where the next roadmap item lands. `tasks.md` holds the committed
work; this file holds the option space. Percentages are the real
(rebrand-normalized) change measured 2026-09-11 against the vendored upstream
at the root commit (`bda4ef0`, upstream `c20ac6c`). Upstream `HEAD` was still
`c20ac6c` on that date.

Three constraints apply to every part. A move that violates one is not an
option.

1. **Namespace lock-step.** The extension id and every command or hook name
   match, or `validate-extension-metadata.py` fails.
2. **Superpowers optional.** Every command keeps a built-in fallback when the
   skill is absent.
3. **Both targets.** Anything shipped in `specflow/` runs on the Copilot CLI as
   well as Claude Code. A shipped file may not depend on `.claude/` hooks,
   agents, or `model:` frontmatter, which Copilot cannot execute.

## Five moves

| Move | Meaning | Reversible | Breaks resync |
|------|---------|------------|---------------|
| Tighten | Same steps, stricter gate or stricter output shape | yes | rarely |
| Extend | New step, section, or placeholder appended to the upstream shape | yes | sometimes |
| Add | New file with no upstream counterpart | yes | no |
| Replace | Same file name, different process | no | yes |
| Remove | Drop a file or step upstream still ships | no | yes |

Tighten and Add are the cheap moves. Replace and Remove are where the fork
stops being a fork; take them only when the upstream shape is wrong for the two
targets. Every bullet ends with a `Verify:` line naming the check that proves
it done and a `Claimed by:` line naming a D-item with a live worktree, a
`tasks.md` group, or "none".

## Claimed now

A D-item is a single divergence bullet with its own worktree under
`~/PycharmProjects/worktrees/D-0N-*` and its own PR. Mark a bullet
`(working on)` and commit that to `main` before creating the worktree.

| Item | Bullet | Worktree |
|------|--------|----------|
| D-01 | `after-tasks.md` reads `progress.yml` | `D-01-after-tasks-progress` |
| D-05 | manifest name and strings, CHANGELOG Unreleased, stale validator check | `D-05-stale-names-manifest` |

Merged on 2026-09-11: D-02 (PR #57), D-03 (PR #59), D-06 (PR #58), D-07
(PR #55), and D-04's CI smoke step and gate-marker assertion (PR #53). D-04's
step-count half is still open under scripts/ below.

## Measured state, 2026-09-11

| File | Changed lines |
|------|---------------|
| `commands/hooks/before-execute.md` | 51% |
| `commands/status.md` | 33%, after two `prose-rephraser` passes |
| `commands/execute.md` | 31% |
| `scripts/validate-release-archive.py` | 29%, after `script-refactorer` |
| `README.md` | 23%, nearly all the removed Chinese section |
| `references/workflow-guide.md` | 17% |
| `commands/tasks.md`, `templates/spec-template.md` | 12% |
| `commands/brainstorm.md`, `commands/review.md` | 10%, 7% |

Byte-identical after the rename: `SKILL.md`, `extension.yml`, `CHANGELOG.md`,
both `after-*` hooks, `plan-template.md`, and `tasks-template.md`. The
installable payload stays close to upstream. The fork's divergence lives in
`.claude/`, `standards/`, `scripts/`, and CI, which the archive strips.

Reproduce the table from the repository root:

```bash
git clone -q https://github.com/WangX0111/superspec "$SCRATCH/upstream"
cd specflow && git ls-files | grep -E '\.(md|yml|py|sh)$' | grep -v '^examples/' \
  | xargs python3 ../.claude/divergence/measure-divergence.py --local . --upstream "$SCRATCH/upstream"
```

## commands/hooks/

- **Tighten** `after-tasks.md` to read `progress.yml` before writing, as
  `before-execute.md` does at step 6. Verify: the Process lists a
  progress-state read step. Claimed by: D-01 (working on).
- **Extend** `after-execute.md` to write a findings file `review.md` reads,
  closing implement to review. Verify: `review.md` names the file as an input.
  Claimed by: D-02 (done, PR #57).
- **Add** a `before_tasks` hook that stops when the spec's Open Questions
  table has unresolved rows. Spec-kit fires `hooks.before_tasks`; upstream never
  registered one. Not cheap: it changes the hook count `e2e-smoke.sh`,
  `ci.yml`, and the hook tuple in `validate-extension-metadata.py` assert.
  Verify: all three assertions updated and green. Claimed by: none.
- **Replace**: not warranted. The hooks are thin and spec-kit fixes their order.

## commands/

Command names are asserted in `e2e-smoke.sh`, `e2e-agent-claude.sh`, and
`ci.yml`. Every Process-step change needs a smoke-test update.

- **Tighten** `status.md` to report `.clarified` and `.analyzed` per feature.
  Verify: the smoke test asserts the marker column. Claimed by: D-07 (done, PR #55).
- **Tighten** `tasks.md` to reject a generated task line containing " and ".
  Verify: a fixture with a compound task stops the command. Claimed by: D-06 (done, PR #58).
  ADR-0016 records why the lint is blunt.
- **Extend** `review.md` with a prose risk tier that selects which review
  dimensions run, using `risk-classifier.sh` only when present. Verify: the
  fallback tier rule is in the command file. Claimed by: D-03 (done, PR #59).
- **Extend** `brainstorm.md` to write resolved questions to `decisions.md` as
  ADR-lite entries. G-17 covers the read. Verify: a resolved question appears
  in `decisions.md` after a run. Claimed by: G-20.
- **Replace** `execute.md` with a dispatcher over the `.claude/agents/` squad
  on Claude Code, keeping the sequential walk as the Copilot fallback. Verify:
  both paths pass the agent e2e in dry run. Claimed by: none, deferred in
  `tasks.md` until G-19 lands a snapshot to assert against.
- **Add** a sixth command: not an option. It changes `extension.yml`, README,
  and command-name assertions in four files.

## SKILL.md

The largest single behavior contract and the file a `~/.agents/skills/` install
reads first. Byte-identical to upstream.

- **Tighten** the phase list to name the gate marker each phase produces, so
  it and `workflow-guide.md` cannot drift. Verify: the marker names in both
  files match by grep. Claimed by: G-22.
- **Extend** with a "Target surface" section stating which steps are Claude
  Code only and what Copilot does instead. Verify: every Claude-only step has
  a named fallback. Claimed by: D-03 (done, PR #59).
- **Replace**: not warranted. Spec-kit's skill loader expects the upstream
  section shape.

## references/

Nothing asserts against these structurally, so they are cheap to diverge.

- **Add** a `copilot-cli.md` reference stating what the Copilot runtime lacks
  and which fallback each command uses there. Verify: one row per command.
  Claimed by: D-03 (done, PR #59).
- **Extend** `superpowers-bridge.md` to map the review personas under
  `.claude/agents/` to the `requesting-code-review` skill, so Claude Code
  prefers the squad and Copilot the skill. Verify: one row per persona.
  Claimed by: G-22.
- **Extend** `workflow-guide.md` with one section per new gate or marker. The
  Gate markers table stays the single source for marker names, and
  `e2e-smoke.sh` asserts every row since PR #53. Claimed by: continuing, per
  group.

## templates/

Spec-kit's own commands fill these and expect the upstream section names. A
change here reaches every downstream artifact.

- **Extend** `constitution-template.md` with a review-stage table naming a
  model class per stage, never an agent alias. Verify: no alias in the
  template. Claimed by: G-21.
- **Extend** `tasks-template.md` with a Verify column. Verify: the table
  header has the column. Claimed by: G-21.
- **Tighten** `checklist-template.md` with an `R-NNN` column joining `CHK`
  rows to review findings. Verify: a review run fills the column. Claimed by:
  G-21.
- **Replace**: not warranted.

## examples/

Export-ignored. Teaching material and the scorer's test fixture. Both files
are upstream's: `static-landing-page/` is upstream's snapshot and predates
every gate this fork added; `sample-workflow.md` walks a "User Authentication"
feature no snapshot contains, with abbreviated outputs that show none of the
markers.

- **Replace** the snapshot with a run of this fork's pipeline on a feature of
  its own, so the example shows `.clarified`, `.analyzed`, Threat Model,
  Traceability, and Changelog. Verify: the snapshot carries all five.
  Claimed by: G-19.
- **Add** a failing-gate snapshot showing `ANALYZE_REQUIRED` and the rerun.
  Every example today is a happy path. Verify: the snapshot contains the stop
  code and the rerun. Claimed by: G-19.
- **Remove** `sample-workflow.md`. Its feature has no snapshot and its
  outputs predate the gates. Verify: `README.md` links no removed file.
  Claimed by: G-19.
- **Add** a snapshot of a Copilot CLI run, so the fallback path has an
  example and a dry-run fixture. Verify: the snapshot has no `.claude/` files
  and every stage artifact. Claimed by: none. Needs a Copilot e2e script
  (playbook Part 9, item 27).
- **Tighten**: regenerate the snapshot spec when `spec-template.md` changes,
  so the scorer golden matches the template. Verify: `score-artifacts.py`
  passes after a template change. Claimed by: G-13, implicitly.

## scripts/

Export-ignored, so divergence here never reaches an installed extension.

- **Tighten** `e2e-smoke.sh` to assert the Process-step count of each command
  file (status 9, brainstorm 7, tasks 10, execute 9, review 8 on 2026-09-11),
  so a dropped step fails before merge. The gate-marker half landed in PR #53.
  Verify: deleting one step from any command fails the smoke test. Claimed
  by: G-23.
- **Add** an upstream drift check that compares the vendored commit to
  upstream `HEAD`. Verify: a hook test covers both exits. Claimed by: G-23.
- **Refactor** `e2e-smoke.sh` and `e2e-agent-claude.sh` to `standards/code.md`
  with `script-refactorer`. Verify: `divergence-auditor` reports every guard
  green. Claimed by: none.

## assets/

12 MiB of workflow diagrams, export-ignored because one PNG broke install for
every user (upstream issue #6).

- **Remove** the PNGs and check in Mermaid or SVG source beside the deck under
  `presentation/`, per `standards/presentations.md`. Verify:
  `validate-release-archive.py` passes and the README renders the diagram from
  source. Claimed by: none.
- **Add** or **Extend**: not an option. There is no reason to ship a binary
  the archive strips.

## Names

Names are asserted in more files than behavior is. Each row states where a
rename lands, so the cost is known before the move.

| Name | Today | Asserted in | Cost | Claimed by |
|------|-------|-------------|------|------------|
| Manifest `name:` | "Superpowers Bridge" | `extension.yml`, `CHANGELOG.md`, validator test, `AGENTS.md`, `copilot-instructions.md` | Cheap; "bridges" is a banned metaphor | D-05 (working on) |
| Manifest description and `purpose:` strings | "Bridges", "Deep-dive" (2), "Intelligent", "Enhanced" (6) | Nothing greps them | Free Tighten | D-05 (working on) |
| Hook `prompt:` and `description:` strings | "Run enhanced Superpowers task decomposition and validation?" | Nothing greps them | Free Tighten | none |
| `tags:` list | `superpowers`, `brainstorming`, `tdd`, `code-review`, `subagent`, `workflow` | The spec-kit catalog search | Free; add `copilot`, `claude-code` | none |
| `author:` | "Specflow Contributors" | Nothing | Free | none |
| `references/superpowers-bridge.md` | Named for the metaphor | 10 citations in commands, `SKILL.md`, README; both validators; the `CLAUDE.md` import | About 8 files | none |
| `examples/static-landing-page/` | Upstream's feature | dry run, `score-artifacts.yml`, README | Replaced, not renamed | G-19 |
| `.claude/review/schema.json` title | `SuperspecReviewFindings` was renamed | Hook tests | done | D-05 |
| `validate-extension-metadata.py` line 147 | Checks for a `superpowers-bridge --from` string no README carries | Validator tests | Delete the branch | D-05 (working on) |
| `commands/hooks/*.md` file names | `after-tasks`, `before-execute`, `after-execute` | Nothing; the manifest maps hooks to commands | Free, and no reason | none |
| `commands/*.md` file names | `status`, `brainstorm`, `tasks`, `execute`, `review` | The `file:` field in `extension.yml` | Cheap, and no reason | none |
| Extension id `specflow` | | 27 files | Not an option | |
| `templates/*.md` file names | | Spec-kit reads `.specify/templates/<name>`; `e2e-smoke.sh` | Not an option | |
| `superpowers.yml` cache name | | Every command and the smoke test | Not an option | |
| `LICENSE` "Superspec Contributors" | | MIT requires the original notice | Not an option | |

## Wording and structure, by file

`prose-rephraser` rewrites sentences to `standards/documentation.md` and keeps
every heading, step, code block, path, and marker verbatim. `script-refactorer`
applies `standards/code.md` to a script and keeps every exit code, output
line, and flag. `divergence-auditor` measures the result with
`.claude/divergence/measure-divergence.py` and runs the guards. Files a D-item
or group holds are skipped until it merges, so two worktrees never edit one
file.

| File | Real | Agent | Claimed by |
|------|------|-------|------------|
| `SKILL.md` | 40% | `prose-rephraser` | done, PR #70 |
| `templates/plan-template.md` | 20% | `prose-rephraser` | done, PR #69 |
| `templates/tasks-template.md` | 42% | `prose-rephraser` | done, PR #69 |
| `commands/hooks/after-execute.md` | 65% | `prose-rephraser` | done, PR #70 |
| `commands/hooks/after-tasks.md` | 0% | `prose-rephraser` | D-01 first |
| `CHANGELOG.md`, `extension.yml` | 0% | `prose-rephraser` | D-05 first |
| `scripts/e2e-smoke.sh` | 56% | `script-refactorer` | done, PR #68; G-23 lands on the refactored file |
| `scripts/e2e-agent-claude.sh` | 42% | `script-refactorer` | done, PR #68 |
| `templates/checklist-template.md` | 34% | `prose-rephraser` | done, PR #69 |
| `references/superpowers-bridge.md` | 2% | `prose-rephraser` | G-22 first |
| `scripts/validate-extension-metadata.py` | 7% | `script-refactorer` | D-05 first |
| `templates/constitution-template.md` | 36% | `prose-rephraser` | done, PR #69 |
| `commands/brainstorm.md` | 54% | `prose-rephraser` | done, PR #67 |
| `commands/review.md` | 76% | `prose-rephraser` | done, PR #67 |
| `commands/tasks.md` | 58% | `prose-rephraser` | done, PR #66 |
| `templates/spec-template.md` | 33% | `prose-rephraser` | done, PR #69 |
| `references/workflow-guide.md` | 57% | `prose-rephraser` | done, PR #71 |
| `commands/execute.md` | 57% | `prose-rephraser` | done, PR #66 |
| `README.md` | 46% | `prose-rephraser` | D-05 first |
| `commands/hooks/before-execute.md` | 70% | `prose-rephraser` | done, PR #70 |

Done: `commands/status.md` (two passes) and
`scripts/validate-release-archive.py`. Order of work: the unclaimed rows first
(`plan-template.md`, both `after-*` hooks, `e2e-agent-claude.sh`, `review.md`,
`tasks.md`, `spec-template.md`, `workflow-guide.md`, `execute.md`,
`before-execute.md`), then each claimed row
after its item merges. A command rewrite runs `e2e-smoke.sh` through the
auditor because the smoke test greps command prose. Mark a row `(working on)`
before dispatching, and commit that mark to `main`.

## Choosing

Pick by blast radius, not by the percentage. The percentage measures past
divergence; it says nothing about what a new change costs. Order of preference:

1. A reference or example, which nothing asserts against.
2. A script, which never ships.
3. A template, which reaches every downstream artifact once and needs no smoke
   test change.
4. A command or hook, which changes what the user sees and needs the smoke test,
   CI, and the validators updated together.

When two parts both reach the goal, change the one further from the user.
