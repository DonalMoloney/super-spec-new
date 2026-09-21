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
| G-19 | The examples are upstream's, not this fork's | high | `static-landing-page/` and `sample-workflow.md` both present |
| G-26 | The gates cannot run on the Copilot CLI | medium | Blocked by ADR-0022; T261 done, T262 and T263 behind three prerequisites |
| G-43 | `SKILL.md` documents a `progress.yml` schema the validator rejects | low | Not started; see G-43 below |
| G-45 | The merge gate cannot read `code-reviewer`'s findings | low | T451 and T452 open; see G-45 below |
| G-49 | No check catches a document that has gone out of date | low | `AGENTS.md` claimed main carried no commits until `5a5e8db` |

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
the Copilot CLI. `reference.md` does not name the mechanism. Settle this group before N-03, which ships the same gates the long
way as `provides.scripts` under `gates/`, and before backlog item 28, which
writes a second hook config by hand.

- [x] T261 Write the event mapping

One row per gate script, naming the spec-kit event it registers on and the
adapter each surface needs from exit code to deny JSON. Verify: the table
names an event for `block-main-commit.sh`, `test-gate.sh`, `artifact-lint.sh`,
and `session-start.sh`.

- [ ] T262 Declare the block in `extension.yml`

Blocked, and shipping the block today would brick the extension. Two of the
three prerequisites cleared on 2026-09-20: every command file now carries
frontmatter with a `scripts:` block, and `docs/agent-event-mapping.md` records
Copilot's `toolName`, `toolArgs.command`, and `toolArgs.path`. ADR-0027 covers
the `jq` dependency.

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

## G-45 — The merge gate cannot read `code-reviewer`'s findings (working on)

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

- [ ] T451 Decide whether `code-reviewer` writes a findings document

The other nine personas write the shape `references/findings-schema.json`
declares. `code-reviewer` runs as phase 11 of the BDD squad, where
`bdd-orchestrator` reads its prose directly, so switching its output changes a
contract inside the squad rather than only a reviewer file. Record the choice
as an ADR. Verify: the ADR names which consumer reads `code-reviewer`'s output
and states whether the gate is meant to block on it.

- [ ] T452 Make the chosen contract true in the file

Either give `code-reviewer.md` an `## Output format` naming
`references/findings-schema.json`, matching the eight personas, or state in
that file why its output stays prose and that the merge gate does not read it.
Verify: `grep -L 'findings-schema.json' .claude/agents/*-reviewer.md` prints
nothing, or `code-reviewer.md` carries the sentence that explains the
exception.

## G-49 — No check catches a document that has gone out of date (working on)

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

- [ ] T491 Fail the build when a repository document cites a path that does not exist

Verify: adding a line citing `specflow/nope.md` to any linted file makes
`python3 specflow/scripts/lint-standards.py` exit nonzero, naming the file, the
line, and the missing path.

- [ ] T492 Match inflected forms in the banned-word check

`banned_entries` builds one pattern per table entry. A noun with a verb form
escapes it. Verify: a fixture containing "bridging" is reported when "bridge"
is a banned entry.

- [ ] T493 Record whether "bridge" joins the banned table in `standards/documentation.md`

The unqualified entry catches 5 lines, of which 2 are `CHANGELOG.md` entries
that record the old name accurately ("The extension is listed as Specflow, not
Superpowers Bridge"). A qualified entry such as "bridge (as metaphor)" is
ignored, because `banned_entries` returns unqualified entries only. So the
choice is a per-rule CHANGELOG exclusion or leaving the rule unenforced.
Verify: the outcome is an ADR in `decisions.md`, whichever way it goes.

- [ ] T494 Re-check every count a document states against the repository

`AGENTS.md`, both READMEs, and `SKILL.md` state counts: commands, hooks,
templates, scripts, agents, assertions. Verify: each count is listed beside the
command that produced it, and every one matches.

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
id. Effort: low. Depends on: G-36 (merged).

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
on: G-36 (merged).

**26. An upgrade path the smoke test walks.** `e2e-smoke.sh` installs the
v1.0.2 release ZIP, installs the checkout over it with `--dev`, and asserts no
stale command file or `extensions.yml` entry remains. Every user who installed
1.0.2 upgrades through this path and it has never run. Verify: the smoke test
reports the upgrade assertions and passes. Effort: low. Depends on: G-36
(merged).

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
- **A `before_tasks` hook** that stops on unresolved Open Questions: cheaper
  than a sixth command now that G-24 T241 derives `e2e-smoke.sh`'s and
  `ci.yml`'s hook counts from `extension.yml`; only the manifest entry and the
  hook's own prompt remain to write.
- **A Copilot CLI run snapshot** under `examples/`: needs the Copilot e2e
  script, backlog item 27.
- **A spec-kit workflow file** (was N-06): deferred on 2026-09-20. Most of its stated value was running the gates on the Copilot
  CLI, which the `events:` block in G-26 buys for less. Reprice it after G-26.
- **A spec-kit bundle** (was N-08): deferred on 2026-09-20. It composes the
  workflow above with the preset G-25 decides, so it cannot start before
  either.
- **Upstream the resync-safe moves**: four Tighten moves this fork made that
  upstream could take, each tagged "breaks resync: rarely": the after-tasks
  progress read (D-01), the status marker column (D-07), the compound-task rule
  (D-06), and the Copilot fallback rows (D-03). Every accepted one shrinks the
  diff `upstream-drift.yml` reports. Open one pull request per move against
  `WangX0111/superspec` and record each link beside its bullet in
  `reference.md`.

## Suggested order

D-01, D-05, G-20 through G-25, G-28 through G-42, G-44, G-46, G-48, and C-01
through C-09 are merged or closed. What is left, in order:

1. G-43. Low effort, and it is the second `SKILL.md` schema inaccuracy G-41
   found in the same file; the drift compounds the longer it sits.
2. G-45 T451 and T452, whenever a session is short.
3. G-49, which stops the next document going stale unnoticed. Its T491 also
   catches a dangling path before a reader hits it.
4. G-26 T262 and T263, once the three ADR-0022 prerequisites clear.
5. Backlog items 23, 25, and 26 next; each depended only on G-36, now merged.
6. Backlog item 27, then 28, which depends on it for the live check.
7. Backlog items 31 through 36 whenever a session is short; none depends on
   another still open.
8. G-19 whenever a live agent run is available; this environment has no API
   key to make one.

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
