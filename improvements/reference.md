# How specflow/ can diverge from upstream

For each part of the extension, the ways it can diverge from upstream superspec
without breaking spec-kit's install contract. Read it when choosing where the
next roadmap item lands. `roadmap.md` holds the committed work; this file holds
the option space and the measured distance to upstream.

Percentages are the real (rebrand-normalized) change against the vendored
upstream at the root commit (`bda4ef0`, upstream `c20ac6c`). Upstream `HEAD`
was still `c20ac6c` on 2026-09-28. An option a roadmap item already claims names
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

- **Tighten** `after-tasks.md` to read `progress.yml` before writing, as
  `before-execute.md` does at step 6. Claimed by: D-01.
- Done: `before-tasks.md`, a `before_tasks` hook that stops when the spec's
  Open Questions table has unresolved rows, or the constitution is missing.
  G-56, PR #78.
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
  paths pass the agent e2e in dry run. Dropped on 2026-09-28: the install
  archive strips `.claude/agents/`, so a shipped command cannot dispatch it.
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
- **Replace**: Low. Spec-kit 0.16.2 never reads the extension-root `SKILL.md`;
  it renders one skill per `commands/*.md`. An external `~/.agents/skills/`
  loader's section expectations are unverified.
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
`link-audit/` is a recorded run of this fork's pipeline and the scorer's
golden. Each `seeded-*/` directory copies its feature directory with one
planted flaw. `mutation-gate-sample/` feeds the mutation gate. No upstream
text remains here.

The reproduce command above excludes every path under `examples/`, so the
directory sits outside the Measured state table.

- **Replace** the snapshot with a run of this fork's pipeline, **Add** a
  failing-gate snapshot, and **Remove** `sample-workflow.md`. Done under G-19.
  `link-audit/analyze-gate.md` records the gate refusing the marker and the
  rerun that cleared it.
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

