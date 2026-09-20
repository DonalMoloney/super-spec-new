# Roadmap

Every piece of open work on this repository: the divergence items, the second
wave of groups, the spec-kit 1.0 decay groups, the hygiene debt, and the
scoped backlog behind them. Read it to pick the next thing to build. `reference.md` holds the divergence option
space each group draws from and the measured distance to upstream;
`docs/review-research.md` holds the evidence behind the review stack.

The first wave, G-01 to G-18, merged between PR #8 and PR #53. The first
cleanup wave, Q-01 to Q-28, merged in PR #53. Neither appears below. Every
status line was verified against `main` at `ff774c2` on 2026-09-20 by running
the check named beside it. G-24 to G-28 were measured the same day against
spec-kit 1.0.9.dev0 at `d4229c0`.

## How to use this file

- **One item = one git worktree = one PR.** Items are independent unless a
  `Depends on:` line says otherwise.
- Tasks inside a group run in order. Each is singular and ends with a `Verify:`
  line that proves it done. Tick the box when that line passes.
- Before creating a worktree, append `(working on)` to the item header and
  commit that to `main`, so a second session does not start the same item.
- After merge: remove the worktree, mark the header `(merged: PR #N)`, and
  record any non-obvious choice in `decisions.md`.
- A shipped file under `specflow/` runs on the Copilot CLI as well as Claude
  Code. A group that adds a step to a command needs a fallback that works with
  no hooks, no subagents, and no `model:` frontmatter.
- A `(working on)` marker is a claim on a file, not a reservation forever. If
  its worktree has no commits and no open PR, clear the marker.

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

## Open work at a glance

| Item | What it closes | Effort | Verified open by |
|---|---|---|---|
| G-19 | The examples are upstream's, not this fork's | high | `static-landing-page/` and `sample-workflow.md` both present |
| G-24 | Six command lines read a template path instead of resolving it | medium | See the nine checks under G-24 |
| G-26 | The gates cannot run on the Copilot CLI | medium | Blocked by ADR-0022; T261 done, T262 and T263 behind three prerequisites |

## D-01 — `after-tasks.md` reads the progress file (merged: `8fb7813`)

Executor: `general-purpose`. Effort: low. Depends on: none.

`before-execute.md` reads `progress.yml` at its step 6. `after-tasks.md` is
the one hook that assumes a fresh run, so a resumed feature rewrites state the
earlier run already wrote.

- [x] D-01 Add a progress-state read step

Verify: the Process in `commands/hooks/after-tasks.md` lists a step that reads
`progress.yml` before writing, and `e2e-smoke.sh` passes.

After this merges, `commands/hooks/after-tasks.md` is free for
`prose-rephraser`; it is the last shipped file still byte-identical to
upstream.

## D-05 — Stale names and the missing CHANGELOG section (merged: `feb6777`, `8659302`, `cf85936`)

Executor: `general-purpose`. Effort: low. Depends on: none.

Four separate stale strings, all verified present on `main` at `ff774c2`.
They are one item because they are one rename, and because five files in
`reference.md` wait on it. D-05a needed no commit: the retitle was already on
disk, uncommitted, when the item was picked up, and landed in `cbfc731`.

- [x] D-05a Retitle the findings schema

`.claude/review/schema.json` line 3 titles the schema
`SuperspecReviewFindings`, a name this fork dropped. Verify: the title names
specflow and `bash .claude/hooks/tests/run.sh` passes.

- [x] D-05b Delete the dead README check

`validate-extension-metadata.py` line 147 tests the README for a
`specify extension add superpowers-bridge --from ./specflow` string that no
README has carried since the rename, so the branch can never run. Verify: the
branch is gone and `python3 scripts/validate-extension-metadata.py` exits 0.

- [x] D-05c Open a CHANGELOG Unreleased section

`specflow/CHANGELOG.md` opens at 1.0.2 and records nothing since. Verify: the
file has an `## [Unreleased]` section and this PR adds a line to it.

- [x] D-05d Rewrite the manifest strings

`extension.yml` line 4 reads `name: "Superpowers Bridge"`, which uses a banned
metaphor, and the descriptions carry "Enhanced" five times, "Deep-dive"
twice, and "Intelligent" once, on eight lines. Nothing greps them. Verify: `grep -cE
'Enhanced|Deep-dive|Intelligent' specflow/extension.yml` prints 0 and both
validators pass.

## G-19 — Examples produced by this fork, not upstream

Executor: `bdd-orchestrator`. Model: opus. Effort: high. Depends on: none.

`examples/static-landing-page/` is upstream's snapshot and predates every gate
marker, the Threat Model and Traceability sections, and the Changelog section.
`sample-workflow.md` walks a feature no snapshot contains. The scorer's golden
is the upstream snapshot, and `e2e-agent-claude.sh` line 223 seeds its dry run
from it.

- [x] T191 Record a fresh run of the current pipeline

Drive `e2e-agent-claude.sh` live on a feature of this fork's choosing, not a
landing page, and snapshot it under `examples/<feature>/`. Verify: the
snapshot carries `.clarified`, `.analyzed`, `## Threat Model`,
`## Traceability`, and `## Changelog`.

- [x] T192 Point the scorer golden at the new snapshot

Verify: `score-artifacts.py` passes on the new snapshot and
`score-artifacts.yml` replays it.

- [x] T193 Add a failing-gate snapshot

Record a run that stops with `ANALYZE_REQUIRED` and the rerun that clears it.
Verify: the snapshot contains the stop code and the rerun.

- [ ] T194 Delete `static-landing-page/` and `sample-workflow.md`

Deferred on 2026-09-20, and not for its blast radius. T191 was meant to replace
upstream's snapshot with a run of this fork's pipeline. No API key exists in
this environment, so `link-audit/` was constructed from the templates and gate
rules instead, and says so in its own README. `static-landing-page/` is the
only recorded run in the repository. Deleting it would leave the examples
directory holding nothing that any pipeline actually produced, which is a worse
state than holding one stale recording beside one honest reconstruction.

Run T194 after a live run replaces `link-audit/`'s constructed artifacts with
recorded ones. The move then costs what the notes below say: the hook suite
reads `static-landing-page/specs` at `run.sh:110`, `test_score_artifacts.py`
defines the seeded-bug golden as that snapshot minus one row, and
`e2e-agent-claude.sh` seeds its 30 dry-run assertions from it.

Update `README.md` and the dry run, which seeds from the snapshot.

`validate-extension-metadata.py` line 107 lists `examples/sample-workflow.md`
in the docs it scans for stale command references, and `read` at line 20 calls
`read_text` with no existence check. Deleting the file raises an unhandled
`FileNotFoundError` and CI runs that validator, so drop the entry from the
list in the same change. `scripts/tests/test_validate_extension_metadata.py`
names the file too and its fixture copy needs the same edit.

