# How specflow/ can diverge from upstream

For each part of the extension, the ways it can diverge from upstream superspec
without breaking spec-kit's install contract. Read it when choosing where the
next roadmap item lands. `roadmap.md` holds the committed work; this file holds
the option space and the measured distance to upstream.

Percentages are the real (rebrand-normalized) change against the vendored
upstream at the root commit (`bda4ef0`, upstream `c20ac6c`). Upstream `HEAD`
was still `c20ac6c` on 2026-09-25. An option a roadmap item already claims names
that item instead of repeating its tasks.

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

Measured 2026-09-25 against upstream `c20ac6c1` by rerunning the reproduce
command below. Lowest real change first. One row the command cannot reach:
G-30 renamed `references/superpowers-bridge.md` to
`references/superpowers-mapping.md`, and the measurer resolves one relative
path against both roots, so that row is measured by copying upstream's file
to the local path first. Three files carry no upstream counterpart at all and
are left out of both the table and the reproduce command below for that
reason: `commands/gate.md`, `commands/hooks/after-analyze.md`, and
`commands/hooks/after-clarify.md`.

| File | Real | Last moved by |
|------|------|---------------|
| `templates/plan-template.md` | 23% | `prose-rephraser` |
| `templates/spec-template.md` | 38% | `prose-rephraser` |
| `templates/checklist-template.md` | 45% | `prose-rephraser` |
| `templates/tasks-template.md` | 49% | `prose-rephraser` |
| `templates/constitution-template.md` | 50% | `prose-rephraser` |
| `extension.yml` | 56% | `prose-rephraser` |
| `SKILL.md` | 57% | skill count and sample version updated |
| `references/superpowers-mapping.md` | 57% | `prose-rephraser` |
| `commands/execute.md` | 61% | `divergence-renamer` |
| `commands/status.md` | 62% | per-command script declared in frontmatter |
| `commands/hooks/after-tasks.md` | 65% | `divergence-renamer` |
| `references/workflow-guide.md` | 65% | `divergence-renamer` |
| `commands/brainstorm.md` | 67% | `divergence-renamer` |
| `commands/hooks/after-execute.md` | 70% | `divergence-renamer` |
| `commands/hooks/before-execute.md` | 74% | `divergence-renamer` |
| `commands/tasks.md` | 75% | `divergence-renamer` |
| `CHANGELOG.md` | 77% | `prose-rephraser` |
| `commands/review.md` | 80% | `divergence-renamer` |
| `scripts/e2e-smoke.sh` | 83% | frontmatter asserted on both surfaces |
| `scripts/validate-release-archive.py` | 87% | `script-refactorer` |
| `scripts/e2e-agent-claude.sh` | 90% | Copilot CLI added to the seven e2e stages |
| `scripts/validate-extension-metadata.py` | 90% | `script-refactorer` |
| `README.md` | 134% | `prose-rephraser` |

The installable payload has moved a long way from upstream in wording and,
since the previous measurement, in shape as well: `extension.yml` now
declares a sixth command (`speckit.specflow.gate`) and five hooks
(`after_clarify`, `after_analyze`, `after_tasks`, `before_implement`,
`after_implement`). The `commands/` and `commands/hooks/` sections below are
corrected to match. The fork's remaining behavioral divergence lives in
`.claude/`, `standards/`, `scripts/`, and CI, which the archive strips.

Reproduce the table from the repository root:

```bash
git clone -q https://github.com/WangX0111/superspec "$SCRATCH/upstream"
cd specflow && git ls-files | grep -E '\.(md|yml|py|sh)$' | grep -v '^examples/' \
  | grep -vE 'copilot-cli\.md|lint-standards\.py|score-artifacts\.py|tests/test_(lint_standards|score_artifacts|validate_extension_metadata|validate_release_archive)\.py|commands/gate\.md|commands/hooks/after-(analyze|clarify)\.md|scripts/e2e-(agent-copilot|stages)\.sh|^gates/|references/superpowers-mapping\.md' \
  | xargs python3 ../.claude/divergence/measure-divergence.py --local . --upstream "$SCRATCH/upstream"
```

The excluded paths are files this fork added with no upstream counterpart,
plus `references/superpowers-mapping.md`, measured separately above because
it no longer shares upstream's file name. `measure-divergence.py` exits
nonzero on the first missing or misnamed counterpart it hits, so the
unfiltered command in earlier revisions of this file never produced the full
table above.

## commands/hooks/

