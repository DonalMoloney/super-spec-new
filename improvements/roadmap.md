# Roadmap

Every piece of open work on this repository, ranked, and the divergence
option space each item draws from. Read the top half to pick the next thing
to build, and the option space below it when choosing where that item should
land. It is the only file that holds a claim, a checkbox, or a measured
divergence percentage (ADR-0046, which merged this file with the former
`improvements/reference.md` and superseded ADR-0017's split).
`docs/review-research.md` holds the evidence behind the review stack.

A group leaves the open-work section the day its PR merges; git history holds
its statement and its ticked tasks. G-01 to G-18 merged between PR #8 and PR
#53, the Q-01 to Q-28 cleanup wave in PR #53, and G-19 to G-58 and G-60 by
2026-09-28. G-57's second pass closed with no PR of its own: G-60's own
change took its last worthwhile candidates, and the candidate inventory below
records the rest as dropped.

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

1. Backlog item 26, the upgrade path, now that a release exists to upgrade from.
2. G-59, the upstream comparison. Its result ranks every later divergence item:
   a gap it finds outranks a heading rename.

## Backlog item 26 — An upgrade path the smoke test walks (working on)

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
and it goes into the divergence option space below as a gap to close before
any further divergence pass.

## Deferred

- **Multi-feature concurrency** (first-wave item 11): revisit after G-14's
  `[P]` dispatch has run on three features. None has run yet.
- **Replace `execute.md` with a squad dispatcher**: ruled out on 2026-09-28.
  `git archive --prefix=specflow/` only ever contains `specflow/`;
  `.claude/agents/` sits outside it, so a shipped command cannot reach the
  squad. Revisit only if the squad ships inside `specflow/` instead.
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

For each part of the extension, the ways it can diverge from upstream
superspec without breaking spec-kit's install contract. Read it when choosing
where the next roadmap item lands. Percentages are the real
(rebrand-normalized) change against the vendored upstream at the root commit
(`bda4ef0`, upstream `c20ac6c`). Upstream `HEAD` was still `c20ac6c` on
2026-09-28. An item above already claims some of the options below; where one
does, this section names the item instead of repeating its tasks.

## Three constraints

A move that violates one is not an option.

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
targets.

## Measured state

Measured 2026-09-28 against upstream `c20ac6c1` by rerunning the reproduce
command below, after PR #92 merged. Lowest real change first. One row the
command cannot reach: G-30 renamed `references/superpowers-bridge.md` to
`references/superpowers-mapping.md`, and the measurer resolves one relative
path against both roots, so that row is measured by copying upstream's file
to the local path first. Six files carry no upstream counterpart at all and
are left out of both the table and the reproduce command below for that
reason: `commands/gate.md`, `commands/hooks/after-analyze.md`,
`commands/hooks/after-clarify.md`, `references/publishing.md` (added by
G-50 T540), `commands/hooks/before-tasks.md` (added by G-56, PR #78,
registering the `before_tasks` hook upstream never shipped), and
`commands/agent-event.md` (added by G-26, PR #84, backing the `events:`
block ADR-0034 registers). The reproduce command's exclusion list needs each
new entry added the day it lands, or the measurer exits nonzero on the first
missing counterpart and never reaches the files after it alphabetically.
`commands/agent-event.md` landed without that edit, so the command printed
three rows and stopped until this revision.

| File | Real | Last moved by |
|------|------|---------------|
| `templates/plan-template.md` | 28% | PR #92, then the Constitution Check trigger and `[P]` note |
| `templates/checklist-template.md` | 48% | PR #92 (aligned with the gates and reviewers that read it) |
| `templates/constitution-template.md` | 53% | PR #92 |
| `templates/tasks-template.md` | 54% | PR #92 |
| `references/superpowers-mapping.md` | 57% | `prose-rephraser` |
| `templates/spec-template.md` | 58% | PR #92, then the FR example lines |
| `commands/execute.md` | 61% | `divergence-renamer` |
| `commands/hooks/after-tasks.md` | 65% | `divergence-renamer` |
| `commands/status.md` | 65% | ADR-0043 (`## Phase without progress.yml`) |
| `extension.yml` | 67% | G-26 (`events:` block registered, PR #84) |
| `references/workflow-guide.md` | 71% | G-57 (`### Steps`, `### Repeat runs`) |
| `commands/brainstorm.md` | 74% | ADR-0043 (`## Repeat runs`) |
| `commands/hooks/after-execute.md` | 74% | ADR-0043 (`## Stop behavior`) |
| `commands/tasks.md` | 75% | `divergence-renamer` |
| `SKILL.md` | 76% | G-50 (retitled, reordered, hooks and gates documented, 8 headings renamed) |
| `commands/hooks/before-execute.md` | 78% | ADR-0043 (`## Stop behavior`) |
| `commands/review.md` | 80% | `divergence-renamer` |
| `scripts/e2e-smoke.sh` | 85% | G-57 and G-26 (heading and hook assertions added) |
| `CHANGELOG.md` | 87% | the entries after 1.1.0 |
| `scripts/validate-release-archive.py` | 87% | `script-refactorer` |
| `scripts/validate-extension-metadata.py` | 91% | ADR-0041 (catalog counts held to `extension.yml`) |
| `scripts/e2e-agent-claude.sh` | 95% | G-19 (live run, PR #81) |
| `README.md` | 129% | G-58 (PNG links dropped, PR #91) |

Six rows moved since the 2026-09-27 measurement, five of them templates.
PR #92's alignment of the five templates with the gates and reviewers that
read them moved `spec-template.md` furthest, 39% to 58%, and the other four
between 1 and 5 points. A follow-up functional pass on 2026-09-28 rewrote
the FR example lines in `spec-template.md`, named the Constitution Check
re-run trigger in `plan-template.md`, and taught its Independent Work
Streams comment the `[P]` marker `commands/tasks.md` derives from it.
`CHANGELOG.md` rose 86% to 87% from post-1.1.0 entries. Every other row
held.

The installable payload has moved a long way from upstream in wording and,
since the previous measurement, in shape as well: `extension.yml` now
declares seven commands (`speckit.specflow.gate` and
`speckit.specflow.agent-event` beyond the original five), six hooks
(`after_clarify`, `after_analyze`, `after_tasks`, `before_tasks`,
`before_implement`, `after_implement`), and an `events:` block binding
`pre_tool_use`, `post_tool_use`, and `session_start` per ADR-0034. The
`commands/` and `commands/hooks/` sections below are corrected to match. The fork's remaining behavioral
divergence lives in `.claude/`, `standards/`, `scripts/`, and CI, which the
archive strips.

Reproduce the table from the repository root:

```bash
git clone -q https://github.com/WangX0111/superspec "$SCRATCH/upstream"
cd specflow && git ls-files | grep -E '\.(md|yml|py|sh)$' | grep -v '^examples/' \
  | grep -vE 'copilot-cli\.md|lint-standards\.py|score-artifacts\.py|tests/test_(lint_standards|score_artifacts|validate_extension_metadata|validate_release_archive)\.py|commands/(gate|agent-event)\.md|commands/hooks/(after-(analyze|clarify)|before-tasks)\.md|scripts/e2e-(agent-copilot|stages)\.sh|^gates/|references/superpowers-mapping\.md|references/publishing\.md' \
  | xargs python3 ../.claude/divergence/measure-divergence.py --local . --upstream "$SCRATCH/upstream"
```

The excluded paths are files this fork added with no upstream counterpart,
plus `references/superpowers-mapping.md`, measured separately above because
it no longer shares upstream's file name. `measure-divergence.py` exits
nonzero on the first missing or misnamed counterpart it hits, so the
unfiltered command in earlier revisions of this file never produced the full
table above.

## commands/hooks/

Six hook prompts spec-kit runs around its own commands: `after-clarify.md`,
`after-analyze.md`, `after-tasks.md`, `before-tasks.md`, `before-execute.md`,
and `after-execute.md`. The last two file names predate the rename in
`extension.yml`'s `hooks:` block to `before_implement` and `after_implement`;
their content already carries the new names (each file opens `# Hook:
before_implement` or `# Hook: after_implement`), so this is a Names-table gap,
not an open option.

- **Replace**: not warranted. The hooks are thin and spec-kit fixes their order.

## commands/

Command names are asserted in `e2e-smoke.sh`, `e2e-agent-claude.sh`, and
`ci.yml`. Every Process-step change needs a smoke-test update.

- **Replace** `execute.md` with a dispatcher over the `.claude/agents/` squad on
  Claude Code, keeping the sequential walk as the Copilot fallback. Verify: both
  paths pass the agent e2e in dry run. Dropped on 2026-09-28: the install
  archive strips `.claude/agents/`, so a shipped command cannot dispatch it.

## SKILL.md

The largest single behavior contract and the file a `~/.agents/skills/` install
reads first.

- **Tighten** the phase list to name the gate marker each phase produces, so it
  and `workflow-guide.md` cannot drift. Claimed by: G-22.
- **Replace**: Low. Spec-kit 0.16.2 never reads the extension-root `SKILL.md`;
  it renders one skill per `commands/*.md`. An external `~/.agents/skills/`
  loader's section expectations are unverified.

## references/

Content is cheap to diverge; the file names are not. Both validators require
`references/superpowers-mapping.md` and `references/workflow-guide.md` to
exist by that exact path, so a content rewrite is free but a rename is not.
See G-30 for the cost of renaming `superpowers-bridge.md`.

- **Extend** `workflow-guide.md` with one section per new gate or marker. The
  Gate markers table stays the single source for marker names, and
  `e2e-smoke.sh` asserts every row since PR #53. Claimed by: continuing, per
  item.

## templates/

Spec-kit's own commands fill these and expect the upstream section names. A
change here reaches every downstream artifact.

- **Replace**: not warranted.

## examples/

Export-ignored. Teaching material and the scorer's test fixture.
`link-audit/` is a recorded run of this fork's pipeline and the scorer's
golden. Each `seeded-*/` directory copies its feature directory with one
planted flaw. `mutation-gate-sample/` feeds the mutation gate. No upstream
text remains here.

The reproduce command above excludes every path under `examples/`, so the
directory sits outside the Measured state table.

- **Add** a snapshot of a Copilot CLI run, so the fallback path has an example
  and a dry-run fixture. Verify: the snapshot has no `.claude/` files and every
  stage artifact. Open; see Deferred above.
- **Tighten**: regenerate the snapshot spec when `spec-template.md` changes, so
  the scorer golden matches the template. Verify: `score-artifacts.py` passes
  after a template change. Claimed by: G-13, implicitly.

## scripts/

Export-ignored, so divergence here never reaches an installed extension.

## assets/

Deleted. The directory held 12 MiB of workflow diagrams, export-ignored
because one PNG broke install for every user (upstream issue #6).

- **Add** or **Extend**: not an option. There is no reason to ship a binary the
  archive strips. `.gitattributes` keeps its `assets/ export-ignore` rule and
  `validate-release-archive.py` keeps `assets/` in `EXCLUDED_PREFIXES`, so a
  directory added back under that name is stripped from the archive rather
  than shipped.

## Names

Names are asserted in more files than behavior is. Each row states where a
rename lands, so the cost is known before the move.

| Name | Today | Asserted in | Cost | Claimed by |
|------|-------|-------------|------|------------|
| `author:` | "Specflow Contributors" | Nothing | Free | none |
| `commands/hooks/*.md` file names | `after-clarify`, `after-analyze`, `before-tasks`, `after-tasks`, `before-execute`, `after-execute` | Nothing; the manifest maps hooks to commands | `e2e-smoke.sh` greps `commands/hooks/after-execute.md` | none |
| `commands/*.md` file names | `status`, `brainstorm`, `tasks`, `execute`, `review`, `gate`, `agent-event` | The `file:` field in `extension.yml` | Cheap, and no reason | none |
| Extension id `specflow` | | 27 files | Not an option | |
| `templates/*.md` file names | | Spec-kit reads `.specify/templates/<name>`; `e2e-smoke.sh` | Not an option | |
| `superpowers.yml` cache name | | Every command and the smoke test | Not an option | |
| `LICENSE` "Superspec Contributors" | | MIT requires the original notice | Not an option | |

## Rewrite status

`prose-rephraser` rewrites sentences to `standards/documentation.md` and keeps
every heading, step, code block, path, and marker verbatim. `script-refactorer`
applies `standards/code.md` to a script and keeps every exit code, output line,
and flag. `divergence-auditor` measures the result with
`.claude/divergence/measure-divergence.py` and runs the guards.

Every shipped text file with an upstream counterpart has had its dedicated
`prose-rephraser` or `script-refactorer` pass; none is waiting on one. Mark a
file `(working on)` before dispatching a pass, and commit that mark to
`main`, the same as any roadmap item. The Real column in Measured state above
is the raw divergence measured there, not a proxy for whether the pass has
run: `README.md` measured 134% both before and after its `prose-rephraser`
pass, because its content had already diverged from upstream. It now measures
129%, moved by two later, unrelated changes: G-50 T540 moved 59 lines of
catalog-submission process to `references/publishing.md`, and G-58 dropped the
PNG links. `extension.yml` measured 56% at its `prose-rephraser` pass and now
measures 67%, moved by G-56's `before_tasks` hook registration and G-26's
`events:` block, also unrelated to the pass.

A template's Real column moves little because most of its lines cannot move.
G-47 measured what each template's still-identical lines are made of: of
`constitution-template.md`'s 65 identical lines, 3 are prose and 62 are
headings, blank lines, tables, and bracket placeholders the contract freezes.
`tasks-template.md` carries 64 blank lines among its 115. A prose pass reaches
the remainder, so a template that rises 3 points has had as full a pass as one
that rises 50. `validate-release-archive.py` rose from 39% to 87% in the same
sweep because a script's structure is free and a template's is not. Read a
template's Real column against its prose line count, never against a script's.

A command rewrite runs `e2e-smoke.sh` through the auditor, because the smoke
test greps command prose.

## What has not moved

The Real column counts changed lines, so it conflates a reworded file with a
restructured one. This records the other half: the headings, functions, and
manifest keys still spelled as upstream spells them, measured 2026-09-28
against `c20ac6c1`. Read it before choosing a rewrite target.

Structure is moving, but only where a renamer pass has reached. A count below
is heading lines, not unique headings, so a name upstream uses in several
places counts once per use. Every command file keeps upstream's `## Usage`,
`## Process`, and `## Output`; each lost its `# speckit.specflow.*` title to
the namespace rename and `## Superpowers Adaptation`, now
`## Skill Mode Behavior`. `commands/status.md` lost a third to ADR-0043.
`commands/hooks/after-tasks.md` keeps 2 of 3 headings; the other two prompts
keep 1, having traded `## Checks` for `## Preconditions` and then `## Gate`
for `## Stop behavior`. `extension.yml` keeps all six of upstream's top-level
keys and adds a seventh, `events:`. ADR-0013 bars `prose-rephraser` from
touching a heading, so a prose pass moves the Real column without moving the
shape; only `divergence-renamer` moves the shape.

| File | Real | Named units shared |
|------|------|--------------------|
| `templates/plan-template.md` | 28% | 11 of 13 headings |
| `templates/spec-template.md` | 58% | 13 of 18 headings |
| `templates/checklist-template.md` | 48% | 11 of 12 headings |
| `templates/constitution-template.md` | 53% | 15 of 17 headings |
| `templates/tasks-template.md` | 54% | 14 of 19 headings |
| `commands/hooks/*.md` | 65 to 78% | 1 or 2 of 3 |
| `extension.yml` | 67% | 6 of 7 keys |
| `SKILL.md` | 76% | 5 of 22 headings |
| `references/workflow-guide.md` | 71% | 22 of 47 headings |
| `commands/*.md` | 61 to 80% | 3 to 4 of 6 to 7 headings |
| `scripts/validate-release-archive.py` | 87% | 3 of 13 functions |
| `scripts/validate-extension-metadata.py` | 91% | 2 of 4 functions |
| `scripts/e2e-agent-claude.sh` | 95% | 0 of 11 functions |

A template's Real column cannot move much, because most of its lines are not
prose. Of the lines each template still shares with upstream:

| Template | Identical | Free prose | Frozen scaffolding |
|----------|-----------|------------|--------------------|
| `tasks-template.md` | 115 | 26 | 89, of which 64 are blank |
| `spec-template.md` | 123 | 44 | 79 |
| `plan-template.md` | 103 | 24 | 78 |
| `checklist-template.md` | 67 | 10 | 57 |
| `constitution-template.md` | 65 | 3 | 62 |

Scaffolding is a heading, a blank line, a table row, a fenced block, or a
bracket placeholder, and the contract freezes all of it. So
`constitution-template.md` had three prose lines left to change and rose four
points, while `validate-release-archive.py`, which carries no such floor, rose
from 39% to 87% in the same sweep. Read a template's Real column against its
free prose count, never against a script's.

## Reducing what is left

Wording has moved a long way; shape has moved only where a renamer pass has
reached.

A heading counts here when it is still spelled as upstream spells it and no
script, workflow, or test in this repository greps it. A heading that is free
but already moved buys nothing, so the count excludes it; earlier revisions of
this table counted every free heading and so overstated what a pass could
reach. Measured 2026-09-11, re-verified 2026-09-25 for
`references/workflow-guide.md` and `SKILL.md`, by searching every heading
against `*.sh`, `*.py`, and `*.yml` outside `examples/`. A coincidental
substring match counts as frozen, so each number is a floor.

| File | Free and still upstream's | Risk | Yield |
|------|---------------------------|------|-------|
| `templates/tasks-template.md` | 16 of 20 | Medium. Renaming strands the recorded goldens | Highest |
| `templates/constitution-template.md` | 14 of 17 | Medium. Same | High |
| `templates/checklist-template.md` | 10 of 12 | Medium. Same | Medium |
| `references/workflow-guide.md` | 9 of 46 (re-verified 2026-09-27: `Human Checkpoint Protocol`, `` Writing `progress.yml` ``, `Phase 1: Specification`, `Phase 3: Planning`, and the five brainstorm categories are free; `Phase 2/4/5/6` and the four `Steps` headings under them are grepped in `e2e-smoke.sh`'s `MIRRORED_PHASES`, and the other four `Steps` headings share that name) | Low. A reference; content is cheap to diverge, the file name is not | Medium, most of the pre-G-50 yield is taken |
| `templates/plan-template.md` | 8 of 13 | Medium. Same | Medium |
| `templates/spec-template.md` | 8 of 19 | Medium. Same | Low |
| `commands/*.md` | 1 or 2 of 5 to 7 | High. `e2e-smoke.sh` counts each file's Process steps | Low |
| `commands/hooks/*.md` | 1 of 3 each | Low | Low; one heading each |
| `SKILL.md` | 1 of 21 (re-verified 2026-09-25: only `` `/speckit.checklist` `` is both shared and ungrepped; the other 3 shared headings are cited in `e2e-stages.sh`/`e2e-smoke.sh`/`write-marker.sh`) | Low. Spec-kit 0.16.2 never reads the extension-root `SKILL.md`; it renders one skill per `commands/*.md`. An external `~/.agents/skills/` loader's section expectations are unverified. | Low, G-50 took the rest |

Order of attack: `templates/tasks-template.md` first (16 reachable headings,
Medium risk: regenerate the recorded goldens in the same change, because a
template and its recorded output drift the moment either moves), then
`templates/constitution-template.md` (14), `templates/checklist-template.md`
(10), `references/workflow-guide.md` (9, Low risk against the templates'
Medium; one exception: `### Gate markers` is frozen at `###` depth, not free.
`specflow/gates/python/validate-progress.py` pins the literal `### Gate
markers` in `GATE_SECTION` and raises `ContractUnavailable` without it, proven
by renaming it in a scratch copy and watching the shipped gate exit 2;
`e2e-smoke.sh` separately greps the table's rows, unscoped to the heading, and
the heading check is the stricter one), then `templates/plan-template.md` and
`templates/spec-template.md` (8 each).

Not worth taking: `SKILL.md` (1 reachable heading, dropped below the command
and hook files) and the command files (two or three free headings each,
against a smoke test that counts Process steps per file and a workflow guide
that names every artifact each command writes; the cost is three assertions
updated per heading moved, for the smallest share of the remaining
similarity).

## Choosing

Pick by blast radius, not by the percentage. The percentage measures past
divergence; it says nothing about what a new change costs. Order of preference:

1. A reference's content, which nothing asserts against; not its file name,
   which the validators do.
2. A script, which never ships.
3. A template, which reaches every downstream artifact once and needs no smoke
   test change.
4. A command or hook, which changes what the user sees and needs the smoke test,
   CI, and the validators updated together.

## Files worth a better name

Three files outside the Names table above have a name that misleads or
collides, found by reading every shipped and tooling file name against
`standards/code.md`'s naming rule. None sits behind a validator or the
namespace lock-step, so each is a plain rename: `divergence-renamer` for the
two cited from more than one file, a direct `git mv` and edit for the third.

| File | Problem | Used in | Better name |
|------|---------|---------|-------------|
| `.claude/hooks/diff-impl.sh` | Shortens "implementation" to "impl"; its own header comment spells out "differential implementation run" | `.claude/hooks/tests/run.sh`, `specflow/references/workflow-guide.md`, `specflow/references/copilot-cli.md` | `differential-implementation.sh` |
| `.claude/review/scorecard.sh` | Shares the verb "score" with `specflow/scripts/score-artifacts.py`, which scores golden artifacts against upstream, not reviewer precision; the two names give no hint they measure different things | `.claude/review/tests/test_scorecard.py`, `docs/review-research.md`, `presentation/marp-deck/deck.md` | `reviewer-precision.sh` |
| `specflow/examples/link-audit/analyze-gate.md` | Reads like a script or command name; every sibling file in the directory (`spec.md`, `plan.md`, `tasks.md`, `progress.yml`) is a document the pipeline writes, but this one records seven sessions run after the pipeline ended | `specflow/examples/link-audit/README.md` | `analyze-gate-walkthrough.md` |

## Diverging further, and how to tell a real move from churn

The prose passes are done, so the remaining moves are structural. ADR-0043
sets the bar: a heading moves only when the new name is better on its own
merits, judged against `standards/documentation.md`. A rename that only moves
the measure is churn, and a reviewer rejects it. Expect to reject most
candidates.

### The method

1. Measure the file, so the before value is recorded:
   `python3 .claude/divergence/measure-divergence.py --local specflow
   --upstream <checkout> <path>`.
2. List what upstream still owns:
   `comm -12 <(grep -h '^#\{1,4\} ' specflow/<path> | sort -u)
   <(grep -h '^#\{1,4\} ' <upstream>/<path> | sort -u)`.
3. Sort each shared heading into the four classes below.
4. Check the four contracts before touching a class 3 heading, then grep the
   repository for prose that cites it and move that in the same change.
5. Measure again and record both values.

### Four classes of shared heading

- **Frozen by a contract.** `constitution-template.md`'s `## Core Principles`
  is grepped by `e2e-stages.sh`. `spec-template.md`'s three `*(mandatory)*`
  headings feed `score-artifacts.py`'s `spec_sections` dimension against both
  goldens, and `artifact-lint.sh` requires them by name along with
  `plan-template.md`'s `## Summary`, `## Technical Context`, and
  `## Constitution Check`. A bracket placeholder such as
  `### [PRINCIPLE_1_NAME]` is substituted at run time. None of these moves
  without moving its contract first. `tasks-template.md`'s `## Phase N:`
  lines are not among them: `score-artifacts.py` carries no `Phase` pattern,
  re-checked 2026-09-27.
- **Already the right name.** `## Usage`, `## Process`, `## Output`,
  `## Summary`, `## Notes`, `## Security`, `## Performance`,
  `## Correctness`. A shorter or plainer name does not exist. Leave them.
- **Improvable.** The table below.
- **Moved.** `## Superpowers Adaptation` became `## Skill Mode Behavior`,
  `## Checks` became `## Preconditions`, and ADR-0043 records three more.

### What makes a rename real

Each of these is a rule in `standards/documentation.md`, and each one found a
rename that stood on its own:

- **It collides with another term in the project.** `## Gate` in five hook
  prompts collided with the Gate markers protocol in `workflow-guide.md`. One
  term serves one concept, so it became `## Stop behavior`.
- **It stacks nouns.** `## File Inference Fallback` is three nouns and names
  no condition. It became `## Phase without progress.yml`.
- **It is an abstract noun over a concrete section.** `## Iteration` sat over
  two sentences about re-running, so it became `## Repeat runs`.
- **It joins two ideas with an ampersand.** One idea per heading.
- **It carries an instruction.** A parenthetical such as
  `*(include if feature involves data)*` is guidance for the author, not a
  section name.

### Moves that are not renames

A heading is the cheapest structural move, not the only one, and the others
often improve the document more:

- **Delete a heading that sits over one sentence.** A one-sentence section is
  a bullet in disguise. Fold it into the section above and keep the sentence.
  Check first that the sentence is not the only place a behavior is stated.
- **Turn three or more parallel prose items into a table**, and a table of
  two rows back into prose.
- **Reorder so the action leads.** Background after the answer, never before.
- **Drop a section this fork does not use.** Upstream's User Story 3
  boilerplate is the worked example; ADR-0021 records why the templates carry
  their own shape.

### Candidate inventory

Measured 2026-09-27 against `WangX0111/superspec`. Each row names the rule it
breaks. A row is a candidate, not a decision: check its contracts first.

| Heading | File | Rule it breaks | Candidate |
|---------|------|----------------|-----------|
| `## Phase N: Polish & Cross-Cutting Concerns` | `templates/tasks-template.md` | Ampersand, and "cross-cutting concerns" is jargon | Free: no scorer pattern reads `## Phase`; the goldens carry the heading |
| `## Technical Context` | `templates/plan-template.md` | "Context" is the vaguest available noun | Frozen: `artifact-lint.sh` requires the name on a filled plan.md |
| `## [Custom Category]` | `templates/checklist-template.md` | Placeholder, frozen | None |

`SKILL.md`'s four shared headings are the core command names
(`/speckit.specify`, `/speckit.plan`, `/speckit.constitution`,
`/speckit.checklist`). They are spec-kit's, not upstream's, and never move.

G-57's remaining renames were dropped on 2026-09-28; a rename here needs a reason of its own.