Ordering dependency on G-24 T248, delivered in `4d9d3f1`: that commit repointed
`SKILL.md`'s Additional Resources bullet at
`https://github.com/DonalMoloney/super-spec-new/blob/main/specflow/examples/sample-workflow.md`,
because `examples/` is export-ignored and the old relative link broke on
install. Deleting the file makes that pointer dangle. Repoint the bullet at
the snapshot T191 records, or delete the bullet.

Verify: `E2E_DRY_RUN=1 bash scripts/e2e-agent-claude.sh` exits 0, and this
grep prints nothing.

```bash
grep -r 'static-landing-page\|sample-workflow' specflow/ README.md
```

## G-20 — Brainstorm writes decisions (merged: `bc35f95`)

Executor: `general-purpose`. Model: sonnet. Effort: medium. Depends on: none.

G-17 made `brainstorm.md` read `decisions.md` at step 3. Nothing writes to it,
so a question resolved in a session is lost by the next one.

- [x] T201 Write a resolved question as an ADR-lite entry

Add a Process step that appends a Context, Decision, Consequences entry to
`decisions.md` for each Open Questions row the run marks Resolved, numbered
after the highest existing ADR. Verify: the step names the file and the shape,
and `e2e-smoke.sh` passes.

- [x] T202 Assert the write in the dry run

Verify: the brainstorm stage assertion checks that a resolved fixture row
lands in `decisions.md`.

## G-21 — Templates carry their own checks (merged: `9c9c878`)

Executor: `general-purpose`. Model: sonnet. Effort: medium. Depends on: none.

- [x] T211 Add a Verify column to `tasks-template.md`

The template carries an Independent Test line per story and no per-task check.
Verify: the template's task table header carries the column and
`score-artifacts.py` still parses the golden.

- [x] T212 Add a review-stage table to `constitution-template.md`

Three rows (pre-mortem, single reviewer, panel) and a model class per row
(fast, standard, strongest). No agent alias, per constraint 3 in
`reference.md`. Verify: `grep -E 'opus|sonnet|haiku'` on the template prints
nothing.

- [x] T213 Add an `R-NNN` column to `checklist-template.md`

Joins the `CHK` row ids to review finding ids. Verify: the column exists and
the dry run's checklist assertion passes.

## G-22 — `SKILL.md` and the bridge name the gates and the personas (merged: `139eaf8`)

