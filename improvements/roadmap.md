# Roadmap

Every piece of open work on this repository, ranked. Read it to pick the next
thing to build. It is the only file that holds a claim or a checkbox
(ADR-0017). `reference.md` holds the divergence option space each group draws
from and the measured distance to upstream; `docs/review-research.md` holds the
evidence behind the review stack.

`priority.md` and `new-improvements/scoped-improvements.md` were folded into
this file and deleted on 2026-09-21. Their open items are below; git history
holds the rest.

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
| G-26 | The gates cannot run on the Copilot CLI | medium | Blocked by ADR-0022; T261 and G-55's script move done, T262 and T263 behind the remaining `post_tool_use` one-event-one-handler design question |

## G-19 — Examples produced by this fork, not upstream (merged: PR #81)

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

- [x] T194 Delete `static-landing-page/` and `sample-workflow.md`

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

When a key exists, the live run is one session and one feature, in this order.

1. Export `ANTHROPIC_API_KEY` and run `bash scripts/e2e-agent-claude.sh` with
   the link-audit description from `examples/link-audit/README.md` as the
   stage 2 prompt. Keep the work directory the script reports.
2. Copy `specs/001-*/` from that directory over `examples/link-audit/specs/`.
3. Rewrite `examples/link-audit/README.md` to say the run was recorded, with
   the date, the model, and `git rev-parse HEAD`. Delete the word
   "constructed".
4. Replace the sentence in `examples/static-landing-page/README.md` that says
   nothing is hand-edited with the list of its hand edits, starting with
   `.analyzed` from `df50cb8`; `git log --oneline -- specflow/examples/static-landing-page`
   names the other four.
5. Point `SNAPSHOT` in `e2e-stages.sh` at `examples/link-audit`, then fix every
   assertion that named the old snapshot's content.
6. Build `examples/seeded-ambiguity/` from the recorded spec with one sort
   order left unspecified, then add `score_seeded_ambiguity` to
   `score-artifacts.py` with a test.

## G-26 — Register the gates as agent-native hooks (blocked: ADR-0022) (working on)

Executor: `bdd-orchestrator`. Model: opus. Move: Add. Effort: medium. Depends
on: G-24. Diverges: yes.

Spec-kit's manifest takes an `events:` block, read at
`extensions/__init__.py` lines 381 and 397, that installs hooks into the
agent's own hook system. The canonical events are `session_start`,
`pre_tool_use`, `post_tool_use`, `stop`, `user_prompt_submit`, and
`session_end`. `events.py` line 2287 merges Copilot config through
`_merge_copilot_json` in the `copilot-json` format, so an `events:` block is
the supported route for running this repository's `.claude/hooks/` gates on
the Copilot CLI. `reference.md` does not name the mechanism. Settle this group before backlog item 28, which
writes a second hook config by hand.

- [x] T261 Write the event mapping

One row per gate script, naming the spec-kit event it registers on and the
adapter each surface needs from exit code to deny JSON. Verify: the table
names an event for `block-main-commit.sh`, `test-gate.sh`, `artifact-lint.sh`,
and `session-start.sh`.

- [ ] T262 Declare the block in `extension.yml`

Blocked, and shipping the block today would brick the extension. One of the
three prerequisites cleared on 2026-09-20: `docs/agent-event-mapping.md`
records Copilot's `toolName`, `toolArgs.command`, and `toolArgs.path`.
ADR-0027 covers the `jq` dependency. The frontmatter prerequisite is not
cleared: every command file's source carries a `scripts:` block, but a real
install strips it. Verified on 2026-09-25 by installing this checkout with
`specify extension add specflow --dev` into a scratch spec-kit project: the
installed `.claude/skills/speckit-specflow-tasks/SKILL.md` frontmatter
carries `name`, `description`, `compatibility`, and `metadata` only. The
command's Process step still names
`.specify/scripts/bash/resolve-template.sh` in prose and resolves templates
correctly regardless, so this gap blocks only the `events:` block's own
prerequisite claim, not template resolution.

What remains is a handler. An `events:` entry names a command, the dispatcher
resolves that command to one script, and that script receives a hook payload on
stdin and nothing else. No shipped script reads one: `speckit.specflow.gate`
resolves to `write-marker.sh`, which takes two arguments and exits 2 without
them, so registering it on `pre_tool_use` denies every Bash call. Reproduced
against spec-kit `d4229c0`:

```
$ echo '{"toolName":"bash","toolArgs":{"command":"ls"}}' | python3 .specify/events.py speckit.specflow.gate pre_tool_use 30
write-marker: got 0 argument(s); expected 2.
DISPATCHER EXIT=2
```

The four scripts that do read a payload, `block-main-commit.sh`,
`test-gate.sh`, `artifact-lint.sh`, and `session-start.sh`, are still under
`.claude/`; ADR-0025 moved a different four. Moving them is the real
prerequisite. Note also that `validate_events` requires each `events:` value to
be a mapping, so one event name takes one entry: the mapping table's two
`post_tool_use` gates cannot both register. Copilot drops the `matcher` field
Claude Code keeps, so a gate filters by tool name itself.

Verify: `grep -c '^events:' specflow/extension.yml` prints 1 and both
validators pass.

- [ ] T263 Assert the installed hook config in the smoke test

Verify: the Copilot leg of `e2e-smoke.sh` finds the hook file the install
wrote and names the events in it.

## G-43 — SKILL.md documents a progress file the validator rejects (merged: direct)

Executor: `general-purpose`. Model: sonnet. Move: Tighten. Effort: low.
Depends on: none. Diverges: no. Found by G-41 on 2026-09-20. Not started.

`specflow/SKILL.md` lines 120 to 134 document a different `progress.yml` schema
from the one the goldens carry and `validate-progress.py` enforces: `feature`
and `created` keys, `current_phase` holding a phase name rather than a number,
and `phases` as a mapping of command name to `{status, updated}`. An agent
following that block writes a file the validator rejects on four counts.

`workflow-guide.md` line 663 has a smaller version of the same problem: it tells
an agent to update `completed_tasks` and `current_task`, neither of which is in
the schema, so the validator rejects both as unknown keys.

G-41 settled the vocabulary and deliberately left the schema alone, because
changing a documented shape is a different move from changing a word.

- [x] T431 Make SKILL.md and the guide document the schema the goldens carry

Verify: a `progress.yml` written by following `SKILL.md` alone validates clean,
and `grep` for `completed_tasks` and `current_task` in `workflow-guide.md`
prints nothing.

## G-45 — The merge gate cannot read `code-reviewer`'s findings (merged: direct)

Executor: `bdd-orchestrator`. Model: sonnet. Move: Extend. Effort: low.
Depends on: none. Raised on 2026-09-20 while rewriting the eight persona
bodies.