Five hook prompts spec-kit runs around its own commands: `after-clarify.md`,
`after-analyze.md`, `after-tasks.md`, `before-execute.md`, and
`after-execute.md`. The last two file names predate the rename in
`extension.yml`'s `hooks:` block to `before_implement` and `after_implement`;
their content already carries the new names (each file opens `# Hook:
before_implement` or `# Hook: after_implement`), so this is a Names-table gap,
not an open option.

- **Tighten** `after-tasks.md` to read `progress.yml` before writing, as
  `before-execute.md` does at step 6. Claimed by: D-01.
- **Add** a `before_tasks` hook that stops when the spec's Open Questions table
  has unresolved rows. Spec-kit fires `hooks.before_tasks`; upstream never
  registered one. Cheaper than it was: G-24 T241 made `e2e-smoke.sh` and
  `ci.yml` derive their hook count from `extension.yml`, and the hook tuple in
  `validate-extension-metadata.py` already passes a fourth hook unedited. Only
  the manifest and the hook's own prompt need writing. Verify: all three checks
  stay green with no manual count edit. Claimed by: none, deferred in
  `roadmap.md`.
- **Extend** `after-execute.md` to write a findings file `review.md` reads.
  Done, PR #57.
- Done: `after-clarify.md` and `after-analyze.md`, each firing
  `speckit.specflow.gate`, which `gates/bash/write-marker.sh` backs. Neither
  has an upstream counterpart (see `commands/` below).
- **Replace**: not warranted. The hooks are thin and spec-kit fixes their order.

## commands/

Command names are asserted in `e2e-smoke.sh`, `e2e-agent-claude.sh`, and
`ci.yml`. Every Process-step change needs a smoke-test update.

- **Extend** `brainstorm.md` to write resolved questions to `decisions.md` as
  ADR-lite entries. G-17 covers the read. Claimed by: G-20.
- **Replace** `execute.md` with a dispatcher over the `.claude/agents/` squad on
  Claude Code, keeping the sequential walk as the Copilot fallback. Verify: both
  paths pass the agent e2e in dry run. Claimed by: none, deferred in
  `roadmap.md` until G-19 lands a snapshot to assert against.
- Done: a sixth command, `gate.md` (`speckit.specflow.gate`), writes a
  feature's `.clarified` or `.analyzed` marker from the `after_clarify` and
  `after_analyze` hooks. `extension.yml` lists it under `provides.commands`;
  no upstream counterpart exists, so it is excluded from the Measured state
  table above rather than shown as 100 percent.