Deleted. The directory held 12 MiB of workflow diagrams, export-ignored
because one PNG broke install for every user (upstream issue #6).

- Done: both PNGs removed and replaced by
  `presentation/marp-deck/pipeline-overview.mmd` and its rendered `.svg`,
  linked from `specflow/README.md`. G-58, PR #91.
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
`prose-rephraser` or `script-refactorer` pass. An empty Waiting on cell means
the pass has run and the Real column records what it measured. Mark a row
`(working on)` before dispatching, and commit that mark to `main`. The Real
column is the raw divergence measured above, not a proxy for whether the pass
has run: `README.md` measured 134% both before and after its `prose-rephraser`
pass, because its content had already diverged from upstream. It now measures
129%, moved by two later, unrelated changes: G-50 T540 moved 59 lines of
catalog-submission process to `references/publishing.md`, and G-58 dropped the
PNG links. `extension.yml` measured 56% at its `prose-rephraser` pass and now
measures 67%, moved by G-56's `before_tasks` hook registration and G-26's
`events:` block, also unrelated to the pass.

| File | Real | Agent | Waiting on |
|------|------|-------|------------|
| `commands/hooks/after-tasks.md` | 65% | `prose-rephraser` | |
| `extension.yml` | 67% | `prose-rephraser` | |
| `CHANGELOG.md` | 87% | `prose-rephraser` | |
| `scripts/validate-extension-metadata.py` | 91% | `script-refactorer` | |
| `references/superpowers-mapping.md` | 57% | `prose-rephraser` | |
| `README.md` | 129% | `prose-rephraser` | |
| `templates/plan-template.md` | 28% | `prose-rephraser` | |
| `templates/spec-template.md` | 58% | `prose-rephraser` | |
| `templates/checklist-template.md` | 48% | `prose-rephraser` | |
| `templates/constitution-template.md` | 53% | `prose-rephraser` | |
| `templates/tasks-template.md` | 54% | `prose-rephraser` | |
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
reached. G-50 (merged 2026-09-25) executed most of what this table
recommended for `references/workflow-guide.md` and `SKILL.md`: title
rewrites, 4 heading renames in the guide, 8 in `SKILL.md`, and a reorder in
both. `references/workflow-guide.md`'s row below is re-verified 2026-09-25
against the same per-heading guard check the rest of the table used; the
`templates/*.md` and `commands/*.md` rows are unaffected, since no G-50 task
renamed a template or command heading.

A heading counts here when it is still spelled as upstream spells it and no
script, workflow, or test in this repository greps it. A heading that is free
but already moved buys nothing, so the count excludes it; earlier revisions of
this table counted every free heading and so overstated what a pass could reach.
Measured 2026-09-11, re-verified 2026-09-25 for `references/workflow-guide.md`
and `SKILL.md`, by searching every heading against `*.sh`, `*.py`, and `*.yml`
outside `examples/`. A coincidental substring match counts as frozen, so each
number is a floor.

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

Done: the two repeated names below, each moved by one `divergence-renamer` pass
in a single-purpose worktree, verified against `e2e-smoke.sh`,
`lint-standards.py`, and (for the hooks) `.claude/hooks/tests/run.sh` before
merging.

- `## Superpowers Adaptation`, upstream's section name in 4 of the 5 command
  files, is now `## Skill Mode Behavior`.
- `## Checks` opened all five hook prompts, not three as first sampled; the
  sample missed `after-clarify.md` and `after-analyze.md`. All five are now
  `## Preconditions`.

G-57 moved six more, each against the ADR-0043 bar:

- `references/workflow-guide.md`: Phase 2's `### Process` is now `### Steps`,
  the name every other phase gives its numbered list, and `### Iteration` is
  now `### Repeat runs`.
- `templates/tasks-template.md`: `## Superpowers Execution` is now
  `## Execution rules`, `### Execution Discipline by Marker` is now
  `### What each marker requires`, and `### Within Each User Story` is now
  `### Order within a user story`.
- `templates/plan-template.md`: `## Complexity Tracking` is now
  `## Justified constitution violations`.

Order of attack, by yield per unit of risk, before G-50:

1. `references/workflow-guide.md`. Nineteen reachable headings in the file
   with the loosest contract, with one exception: `### Gate markers` is
   frozen at `###` depth, not free. `specflow/gates/python/validate-progress.py`
   pins the literal `### Gate markers` in `GATE_SECTION` and raises
   `ContractUnavailable` without it, proven by renaming it in a scratch copy
   and watching the shipped gate exit 2. `e2e-smoke.sh` separately greps the
   table's rows, unscoped to the heading; both checks exist, and the heading
   check is the stricter one.
2. `templates/tasks-template.md`, then the other four in the order of the
   table. It ties the guide on count and loses on risk: regenerate the goldens
   in the same change, because a template and its recorded output drift the
   moment either moves.
3. `SKILL.md`, last among the worthwhile ones. Thirteen reachable headings.
   Spec-kit 0.16.2's own loader is checked and clear: it never opens the
   extension-root `SKILL.md`. The file a `~/.agents/skills/` install reads
   first still wants its section expectations checked before a rename lands.

G-50 executed items 2 and 3 (`templates/tasks-template.md`'s reachable prose
untouched, so it still leads at 19; `SKILL.md` down to 1 of 21) and most of
item 1 (`references/workflow-guide.md` down to 10 of 46, re-verified above).
G-57 then took six headings across three of those files. Order of attack now:
`templates/tasks-template.md` first (16, Medium risk), then
`templates/constitution-template.md` (14), `templates/checklist-template.md`
(10), `references/workflow-guide.md` (9, Low risk against the templates'
Medium), then `templates/plan-template.md` and `templates/spec-template.md`
(8 each).
`SKILL.md` (1) has dropped below the command and hook files and is no longer
worth a dedicated pass on its own.

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
| `## Dependencies & Execution Order` | `templates/tasks-template.md` | Two ideas joined by an ampersand | Moved to `## Task order` under G-60, in the template and every golden copy |
| `## Phase N: Polish & Cross-Cutting Concerns` | `templates/tasks-template.md` | Ampersand, and "cross-cutting concerns" is jargon | Free: no scorer pattern reads `## Phase`; the goldens carry the heading |
| `## Technical Context` | `templates/plan-template.md` | "Context" is the vaguest available noun | Frozen: `artifact-lint.sh` requires the name on a filled plan.md |
| `### Key Entities *(include if feature involves data)*` | `templates/spec-template.md` | Instruction inside a heading; "key" is a banned adjective | Moved to `### Entities` under G-60, with the condition as the section's first sentence |
| `## [Custom Category]` | `templates/checklist-template.md` | Placeholder, frozen | None |
| `## Path Conventions` | `templates/tasks-template.md` | Reads as policy; the section lists paths | Dropped under G-60: one line points at plan.md's Project Structure |

`SKILL.md`'s four shared headings are the core command names
(`/speckit.specify`, `/speckit.plan`, `/speckit.constitution`,
`/speckit.checklist`). They are spec-kit's, not upstream's, and never move.

G-57's remaining renames were dropped on 2026-09-28; a rename here needs a reason of its own.