`merge-gate.sh` reads `.claude/review/*.json` and `specs/*/review-findings.json`
and blocks on an unresolved Critical or Important finding. `code-reviewer.md`
states its output as findings grouped Critical, Important, and Suggestion in
prose, and cites no schema. It is the only persona in the Review personas
table of `references/superpowers-mapping.md` whose Critical finding cannot
reach the gate, so the whole-change-set review is the one review a merge
never waits on.

- [x] T451 Decide whether `code-reviewer` writes a findings document

The other nine personas write the shape `references/findings-schema.json`
declares. `code-reviewer` runs as phase 11 of the BDD squad, where
`bdd-orchestrator` reads its prose directly, so switching its output changes a
contract inside the squad rather than only a reviewer file. Record the choice
as an ADR. Verify: the ADR names which consumer reads `code-reviewer`'s output
and states whether the gate is meant to block on it.

- [x] T452 Make the chosen contract true in the file

Either give `code-reviewer.md` an `## Output format` naming
`references/findings-schema.json`, matching the eight personas, or state in
that file why its output stays prose and that the merge gate does not read it.
Verify: `grep -L 'findings-schema.json' .claude/agents/*-reviewer.md` prints
nothing, or `code-reviewer.md` carries the sentence that explains the
exception.

## G-49 — No check catches a document that has gone out of date (merged: direct)

Executor: `bdd-orchestrator`. Model: sonnet. Effort: low. Depends on: none.
Raised on 2026-09-21.

Two documents were found stating things that had stopped being true, both in
one afternoon. `AGENTS.md` opened by telling every agent "No commits exist on
`main` yet; this is a fresh checkout" while `main` carried seventy. Seven rows
of `reference.md`'s Names table described renames that had already shipped, one
of them citing `.claude/review/schema.json`, a file that no longer exists. Both
were fixed in `5a5e8db`, by reading, not by a check.

`lint-standards.py` reads every Markdown file already, so it is where a
currency check belongs. It has two blind spots of its own, found the same way:
the metaphor rule in `standards/documentation.md` sits in prose outside the
banned table, so the word "bridge" survived in five places while the linter
reported 73 files clean; and the check matched "bridge" but not "bridges" or
"bridging", so two of those five needed a hand grep to find.

- [x] T491 Fail the build when a repository document cites a path that does not exist

Verify: adding a line citing `specflow/nope.md` to any linted file makes
`python3 specflow/scripts/lint-standards.py` exit nonzero, naming the file, the
line, and the missing path.

- [x] T492 Match inflected forms in the banned-word check

`banned_entries` builds one pattern per table entry. A noun with a verb form
escapes it. Verify: a fixture containing "bridging" is reported when "bridge"
is a banned entry.

- [x] T493 Record whether "bridge" joins the banned table in `standards/documentation.md`