- Done: the status marker column (D-07, PR #55), the compound-task rule (D-06,
  PR #58, with ADR-0016 on why the lint is blunt), and the review risk tier
  (D-03, PR #59).

## SKILL.md

The largest single behavior contract and the file a `~/.agents/skills/` install
reads first.

- **Tighten** the phase list to name the gate marker each phase produces, so it
  and `workflow-guide.md` cannot drift. Claimed by: G-22.
- **Replace**: not warranted. Spec-kit's skill loader expects the upstream
  section shape.
- Done: the Target surface section (D-03, PR #59) and the prose rewrite
  (PR #70).

## references/

Content is cheap to diverge; the file names are not. Both validators require
`references/superpowers-mapping.md` and `references/workflow-guide.md` to
exist by that exact path, so a content rewrite is free but a rename is not.
See G-30 for the cost of renaming `superpowers-bridge.md`.

- Done: `superpowers-mapping.md` maps the review personas under
  `.claude/agents/` to the `requesting-code-review` skill, so Claude Code
  prefers the squad and Copilot the skill (G-22). Its `prose-rephraser` pass
  then took it to 57 percent.
- **Extend** `workflow-guide.md` with one section per new gate or marker. The
  Gate markers table stays the single source for marker names, and
  `e2e-smoke.sh` asserts every row since PR #53. Claimed by: continuing, per
  item.
- Done: the `copilot-cli.md` reference (D-03, PR #59).

## templates/

Spec-kit's own commands fill these and expect the upstream section names. A
change here reaches every downstream artifact.

- **Extend** `constitution-template.md` with a review-stage table naming a model
  class per stage, never an agent alias. Claimed by: G-21.
- **Extend** `tasks-template.md` with a Verify column. Claimed by: G-21.
- **Tighten** `checklist-template.md` with an `R-NNN` column joining `CHK` rows
  to review findings. Claimed by: G-21.
- **Replace**: not warranted.

## examples/

Export-ignored. Teaching material and the scorer's test fixture.
`static-landing-page/` is upstream's snapshot and predates every gate this fork
added; `sample-workflow.md` walks a "User Authentication" feature no snapshot
contains, with abbreviated outputs that show none of the markers.
`mutation-gate-sample/` and `seeded-bug/` are this fork's, added in PR #64 and
the scorer work.

- **Replace** the snapshot with a run of this fork's pipeline, **Add** a
  failing-gate snapshot, and **Remove** `sample-workflow.md`. All three claimed
  by: G-19.
- **Add** a snapshot of a Copilot CLI run, so the fallback path has an example
  and a dry-run fixture. Verify: the snapshot has no `.claude/` files and every
  stage artifact. Claimed by: none. Needs a Copilot e2e script, backlog item 27.
- **Tighten**: regenerate the snapshot spec when `spec-template.md` changes, so
  the scorer golden matches the template. Verify: `score-artifacts.py` passes
  after a template change. Claimed by: G-13, implicitly.

## scripts/

Export-ignored, so divergence here never reaches an installed extension.

- **Tighten** `e2e-smoke.sh` to assert the Process-step count of each command
  file, so a dropped step fails before merge. The gate-marker half landed in
  PR #53. Claimed by: G-23.
- **Add** an upstream drift check that compares the vendored commit to upstream
  `HEAD`. Claimed by: G-23.
- Done: both e2e scripts refactored to `standards/code.md` (PR #68), and
  `validate-release-archive.py` before them.

## assets/

12 MiB of workflow diagrams, export-ignored because one PNG broke install for
every user (upstream issue #6).

- **Remove** the PNGs and check in Mermaid or SVG source beside the deck under
  `presentation/`, per `standards/presentations.md`. Verify:
  `validate-release-archive.py` passes and the README renders the diagram from
  source. Claimed by: none.
- **Add** or **Extend**: not an option. There is no reason to ship a binary the
  archive strips.

## Names

Names are asserted in more files than behavior is. Each row states where a
rename lands, so the cost is known before the move.

| Name | Today | Asserted in | Cost | Claimed by |
|------|-------|-------------|------|------------|
| `author:` | "Specflow Contributors" | Nothing | Free | none |
| `examples/static-landing-page/` | Upstream's feature | dry run, `score-artifacts.yml`, README | Replaced, not renamed | G-19 |
| `commands/hooks/*.md` file names | `after-tasks`, `before-execute`, `after-execute` | Nothing; the manifest maps hooks to commands | Free, and no reason | none |
| `commands/*.md` file names | `status`, `brainstorm`, `tasks`, `execute`, `review` | The `file:` field in `extension.yml` | Cheap, and no reason | none |
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
`prose-rephraser` or `script-refactorer` pass. An empty Waiting on cell means
the pass has run and the Real column records what it measured. Mark a row
`(working on)` before dispatching, and commit that mark to `main`. The Real
column is the raw divergence measured above, not a proxy for whether the pass
has run: `README.md` measured 134% both before and after its pass, because its
content had already diverged from upstream.

| File | Real | Agent | Waiting on |
|------|------|-------|------------|
| `commands/hooks/after-tasks.md` | 60% | `prose-rephraser` | |
| `extension.yml` | 56% | `prose-rephraser` | |
| `CHANGELOG.md` | 77% | `prose-rephraser` | |
| `scripts/validate-extension-metadata.py` | 90% | `script-refactorer` | |
| `references/superpowers-mapping.md` | 57% | `prose-rephraser` | |
| `README.md` | 134% | `prose-rephraser` | |
| `templates/plan-template.md` | 23% | `prose-rephraser` | |
| `templates/spec-template.md` | 38% | `prose-rephraser` | |
| `templates/checklist-template.md` | 45% | `prose-rephraser` | |
| `templates/constitution-template.md` | 48% | `prose-rephraser` | |
| `templates/tasks-template.md` | 49% | `prose-rephraser` | |
| `scripts/validate-release-archive.py` | 87% | `script-refactorer` | |

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
manifest keys still spelled as upstream spells them, measured 2026-09-25
against `c20ac6c1`. Read it before choosing a rewrite target.

Structure is moving, but only where a renamer pass has reached. Every command
file keeps upstream's `## Usage`, `## Process`, `## Output`, and
`## Human Checkpoints`; the two headings each lost are its
`# speckit.specflow.*` title, which the namespace rename moved, and
`## Superpowers Adaptation`, now `## Skill Mode Behavior`. The three hook
prompts keep 2 of 3 headings, having traded `## Checks` for
`## Preconditions`. `extension.yml` keeps all six top-level keys. ADR-0013
bars `prose-rephraser` from touching a heading, so a prose pass moves the Real
column without moving the shape; only `divergence-renamer` moves the shape.

| File | Real | Named units shared |
|------|------|--------------------|
| `templates/plan-template.md` | 23% | 12 of 13 headings |
| `templates/spec-template.md` | 38% | 15 of 19 headings |
| `templates/checklist-template.md` | 45% | 11 of 12 headings |
| `templates/constitution-template.md` | 50% | 15 of 17 headings |
| `templates/tasks-template.md` | 49% | 19 of 20 headings |
| `commands/hooks/*.md` | 65 to 74% | 2 of 3 each |
| `extension.yml` | 56% | 6 of 6 keys |
| `SKILL.md` | 57% | 14 of 21 headings |
| `references/workflow-guide.md` | 65% | 30 of 43 headings |
| `commands/*.md` | 61 to 80% | 4 of 5 to 7 headings |
| `scripts/validate-release-archive.py` | 87% | 3 of 13 functions |
| `scripts/validate-extension-metadata.py` | 90% | 2 of 4 functions |
| `scripts/e2e-agent-claude.sh` | 90% | 0 of 11 functions |

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
reached. The inherited shipped documents still share about 77 percent of their
heading structure with upstream, down from 84 percent before the two renames
recorded below. ADR-0013 freezes a heading during a prose pass, so moving shape
is the only lever left and `divergence-renamer` is the only agent that pulls it.

A heading counts here when it is still spelled as upstream spells it and no
script, workflow, or test in this repository greps it. A heading that is free
but already moved buys nothing, so the count excludes it; earlier revisions of
this table counted every free heading and so overstated what a pass could reach.
Measured 2026-09-25 by searching every heading against `*.sh`, `*.py`, and
`*.yml` outside `examples/`. A coincidental substring match counts as frozen, so
each number is a floor.

| File | Free and still upstream's | Risk | Yield |
|------|---------------------------|------|-------|
| `references/workflow-guide.md` | 19 of 34 | Low. A reference; content is cheap to diverge, the file name is not | Highest |
| `templates/tasks-template.md` | 19 of 20 | Medium. Renaming strands the recorded goldens | High |
| `templates/constitution-template.md` | 14 of 17 | Medium. Same | Medium |
| `SKILL.md` | 13 of 21 | Medium. Spec-kit's skill loader expects the upstream section shape | Medium |
| `templates/checklist-template.md` | 10 of 12 | Medium. Same | Medium |
| `templates/plan-template.md` | 9 of 13 | Medium. Same | Medium |
| `templates/spec-template.md` | 8 of 19 | Medium. Same | Low |
| `commands/*.md` | 1 or 2 of 5 to 7 | High. `e2e-smoke.sh` counts each file's Process steps | Low |
| `commands/hooks/*.md` | 1 of 3 each | Low | Low; one heading each |

Done: the two repeated names below, each moved by one `divergence-renamer` pass
in a single-purpose worktree, verified against `e2e-smoke.sh`,
`lint-standards.py`, and (for the hooks) `.claude/hooks/tests/run.sh` before
merging.

- `## Superpowers Adaptation`, upstream's section name in 4 of the 5 command
  files, is now `## Skill Mode Behavior`.
- `## Checks` opened all five hook prompts, not three as first sampled; the
  sample missed `after-clarify.md` and `after-analyze.md`. All five are now
  `## Preconditions`.

Order of attack, by yield per unit of risk:

1. `references/workflow-guide.md`. Nineteen reachable headings in the file with
   the loosest contract. Nothing a catalog install runs asserts its section
   names, and the Gate markers table `e2e-smoke.sh` reads is matched by its
   rows, not by the heading above them.
2. `templates/tasks-template.md`, then the other four in the order of the
   table. It ties the guide on count and loses on risk: regenerate the goldens
   in the same change, because a template and its recorded output drift the
   moment either moves.
3. `SKILL.md`, last among the worthwhile ones. Thirteen reachable headings, and
   it is the file a `~/.agents/skills/` install reads first, so a section rename
   needs the loader checked before it lands.

Not worth taking: the command files. Two or three free headings each, against a
smoke test that counts Process steps per file and a workflow guide that names
every artifact each command writes. The cost is three assertions updated per
heading moved, for the smallest share of the remaining similarity.

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