Executor: `general-purpose`. Model: sonnet. Effort: low. Depends on: none.
D-03 (PR #59) added the Target surface section. PR #70 rewrote the prose, so
`SKILL.md` now stands at 40 percent real change.

- [x] T221 Name the gate marker on each phase line

`SKILL.md` names `.clarified` and `.analyzed` in its status section, so a grep
for the markers already passes. It does not name the marker each phase
produces, which is what stops the phase list and `workflow-guide.md` drifting.
Verify: every phase line under `## Unified Workflow` that produces a marker
names it, and every marker in the Gate markers table of `workflow-guide.md`
appears under that heading.

- [x] T222 Map the review personas in `superpowers-bridge.md`

One row per `.claude/agents/*-reviewer.md` file, naming the
`requesting-code-review` step it replaces on Claude Code and the skill step
Copilot runs instead. Verify: one row per `.claude/agents/*-reviewer.md` file.
Measured 10 on 2026-09-20; an earlier revision of this line said eight, which
went stale when reviewers were added.

## G-23 — The smoke test catches a dropped step, and CI watches upstream (merged: `d34d637`)

Executor: `bdd-orchestrator`. Model: sonnet. Effort: low. Depends on: none.
T231 absorbs the step-count half of the old D-04, which PR #53 left open when
it landed the gate-marker half.

- [x] T231 Assert the Process-step count of each command file

Read the counts from a table at the top of `e2e-smoke.sh`. Counted on
2026-09-20: status 7, brainstorm 7, tasks 10, execute 9, review 8. Verify:
deleting one step from any command fails the smoke test.

- [x] T232 Add `.claude/divergence/check-upstream.sh`

Print the vendored commit, `git ls-remote` upstream `HEAD`, and exit 1 when
they differ. Upstream `HEAD` was `c20ac6c` on 2026-09-11. Verify: a hook test
stubs `git ls-remote` and checks both exits.

- [x] T233 Run the drift check weekly in CI

A scheduled workflow that opens one issue when the script exits 1 and none
when an open issue already exists. Verify: the workflow file exists and is
`schedule`-triggered.

## G-24 — Fix the spec-kit 1.0 decay (merged)

Worktree `~/PycharmProjects/worktrees/fix-speckit-decay`, branch
`fix-speckit-decay`, cut from `main` at `ff774c2`. Executor:
`bdd-orchestrator`. Model: opus. Move: Tighten. Effort: medium. Depends on:
none. Diverges: no for T241, T245, and T249; yes for the rest.

The branch was cut before this file reached `main`, so the ADR-0017 rule that
a claim lives in `roadmap.md` could not be followed at the time. This section
is the claim, written after the fact. Clear the marker when the PR merges.

Upstream superspec targets spec-kit 0.x and is frozen. Spec-kit is at
1.0.9.dev0, commit `d4229c0` of 2026-09-18, and it resolves a template through
a four-priority stack. `resolve_template_content` in
`.specify/scripts/bash/common.sh` implements it, and
`.specify/scripts/bash/resolve-template.sh <name>` calls it.

| Priority | Source | Strategy |
|---|---|---|
| 1 | `.specify/templates/overrides/<name>.md` | replace |
| 2 | `.specify/presets/` | replace, prepend, append, or wrap |
| 3 | `.specify/extensions/<id>/templates/<name>.md` | replace |
| 4 | `.specify/templates/<name>.md` | core's own file |

Our templates win at priority 3. Measured on 2026-09-20 in a real install,
`bash .specify/scripts/bash/resolve-template.sh spec-template` returns md5
`c4ca2833a604d64c5e8fdfcd6dc060f0`, which is our file. Six command lines never
call the resolver: they read `.specify/templates/<name>.md`, priority 4, where
core's file sits unchanged at md5 `45ac8538bc1220324c9f0d610145b53f` both
before and after `specify extension add specflow`. A file does exist at that
path, so nothing reports the miss. The command writes an artifact with no Open
Questions, Threat Model, Traceability, or Brainstorm Log section, and
`score-artifacts.py` then grades it for a Traceability section core's template
never produces.

- [x] T241 Derive the command and hook counts from the manifest

Done in `f68f45c`. `e2e-smoke.sh` and `.github/workflows/ci.yml` read
`extension.yml` instead of repeating what it declares. This closes N-10 with
two corrections to the scope the survey stated. First, the tuple at
`validate-extension-metadata.py` line 86 needed no edit: it checks that three
named hooks exist, so adding a fourth already exits 0. Second, the survey
missed a fifth literal, `SPECFLOW_COMMANDS=(status brainstorm tasks execute
review)` at `e2e-smoke.sh` line 25, which the commit also derives. Real scope
was two files, not four. Verify: adding a hook to a scratch manifest changes
every assertion with no script edit.

- [x] T242 Resolve every template through `resolve-template.sh`

Done in `0f60186`.

Six lines read a template path directly: `commands/tasks.md` line 14, and
`SKILL.md` lines 239, 256, 302, 325, and 399. Each becomes a call to the
resolver spec-kit installs under `.specify/scripts/`. The command stops and
reports when the resolver fails; it does not fall back to reading
`.specify/templates/<name>.md`, which returns only the core layer. ADR-0019
records why, and supersedes this task's original fallback clause. Verify: in a
real install `resolve-template.sh spec-template`
returns our content while `.specify/templates/spec-template.md` still holds
core's, and no command file reads a template path without the resolver.

- [x] T243 Remove the template copy step from `SKILL.md`

Done in `0f60186`.

Line 238 tells the agent to copy every file from the skill's `templates/`
directory into `.specify/templates/`. The copy is a workaround that makes the
direct reads in T242 find our content, and it overwrites core's files in
place, so it defeats the stack: a preset's contribution at priority 2 and
another extension's at priority 3 are both lost. Verify: Phase 0 of `SKILL.md`
has no copy step and `e2e-smoke.sh` passes. Closes the `SKILL.md` half of
N-20.

- [x] T244 Remove the template copy step from `workflow-guide.md`

Done in `0f60186`.

Lines 23 and 24 carry the same instruction and clobber the same files. Verify:
Phase 0 of the file has no copy step and `e2e-smoke.sh` passes. Closes the
`workflow-guide.md` half of N-20.

- [x] T245 Assert the resolved template in the smoke test

Done in `0f60186, extended to both surfaces in 65efe44`.

`e2e-smoke.sh` line 78 asserts that `.specify/templates/spec-template.md`
exists. It passes on core's file, which `specify init` writes before the
extension install, so the assertion proves nothing about specflow. Replace it
with two assertions: `resolve-template.sh spec-template` returns content
carrying our section headings, and `.specify/templates/spec-template.md` still
holds core's. Verify: the smoke test fails when
`.specify/extensions/specflow/templates/spec-template.md` is deleted.

- [x] T246 Correct the `.specify/` tree in `workflow-guide.md`

Done in `0f60186`.

The tree at line 20 lists `specs/` under `.specify/`. A real install has no
`.specify/specs`. A feature directory lives at the project root, which is the
gotcha `AGENTS.md` records and `e2e-smoke.sh` asserts. Verify: the tree has no
`specs/` entry and the text around it names the root path.

- [x] T247 Correct the Budgets section of `workflow-guide.md`

Done in `0c7ff4a`.

Line 436 says the budget flag's name is "not yet confirmed; see G-09 T092"
while `merge-gate.yml` passes `--max-budget-usd`. Line 448 carries
`[budget-flag-TBD]`. Line 450 names `.specify/telemetry.jsonl` while the hook
writes `.claude/telemetry.jsonl`. Closes N-21. Verify: this grep prints 0.

```bash
grep -c 'TBD\|not yet confirmed\|specify/telemetry' specflow/references/workflow-guide.md
```

- [x] T248 Remove the two install-time breaks in `SKILL.md`

Done in `4d9d3f1`.

Line 25 links `assets/workflow-overview-en.png`, a path `.gitattributes`
strips from the archive, so an installed extension links a file it does not
have. Line 11 carries `description_zh`, against the Language rule in
`standards/documentation.md`. PR #70 rewrote the prose around both and kept
them. Verify: `git archive HEAD:specflow | tar -t` lists every path `SKILL.md`
links, and `grep -c '_zh' specflow/SKILL.md` prints 0. Closes N-19.

- [x] T249 Correct the agent count in `.github/copilot-instructions.md`

Done in `9509fa8`.

Line 64 says the squad holds 17 agents. `.claude/agents/` holds 28, across the
BDD squad, the review panel, and the three rewrite agents. Verify: the number
in the file equals `ls .claude/agents/*.md | wc -l`. Closes N-22.

## G-25 — Decide the template mechanism in an ADR (merged: `41b33e5`)

Executor: `general-purpose`. Model: opus. Move: Replace. Effort: high.
Depends on: G-24 T242. Diverges: yes.

N-07 in `improvements/new-improvements/scoped-improvements.md` asks whether
the five templates become a preset. The question is open, and it needs an ADR
before any file moves. Both mechanisms resolve: spec-kit reads an installed
preset at priority 2 and an extension's templates at priority 3 of the stack
in G-24.

The choice is the strategy each mechanism allows. An extension template is
always a replace, so every improvement spec-kit makes to a core template is
lost the moment specflow ships its own copy. A preset takes `append`, which
adds our sections (Open Questions, Threat Model, Traceability, Brainstorm Log,
Changelog, Code Review Rules, Execution Strategy, Superpowers Execution) on
top of whatever core ships. The cost of replace is already visible: core's
`tasks-template.md` is 252 lines against our 225. G-25 measured the rest and
the framing did not survive: ours is the larger file for the other four
templates, and core's extra task lines are User Story 3 boilerplate and an
`## Implementation Strategy` section this fork replaced deliberately.

The price of moving: `provides.templates` leaves the manifest,
`validate-release-archive.py` and `e2e-smoke.sh` lose five assertions, and the
scorer golden is regenerated. Backlog item 25 is the alternative, which
reports the drift instead of ending it.

- [x] T251 Record the template mechanism as an ADR

State what an extension template can do, what a preset can do, and which of
the two this repository adopts, with the reason. Verify: the ADR is in
`decisions.md`, dated, with a status.

- [x] T252 Move the five templates to a preset

Not run, and it will not be: T251 rejected the preset, so this task's own
precondition never held. ADR-0021 records the reason. Reopen it only by
superseding that ADR, not by reviving this line.

## G-26 — Register the gates as agent-native hooks (blocked: ADR-0022)

Executor: `bdd-orchestrator`. Model: opus. Move: Add. Effort: medium. Depends
on: G-24. Diverges: yes.

Spec-kit's manifest takes an `events:` block, read at
`extensions/__init__.py` lines 381 and 397, that installs hooks into the
agent's own hook system. The canonical events are `session_start`,
`pre_tool_use`, `post_tool_use`, `stop`, `user_prompt_submit`, and
`session_end`. `events.py` line 2287 merges Copilot config through
`_merge_copilot_json` in the `copilot-json` format, so an `events:` block is
the supported route for running this repository's `.claude/hooks/` gates on
the Copilot CLI. Neither `scoped-improvements.md` nor `reference.md` names the
mechanism. Settle this group before N-03, which ships the same gates the long
way as `provides.scripts` under `gates/`, and before backlog item 28, which
writes a second hook config by hand.

- [x] T261 Write the event mapping

One row per gate script, naming the spec-kit event it registers on and the
adapter each surface needs from exit code to deny JSON. Verify: the table
names an event for `block-main-commit.sh`, `test-gate.sh`, `artifact-lint.sh`,
and `session-start.sh`.

- [ ] T262 Declare the block in `extension.yml`

Blocked by ADR-0022. Three prerequisites, each verified by G-26 against
spec-kit 1.0.9.dev0: our command files need YAML frontmatter with a `scripts:`
block, since none has any today and the dispatcher resolves the script through
it; Copilot's tool-payload field names need recording, because the gates read
`.tool_input.command` and `.tool_input.file_path` and a wrong key passes
everything; and the four gates need moving under `specflow/`, which reverses
ADR-0001 and adds `jq` as an install-time dependency. Copilot also drops the
`matcher` field Claude Code keeps, so a gate filters by tool name itself.

Verify: `grep -c '^events:' specflow/extension.yml` prints 1 and both
validators pass.

- [ ] T263 Assert the installed hook config in the smoke test

Verify: the Copilot leg of `e2e-smoke.sh` finds the hook file the install
wrote and names the events in it.

## G-28 — Settle the name before submitting a catalog entry (merged: `0cd7dd0`)

Executor: `general-purpose`. Model: opus. Move: Add. Effort: low. Depends on:
none. Diverges: no. No code.

Backlog item 23 adds a `catalog.json` and a README line telling a user to list
it. It does not say that spec-kit's `docs/community/extensions.md` already
lists three spec-kit-to-superpowers bridges: `superpowers-bridge` by
RbBtSn0w, `speckit-superpowers-bridge` by lihan3238, and `superspec` by
WangX0111, which is the upstream this repository forked.
`docs/community/friends.md` lists `cc-spex` beside them. specflow is in no
catalog. A fourth entry carrying our current description reads as a duplicate
of the third, under a near-identical summary.

- [x] T281 Write the one line that separates specflow from the three

Name what a reader gets here and nowhere else: the gate markers, the review
panel, the two-surface contract. Verify: the line is in `specflow/README.md`
and in the `description` field of `extension.yml`, worded the same.

- [x] T282 Decide whether the extension id changes

`reference.md` prices the id at 27 files and calls a rename not an option.
Record the answer beside backlog item 23 so the catalog work does not reopen
it. Verify: the answer is recorded with a date.

## G-29 — Two free wording moves reference.md priced but nobody claimed (merged: `525e172`)

Executor: `general-purpose`. Model: sonnet. Effort: low. Depends on: none.
Both rows come from the Names table in `reference.md`, marked `Free` with
`Claimed by: none`. Neither touches a file a validator, the smoke test, or a
test fixture reads.

- [x] T291 Drop "enhanced" from the `after_tasks` hook prompt

`extension.yml`'s `after_tasks` hook reads `prompt: "Run enhanced Superpowers
task decomposition and validation?"`. "Enhanced" is banned filler in
`standards/documentation.md`. This is a different line from the five
`description:` fields D-05d owns. Verify: `grep -n 'prompt:.*[Ee]nhanced'
specflow/extension.yml` prints nothing and
`python3 scripts/validate-extension-metadata.py` passes.

- [x] T292 Add the two tags nothing lists

`extension.yml`'s `tags:` list carries `superpowers`, `brainstorming`, `tdd`,
`code-review`, `subagent`, `workflow`. Neither target surface appears.
Verify: `grep -c '"claude-code"' specflow/extension.yml` and
`grep -c '"copilot"' specflow/extension.yml` each print 1, and
`python3 scripts/validate-extension-metadata.py` passes.

## G-31 — The fallback guide names a template only on the superpowers path (merged: `321c202`)

Executor: `general-purpose`. Model: sonnet. Move: Tighten. Effort: low.
Depends on: none. Diverges: yes.

`references/workflow-guide.md` is the built-in protocol an agent follows when
no superpowers skill is installed, which is what constraint 2 in
`reference.md` requires every command to have. Its Phase 4 names
`tasks-template` only inside step 2, and that step is conditional on the
`writing-plans` skill being detected. An agent on the no-superpowers path
reaches the end of Phase 4 without being told to resolve a template at all, so
the one path the document exists to serve is the one path it does not cover.
Phases 0, 1, and 3 each name their template unconditionally, so Phase 4 is
alone in this.

Found while fixing the resolver routing in `fd121f8`; out of scope there
because closing it means restructuring the step or adding one, not rewording.

- [x] T311 Name the tasks template outside the superpowers condition

Give Phase 4 an unconditional step that resolves `tasks-template` and reads
`TEMPLATE_CONTENT`, matching Phases 0, 1, and 3, and leave step 2's
`writing-plans` branch to describe only what that skill adds. Verify: Phase 4
names `tasks-template` on a line that no skill-detection condition governs,
and `e2e-smoke.sh` passes.

## G-34 — The fallback guide freezes when a command gains a step (merged: `00f2fc9`)

Executor: `bdd-orchestrator`. Model: opus. Move: Tighten. Effort: medium.
Depends on: none. Diverges: yes.

`references/workflow-guide.md` is the protocol an agent follows when no
superpowers skill is installed, which is what constraint 2 in `reference.md`
requires. It lags its command files, and nothing catches it: the smoke test
greps this file only for the gate-marker table.

Two instances were fixed on 2026-09-20 after being found by accident during
unrelated work. Phase 4 named its template only inside a skill-conditional
step, so the fallback path never resolved one (G-31). Phase 2 never described
the `decisions.md` write that `brainstorm.md` gained (G-20), and then briefly
described the write without the read, which is worse than neither.

An audit then found three more genuinely absent, plus two stated outside the
phase's Steps list where a reader walking the phase misses them.

| Phase | Command step | State |
|---|---|---|
| 4 | `tasks.md` step 8, stable `TNNN` IDs | absent; Session Resumability line 612 is weaker and elsewhere |
| 4 | `tasks.md` step 9, diff summary before writing | absent from the file |
| 6 | `review.md` step 7, append a spec gap to Open Questions | absent; the only Open Questions append is unrelated |
| 5 | `execute.md` step 7, the `handoff.md` write | stated in Session Resumability, not in Phase 5 |
| 5 | `execute.md` step 9, the `progress.yml` update | stated in a table, not in Phase 5 |

Five instances across three of the four mirrored phases, all the same shape.
`/speckit.specflow.status` is excluded by design: the guide is phase-structured
and status is not a phase.

- [x] T341 Mirror the three absent instructions

Verify: Phase 4 names the stable-ID rule and the diff summary, Phase 6 names
the Open Questions append, and `e2e-smoke.sh` passes.

- [x] T342 Move the two misplaced instructions into their phase

Verify: Phase 5's Steps list names `handoff.md` and the `progress.yml` update,
and each still appears once, not twice.

- [x] T343 Check the mirror mechanically

A prose diff is not checkable, but an artifact set is. Every path, marker, and
file name a command's Process steps write is a set; the phase that mirrors that
command must name the same set. Compare the two and fail on a member the phase
omits, the way `EXPECTED_PROCESS_STEPS` compares step counts. Verify: adding a
write to a command's Process fails the smoke test until its phase names the
same artifact, and the five rows above pass once T341 and T342 land.

## G-35 — Local verification and CI verification check different things (merged: `c23528e`)

Executor: `bdd-orchestrator`. Model: sonnet. Move: Add. Effort: low.
Depends on: none. Diverges: no.

`main` was red from `a8ffd71` to `6871486`, five pushes, and every branch that
landed in between reported green. Nothing was wrong with the branches: the
suite that failed is the one nobody ran.

`.github/workflows/ci.yml` runs `pytest scripts/tests`, `.claude/review/tests`
and `.claude/divergence/tests` on Python 3.12. The default `python3` on a
developer machine here is 3.9.6, which cannot collect
`test_lint_standards.py` or `test_validate_release_archive.py` because they
annotate `Path | None` at module scope. So `pytest scripts/tests` is not in
anyone's local routine, and the habitual local set, the hook suite, the smoke
test, both validators and the scorer, omits the one suite that caught the
break.

The failure itself was a golden pair drifting apart, which the scorer's own
test defends. The reason it reached `main` is that no single command answers
"did this pass what CI runs".

- [x] T351 Raise the annotations to the floor the tests already assume

Either add `from __future__ import annotations` to the two files or state a
Python floor and enforce it, so the suite collects on the interpreter a
contributor has. Verify: `python3 -m pytest specflow/scripts/tests -q`
collects every file on 3.9.

- [x] T352 Add one command that runs what CI runs

A script at the repository root running the three pytest targets, both
validators, the hook suite and the smoke test, in CI's order, exiting nonzero
on the first failure. Verify: the script's steps match `ci.yml` step for step,
and deleting a step from `ci.yml` without changing the script fails a test.

## G-42 — The catalog entry we publish cannot install anything (working on)

Executor: `general-purpose`. Model: sonnet. Move: Tighten. Effort: low.
Depends on: none. Diverges: no. Found by G-39 on 2026-09-20.

`specflow/README.md` tells a maintainer to paste a `catalog.community.json`
entry that carries no `download_url`. Spec-kit raises
`Extension 'specflow' has no download URL` at
`extensions/__init__.py:4384` before it fetches anything, so the entry is
unusable as written and backlog item 23 would submit it that way.

The URL that looks obvious is also wrong. `install_from_archive` at the same
file's line 2756 wants `extension.yml` at the archive root or inside its single
top-level directory. The repository tag ZIP unpacks to
`super-spec-new-<tag>/specflow/extension.yml`, two levels down, and aborts with
`No extension.yml found in archive`. Upstream superspec cites that URL safely
because its repository root is the extension; this fork nested the extension
under `specflow/`.

The installable artifact is the release asset `specflow-vX.Y.Z.zip` that
`release.yml` now builds and uploads, which is the same archive
`validate-release-archive.py` checks.

- [ ] T421 Give the catalog entry a working download URL

Verify: the snippet carries a `download_url` naming the release asset, and the
entry's fields match `extension.yml` field for field.

## G-41 — The guide and the goldens disagree on progress vocabulary (working on)

Executor: `general-purpose`. Model: sonnet. Move: Tighten. Effort: low.
Depends on: none. Diverges: no. Found by G-38 on 2026-09-20.

`workflow-guide.md`'s "Writing `progress.yml`" table says a command sets its
phase to `in_progress` on start and `done` on success. Both goldens write
`status: complete`, and `static-landing-page` also carries
`manual-browser-only`. So the document that defines the resumability contract
and the artifacts that implement it use different vocabularies.

`progress.yml` is the file every command reads to decide where a resumed run
picks up. A command following the guide looks for a value no artifact carries.
G-38's validator type-checks the field rather than enumerating it, because
enumerating either set rejects real files, so nothing catches the drift today.

- [ ] T411 Settle which vocabulary is canonical

Decide from what reads the field, not from which document is older. Verify: the
guide's table and both goldens use one set of values, and the choice is
recorded.

- [ ] T412 Enumerate the settled values in the validator

Verify: `validate-progress.py` rejects a status outside the settled set, both
goldens still validate clean, and the hook suite passes.

## G-40 — The merge gate judges a findings file it never validates (working on)

Executor: `bdd-orchestrator`. Model: sonnet. Move: Tighten. Effort: low.
Depends on: none. Diverges: no. Found by G-37 on 2026-09-20.

`merge-gate.sh` counts findings with `jq` and never runs
`.claude/review/validate-findings.py` against the file it is judging. A file
that is valid JSON but violates `schema.json` passes silently. Reproduced on
`main`: a finding with `"severity": "critical"` in lowercase, which the schema
enumerates as `Critical`, counts zero and prints `MERGE GATE PASSED.` with
exit 0.

ADR-0006 says a Critical or Important finding blocks unless fixed or rebutted.
A gate that cannot read the severity cannot apply that rule, and the failure is
silent rather than loud, so the reviewer who wrote the file learns nothing.
`/speckit.specflow.review` writes these files on both surfaces, and only the
CI headless step validates its own file today.

- [ ] T401 Validate a findings file before judging it

Run the existing validator on each file the globs match, and fail loudly on a
file that does not conform rather than counting zero. Verify: a hook test with
`"severity": "critical"` in lowercase blocks the merge and names the schema
violation, and a conforming file still blocks and passes as it did before.

## G-36 — No check runs on a release tag before users pull it (working on)

Executor: `bdd-orchestrator`. Model: sonnet. Move: Add. Effort: low.
Depends on: none. Diverges: no. Was backlog item 24.

The catalog downloads the tag ZIP. The last tag is v1.0.2 of 2026-08-07, and
nothing validates a tag before a user installs from it. Upstream issue #6 was
exactly this failure: a 12 MiB PNG took the archive over spec-kit's per-member
limit and broke install for everyone.

- [ ] T361 Validate the archive on a `v*` tag

`release.yml` on a `v*` tag runs `validate-release-archive.py <tag>` and
attaches the `git archive` ZIP and the validator output to the GitHub release.
Verify: the workflow is tag-triggered, and a dry run of its steps against the
current HEAD produces both assets.

- [ ] T362 Adopt a version rule for a prompt contract

A changed Process step or template section is minor, a renamed marker, command
or file is major, wording is patch. Verify: the rule is written in
`specflow/CHANGELOG.md`'s header or beside it, and names the three cases.

## G-37 — The merge gate never reads a feature's findings (working on)

Executor: `bdd-orchestrator`. Model: sonnet. Move: Tighten. Effort: low.
Depends on: none. Diverges: no. Was backlog item 29.

`review.md` has written `specs/NNN-*/review-findings.json` since PR #57, and
`merge-gate.sh`'s default glob does not include it. A review run on the Copilot
CLI writes findings the gate never reads, so a Critical finding blocks nothing
there.

- [ ] T371 Read the feature findings file in the merge gate

Verify: a hook test with a Critical finding in
`specs/001-x/review-findings.json` prints `MERGE BLOCKED`, and `merge-gate.yml`
passes both globs.

## G-38 — Nothing validates the resumability contract (working on)

Executor: `bdd-orchestrator`. Model: sonnet. Move: Add. Effort: low.
Depends on: none. Diverges: no. Was backlog item 30.

`progress.yml` is the file every command reads to resume, and nothing checks
it. A misspelled phase resumes at the wrong step with no message.

- [ ] T381 Add a progress-file validator

`.claude/review/validate-progress.py`, dependency-free like
`validate-findings.py`, checking the keys of `progress.yml`, phase names
against the Gate markers table in `workflow-guide.md`, and that every task ID
marked complete exists in `tasks.md`. `artifact-lint.sh` calls it on write.
Verify: three tests, an unknown phase, an unknown task ID, and a valid file.

## G-32 — The standards linter reads no YAML string (merged: `7cafc62`)

Executor: `bdd-orchestrator`. Model: sonnet. Move: Tighten. Effort: low.
Depends on: none. Diverges: no.

`scripts/lint-standards.py` collects tracked `.md` files only, so `.yml`, `.py`
and `.sh` are never opened and `extension.yml` has never been in scope. The
manifest is the file spec-kit's catalog shows a user, and it carried
"Superpowers Bridge", "Enhanced" five times, "Deep-dive" twice and
"Intelligent" once until D-05d and G-29 removed them by reading. The linter
reported 0 findings before and after each of those fixes, so an identical
string lands silently tomorrow.

Measured by G-29 on 2026-09-20: the file is 160 lines; the matching engine
already does the work and the gap is input, not logic. The design work is
deciding which strings are user-facing. `extension.description`, the five
command and five template `description:` fields, and the three hook `prompt:`
and `description:` fields are. `id`, `name`, `file`, `command`, and the
`optional_skills` ids are identifiers and must be exempt, or every
`test-driven-development` trips a match.

- [x] T321 Lint the manifest's user-facing strings

`findings_for` assumes text lines for its fenced-block and line-number
handling, so the YAML path reports through its own function rather than
reusing it. Verify: a banned word planted in `extension.yml`'s `description`
fails the linter, the same word in its `id` does not, and the suite passes.

## G-33 — The word-choice table is enforced by reading, not by a check (merged: `f4d9c6c`)

Executor: `bdd-orchestrator`. Model: sonnet. Move: Tighten. Effort: medium.
Depends on: G-32. Diverges: no.

`lint-standards.py` checked two rules: em-dashes, and the banned-words table it
parses out of `standards/documentation.md` at run time. The word-choice table,
the sentence-structure rules, and the per-document rules were checked nowhere.

The motivating example does not survive contact with the fix, and the record
should say so. "Verify task coverage" sat in `extension.yml` until G-29 read
it, but the word-choice row bans the phrase "verify that", not bare "verify",
so the check G-33 built still misses that string. Catching it needs a bare
"verify" row in the standard, which would then fire on the `| Task | Verify |`
column G-21 added to `tasks-template.md` and on every `Verify:` line this file
uses. The row was not added. The gap G-33 closes is real; the example that
motivated it is not the one it catches.

Harder than G-32, which is why it is separate. The banned table is a category
and a list; the word-choice table is two columns, so a check matches the "Not"
column and reports the "Write" suggestion. Its exclusions are contextual
(`execute (unless the command is execute)`, `issue (unless a tracker issue)`,
`update (unless a version bump)`), and `banned_entries` already drops
qualifier-carrying rows rather than guessing at them.

- [x] T331 Decide which word-choice rows a check can hold

A row whose exclusion needs the sentence's meaning is not checkable. Sort the
table into rows a matcher can judge and rows it cannot, and record the split.
Verify: the split is written down with a reason per excluded row.

- [x] T332 Check the rows that survive T331

Verify: a "Not" column word in a shipped document fails the linter and names
its "Write" replacement, an excluded row does not fire, and the suite passes.

## G-30 — Drop the "bridge" metaphor from `superpowers-bridge.md`'s name (merged: `68ade5b`)

Executor: `divergence-renamer`. Model: sonnet. Effort: medium. Depends on: none.
`standards/documentation.md`'s word-choice table bans "bridges" as a metaphor
that "says less than the literal term," yet the file the fork's own bridging
logic lives in is named for it. `reference.md` priced this rename at "about 8
files"; the real count is higher. `references/superpowers-mapping.md` is
required by name in `scripts/validate-extension-metadata.py` line 105 and
`scripts/validate-release-archive.py` line 49, and by a fixture in
`scripts/tests/test_validate_release_archive.py`, so the `references/`
section's claim that "nothing asserts against these structurally" does not
hold for this file. Sixteen files cite the path outright:
`AGENTS.md`, `presentation/marp-deck/deck.md`, both `improvements/` files,
`specflow/README.md`, `specflow/SKILL.md`, `specflow/references/workflow-guide.md`,
all five `specflow/commands/*.md` files, and the three script/test paths above.

- [x] T301 Rename the file and update every citing path

Pick a name that states what the file does (for example
`references/superpowers-mapping.md`), rename it, and update all sixteen
citing paths, including the two validators and the test fixture. Verify:
`grep -rl 'superpowers-bridge\.md' . --include='*.md' --include='*.py'
--include='*.yml'` prints nothing, `python3
scripts/validate-extension-metadata.py` and `python3
scripts/validate-release-archive.py` both pass, and `bash
scripts/e2e-smoke.sh` passes.

## Checked on 2026-09-20, no work needed

Measured against spec-kit 1.0.9.dev0 at `d4229c0`. Each line held, so do not
re-verify it when picking up G-24 to G-28.

| Claim | Measured |
|---|---|
| Hook events a core command fires | 20: `before_` and `after_` for each of the 10 core commands, in `templates/commands/*.md` |
| Workflow step types | 12, listed at `workflows/engine.py` line 142 |
| Core `spec-template.md` against ours | 131 lines against 197 |
| Core `tasks-template.md` against ours | 252 against 225. Core is larger for this one template only; ours is larger for the other four (constitution 123/50, spec 197/131, plan 130/113, checklist 120/45). Core's extra lines are User Story 3 boilerplate and an Implementation Strategy section this fork replaced on purpose, measured under G-25 |
| Agents under `.claude/agents/` | 28, against the 17 that `.github/copilot-instructions.md` line 64 states |

## Cleanup

Hygiene debt: work that needs no design, only a session short enough to run one
`Verify:` line. C-02 (stale local branches) and C-07 (the playbook split)
closed on 2026-09-20.

- [x] **C-01** Delete the merged remote branches. 46 were deleted on
  2026-09-20, not the 44 this line estimated. Each was checked first: 19 were
  ancestors of `origin/main` and 27 had a merged pull request, squash-merged so
  their tips were not ancestors. None had an open PR. `delete_branch_on_merge`
  is now true on the repository, so the list stops growing. Verify:
  `git branch -r` lists only `origin/main` and `origin/HEAD`.
- [x] **C-03** Rename the `imporvements/` directory to `improvements/`. Done
  on 2026-09-20 in `ab859e7`: 26 citations moved across 14 files, including
  `lint-standards.py`'s `EXCLUDED_DIRS` and the two fixtures that prove the
  exclusion works, which had to move together or the tests would pass while
  testing nothing. One citation keeps the typo on purpose:
  `docs/review-research.md:12` names the deleted `imporvements/imporvements2.md`,
  a file that never existed under the corrected spelling. Verify:
  `grep -rn imporvements . --exclude-dir=.git` prints that one line and no
  other.
- [x] **C-04** Retitle `presentation/use-guide/use-guide.md`. The H1 is a path.
  Verify: the H1 is a noun phrase and no header carries a capital after its
  first word except a proper noun.
- [x] **C-05** Delete the e2e work directory on a passing run. Both
  `e2e-smoke.sh` and `e2e-agent-claude.sh` print "Workdir kept at" and leave a
  directory under `$TMPDIR` every time they pass. Keep it only on failure or
  when `KEEP_WORKDIR=1`. Verify: after a passing run the printed path does not
  exist.
- [x] **C-06** Make the assertion count the last line of the agent dry run.
  The run prints the count already; the API-key hint follows it, so a reader
  sees the hint and not the result. Verify: the last line of `E2E_DRY_RUN=1
  bash scripts/e2e-agent-claude.sh` reads `N assertions, 0 failed`. Merged in
  `069a384`. The hint was not the real trailer: the `cleanup` EXIT trap printed
  `workdir kept:` after it, so the count now prints from the trap.
- [x] **C-08** Fix the vacuous pass in the `jq missing from PATH fails` hook
  case. Its setup runs `ln -s "$(command -v mutmut)" "$shim/mutmut"`, which
  errors when mutmut is absent, so the case exits 2 on the mutmut check and
  never reaches the jq check it names. It passes for the wrong reason on any
  machine without mutmut. Verify: the case fails when jq is on `PATH` and
  mutmut is not.
- [x] **C-09** Scope `artifact-lint.sh` by path instead of by basename. Two
  symptoms, one cause. Editing `specflow/commands/tasks.md` trips `no task
  lines with stable IDs (expected '- [ ] T001 ...')`, because the lint matches
  the basename `tasks.md`; a command file is a behavior contract, not a
  feature's task list. Separately, the hook fired on a file under
  `~/.claude/projects/`, outside this repository entirely, and blocked the
  write over an em-dash. Verify: an edit to `specflow/commands/tasks.md`
  passes, a `specs/NNN-*/tasks.md` with no stable IDs still fails, and a path
  outside the repository is not linted.

## Backlog: items 23 to 36

Scoped, not decomposed. Claiming one means turning it into a group numbered
G-24 or later. Each keeps the three constraints in `reference.md`. Facts marked
*verified* were checked on 2026-09-11; sources are in
`docs/review-research.md`.

### Ship it: install, upgrade, release

**23. A catalog entry users can search.** A `catalog.json` (spec-kit catalog
schema 1.0) at the repository root, served raw from GitHub, and a README line
telling a user to list it in `.specify/extension-catalogs.yml` with
`install_allowed: true` or to set `SPECKIT_CATALOG_URL`. Spec-kit's own catalog
is empty by design, so `specify extension search specflow` finds nothing and
the only install paths are `--from <zip>` and `--dev`. *Verified:* catalogs are
JSON files with a schema version, listed with name, url, priority, and
`install_allowed`; check the entry fields against `docs/reference/extensions.md`
in your spec-kit version. G-28 settles the naming collision with the three
bridges already listed, so run it first. Verify: a CI step runs
`SPECKIT_CATALOG_URL=<raw url> specify extension search specflow` and greps the
id. Effort: low. Depends on: 24.

**24. A release workflow that runs the archive validator.** `release.yml` on a
`v*` tag runs `validate-release-archive.py <tag>` and attaches the `git archive`
ZIP and the validator output to the GitHub release. The last tag is v1.0.2
(2026-08-07), the catalog downloads the tag ZIP, and no check runs on a tag
before users pull it; upstream issue #6 was exactly that. Adopt a version rule
for a prompt contract: a changed Process step or template section is minor, a
renamed marker, command, or file is major, wording is patch. Verify: pushing a
tag produces a release with two assets, and `specify extension add specflow
--from <release zip>` installs in a fresh project. Effort: low. Depends on:
D-05c for the CHANGELOG input.

**25. A template drift report in status.** A stamp comment in every shipped
template (`<!-- specflow template: spec-template 1.1.0 -->`) and a Doctor
section in `/speckit.specflow.status` that compares the stamps in
`.specify/templates/` with the installed extension version and lists stale
templates. `/speckit.constitution` copies templates once; an extension upgrade
leaves the copies behind and nothing says so. G-24 T243 and T244 delete the
copy step, and an extension upgrade rewrites
`.specify/extensions/specflow/templates/` in place, so after them no stale
copy is left to report. Write it as a prose Process step
so it runs on the Copilot CLI. Verify: the smoke test greps the stamp, and a
dry-run fixture with an old stamp prints the stale line. Effort: low. Depends
on: 24.

**26. An upgrade path the smoke test walks.** `e2e-smoke.sh` installs the
v1.0.2 release ZIP, installs the checkout over it with `--dev`, and asserts no
stale command file or `extensions.yml` entry remains. Every user who installed
1.0.2 upgrades through this path and it has never run. Verify: the smoke test
reports the upgrade assertions and passes. Effort: low. Depends on: 24.

### Prove it on both runtimes

**27. An agent-driven e2e for the Copilot CLI.**
`scripts/e2e-agent-copilot.sh`, the twin of the Claude script: the dry run
replays the snapshot, the live run drives each stage with `copilot -p "<stage
prompt>"` and per-tool allow flags such as `--allow-tool='shell(git:*)'`, under
`timeout`. The README says the extension runs on the Copilot CLI, and the only
Copilot check is the install layout the smoke test asserts (PR #59). Move the
stage prompts and assertions into a sourced `e2e-stages.sh` both scripts share.
*Verified:* `-p` is the non-interactive mode and `--allow-tool` scopes
permissions; check the flag names against the programmatic reference in your
version, and never use `--allow-all-tools` on a runner that can push. Verify:
`E2E_DRY_RUN=1 bash scripts/e2e-agent-copilot.sh` exits 0 in CI. Effort:
medium. Depends on: none.

**28. Gate hooks on the Copilot CLI.** A `.github/hooks/specflow.json`
registering the existing scripts under `preToolUse` (block-main-commit,
test-gate), `postToolUse` (artifact-lint), and `sessionStart` (session-start).
`copilot-cli.md` says the agent runs each gate itself as a command step, which
is the prompt-level gate that first-wave item 2 exists to remove. The scripts
stay in `.claude/hooks/` (ADR-0001); a thin adapter maps exit 2 to the deny
JSON the Copilot hook expects on stdout, and the config carries both `bash` and
`powershell` keys. Record the second harness directory as an ADR. *Verified:*
Copilot CLI hooks live in `.github/hooks/`, support `sessionStart`,
`sessionEnd`, `userPromptSubmitted`, `preToolUse`, `postToolUse`, and
`errorOccurred`, and `preToolUse` denies by a JSON object on stdout, not by exit
code. Verify: a hook test runs the adapter on a blocked command and asserts the
deny JSON; a live Copilot session refuses `git commit` on main. Effort: medium.
Depends on: 27 for the live check.

**29. The merge gate reads the feature's findings file.** `merge-gate.sh`
includes `specs/*/review-findings.json` in its default glob, the file
`review.md` writes since PR #57, and `merge-gate.yml` passes both globs. A
review on the Copilot CLI writes findings the gate never reads, so a Critical
finding blocks nothing there. Verify: a hook test with a Critical finding in
`specs/001-x/review-findings.json` prints `MERGE BLOCKED`. Effort: low. Depends
on: none.

**30. A contract for the progress file.**
`.claude/review/validate-progress.py`, dependency-free like
`validate-findings.py`, checking the keys of `progress.yml`, phase names against
the Gate markers table, and that every task ID marked complete exists in
`tasks.md`; `artifact-lint.sh` calls it on write. `progress.yml` is the
resumability contract and nothing validates it, so a misspelled phase resumes at
the wrong step without a message. Verify: three tests: an unknown phase, an
unknown task ID, and a valid file. Effort: low. Depends on: none.

### Operate it

**31. A reviewer scorecard.** `.claude/review/scorecard.sh` reads every findings
file, prints per-persona precision (fixed divided by fixed plus rejected plus
rebutted) with counts, and writes `.claude/review/scorecard.md`. Section 3.9 of
`docs/review-research.md` and the weekly ritual in Part 6 both assume a
scorecard and none exists, so a persona below 0.5 precision cannot be found, let
alone demoted. Verify: a fixture with four findings, two fixed and two rejected,
prints 0.50. Effort: low. Depends on: none.

**32. Cost per feature against the budget table.**
`.claude/hooks/cost-report.sh` sums `total_cost_usd` per feature from
`.specify/telemetry.jsonl`, prints a table beside the Budgets table in
`workflow-guide.md`, and exits 1 when a feature is over budget. G-16 set budgets
and G-07 logs phases; nothing joins them, so a budget is a number nobody checks.
Verify: a fixture over budget exits 1 and names the feature. Effort: low.
Depends on: none.

**33. The lint checks a traceability row names a real test.** Once `.analyzed`
exists, `artifact-lint.sh` reads the `## Traceability` rows and fails when the
named test is not found in the test tree. `spec-template.md` records that the
scorer reads only the Test name column, not whether the test exists, so an
invented name passes. Verify: a hook test with a row naming a missing test
blocks. Effort: low. Depends on: none.

**34. A seeded-ambiguity golden.** `examples/seeded-ambiguity/`, a spec with one
planted ambiguity such as an undefined sort order, and a scorer dimension for
whether brainstorm or clarify surfaced it as an open question. The scorer proves
the reviewer finds a seeded bug; nothing proves the spec phase finds a seeded
ambiguity, and the spec phase is where upstream is thinnest. Verify:
`score-artifacts.py` scores the new golden and `score-artifacts.yml` replays it.
Effort: medium. Depends on: G-19.

**35. A tested superpowers version range.** `superpowers.yml` records the
installed superpowers version from the plugin manifest,
`superpowers-mapping.md` states the tested range, and status warns outside it.
Superpowers v6.0 rewrote `subagent-driven-development` and v6.2 moved the SDD
workspace; the bridge assumes a skill shape and nothing says which. Verify: a
dry-run fixture with `version: 5.0.0` prints the warning. Effort: low. Depends
on: none.

**36. Upstream the resync-safe moves.** Open pull requests against
WangX0111/superspec for the Tighten moves tagged "breaks resync: rarely": the
after-tasks progress read (D-01), the status marker column (D-07), the
compound-task rule (D-06), and the Copilot fallback rows (D-03). Every accepted
move shrinks the diff the drift check in G-23 reports, and the fork's value is
the `.claude/` toolkit, not five prompt files. Verify: the PR links are recorded
beside each bullet in `reference.md`. Effort: low. Depends on: none. No code.

## Deferred

- **Multi-feature concurrency** (first-wave item 11): revisit after G-14's
  `[P]` dispatch has run on three features. None has run yet.
- **The mutation gate's CI step**: PR #64 added `.claude/hooks/mutation-gate.sh`
  and a sample project under `specflow/examples/mutation-gate-sample/`. The
  `merge-gate.yml` mutation step at line 90 still runs `mutmut run
  --paths-to-mutate`, a mutmut 2 flag that mutmut 3 rejects. Replace that run
  line with `bash .claude/hooks/mutation-gate.sh <project-dir>` in the CI wave.
  The eight mutation cases in `.claude/hooks/tests/run.sh` fail on a machine
  without mutmut, which CI installs from `requirements-dev.txt`. Install it
  locally before reading a red run as a regression.
- **Replace `execute.md` with a squad dispatcher**: the one Replace move worth
  taking, and only after G-19 gives it a snapshot to assert against on both
  runtimes.
- **A `before_tasks` hook** that stops on unresolved Open Questions: same cost
  class as a sixth command, because `e2e-smoke.sh`, `ci.yml`, and the hook
  tuple in `validate-extension-metadata.py` all assert the hook count.
- **A Copilot CLI run snapshot** under `examples/`: needs the Copilot e2e
  script, backlog item 27.
- **A spec-kit workflow file** (N-06 in
  `improvements/new-improvements/scoped-improvements.md`): deferred on
  2026-09-20. Most of its stated value was running the gates on the Copilot
  CLI, which the `events:` block in G-26 buys for less. Reprice it after G-26.
- **A spec-kit bundle** (N-08): deferred on 2026-09-20. It composes the
  workflow above with the preset G-25 decides, so it cannot start before
  either.

## Suggested order

1. G-24 first. Its worktree is open, and no other group corrects a statement
   an agent acts on every run.
2. D-01 and D-05 next. Both are low effort and five rewrite rows in
   `reference.md` wait on them.
3. G-20, G-21, G-22, and G-23 in parallel worktrees. None touches a file
   another holds.
4. G-26 before N-03 and before backlog item 28, both of which it may shrink.
5. C-05 and C-06 before the next script change, so the change lands on a clean
   base. C-01 and C-04 fit any short session.
6. C-03 in its own PR, once no worktree is open.
7. G-25 after G-24 T242, so the ADR is written against commands that call
   the resolver.
8. G-19 last, so its snapshot records every gate the other groups add.
9. Backlog item 24, then G-28, then backlog items 23 and 26.

Pick the item whose `Verify:` line you can run before you start. An item whose
check you cannot run today is a design task, not a roadmap task.