The unqualified entry catches 5 lines, of which 2 are `CHANGELOG.md` entries
that record the old name accurately ("The extension is listed as Specflow, not
Superpowers Bridge"). A qualified entry such as "bridge (as metaphor)" is
ignored, because `banned_entries` returns unqualified entries only. So the
choice is a per-rule CHANGELOG exclusion or leaving the rule unenforced.
Verify: the outcome is an ADR in `decisions.md`, whichever way it goes.

- [x] T494 Re-check every count a document states against the repository

`AGENTS.md`, both READMEs, and `SKILL.md` state counts: commands, hooks,
templates, scripts, agents, assertions. Verify: each count is listed beside the
command that produced it, and every one matches.

## G-50 — Diverge more: wording, layout, and correctness fixes from the 2026-09-25 survey (merged: direct)

Executor: `general-purpose` per task, or `prose-rephraser`/`script-refactorer`/
`divergence-renamer` where named. Effort: low unless stated. Depends on: none
unless stated. Raised on 2026-09-25 by seven parallel read-only surveys, one
per shipped file or file group, each proving its guard claims against the
actual scripts and tests rather than assuming `reference.md`'s existing risk
notes. Three surveys disproved a claim in `reference.md` itself (T510, T536,
T548 below); fix those first, since later tasks in this group cite the
corrected version.

Two cross-file couplings span two tasks each and must land together:
`## Session Resumability` is spelled identically in both `SKILL.md:116` and
`workflow-guide.md`, so a rename of one without the other leaves two names for
one concept (T520 covers `SKILL.md`'s copy only; renaming both is a
`divergence-renamer` job, not yet a separate task — do not take T520 without
also renaming the guide's copy in the same change). T514's `superpowers.yml`
sample move must land in the same commit as the matching edit to
`workflow-guide.md:717-735`, named in that task.

### references/workflow-guide.md

- [x] T500 Rewrite the file's title and drop its progressive-disclosure framing

Replace the title `# Running Specflow Without Superpowers` with `# The
specflow workflow, phase by phase`: the file also documents skill mode in
Phases 2 through 6, so the current title describes only half the file.
Replace the two-sentence intro (lines 3-5) with a paragraph stating each
section is one phase carrying its command, gate, steps, and exit criteria,
that a reader reads only their own phase, and that a phase with a skill
alternative says so under its Skill mode heading. Drop "progressive
disclosure": `standards/documentation.md` bans describing the document and
bars jargon the reader is not in.
Verify: `bash verify.sh` passes; `python3 specflow/scripts/lint-standards.py`
reports 0 findings.

- [x] T501 Rename Phase 0 for the artifact it writes

Replace the heading `## Phase 0: Project Initialization` with `## Phase 0:
Constitution`. The phase writes `constitution.md`; this file's own Budgets
table and `SKILL.md` already call the row "0 - Constitution". Do not change
any later body citation of "Phase 0" (the number, not the name, is what other
sections cite).
Verify: `bash verify.sh` passes; `grep -rF 'Project Initialization' specflow/`
returns nothing.

- [x] T502 Rename the Phase 2 mode headings to the repo's skill-mode vocabulary

Replace `### Superpowers Integration` with `### Skill mode` and `### Built-in
Fallback Protocol` with `### Fallback mode`. Four command files already say
`## Skill Mode Behavior`; this file is the one place still using the old
pair. Do not touch `### Process` on line 152, which `e2e-smoke.sh:66` asserts
verbatim.
Verify: `bash verify.sh` passes; `grep -rF 'Built-in Fallback Protocol'
specflow/` returns nothing.

- [x] T503 Rename the four Session Resumability subheadings from labels to claims

Replace `` ### Progress File: `progress.yml` `` with `` ### What
`progress.yml` holds ``, `### Resume Check Protocol` with `### The check
every command runs first`, `### Phase-Specific Resume Rules` with `### Where
each phase resumes`, and `` ### Superpowers Status File: `superpowers.yml` ``
with `` ### What `superpowers.yml` caches ``. Leave `` ### Writing
`progress.yml` `` alone; it already reads as an imperative. Leave every body
line unchanged.
Verify: `bash verify.sh` passes; `grep -rF -e 'Resume Check Protocol' -e
'Phase-Specific Resume Rules' -e 'Progress File:' -e 'Superpowers Status
File:' specflow/` returns nothing.

- [x] T504 Rewrite the 15 sample brainstorm questions to the documentation standard

Rewrite each of the 15 quoted questions under the five `#### Category`
headings (lines 124-150). Keep each question's concept, its `[bracket]`
placeholder, its quotation marks, and three questions per category. Drop the
contractions ("What's" becomes "What is"), the capitals-for-emphasis in "Who
should NOT have access to [resource]?", and the weak verbs `handle`,
`needed`, and `should` that `standards/documentation.md`'s word-choice table
rejects. ADR-0028 authorizes rewriting sample content the same as any prose.
Verify: `bash verify.sh` passes; `python3 specflow/scripts/lint-standards.py`
reports 0 findings.

- [x] T505 Add an Exit Criteria section to Phases 2, 5, and 6

Four of seven phases state how a reader knows the phase is done; three do
not. Add a `### Exit Criteria` heading with a bullet list to Phase 2 (after
`### Iteration`, before its closing `---`), Phase 5 (after `### Human
Checkpoint Protocol`, before its closing `---`), and Phase 6 (after `###
Steps`, before its closing `---`), matching the bullet style of the four
existing Exit Criteria sections. Phase 2: the Brainstorm Log carries a dated
entry, every category is covered or skipped, each resolved choice has a
`decisions.md` entry. Phase 5: every task line in `tasks.md` is checked or
`skipped` with a stated reason, `progress.yml` records each phase status,
every checkpoint was confirmed. Phase 6: each reported finding scores 80 or
above, `review-findings.json` exists, each spec gap has an Open Questions row.
Verify: `bash verify.sh` passes; `grep -c '^### Exit Criteria'
specflow/references/workflow-guide.md` prints 7.

- [x] T506 Rewrite the Budgets section's unwrapped prose

Rewrap lines 515, 527, and 529 to the roughly 80-column width the rest of the
file uses. Delete the mirrored clause pair "A higher ceiling buys deeper
exploration; a lower ceiling keeps cost down." Replace the en-dash range
`20–50%` with "20 to 50 percent". Drop the word "actual" from "Track actual
spend per phase" and from "actual implementation" in the Phase 5 table row.
Keep the literal `--max-budget-usd 1.00`, which `.claude/hooks/cost-report.sh`
cites.
Verify: `bash verify.sh` passes; `grep -c '–' specflow/references/workflow-guide.md`
prints 0.

- [x] T507 Reorder the file to lead with the phase table

Move `## Quick Reference` and its `### Stop codes` subsection to sit
immediately after the intro paragraph and before `## Phase 0`. Move `##
Review stack` to sit immediately after Phase 6. Move `## Budgets` to the end
of the file. Keep every `---` rule between adjacent `##` sections; change no
line of any section's body. Depends on: land before T508, which renames a
heading this task moves.
Verify: `bash verify.sh` passes, including the structural smoke test and both
agent dry runs.

- [x] T508 Rename Quick Reference to name the table's columns

Replace the heading `## Quick Reference` with `## Gate and output per phase`.
Change nothing else. Depends on: T507.
Verify: `bash verify.sh` passes; `grep -rF 'Quick Reference' specflow/
.claude/ .github/` returns nothing.

### SKILL.md

- [x] T510 Correct reference.md's claim that spec-kit's loader reads SKILL.md's sections

`improvements/reference.md:157` and `:364` both say spec-kit's skill loader
expects SKILL.md's upstream section shape. Spec-kit 0.16.2's
`ExtensionManager.generate_skills` (`extensions/__init__.py:1537-1640`)
iterates `manifest.commands` and reads `commands/*.md` only; no code path
opens the extension-root `SKILL.md`, and `extension.yml` does not declare it
— verified by reading the installed 0.16.2 source, not assumed. Replace both
cells with: "Low. Spec-kit 0.16.2 never reads the extension-root `SKILL.md`;
it renders one skill per `commands/*.md`. An external `~/.agents/skills/`
loader's section expectations are unverified." Update the sentence at line
392 to record that the check was done.
Verify: `python3 specflow/scripts/lint-standards.py` passes; `grep -n "skill
loader expects the upstream section shape" improvements/reference.md` returns
nothing.

- [x] T511 Move the superpowers.yml schema sample out of SKILL.md

Replace `SKILL.md` lines 160-212 (`### Superpowers Status Tracking` through
the "Why persist this" paragraph) with a seven-line `### The skill detection
cache` pointer: state that `.specify/superpowers.yml` records one entry per
skill the Skill Mapping table in `superpowers-mapping.md` names, plus the
superpowers release in `version`, that no command re-runs detection while the
file is current, and that `workflow-guide.md` holds the file's shape and the
events that rewrite it. In the same commit, replace
`workflow-guide.md:717-735` with `SKILL.md`'s current lines 166-196, because
the guide's sample omits `version:` and six of the twelve skills the Skill
Mapping table names — it is the stale copy, not this one.
Verify: `cd specflow && python3 scripts/validate-extension-metadata.py &&
python3 scripts/validate-release-archive.py && bash scripts/e2e-smoke.sh &&
python3 scripts/lint-standards.py` all pass; `grep -c 'detected:'
references/workflow-guide.md` returns 15 (12 from the moved sample block, plus
3 pre-existing prose mentions this task did not touch).

- [x] T512 Delete SKILL.md's phase-resume table in favor of the guide's

Delete `SKILL.md` lines 230-242 (`### How Each Phase Resumes` and its 7-row
table); the guide's `### Phase-Specific Resume Rules` covers all seven phases
and adds the unconfirmed-checkpoint rule this table drops. Append to the
Resume Protocol's step 6, after "resume execution from the first unchecked
task)": " The per-phase rules are in
[workflow-guide.md](references/workflow-guide.md) under Phase-Specific
Resume Rules."
Verify: `cd specflow && bash scripts/e2e-smoke.sh && python3
scripts/lint-standards.py` both pass; `grep -c 'How Each Phase Resumes'
SKILL.md` returns 0.

- [x] T513 Correct the Session Resumability state claim

`SKILL.md:118-120` reads "Specflow is **fully resumable across sessions**. It
keeps all state as Markdown inside the `.specify/` directory..." — both facts
are wrong: the state files are YAML, and `progress.yml` lives under
`specs/NNN-feature-name/`, not `.specify/`. Replace with: "Specflow resumes
across sessions. State lives in two plain-text files: `progress.yml` under
`specs/NNN-feature-name/`, and `.specify/superpowers.yml`. An agent timeout,
a closed session, or a CLI crash drops no progress."
Verify: `cd specflow && bash scripts/e2e-smoke.sh && python3
scripts/lint-standards.py` both pass.

- [x] T514 Move the phase sequence above the resumability section

Cut `SKILL.md` lines 476-506 (the `---` rule, `## Unified Workflow`, the
fenced Phase 0-6 block, and the three trailing paragraphs) and paste them
immediately after the Commands table, before the `---` that precedes
`## Session Resumability`. Change nothing inside the block. Depends on: T511,
T512.
Verify: `cd specflow && bash scripts/e2e-smoke.sh && python3
scripts/validate-extension-metadata.py && python3 scripts/lint-standards.py`
all pass; `grep -n 'Unified Workflow\|Session Resumability' SKILL.md` shows
Unified Workflow on the lower line number.

- [x] T515 Rename SKILL.md's eight remaining upstream-spelled free headings

Apply: `## Prerequisites` to `## Specflow runs without superpowers`; `##
Project Structure` to `## Where the files land`; `## Commands` to `##
Command index`; `## Session Resumability` to `## Every command resumes from
the files on disk`; `### Progress Tracking` to `### The progress file`; `###
Resume Protocol` to `### The resume check runs first`; `## Unified Workflow`
to `## The seven phases in order`; `## Additional Resources` to `## Where to
read more`. Nothing in this repository greps any of them. Depends on: T511,
T512, T514. Renaming `## Session Resumability` here must land together with
renaming `workflow-guide.md`'s identical heading (see this group's header
note); do not take this task's `## Session Resumability` line alone.
Verify: `cd specflow && python3 scripts/validate-extension-metadata.py &&
python3 scripts/validate-release-archive.py && bash scripts/e2e-smoke.sh &&
python3 scripts/lint-standards.py && bash ../.claude/hooks/tests/run.sh` all
pass.

- [x] T516 Document the five hooks in SKILL.md

`grep -i hook SKILL.md` returns only one line naming `test-gate.sh`; none of
the five hooks `extension.yml` declares (`after_clarify`, `after_analyze`,
`after_tasks`, `before_implement`, `after_implement`) appear. Add a `## Five
hooks fire on spec-kit's own commands` section with a 5-row table (Hook /
Fires after / What it does) immediately after the Commands table, taking each
row's wording from the matching `description:` field in `extension.yml`.
Verify: `cd specflow && python3 scripts/validate-extension-metadata.py &&
bash scripts/e2e-smoke.sh` pass; `python3 -c "import yaml,sys;
h=yaml.safe_load(open('extension.yml'))['hooks']; t=open('SKILL.md').read();
sys.exit(0 if all(k in t for k in h) else 1)"` exits 0.

- [x] T517 State the constitution gate in SKILL.md's Prerequisites section

`SKILL.md:315` states the constitution gate only inside the
`/speckit.constitution` section. Add to Prerequisites, after the "**Required**:
None." line: "One gate is unconditional: `.specify/memory/constitution.md`
must exist before any other command runs. Every command checks for it first
and stops with guidance when it is absent." Leave line 315 as is.
Verify: `cd specflow && bash scripts/e2e-smoke.sh && python3
scripts/lint-standards.py` both pass.

- [x] T518 Add the clarify and analyze rows to SKILL.md's Commands table

The table lists ten commands and omits `/speckit.clarify` and
`/speckit.analyze`, which the Unified Workflow makes mandatory gates. Insert
`| /speckit.clarify | Resolve the spec's NEEDS CLARIFICATION markers, then
write .clarified |` after the `/speckit.specify` row, and `|
/speckit.analyze | Check spec, plan, and tasks for inconsistency, then write
.analyzed |` after the `/speckit.specflow.tasks` row.
Verify: `cd specflow && python3 scripts/validate-extension-metadata.py &&
bash scripts/e2e-smoke.sh` pass.

### commands/*.md and commands/hooks/*.md

- [x] T520 Add a constitution gate step to brainstorm.md

Insert a new Process step 2: "**Constitution gate**: Check that
`.specify/memory/constitution.md` exists. If it is missing, stop with
`CONSTITUTION_REQUIRED`, name the missing path, and tell the user to run
`/speckit.constitution`." Renumber the current steps 2-9 to 3-10. `tasks.md`,
`execute.md`, and `gate.md` already carry this step; `brainstorm.md` and
`review.md` (T521) are the two commands where the fork's own rule was never
finished. Update `specflow/scripts/e2e-smoke.sh:52` from `"brainstorm 9"` to
`"brainstorm 10"`.
Verify: `bash specflow/scripts/e2e-smoke.sh` passes with no new failures.

- [x] T521 Add a constitution gate step to review.md

Insert a new Process step 1, the same constitution-gate wording as T520,
renumbering current steps 1-9 to 2-10. Update
`specflow/scripts/e2e-smoke.sh:55` from `"review 9"` to `"review 10"`. Must
land in the same change as T522 (same file, renumbering conflicts).
Verify: `bash specflow/scripts/e2e-smoke.sh` passes.

- [x] T522 Update "Review step 4" citations after T521's renumbering

Replace "step 4" with "step 5" at `specflow/references/superpowers-mapping.md`
lines 176, 185, 186, 187, 188, 189, 190 (7 occurrences) and
`specflow/references/workflow-guide.md` lines 438-439 (2 occurrences), to
match review.md's Process numbering after T521. Depends on: T521, same
commit.
Verify: `grep -c 'step 4' specflow/references/superpowers-mapping.md
specflow/references/workflow-guide.md` returns 0; `grep -c 'step 5'` on the
same two files returns 9.

- [x] T523 Add an Output section to status.md

`status.md` is the one command file with no `## Output` heading; its sample
output is embedded inline in a Process step instead. Add `## Output` after
`## Process` stating the command prints the status summary to the terminal,
writes nothing, and refreshes `.specify/superpowers.yml` as a side effect of
superpowers detection.
Verify: `bash specflow/scripts/e2e-smoke.sh` passes; `python3
specflow/scripts/validate-extension-metadata.py` passes.

- [x] T524 Rewrite "clear description" in review.md's Finding Format section

Replace `- A clear description and a confidence score` (line 79) with `- A
one-line description and a confidence score`. `standards/documentation.md`
bans evaluative adjectives about the work itself ("clear" as praise); this
line was never touched by the file's earlier prose pass.
Verify: `grep -n 'clear' specflow/commands/review.md` returns nothing.

- [x] T525 Correct reference.md's Names-table cost cell for the hook file names

`improvements/reference.md:241` lists the cost of renaming
`before-execute.md`/`after-execute.md` as "Free, and no reason", but
`specflow/scripts/e2e-smoke.sh:515` greps the literal path
`commands/hooks/after-execute.md`, and
`specflow/examples/link-audit/analyze-gate.md:5` cites
`commands/hooks/before-execute.md` in prose. Change the Cost cell to name
both citations instead of "Nothing".
Verify: read the edited row back; no script check applies to this doc-only
change.

### templates/*.md

- [x] T530 Tighten tasks-template.md's Checkpoint Protocol to point at workflow-guide.md

Replace the five-line numbered list under `### Checkpoint Protocol` (lines
206-213) with two sentences naming `references/workflow-guide.md`'s Human
Checkpoint Protocol instead of restating its steps. Keep the heading
unchanged. No golden regeneration needed (`score-artifacts.py` never reads
this body text).
Verify: `bash specflow/scripts/e2e-smoke.sh` passes; `grep -c "Ask the user:"
specflow/templates/tasks-template.md` returns 0.

- [x] T531 Drop tasks-template.md's Notes bullets that repeat Task Format

Delete the four bullets under `## Notes` (lines 219-222) restating `[P]`,
`[TDD]`, `[REVIEW]`, `[SUBAGENT]`, already defined under `## Task Format`
(lines 17-21). Keep the remaining three Notes bullets.
Verify: `bash specflow/scripts/e2e-smoke.sh` passes; `sed -n '/## Notes/,$p'
specflow/templates/tasks-template.md` shows exactly 3 bullets.

- [x] T532 Reorder spec-template.md's Threat Model section after Success Criteria

Move the `## Threat Model` block (lines 126-141, comment and table included)
to sit after `### Measurable Outcomes` and before `## Traceability`, so the
document's two `*(mandatory)*` sections stay adjacent. No text inside the
block changes; `score-artifacts.py` never checks section order.
Verify: `python3 specflow/scripts/score-artifacts.py <a feature dir under
specflow/examples with a threat model>` reports the same `threat_model` and
`spec_sections` scores as before.

- [x] T533 Trim spec-template.md's Brainstorm Prompts to the 5 fallback categories

Delete the `**Data integrity**` and `**Backwards compatibility**` bullets
(lines 92-93) from `#### Brainstorm Prompts`. `superpowers-mapping.md` and
`workflow-guide.md` both state the fallback protocol runs exactly 5
categories (boundary, error, scale, security, UX); this template lists 7,
contradicting the fork's own documented behavior.
Verify: `grep -c "Data integrity\|Backwards compatibility"
specflow/templates/spec-template.md` returns 0.

- [x] T534 Reorder constitution-template.md's Code Review Rules before Governance

Move the `## Code Review Rules` block (lines 117-126) to sit immediately
before `## Governance` (currently line 106), so the version/ratification
stamp in Governance stays the document's closing section. No text inside
either block changes.
Verify: `tail -12 specflow/templates/constitution-template.md` ends with the
`**Version**` line.

### README.md, CHANGELOG.md, references/

- [x] T540 Move the catalog-submission section out of specflow/README.md

`specflow/README.md:317-375` (59 lines) holds maintainer-facing
catalog-submission process inside the user-facing install README. Cut it
verbatim into a new `specflow/references/publishing.md`, and replace it in
`README.md` with a one-line pointer.
Verify: `wc -l specflow/README.md` drops to roughly 320 lines; `python3
scripts/validate-extension-metadata.py` and `python3
scripts/validate-release-archive.py` both exit 0; `grep -rn "Submitting to
the spec-kit catalog" specflow/` finds it only in the new file.

- [x] T541 Rewrite the root README's stale `.claude/` directory-table row

`README.md:25` reads "`.claude/` | The maintainers. It holds the agents and
gate scripts for this checkout.", which predates ADR-0025 moving the real
gate logic to `specflow/gates/` (the `.claude/hooks/` copies are now 3-line
exec wrappers). Replace with: "`.claude/` | The maintainers. It holds the
agents and the wrapper scripts that exec the gates shipped under
`specflow/gates/`."
Verify: `grep -n "gate scripts" README.md` no longer matches the old wording.

### examples/

- [x] T542 Record the examples/ unmeasured-upstream total in reference.md

`static-landing-page/` and `sample-workflow.md` hold approximately 2,224
lines of verbatim upstream text at roughly 0% real divergence, none of it in
the reproduce command's table (it filters `^examples/`). Add one sentence
after reference.md's `## examples/` intro line stating this total, cited to
this survey, so T194's deferral is priced honestly. Do not rewrite the
snapshot's prose: `test_score_artifacts.py` asserts five `seeded-*/`
directories are byte-identical to it except one named diff each, so any
wording change must mirror into all five and their test constants, for a
directory already scheduled for deletion under T194.
Verify: `grep -n "2224\|2200" improvements/reference.md` finds the added
sentence.

## G-52 — Lint a traceability row against a real test (backlog item 33) (merged: direct)

Executor: `general-purpose`. Effort: low. Depends on: none. Raised on
2026-09-25, claiming backlog item 33 below.

`.claude/hooks/artifact-lint.sh` validates `spec.md`'s section structure but
never checks a `## Traceability` row's Test name column against the real test
tree, so an invented test name passes the gate silently. `spec-template.md`'s
Traceability section states "Automated scoring reads only the Test name
column"; nothing today confirms the named test exists.

- [x] T600 Add a traceability-test-exists check to `artifact-lint.sh`, gated on `.analyzed`

In the `spec.md)` case, once `$(dirname "$path")/.analyzed` exists, parse each
`## Traceability` table row's Test name column. Read the existing recorded
examples under `specflow/examples/*/specs/*/spec.md` first to learn the real
format in use (a bare file path, a `file::test_name` pair, or a checklist
item) before writing the parser. For each row whose Test name does not resolve
to an existing file (or an existing test function inside an existing file, if
the row names one), call `err` with the criterion ID and the name that did not
resolve. Skip the check entirely when `.analyzed` is absent, matching the
existing `.clarified`-gated check's pattern in the same file.
Verify: `bash .claude/hooks/tests/run.sh` passes with the new cases from T601
included.

- [x] T601 Add hook tests for the new check

Add at least three cases to `.claude/hooks/tests/run.sh`, following the file's
existing `lint()`/`check` helper pattern: a `spec.md` with `.analyzed` present
and a Traceability row naming a real test, asserting exit 0; a `spec.md` with
`.analyzed` present and a row naming a test that does not exist, asserting
exit 2; and a `spec.md` with a bogus Traceability row but no `.analyzed` file,
asserting exit 0 (the gate is `.analyzed`-conditional).
Verify: `bash .claude/hooks/tests/run.sh` reports 0 failed, with its printed
pass count higher than the count on `main` before this task by exactly the
number of new cases added.

## G-53 — A catalog entry spec-kit's extension search can find (backlog item 23) (merged: direct)

Executor: `general-purpose`. Effort: low. Depends on: none. Raised on
2026-09-25, claiming backlog item 23 below, scoped to what this environment
can verify: the `specify` CLI is not installed here (`which specify` finds
nothing), so the live `specify extension search specflow` check the backlog
item names cannot run in this environment. Do the parts below and say so in
the final report rather than fabricating that check.

- [x] T610 Add `catalog.json` at the repository root

Write a spec-kit catalog schema 1.0 JSON file naming `specflow`. Reuse the
field set already agreed for this extension's catalog submission in
`specflow/references/publishing.md`'s Proposed Catalog Entry JSON block
(`download_url` pattern, `repository`, `license`, `category`,
`provides.commands`/`provides.hooks`), read the command and hook counts live
from `specflow/extension.yml` rather than hardcoding them, and add a
`priority` and `install_allowed: true`.
Verify: `python3 -c "import json; json.load(open('catalog.json'))"` exits 0;
the entry's command and hook counts match `specflow/extension.yml`'s current
`commands:`/`hooks:` list lengths.

- [x] T611 Add a README line naming how to list this catalog

Add one sentence to the root `README.md`'s install section naming the two ways
a user points spec-kit at this catalog: listing it in
`.specify/extension-catalogs.yml` with `install_allowed: true`, or setting
`SPECKIT_CATALOG_URL` to this repository's raw `catalog.json` URL.
Verify: `grep -n 'extension-catalogs.yml\|SPECKIT_CATALOG_URL' README.md`
finds the new line.

## G-54 — Gate hooks on the Copilot CLI's own hook system (backlog item 28) (merged: direct)

Executor: `general-purpose`. Effort: medium. Depends on: none (item 27's
Copilot e2e script, its former blocker, is merged). Raised on 2026-09-25,
claiming backlog item 28 below. Distinct from G-26: G-26 routes through
spec-kit's `events:` block and is blocked on moving four scripts under
`specflow/`; this group writes Copilot's native `.github/hooks/` config
directly, reads the gate scripts from `.claude/hooks/` unmoved (ADR-0001), and
does not touch `extension.yml`. `docs/agent-event-mapping.md` records the
Claude Code vs. Copilot payload field names (`.tool_input.command` vs.
`.toolArgs.command`, etc.) already measured against `@github/copilot` 1.0.86;
read it first. This environment has no `GH_TOKEN` scoped for a live Copilot
CLI session (a local `copilot` binary is installed, but do not assume it is
authenticated for this check), so the roadmap's live-session verify clause
cannot be assumed to run here. Try it; if it fails to authenticate, say so in
the final report and do not fabricate a pass.

- [x] T620 Write the Copilot hook config

Add `.github/hooks/specflow.json` registering `block-main-commit.sh` and
`test-gate.sh` under `preToolUse`, `artifact-lint.sh` under `postToolUse`, and
`session-start.sh` under `sessionStart`. Fetch GitHub's [hooks
reference](https://docs.github.com/en/copilot/reference/hooks-reference) to
confirm the exact file name Copilot reads (`docs/agent-event-mapping.md`
mentions Copilot's own `hooks.json`; confirm whether `.github/hooks/` takes
one file per hook or one combined file before writing this) and the JSON
shape, including both a `bash` and a `powershell` command per entry. The
scripts stay under `.claude/hooks/` per ADR-0001; do not move them.
Verify: the hook config file parses as valid JSON.

- [x] T621 Write the exit-code-to-deny-JSON adapter

Add a thin wrapper script, referenced from the hook config, that runs the
named `.claude/hooks/*.sh` gate script, translating the payload field names
per `docs/agent-event-mapping.md`'s table, and when the gate exits 2, prints
the JSON object Copilot's `preToolUse` contract expects on stdout to deny the
tool call (confirm the exact shape from the hooks reference fetched in T620),
then exits 0 so Copilot reads the JSON rather than treating a nonzero exit as
an unrelated hook failure.
Verify: piping a blocked command's hook payload through the adapter prints
valid JSON denying the call; piping an allowed command's payload through it
exits 0 with no deny JSON.

- [x] T622 Add a hook test for the adapter

Add a case to `.claude/hooks/tests/run.sh` that runs the adapter against a
payload shaped like a Copilot `preToolUse` event for `git commit` on `main`
and asserts the deny JSON is printed.
Verify: `bash .claude/hooks/tests/run.sh` reports 0 failed, including the new
case.

- [x] T623 Record the second harness hook directory as an ADR

Add an ADR to `decisions.md` stating that Copilot CLI hooks live under
`.github/hooks/` (not `.claude/`), that the gate scripts themselves are not
duplicated or moved, and that a thin adapter bridges the exit-code and
deny-JSON contracts. Name this ADR as the one backlog item 28 asked for.
Verify: `decisions.md` has a new ADR entry naming `.github/hooks/specflow.json`.

## G-55 — Move the remaining four payload-reading gates under `specflow/gates/` (merged: direct)

Executor: `general-purpose`. Effort: medium (mechanical, but high blast
radius: one of these scripts gates every commit in this repository). Depends
on: none. Raised on 2026-09-25. This is the stated real prerequisite for G-26
T262: "The four scripts that do read a payload, `block-main-commit.sh`,
`test-gate.sh`, `artifact-lint.sh`, and `session-start.sh`, are still under
`.claude/`; ADR-0025 moved a different four [five]. Moving them is the real
prerequisite." This group does only the move; it does not declare the
`events:` block itself (T262 stays blocked on the `post_tool_use`
one-event-one-handler design question named in its own text).

Mirror ADR-0025 exactly (read it in `decisions.md` first, and read
`specflow/gates/bash/risk-classifier.sh` alongside its `.claude/hooks/`
wrapper as the reference pair): the four scripts move to
`specflow/gates/bash/`, and each one's old path under `.claude/hooks/` becomes
a two-line `exec` wrapper pointing at the new location, so `.claude/settings.json`,
`.github/workflows/merge-gate.yml`, and `.claude/hooks/tests/run.sh` keep
their existing paths unchanged.

- [x] T640 Move `block-main-commit.sh`, `test-gate.sh`, `artifact-lint.sh`, and `session-start.sh` to `specflow/gates/bash/`, wrapped from their old path

For each of the four scripts: move the real script to
`specflow/gates/bash/<name>.sh` unchanged (do not alter its logic in this
task), and replace its old `.claude/hooks/<name>.sh` with a two-line `exec`
wrapper matching `risk-classifier.sh`'s wrapper exactly in shape. Add all four
new paths to `provides.scripts` in `specflow/extension.yml`, beside the five
already listed. Add the four new paths to `RUNTIME_PAYLOAD` (or whatever the
list is named; grep `specflow/scripts/validate-release-archive.py` for
`"gates/bash/risk-classifier.sh"` to find it) in
`specflow/scripts/validate-release-archive.py`.
Verify: `cd specflow && python3 scripts/validate-extension-metadata.py &&
python3 scripts/validate-release-archive.py` both pass, and the archive
report lists all nine `gates/bash/*.sh` paths as present.

- [x] T641 Fix the CI shellcheck/ruff steps to cover `specflow/gates/`

ADR-0025's own Consequences line records this gap: "The shellcheck and ruff
steps in `ci.yml` still name only the old paths." Read `.github/workflows/ci.yml`'s
shellcheck step (it lists `.claude/hooks/*.sh` and
`specflow/scripts/*.sh` but not `specflow/gates/bash/*.sh` or
`specflow/gates/python/*.py`) and add the missing globs to both the
shellcheck and ruff step invocations, so all nine bash gates and both python
gates are actually linted, closing the gap for the five ADR-0025 already
moved as well as the four this group adds.
Verify: running the same shellcheck/ruff commands `ci.yml` runs, by hand,
locally, against `specflow/gates/bash/*.sh` and `specflow/gates/python/*.py`,
reports 0 new findings versus what those tools already reported for the
files' content before the move (a path change alone should not introduce a
new finding).

- [x] T642 Prove the block-main-commit wrapper still blocks a real commit on main

This is the one check that matters most: `block-main-commit.sh` is what
prevents a commit landing directly on `main` in this repository. After moving
it, attempt an actual `git commit` while checked out on `main` in a scratch
clone or a disposable worktree (not this repository's real history) and
confirm it is still refused with the same message, then confirm a commit on a
feature branch still succeeds.
Verify: the blocked-commit attempt is refused; the feature-branch commit
succeeds; `bash .claude/hooks/tests/run.sh` reports 0 failed with no fewer
passing cases than it reported on `main` before this task.

## G-51 — Release readiness: prerequisites and cleanup (merged: PR #76)

Executor: `general-purpose`. Effort: low. Depends on: none. Raised on
2026-09-25 by an adversarial release-readiness audit. Scoped here to the
uncontested, dependency-free tasks: documenting an undeclared install-time
dependency, removing two dead references, correcting a stale prerequisite
claim in G-26, and an environment-setup step. The audit's other findings —
committing the working tree, tagging `v1.1.0`, and everything gated on a
release existing — are deliberately left out of this pass: tagging and
publishing a release is an outward-facing, hard-to-reverse action that
belongs in its own change with its own confirmation, not bundled into a
cleanup PR.

- [x] T551 State `jq` as a prerequisite in specflow/README.md

`specflow/gates/bash/merge-gate.sh:10` guards on `jq` per ADR-0027, but no
document a user reads before installing names the dependency —
`specflow/README.md` had no prerequisites section at all. Verify: `grep -n
'\bjq\b' specflow/README.md` prints a line above the first `specify init`
block; `python3 specflow/scripts/lint-standards.py` still reports 0 findings.

- [x] T552 Remove the dead schema.json references

`.gitignore:3` negated `.claude/review/schema.json`, and
`.claude/review/scorecard.sh` skipped a file by that name; the findings
contract lives at `specflow/references/findings-schema.json`, and no
`schema.json` exists anywhere in that directory. Verify: `grep -rn
'review/schema.json\|SCHEMA_FILE' .gitignore .claude/review/` prints nothing;
`python3 -m pytest .claude/review/tests -q` reports 4 passed.

- [x] T557 Correct G-26 T262's frontmatter prerequisite

T262's body stated "every command file now carries frontmatter with a
`scripts:` block" as a cleared prerequisite. It is cleared in the source but
stripped at install: the registered
`.claude/skills/speckit-specflow-tasks/SKILL.md` carries `name`,
`description`, `compatibility`, and `metadata` only. Verify: `grep -n
'scripts:' improvements/roadmap.md` shows the T262 paragraph no longer calls
the block a cleared prerequisite.

- [x] T558 Install ruff and mutmut locally and confirm verify.sh runs clean

`which ruff` found nothing and `python3 -m mutmut --version` failed, so one
`verify.sh` step reported skipped and 8 hook tests skipped. Both are
declared in `requirements-dev.txt`; environment setup, not a repository
change. Verify: `bash verify.sh` reports 0 skipped; `bash
.claude/hooks/tests/run.sh` reports 0 skipped.

Left for a separate, confirmed change: tagging `v1.1.0` and publishing the
release, installing the published ZIP on both surfaces, making the
release-asset README command a runnable test, and walking the 1.0.2 to 1.1.0
upgrade path. Each depends on the tag existing.

## G-56 — A `before_tasks` hook that stops core `/speckit.tasks` on an unresolved Open Question (merged: PR #78)

Executor: `general-purpose`. Effort: low. Depends on: none. Raised on
2026-09-25, promoted from the Deferred list below, where it read: "cheaper
than a sixth command now that G-24 T241 derives `e2e-smoke.sh`'s and `ci.yml`'s
hook counts from `extension.yml`; only the manifest entry and the hook's own
prompt remain to write."

`specflow/commands/tasks.md` steps 1 and 2 stop `/speckit.specflow.tasks` with
`CONSTITUTION_REQUIRED` or `OPEN_QUESTIONS` before it breaks a feature down,
but nothing stops a user who runs spec-kit's own `/speckit.tasks` directly.
`extension.yml`'s `hooks:` block declares `after_clarify`, `after_analyze`,
`after_tasks`, and `before_implement`; it has no `before_tasks` entry, so the
gate `before-execute.md` gives `/speckit.implement` has no counterpart for
`/speckit.tasks`.

- [x] T650 Write `specflow/commands/hooks/before-tasks.md`

Match `before-execute.md`'s shape exactly: a title, a one-paragraph
description of when the hook fires, and a numbered `## Preconditions` list.
Give it the same two checks as `tasks.md` steps 1 and 2, word for word in
behavior: the Constitution gate stopping with `CONSTITUTION_REQUIRED`, and the
Open questions gate counting `## Open Questions` rows whose Status is not
`Resolved` and stopping with `OPEN_QUESTIONS`. Point both at
`references/workflow-guide.md`'s stop-code table rather than restating the
table. Verify: the file exists and
`grep -c 'CONSTITUTION_REQUIRED\|OPEN_QUESTIONS' specflow/commands/hooks/before-tasks.md`
prints 2.

- [x] T651 Register `before_tasks` in `extension.yml`

Add a `before_tasks` entry to the `hooks:` block, positioned between
`after_tasks` and `before_implement`. Give it the same field shape as
`before_implement`: `command: "speckit.specflow.tasks"`, `optional: true`,
a `priority`, a `prompt` offering to hand the break-down to
`/speckit.specflow.tasks` instead, and a `description` naming the two checks
T650 wrote. Verify: `cd specflow && python3 scripts/validate-extension-metadata.py`
passes, and `grep -c '^  before_tasks:' specflow/extension.yml` prints 1.

- [x] T652 Add `before_tasks` to the stop-code table's "Printed by" columns

`references/workflow-guide.md`'s stop-code table lists `OPEN_QUESTIONS` as
printed only by `/speckit.specflow.tasks`, and `CONSTITUTION_REQUIRED` as
printed by `/speckit.specflow.execute`, `/speckit.specflow.tasks`,
`/speckit.specflow.gate`, and three named hooks that does not include
`before_tasks`. Add the new hook to both rows. Verify: both rows' text
contains `before_tasks`.

- [x] T653 Confirm the derived hook counts still pass with no further edit

Run `bash specflow/scripts/e2e-smoke.sh` and, from `specflow/`,
`python3 scripts/validate-extension-metadata.py`. G-24 T241 is recorded as
having made both derive their hook count from `extension.yml` directly. If
either instead has a hardcoded count that now fails, name the exact line and
fix it in this task rather than treating it as a new item. Verify: both
commands exit 0.

- [x] T654 Fix every other hardcoded hook count

Search for a hook count or a hook-name list that predates this change:
`grep -rn "after_clarify\|before_implement" --include=*.md . | grep -v specs/`
finds candidates, including `AGENTS.md`'s Architecture section and
`specflow/README.md`. Update each to include `before_tasks` and, if it states
a count, raise it by one. Verify: the same grep shows every listed file names
six hooks, not five.

## Checked on 2026-09-20, no work needed

Measured against spec-kit 1.0.9.dev0 at `d4229c0`. Each line held, so do not
re-verify it when picking up G-24 to G-28.

| Claim | Measured |
|---|---|
| Hook events a core command fires | 20: `before_` and `after_` for each of the 10 core commands, in `templates/commands/*.md` |
| Workflow step types | 12, listed at `workflows/engine.py` line 142 |
| Core `spec-template.md` against ours | 131 lines against 197 |
| Core `tasks-template.md` against ours | 252 against 225. Core is larger for this one template only; ours is larger for the other four (constitution 123/50, spec 197/131, plan 130/113, checklist 120/45). Core's extra lines are User Story 3 boilerplate and an Implementation Strategy section this fork replaced on purpose, measured under G-25 |
| Agents under `.claude/agents/` | 34 on 2026-09-20, up from the 28 first measured. `.github/copilot-instructions.md` names the groups and states no count, so the two no longer disagree |

## Backlog: items 23 to 36

Scoped, not decomposed. Claiming one means turning it into a group numbered
G-24 or later. Each keeps the three constraints in `reference.md`. Facts marked
*verified* were checked on 2026-09-11; sources are in
`docs/review-research.md`.

### Ship it: install, upgrade, release

Item 23 was claimed as G-53 on 2026-09-25.

**26. An upgrade path the smoke test walks.** `e2e-smoke.sh` installs the
v1.0.2 release ZIP, installs the checkout over it with `--dev`, and asserts no
stale command file or `extensions.yml` entry remains. Every user who installed
1.0.2 upgrades through this path and it has never run. Blocked as of
2026-09-25: neither `git tag` nor `gh release list` returns anything in this
repository, so there is no v1.0.2 (or any) release to upgrade from yet. This
item cannot start until a release is cut; see G-51 if one exists by the time
this is picked up. Verify: the smoke test reports the upgrade assertions and
passes. Effort: low. Depends on: G-36 (merged), a cut release.

### Prove it on both runtimes

Item 28 was claimed as G-54 on 2026-09-25.

### Operate it

Item 33 was claimed as G-52 on 2026-09-25.

**34. A seeded-ambiguity golden (closed with G-19, PR #81).** `examples/seeded-ambiguity/`, a spec with one
planted ambiguity such as an undefined sort order, and a scorer dimension for
whether brainstorm or clarify surfaced it as an open question. The scorer proves
the reviewer finds a seeded bug; nothing proves the spec phase finds a seeded
ambiguity, and the spec phase is where upstream is thinnest. Verify:
`score-artifacts.py` scores the new golden and `score-artifacts.yml` replays it.
Effort: medium. Depends on: G-19.

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
- **Replace `execute.md` with a squad dispatcher**: the one Replace move worth
  taking, and only after G-19 gives it a snapshot to assert against on both
  runtimes.
- **A Copilot CLI run snapshot** under `examples/`: the Copilot e2e script
  (backlog item 27) is merged; only the live run remains.
- **A spec-kit workflow file** (was N-06): deferred on 2026-09-20. Most of its stated value was running the gates on the Copilot
  CLI, which the `events:` block in G-26 buys for less. Reprice it after G-26.
- **A spec-kit bundle** (was N-08): deferred on 2026-09-20. It composes the
  workflow above with the preset G-25 decides, so it cannot start before
  either.

## Suggested order

D-01, D-05, G-19, G-20 through G-25, G-28 through G-42, G-43, G-44, G-45,
G-46, G-48, G-49, G-50, G-51, G-52, G-53, G-54, G-55, G-56, and C-01 through
C-09 are merged or closed. Backlog item 34 closed with G-19 (PR #81 added
`examples/seeded-ambiguity/`). What is left, in order:

1. G-26 T262 and T263. G-55 cleared the script-relocation prerequisite; what
   remains is the `post_tool_use` one-event-one-handler design question T262's
   own text names (`test-gate.sh` and `artifact-lint.sh` both want that
   event, and `validate_events` takes one handler per event name).
2. Backlog item 26, once a release exists to upgrade from.
3. Backlog item 36, no code.

Pick the item whose `Verify:` line you can run before you start. An item whose
check you cannot run today is a design task, not a roadmap task.

## Ready to release

Run every line on `main` the day of the tag. One false line means the release
is not ready, whatever the order above says.

- A tag exists, `release.yml` ran green for it, and the release carries the ZIP
  and the validator report.
- `specify extension add specflow --from <release zip>` installs in a fresh
  project on both surfaces, and `specify extension list` prints the command and
  hook counts `extension.yml` declares.
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
