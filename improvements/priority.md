# Priority: the final sweep

Read this to pick the next worktree when the goal is a first tagged release
that a stranger can install, run, and trust. Every open item sits in one
worktree block. A block holds a set of files no other open block in the same
wave edits, so any two blocks in one wave run at once. Each block says why it
exists, what to do in order, and which checks prove it done. An agent given
one block name has everything it needs in that block and the two sections
that follow this one.

This file ranks; it does not claim. A checkbox lives in `roadmap.md`
(ADR-0017), a scoped-only item lives in
`new-improvements/scoped-improvements.md`, and an item marked *new* below has
no home yet: claiming it means writing a `G-nn` group in `roadmap.md` first.

Every status below was checked against `main` at `fa54108` on 2026-09-20 by
grep or by reading the file named, then re-checked by `work-verifier` against
the same commit, upstream superspec, and the live spec-kit catalog. Its
findings are folded in. The two claims it could not check open with the word
"Unverified". A line number below is correct at `fa54108`; each one comes
with the text to grep for, because lines move.

## Start here

Twenty-five of the twenty-seven blocks below merged to `main` on 2026-09-20,
in the dependency order the table states. Two remain, both in "Blocked on an
API key": `live-run`, and `delete-upstream-example` behind it. Every other row
in the table is history; read it for the order that worked, not for work to
pick up. "Closed since the scoped list was written" lists each merged block.

Two items inside merged blocks stayed open, each for a reason no worktree can
fix: item 19's `events:` block would deny every Bash call until a shipped
script reads a hook payload (G-26 T262 records the reproduction), and item
20's upgrade test needs a published release, which waits on the first tag.

| Worktree | Items | Wave | Wait for | Rebase over |
|----------|-------|------|----------|-------------|
| `deck-edits` | 40 | 1 | none | none |
| `first-tag` | 2 | 1 | none | none |
| `manifest-schema` | 38 | 1 | none | none |
| `skill-progress-schema` | 33 | 1 | none | none |
| `template-stamp` | 36 | 1 | none | none |
| `merge-gate-steps` | 37 | 1 | none | none |
| `payload-gates` | 3, 10, 16, 17 | 1 | none | `manifest-schema`, `skill-progress-schema`, `template-stamp` |
| `verify-pin` | 39 | 1 | none | `first-tag` |
| `speckit-floor` | 21 | 1 | none | `template-stamp`, `payload-gates` |
| `test-gate` | 15 | 1 | none | `telemetry-budget` |
| `telemetry-budget` | 23, 24 | 1 | none | `test-gate` |
| `scorer-dimensions` | 22 | 1 | none | none |
| `reviewer-scorecard` | 25 | 1 | none | none |
| `rewrite-after-tasks` | 34a | 1 | none | none |
| `rewrite-metadata-validator` | 34b | 1 | none | none |
| `readme-onboarding` | 4 to 9, 11 to 14 | 2 | `first-tag` | none |
| `copilot-e2e` | 18 | 2 | `payload-gates` | `verify-pin`, `speckit-floor` |
| `reviewer-bodies` | 35 | 2 | `payload-gates` | none |
| `rewrite-changelog` | 34c | 2 | `first-tag` | none |
| `register-gates` | 19, 20 | 3 | `payload-gates`, `copilot-e2e`, `first-tag` | `template-stamp`, `manifest-schema` |
| `idempotent-dry-run` | 26 | 3 | `copilot-e2e` | none |
| `superpowers-range` | 27 to 32 | 3 | `copilot-e2e` | `readme-onboarding`, `template-stamp`, `skill-progress-schema` |
| `rewrite-readme` | 34d | 3 | `readme-onboarding` | none |
| `rewrite-extension-yml` | 34e | 3 | `register-gates` | none |
| `rewrite-mapping` | 34f | 3 | `superpowers-range` | none |
| `live-run` | 1, backlog 34 | key | `readme-onboarding`, `copilot-e2e` | none |
| `delete-upstream-example` | 41 | key | `live-run` | none |

Items 42 to 44 have no block yet; they sit under "After the tag" below.

## Working a block

Follow these steps for every block. The block itself adds only what is
specific to it.

1. Read `AGENTS.md`, then the standard that matches the output:
   `standards/code.md` for a script or workflow, `standards/documentation.md`
   for prose. Reviewers reject against them.
2. Find the `G-nn` group in `roadmap.md` that holds the block's item. If the
   item is marked *new*, write the group first: a header, one line of
   context, one `- [ ] Tnnn` line per Do step below, and a Verify line that
   repeats the block's Done when checks. Append `(working on)` to the group
   header and commit that on `main`. The main-commit hook blocks a commit
   whose working directory is on `main`; run the commit from the worktree
   with `git -C <main checkout path> commit`.
3. Create the worktree:
   `git worktree add ~/PycharmProjects/worktrees/<block> -b <block>`.
4. Before a change to a script, hook, validator, or workflow, write the
   failing test first and run it; `superpowers:test-driven-development`
   applies. A hook test is one `check "<name>" <expected exit> "$(...)"`
   line in `.claude/hooks/tests/run.sh`. A Python test goes beside the
   existing file under `specflow/scripts/tests/` or `.claude/review/tests/`.
5. Run every line under the block's Done when, then `bash verify.sh`. Paste
   each command and its result into the PR description, which follows
   `.github/pull_request_template.md`.
6. After the merge, remove `(working on)` from the group header, tick the
   group's tasks, and delete the worktree.

Three checks hold for every block and are not repeated below: `bash
verify.sh` reports 0 failed, the PR is merged, and the `(working on)` marker
has left the `G-nn` header in `roadmap.md`.

## How to read a block

- The block name is the branch name and the directory under
  `~/PycharmProjects/worktrees/`.
- Item numbers 1 to 44 are stable. Cite them by number from `roadmap.md`.
- **Holds** lists every file the block edits. No other open block in the
  same wave edits those files. A file marked (new) does not exist yet.
- **Wait for** names a block whose merged result this one builds on. A block
  with no Wait for line starts today.
- **Rebase over** names a block that edits one of the same files in a
  different region. Either order works; the second to merge rebases first.
  The later wave carries the line; a same-wave pair carries it on both.
  Append points collide silently, so read the merged file before pushing.
- **Default** states the choice taken wherever the item allowed two. Take
  it unless the maintainer says otherwise in the PR.
- **Do** lists the steps in order. Each step names the file it edits and the
  text to grep for.
- **Done when** lists the checks specific to the block.

## Wave 1: start today, no waits

### `deck-edits`: item 40

Five files under `presentation/marp-deck/` carry uncommitted changes on
`main`: `README.md`, `deck.html`, `deck.md`, `kit.mmd`, and `kit.svg`.
`deck.html` is also listed in `.gitignore` line 15 while being tracked, so it
is ignored and modified at once and the next render dirties the tree again.

Holds: `presentation/marp-deck/`, `.gitignore`, this file, and the two-line
pointer in `roadmap.md` that names `priority.md`.

Default: untrack `deck.html`. `.gitignore` already names it, so the tree
treats it as a render output. `presentation/use-guide/` says how to render
it again.

Do:

1. On `main`, run `git stash`.
2. Create the worktree and run `git stash pop` inside it.
3. Run `git rm --cached presentation/marp-deck/deck.html`.
4. Commit the four remaining deck files, this file, and the `roadmap.md`
   pointer in one PR.

Done when:

- `git status --porcelain` on `main` prints nothing after the merge.
- `git ls-files presentation/marp-deck/deck.html` prints nothing.

### `first-tag`: item 2

No tag or release exists. `release.yml` has never run,
`validate-release-archive.py` has never checked a real tag, and the catalog
entry G-42 fixed names a release asset that does not exist. The first open
question in `open-questions.md` (minor or major) is the only blocker and it
is a one-line decision. Unverified: whether the workflow publishes the two
assets it promises, `specflow-<tag>.zip` and
`validate-release-archive-<tag>.txt`, which `release.yml` lines 47 and 54
build. The worktree carries the decision and the CHANGELOG move; the tag
itself is cut on `main` after the merge.

Holds: `open-questions.md`, `decisions.md`, `specflow/CHANGELOG.md`,
`specflow/extension.yml` (the `version` field only).

Default: 1.1.0, by the rule G-36 adopted (a changed Process step is minor).
The raised `speckit_version` floor is the one entry that rule does not
classify; the ADR records it as the exception and states that the next
floor raise is major.

Do:

1. Ask the maintainer once whether the floor raise makes this major. Take
   the default if no answer arrives in the session.
2. Add ADR-0024 to `decisions.md` in the existing form (Date, Status,
   Context, Decision, Consequences, under 150 words) recording the version
   and the floor exception. Delete the "Is the next release minor or major?"
   section from `open-questions.md`.
3. In `specflow/CHANGELOG.md`, insert `## [1.1.0] - <merge date>` under the
   `## [Unreleased]` heading and move every entry beneath it, leaving
   `[Unreleased]` empty. Change `version: "1.0.2"` in `extension.yml` to
   `"1.1.0"`.
4. Run both validators from `specflow/`, then merge the PR.
5. On `main`, run `git tag v1.1.0` and `git push origin v1.1.0`.
   `release.yml` triggers on `v*`.
6. Open the Actions run. Confirm the release page carries both assets.
7. In a fresh directory on each surface, run
   `specify init --here --integration claude` (then `copilot`), then
   `specify extension add specflow --from <release zip URL>` and
   `specify extension list`.

Done when:

- `open-questions.md` no longer holds the version question, and
  `specflow/CHANGELOG.md` has no entry under `[Unreleased]`.
- `git tag` lists `v1.1.0` and `release.yml` ran green for it.
- The release page carries the ZIP and the validator report.
- `specify extension list` in both fresh projects prints the command and
  hook counts `extension.yml` declares.

### `manifest-schema`: item 38

N-05, the half D-05d did not take. `extension.yml` carries the tags and the
raised `speckit_version`; it still has no `category`, no `effect`, and no
hook `priority`, and item 12 shows the live catalog carries the first two.
Merge this before `payload-gates` opens the same file, or that block
rebases.

Holds: `specflow/extension.yml`.

Do:

1. Open the publishing guide `specflow/README.md` links under "Submitting
   to the spec-kit catalog" and read its schema appendix for the allowed
   values of `category` and `effect` and the type of a hook `priority`.
2. Add `category` and `effect` under the `extension:` block of
   `specflow/extension.yml`, after `license`, with the values the appendix
   allows that fit a workflow extension. Add `priority` to each of the three
   hooks, after `optional`.
3. Run both validators from `specflow/` and fix whatever they flag.
4. In a scratch directory, run `specify init --here --integration claude`,
   `specify extension add <checkout>/specflow --dev`, and
   `specify extension info specflow`.

Done when:

- `specify extension info specflow` prints the category.
- Both validators pass from `specflow/`.

### `skill-progress-schema`: item 33

G-43 T431. The block at `SKILL.md` lines 122 to 135 (grep
`feature: feature-name`) breaks the contract `validate-progress.py`
enforces at least eight ways: `feature` and `created` are unknown keys,
`current_phase` is a string where an integer is required, `phases` is a
mapping where a list is required, `spec` and `status` are missing,
`updated` is not in the phase contract, and the `{ ... }` flow mappings are
outside the parsed subset, which is the first error the validator prints.
`workflow-guide.md` line 663 (grep `completed_tasks`) names two more
unknown keys.

Holds: `specflow/SKILL.md`, `specflow/references/workflow-guide.md`.

Do:

1. Replace the YAML block under "### Progress Tracking" in `SKILL.md` with
   this one, which follows the contract at `validate-progress.py` lines 36
   to 46 and matches `examples/static-landing-page/specs/*/progress.yml`:

   ```yaml
   # specs/NNN-feature-name/progress.yml
   spec: NNN-feature-name
   status: in_progress
   current_phase: 2
   phases:
     - phase: 1
       name: Setup
       status: complete
       tasks:
         T001: complete
         T002: complete
     - phase: 2
       name: Foundational
       status: in_progress
       tasks:
         T003: pending
   ```

2. Under the block, keep the "Status values" line and add one sentence:
   `brainstorm` (`sessions`, `last_session`) and `gates` are optional
   top-level mappings; copy their shape from the example under
   `examples/static-landing-page/`.
3. In `workflow-guide.md`, rewrite the table row that reads
   `Update completed_tasks and current_task` to name the task's entry under
   its phase's `tasks:` mapping instead.
4. Write the block above to a scratch `progress.yml` and run
   `python3 .claude/review/validate-progress.py <path>`.

Done when:

- A `progress.yml` written by following `SKILL.md` alone passes
  `validate-progress.py`.
- `grep -c 'completed_tasks\|current_task' specflow/references/workflow-guide.md`
  prints 0.

### `template-stamp`: item 36

Backlog 25, repriced. G-24 T243 and T244 removed the copy step, so the
stale-copy case is gone; what remains is a core template change this fork
does not port (ADR-0021's stated cost).

Holds: `specflow/templates/`, `specflow/commands/status.md`,
`specflow/scripts/e2e-smoke.sh`.

Default: the stamp is an HTML comment on its own line,
`<!-- specflow template: <template name> <extension version> -->`, the
form backlog 25 gives. `<template name>` is the `name` the manifest
declares for the file, and `<extension version>` is `extension.version`
at the time of the edit.

Do:

1. Add the stamp as line 1 of `checklist-template.md`,
   `constitution-template.md`, `plan-template.md`, and `spec-template.md`.
   `tasks-template.md` opens with a `---` frontmatter block; put the stamp
   on the first line after the closing `---`.
2. In `commands/status.md`, add a step after the superpowers detection
   step: read the stamp from each template under
   `.specify/extensions/specflow/templates/`, and print one line per
   template in the form `template <name>: <stamp version> (installed
   <extension version>)`, marking a mismatch with `stale`.
3. Add the same line to the sample output in `SKILL.md`'s status section
   and to the `status.md` Output section.
4. In `e2e-smoke.sh`, after the existing template assertions, add one
   `assert_grep` per template for `specflow template:` in the installed
   copy, on both the Claude and Copilot legs.
5. Run both validators from `specflow/` and `bash scripts/e2e-smoke.sh`.

Done when:

- `bash scripts/e2e-smoke.sh` reports five new stamp assertions per leg
  and passes.
- Both validators pass from `specflow/`.

### `merge-gate-steps`: item 37

N-25 and the deferred mutation step, one item because they share the defect.
`merge-gate.yml` line 83 sets `continue-on-error: true` on the Semgrep step
and line 90 sets it on the mutation step, so neither can fail the job. Line
91 runs `mutmut run --paths-to-mutate`, a mutmut 2 flag that mutmut 3 rejects
with `No such option`, while `.claude/hooks/mutation-gate.sh` already exists
to replace it. Line 84 runs `pipx run semgrep ci`, which wants a Semgrep app
token the repository does not hold. Unverified: what it does without one.
The mutation step carries `if: steps.risk.outputs.level == 'HIGH'`, so a
STANDARD-risk PR never runs it; keep that condition.

Holds: `.github/workflows/merge-gate.yml`.

Default: `pipx run semgrep scan --config auto --error`, which needs no
token and exits non-zero on a finding. Adding a `SEMGREP_APP_TOKEN` secret
is the maintainer's call and is not taken here.

Do:

1. Delete both `continue-on-error: true` lines and the two comments above
   them that explain them (grep `Scanner findings are advisory` and
   `No mutmut configuration is committed`).
2. Replace `run: pipx run semgrep ci` with the default above.
3. Replace `run: pipx run mutmut run --paths-to-mutate specflow/scripts`
   with `run: bash .claude/hooks/mutation-gate.sh specflow/examples/mutation-gate-sample/`.
   Read the header of `mutation-gate.sh` first for the arguments it takes
   and the exit code it uses to fail.
4. Open the PR. If the risk classifier marks it STANDARD, push a second
   commit that touches a file under a directory the classifier treats as
   sensitive (see `SENSITIVE_DIRS` in `risk-classifier.sh`) so the mutation
   step runs once, then revert it in a third commit.
5. Read both steps' logs on the run.

Done when:

- `grep -c 'continue-on-error' .github/workflows/merge-gate.yml` prints 0.
- The mutation step's `run:` line names `.claude/hooks/mutation-gate.sh`
  and `mutation-gate-sample`.
- A pull request run shows Semgrep findings or a clean scan, and the
  mutation step ran once and passed.

### `payload-gates`: items 3, 10, 16, and 17

Rebase over: `manifest-schema` (`extension.yml`), `skill-progress-schema`
(`workflow-guide.md`), and `template-stamp` (`e2e-smoke.sh`).

Holds: `specflow/extension.yml` (`provides.scripts` and the `hooks` block),
`specflow/gates/` (new), `specflow/commands/gate.md` (new),
`specflow/commands/tasks.md`, `specflow/commands/review.md`,
`specflow/commands/hooks/`, `specflow/references/workflow-guide.md`,
`specflow/references/findings-schema.json` (moves from
`.claude/review/schema.json`), `.claude/hooks/risk-classifier.sh`,
`.claude/hooks/merge-gate.sh`, `.claude/hooks/README.md`,
`.claude/review/validate-findings.py`, `.claude/review/validate-progress.py`,
`specflow/scripts/validate-release-archive.py`,
`specflow/scripts/e2e-smoke.sh`, one fixture in
`specflow/scripts/e2e-agent-claude.sh`, and `AGENTS.md`.

Default: a new `specflow/gates/bash/` directory, not export-ignored. The
alternative, shipping `scripts/`, moves every development script and
touches both CI workflows, `verify.sh`, `release.yml`, the parity test, and
every test import. `gates/` touches the archive validator's expected-path
list and nothing else.

3. **Make the markers a machine writes, not a rule the agent remembers.**
   N-01 and N-02. The extension's one-sentence pitch is "execute refuses to
   run until analyze reports zero critical inconsistencies", and today
   `.clarified` and `.analyzed` exist only as a prose rule in
   `workflow-guide.md`. Spec-kit fires `after_clarify` and `after_analyze`
   and nothing listens. On the Copilot CLI, where no `.claude/hooks/` runs,
   the pitch is enforced by memory. Adding the command and its two hooks
   changes the counts to 6 commands and 5 hooks. CI reads both from the
   manifest since G-24 T241; `validate-extension-metadata.py` flags each
   doc that still says 5 and 3, starting with `specflow/README.md` line 58
   (grep `Commands: 5 | Hooks: 3`).
10. **Put every stop code in one table.** *New.* The commands stop with
    `ANALYZE_REQUIRED`, `OPEN_QUESTIONS` after item 3, a missing
    constitution, and a missing resolver, and a user meets each one cold.
16. **Ship the gate scripts in the payload.** N-03. `review.md` says "When
    `.claude/hooks/risk-classifier.sh` exists in the repository", which is
    never true on an installed extension: `.claude/` is outside the archive
    (ADR-0001). `provides.scripts` is spec-kit's own route, and the `git`
    extension bundled with spec-kit ships that way. ADR-0022 blocks the
    `events:` block on three prerequisites; this item clears the largest
    one, which `docs/agent-event-mapping.md` names first under "What blocks
    the block".
17. **Remove every `.claude/` path from the shipped files.** N-04, widened.
    `.claude/review/schema.json`, `validate-findings.py`, and
    `validate-progress.py` never reach an installed project, and
    `workflow-guide.md` cites them and the hook scripts at lines 430, 505,
    544, 550, and 669 (grep `\.claude/`), so a Copilot user reads five
    instructions naming files that do not exist.

Do:

1. Add ADR-0025 to `decisions.md` recording the `gates/` directory and
   that it amends ADR-0001 for the four shipped scripts. Add `gates/` to
   the runtime paths `validate-release-archive.py` expects in the archive.
2. Item 16: move `risk-classifier.sh` and `merge-gate.sh` to
   `specflow/gates/bash/`. Replace each file under `.claude/hooks/` with a
   two-line script that execs the shipped copy, so `settings.json`,
   `merge-gate.yml`, and the hook tests keep their paths. Add a
   `provides.scripts` block to `extension.yml` listing both under
   `gates/bash/` with `runtimes: [bash]`, in the form the `git` extension
   in spec-kit's repository uses. In `review.md`, change the sentence to
   "When `gates/bash/risk-classifier.sh` exists under the installed
   extension directory".
3. Item 3: add `specflow/gates/bash/write-marker.sh`, which takes a
   feature directory and one of `clarified` or `analyzed`. For `clarified`
   it exits 1 while `grep -c 'NEEDS CLARIFICATION' spec.md` is above 0,
   else touches `.clarified`. For `analyzed` it exits 1 while the analysis
   report the agent passes on stdin contains a Critical row, else touches
   `.analyzed`. Add `commands/gate.md` (`speckit.specflow.gate`) in the
   Input, Output, Process shape of the other five commands: Process step 1
   checks the constitution, step 2 finds the feature, step 3 runs the
   script, step 4 prints which marker it wrote or why it refused. Register
   it in `extension.yml` under `provides.commands` and add `after_clarify`
   and `after_analyze` hooks with `command: "speckit.specflow.gate"` and
   `optional: false`. In `commands/tasks.md`, add a step after the
   constitution check: stop with `OPEN_QUESTIONS` and the count while any
   row of the spec's Open Questions table is not `Resolved`. Add a dry-run
   fixture to `e2e-agent-claude.sh` at stage 5 with one open row, asserting
   the stop line.
4. Item 17: `git mv .claude/review/schema.json specflow/references/findings-schema.json`
   and repoint `validate-findings.py`, the reviewer agent files, and
   `merge-gate.sh` at it. Move `validate-findings.py` and
   `validate-progress.py` to `specflow/gates/python/`, leave two-line
   callers under `.claude/review/`, and list both under `provides.scripts`
   with `runtimes: [python]`. Rewrite the five `workflow-guide.md`
   citations: a shipped script is cited at its `gates/` path, and a
   repository-only path (line 550's `diff-impl.sh`, line 505's
   `telemetry.jsonl`) gets the words "in this repository only" in the same
   sentence.
5. Item 10: under `## Quick Reference` in `workflow-guide.md`, add a table
   with columns Code, Printed by, Expected, Found, Next command, and four
   rows: `ANALYZE_REQUIRED` (execute), `OPEN_QUESTIONS` (tasks),
   `CONSTITUTION_REQUIRED` (every command), `RESOLVER_REQUIRED` (tasks and
   the five `SKILL.md` steps ADR-0019 names). Give the last two their codes
   in each command file's constitution and resolver steps. Rewrite each
   stop line to the form `standards/code.md` sets: the fact, the expected
   value, the fix.
6. Update `AGENTS.md`'s Architecture list with one bullet for `gates/`.
   `e2e-smoke.sh` fills `SPECFLOW_COMMANDS` from the manifest, so it
   asserts the gate command's file without an edit; add an `assert_file`
   for `gates/bash/risk-classifier.sh` under the installed extension
   directory on both legs. Run both validators,
   `bash scripts/e2e-smoke.sh`, `E2E_DRY_RUN=1 bash scripts/e2e-agent-claude.sh`,
   and `bash .claude/hooks/tests/run.sh`.

Done when:

- `e2e-smoke.sh` installs the gate command on both surfaces, and the
  dry-run fixture with one open question fails the tasks stage with
  `OPEN_QUESTIONS`.
- Every stop code a command file prints appears in the Quick Reference table
  by grep, and each command's stop line follows the expected-found-fix form.
- `git archive HEAD:specflow | tar -t` lists `gates/bash/risk-classifier.sh`.
- `grep -rn '\.claude/' specflow/ --include='*.md'` returns only lines whose
  sentence says "in this repository only".
- `python3 scripts/validate-release-archive.py` passes with the scripts in
  the archive, and `validate-extension-metadata.py` passes with the new
  counts.

### `verify-pin`: item 39

Local shellcheck 0.11.0 does not implement SC2218, so the parity script
reported clean while CI failed on it for three pushes, and on this machine it
reports `1 skipped` because Ruff is absent.

Holds: `verify.sh`, `open-questions.md`, `decisions.md`,
`tests/test_ci_parity.py`.

Default: state the limit, do not pin. A pin makes every contributor pay an
install step; a stated limit costs one comment. `verify.sh` prints the
local version of each tool beside the version `ci.yml` installs so the
mismatch is visible on every run.

Do:

1. Read the `shellcheck` and `ruff` install lines in `ci.yml` (grep
   `shellcheck` and `ruff`) and note the versions or the absence of a pin.
2. Add a comment block at the top of `verify.sh` stating that it runs the
   same commands as CI with whatever tool versions are installed locally,
   and that shellcheck below 0.11.1 lacks SC2218.
3. Before the shellcheck step, print `shellcheck --version | head -2` and
   `ruff --version` when each tool is present.
4. Run `python3 -m pytest tests/test_ci_parity.py`; if the new lines change
   the step shape it parses, adjust `script_steps` in the test.
5. Add ADR-0026 to `decisions.md` recording the choice and delete the
   "Should `verify.sh` pin the tool versions CI uses?" section from
   `open-questions.md`.

Done when:

- `open-questions.md` no longer holds the pin question.
- The first comment in `verify.sh` states which tool versions it does not
  match, and a run prints the local shellcheck version.
- `python3 -m pytest tests/test_ci_parity.py` passes.

### `speckit-floor`: item 21

*New.* `extension.yml` line 18 declares `>=0.16.2` with no upper bound, and
`ci.yml` line 88 (grep `spec-kit.git specify extension add`) installs
spec-kit from git main, so the floor the install refuses below has never
been installed against. The parity test reads only the `validate` job's
steps, so `verify.sh` stays untouched.

Holds: `.github/workflows/ci.yml`, `improvements/roadmap.md`, and line 27
of `specflow/scripts/e2e-smoke.sh`. Rebase over `template-stamp` and
`payload-gates`, which edit that script's assertions.

Do:

1. Write the `G-nn` group in `roadmap.md`.
2. Run `git ls-remote --tags https://github.com/github/spec-kit.git | grep 0.16.2`
   and copy the exact tag name.
3. Add a job `smoke-floor` after `validate` in `ci.yml` with the same
   `runs-on` and Python setup as `validate`, whose one step runs
   `SPEC_KIT_GIT_URL=https://github.com/github/spec-kit.git@<tag> bash scripts/e2e-smoke.sh`
   from `specflow/`. `run_specify` in that script prefixes the variable
   with `git+`, so the `@<tag>` suffix reaches `uvx` unchanged. Confirm
   the variable is overridable from the environment (grep
   `SPEC_KIT_GIT_URL=` on line 27); if it is a plain assignment, change it
   to `${SPEC_KIT_GIT_URL:-...}` in the same PR.
4. Do not touch the `validate` job.

Done when:

- `grep -c '0.16.2' .github/workflows/ci.yml` prints at least 1.
- The `smoke-floor` job runs `e2e-smoke.sh` and passes on the PR.
- `python3 -m pytest tests/test_ci_parity.py` passes unchanged.

### `test-gate`: item 15

N-15. `test-gate.sh` line 9 defaults `TEST_CMD` to
`cd specflow && python3 scripts/validate-extension-metadata.py`. In a
consuming project the `cd` fails, so the gate blocks every ticked task
instead of testing nothing, reproduced by `work-verifier` in a fixture
project with `GATE_EXIT=2`.

Holds: `.claude/hooks/test-gate.sh`, `.claude/hooks/tests/run.sh`,
`.claude/hooks/README.md`.

Do:

1. In `run.sh`, add three `check` lines for `test-gate.sh`: a fixture
   repository whose `.specify/memory/constitution.md` holds a line
   `Test command: true` under a `## Code Review Rules` heading and a
   `tasks.md` diff that ticks a task, expecting exit 0; the same fixture
   with `Test command: false`, expecting exit 2; and a fixture with no
   constitution and no `specflow/` directory, expecting exit 0. Run the
   suite and confirm the first and third fail.
2. In `test-gate.sh`, replace the `TEST_CMD` line with a lookup in this
   order: `SPECFLOW_TEST_CMD` when set; else the text after
   `Test command:` in `.specify/memory/constitution.md` when the file
   exists and the line is present; else print
   `test-gate: no test command found (SPECFLOW_TEST_CMD unset, no "Test command:" line in .specify/memory/constitution.md); skipping`
   to stderr and exit 0. Keep `SPECFLOW_TEST_CMD` first so this
   repository's own setting still wins.
3. Add a `Test command: <the project's test command>` line to the Code
   Review Rules section of `templates/constitution-template.md`. Do not use
   a `[NEEDS CLARIFICATION]` marker as the placeholder; ADR-0015 allows one
   only on the spec template's example line.
4. Describe the lookup order in `.claude/hooks/README.md` under "Run the
   gate locally".

Done when:

- The three new `check` lines pass, and `bash .claude/hooks/tests/run.sh`
  reports 0 failed.
- `grep -c 'cd specflow' .claude/hooks/test-gate.sh` prints 0.

### `telemetry-budget`: items 23 and 24

23. **Read the phase from `progress.yml`.** N-16. `log-phase.sh` line 9
    reads `.claude/.current-phase`, which no command writes, so every
    telemetry line says `unknown`.
24. **Join the budgets to the telemetry.** Backlog 32. The Budgets table in
    `workflow-guide.md` (grep `## Budgets`) sets a token ceiling per phase,
    the headless example under it passes `--max-budget-usd 1.00`, and
    `log-phase.sh` writes phase lines; nothing compares spend to either
    figure.

Holds: `.claude/hooks/log-phase.sh`, `.claude/hooks/cost-report.sh` (new),
`.claude/hooks/tests/run.sh`, `.claude/settings.json`,
`.claude/hooks/README.md`.

Default: the ceiling is dollars, not tokens, because the only spend figure
a run produces is `total_cost_usd` from `claude -p --output-format json`.
`cost-report.sh` reads the ceiling from `SPECFLOW_BUDGET_USD`, default
`1.00`, the figure the headless example passes. A telemetry line that
carries `total_cost_usd` comes from a headless run; a Stop-hook line
carries none and contributes nothing to the sum.

Do:

1. In `run.sh`, add a `check` for `log-phase.sh` with a fixture holding
   `specs/001-x/progress.yml` whose `current_phase: 3`, asserting the
   appended line's `phase` is `3`. Add two `check` lines for
   `cost-report.sh`: a fixture `telemetry.jsonl` with two lines for feature
   `001-x` summing to 1.50 expecting exit 1, and one summing to 0.50
   expecting exit 0.
2. In `log-phase.sh`, replace the `.current-phase` read with: find the
   newest `specs/*/progress.yml` by modification time, read its
   `current_phase` and `spec` values with `grep` and `cut`, and write them
   as `phase` and `feature`. Delete the header sentence about
   `.current-phase`. Keep exit 0 on every path.
3. Write `cost-report.sh`: read `.claude/telemetry.jsonl`, sum
   `total_cost_usd` per `feature` with `jq -s`, print one line per feature
   as `<feature> <sum> / <ceiling>`, and exit 1 naming each feature whose
   sum exceeds the ceiling, in the expected-found-fix form.
4. Register `cost-report.sh` in `settings.json` under `Stop`, after
   `log-phase.sh`, so the report prints when a run ends. Describe both
   scripts and the `SPECFLOW_BUDGET_USD` setting in the hooks README under
   "Telemetry queries".

Done when:

- The `log-phase.sh` check passes and
  `grep -c 'current-phase' .claude/hooks/log-phase.sh` prints 0.
- The over-budget fixture exits 1 and names the feature; the under-budget
  fixture exits 0.
- `bash .claude/hooks/tests/run.sh` reports 0 failed.

### `scorer-dimensions`: item 22

N-17 with backlog 33. Backlog 34's seeded-ambiguity golden waits on
`live-run` for its snapshot and stays out of this block. New seeded variants
go under `specflow/examples/`, which is export-ignored, so the archive size
does not move. `score-artifacts.py` scores by one `score_<name>` function
per dimension (grep `def score_`), each returning a dict the report prints.

Holds: `specflow/scripts/score-artifacts.py`,
`specflow/scripts/tests/test_score_artifacts.py`, four new directories
under `specflow/examples/`, `.github/workflows/score-artifacts.yml`.

Do:

1. In `test_score_artifacts.py`, add one test per dimension asserting the
   golden scores 100 and the seeded variant scores below 100. Run them and
   confirm they fail.
2. Add four functions beside `score_traceability`:
   `score_threat_model` (every row of the `## Threat Model` table has a
   non-empty Mitigation cell or reads `N/A`), `score_open_questions`
   (every row of `## Open Questions` reads `Resolved` when `.clarified`
   exists beside the spec; 100 when the marker is absent),
   `score_changelog` (at least one row under `## Changelog`), and
   `score_test_exists` (every test the Traceability table names resolves
   to a file under the feature's project root by `grep -rl`). Add each to
   the report in the same place the existing dimensions print.
3. Copy `examples/seeded-bug/` four times under `specflow/examples/`, one
   per dimension, named `seeded-threat-model/`, `seeded-open-question/`,
   `seeded-no-changelog/`, and `seeded-missing-test/`, and break only that
   dimension in each. Give each a README line saying what it seeds.
4. Add the four directories to the replay list in `score-artifacts.yml`
   (grep `seeded-bug` to find it).

Done when:

- The golden scores 100 on each new dimension.
- Each seeded variant scores below 100 on the dimension it seeds and 100
  on the others.
- `score-artifacts.yml` passes on the PR with no dropped score.

### `reviewer-scorecard`: item 25

Backlog 31. Part 6 of `docs/review-research.md` (grep `## Part 6`) assumes
a weekly scorecard and none exists, so a persona below 0.5 precision cannot
be found.

Holds: `.claude/review/scorecard.sh` (new), `.claude/review/tests/`,
`docs/review-research.md`.

Default: precision is fixed divided by fixed plus rejected plus rebutted,
the formula backlog 31 gives. Findings files are every JSON file under
`.claude/review/` and `specs/*/review-findings.json` that validates against
the findings schema; the persona is the `reviewer` field of each finding.
Read `merge-gate.sh` for how it enumerates the same files and reuse that
glob.

Do:

1. Add `.claude/review/tests/test_scorecard.py` in the form of
   `test_validate_findings.py` beside it: run the script with
   `subprocess.run` on a fixture findings file holding four findings for
   one `reviewer`, two `fixed` and two `rejected`, and assert stdout holds
   `0.50` for that reviewer. Run it and confirm it fails.
2. Write `scorecard.sh`: for each findings file, `jq` the persona and
   status of every finding, group by persona, print
   `<persona> <precision> (<fixed> fixed, <rejected> rejected, <rebutted> rebutted)`,
   and write the same lines to `.claude/review/scorecard.md`.
3. In Part 6, replace the sentence that assumes a scorecard with the
   script's name and `bash .claude/review/scorecard.sh` as the weekly
   command.

Done when:

- The four-finding fixture prints `0.50`.
- Part 6 names the script and the command that runs it.

### `rewrite-after-tasks` and `rewrite-metadata-validator`: item 34, two of six

The Rewrite status table in `reference.md` (grep `## Rewrite status`)
lists six files waiting on D-01, D-05, and G-22. All three merged. These two
files have no other block above, so their passes run today. The other four
passes wait for the block that edits their contract; they appear in waves 2
and 3.

Holds: `specflow/commands/hooks/after-tasks.md` in the first block,
`specflow/scripts/validate-extension-metadata.py` in the second, and the
file's row in `reference.md` in each.

Do, for each file:

1. Append `(working on)` to the file's row in the Rewrite status table and
   commit that on `main`.
2. Dispatch `prose-rephraser` on `after-tasks.md`, or `script-refactorer`
   on `validate-extension-metadata.py`, with the file path and the
   matching standard as the prompt.
3. Dispatch `divergence-auditor` on the result.
4. Clear the Waiting on cell for the row and record the Real number
   `measure-divergence.py` prints.

Done when, for each file:

- The table's Waiting on cell is empty for that row and the Real cell
  holds the new number.
- `divergence-auditor` reports every guard passing.

## Wave 2: one merge away

### `readme-onboarding`: items 4 to 9 and 11 to 14

Wait for: `first-tag`, because item 14 runs the release-ZIP install line
that item 5 adds. Item 10 lives in `payload-gates` because it depends on
item 3's code and edits `workflow-guide.md`.

Holds: `README.md` (new, at the root), `specflow/README.md`,
`specflow/references/copilot-cli.md`, `LICENSE` (new), `CONTRIBUTING.md`
(new), `SECURITY.md` (new), and `tests/test_readme_commands.py` (new). Not
`ci.yml`: the new test runs under the existing pytest step. A wrong catalog
procedure costs a rejected submission and a second week, so this cluster
comes before any payload change is announced.

Section names below are the `## ` headings in `specflow/README.md`:
Installation, Verify the install, Commands, Workflow, Resumable state,
Getting started, A complete run, Project structure, Superpowers skills,
Submitting to the spec-kit catalog, License.

4. **Write a root `README.md`.** *New.* GitHub renders the README at the
   repository root and none exists, so the landing page is a file list that
   opens with `AGENTS.md`, `improvements/`, and `presentation/`. Do: write
   one paragraph saying what specflow is, one line per target surface, a
   link to `specflow/README.md#installation`, and a two-column table naming
   which directory a user needs (`specflow/`) and which are the
   maintainers' (`improvements/`, `standards/`, `presentation/`, `docs/`,
   `.claude/`). Under 40 lines.
5. **Open Installation with `specify init`, then a command that works.**
   *New.* The section opens with `specify extension add specflow`, which
   needs an initialized project the README never creates, and which
   searches a catalog that lists no specflow (G-42).
   `specify init --here --integration copilot` appears only in
   `e2e-smoke.sh` (grep `integration copilot`). Do: rewrite the section in
   this order: one `specify init --here --integration claude` line and one
   with `copilot`; the release ZIP form
   `specify extension add specflow --from <release asset URL>`; the
   `--dev` clone form with the sentence that it copies the 13 MiB under
   `assets/` the archive strips; the catalog form last, with the sentence
   "works once the catalog lists specflow".
6. **Put the two gate commands in the walk-through.** *New.* Getting
   started step 4 (grep `Plan, decompose, implement, review`) runs plan,
   tasks, execute, review with no `/speckit.clarify` and no
   `/speckit.analyze`, while `execute.md` stops with `ANALYZE_REQUIRED`
   until `.analyzed` exists. Do: insert `/speckit.clarify` before
   `/speckit.plan` and `/speckit.analyze` between `/speckit.specflow.tasks`
   and `/speckit.specflow.execute`, the order stage 6 of the dry run
   asserts.
7. **Print one status line, not two.** *New.* Verify the install shows
   `11/19 tasks done` (grep it); `status.md` line 29 and `SKILL.md` line
   231 show `gates: clarified, analyzed, T012/T019 tasks done`. Do: copy
   the two feature lines from `SKILL.md` over the README's sample.
8. **Say how a Copilot user invokes a command.** *New.* `e2e-smoke.sh`
   shows that a Copilot install lands each command at
   `.github/skills/speckit-specflow-<cmd>/SKILL.md`, and neither the
   README nor `copilot-cli.md` says what the user types on that surface.
   Do: run one Copilot install in a scratch project, invoke one command,
   record the exact text typed, then add a five-row table to
   `copilot-cli.md` (command, what to type) and one sentence with one
   example to the README's Commands section.
9. **Add upgrade, remove, and troubleshooting sections.** *New.* The README
   has no `specify extension remove specflow` line, no upgrade line, and
   the only troubleshooting text is the marker note in `SKILL.md` (grep
   `Remove a marker before rerunning`) and the Skills Not Detected section
   of the mapping. Do: add three `## ` sections after Resumable state:
   Upgrade (`specify extension add specflow --from <new ZIP>` over the old
   install, noting item 20's smoke test walks it), Remove (the command and
   what stays behind: `specs/`, `.specify/superpowers.yml`, the markers),
   and Troubleshooting (one entry each for constitution missing, resolver
   missing per ADR-0019, `ANALYZE_REQUIRED`, skills not detected, each
   with the line the command prints and the fix).
11. **Fix the catalog submission procedure.** *New.* Submitting to the
    spec-kit catalog tells a maintainer to fork spec-kit, edit
    `catalog.community.json`, and open a pull request, and promises a
    three-to-seven-day review. The publishing guide the section links
    carries a callout that says not to open a pull request against that
    file: submissions go through an Extension Submission issue a spec-kit
    maintainer acts on, and the guide names no review window. Do: rewrite
    the numbered steps around the issue template the guide links, delete
    every step that edits a file in `github/spec-kit`, and delete the
    review-window sentence.
12. **Give the catalog snippet the fields the live catalog carries.** *New.*
    Of 171 entries in `catalog.community.json` on 2026-09-20, all carry
    `provides`, `downloads`, `stars`, `created_at`, and `updated_at`, 170
    carry `category` and `effect`, and 167 carry `changelog`. The JSON
    snippet in that section (grep `"verified": false`) has none of them.
    Do: add `category` and `effect` (the values `manifest-schema` chose),
    `provides` with the command and hook counts read from `extension.yml`,
    and `changelog` pointing at `specflow/CHANGELOG.md` on GitHub. Check
    the schema appendix for whether the four counters are submitted or
    computed by the catalog; add only the submitted ones.
13. **Add the root license and contributor files.** *New.* GitHub reads the
    license from the root and ours is at `specflow/LICENSE` only, so the
    About panel shows no license. Do: copy `specflow/LICENSE` to the root
    unchanged; write `CONTRIBUTING.md` naming `bash verify.sh`, the three
    files under `standards/`, and the one-worktree-per-block rule from this
    file; write `SECURITY.md` with the maintainer's reporting address (ask
    for it; do not invent one).
14. **Execute the README in CI.** *New.* `standards/documentation.md` says
    to run every command a document contains before hand-off, and
    `specflow/README.md` carries an install, a verify, and a walk-through
    that nothing executes. Do: write `tests/test_readme_commands.py` to
    extract each fenced `bash` block from `specflow/README.md`, run it in a
    temporary directory after a `specify init`, and fail on a non-zero
    exit. Skip a block whose first line is a slash command; those run only
    inside an agent. It runs under the existing pytest step.

Done when:

- `README.md` exists at the root and
  `python3 specflow/scripts/lint-standards.py README.md` exits 0.
- The first command under Installation is `specify init`, and the
  walk-through names `/speckit.clarify` and `/speckit.analyze` before
  `/speckit.specflow.execute`.
- The two feature lines of the status sample in the README, `status.md`,
  and `SKILL.md` are identical by `diff`.
- `copilot-cli.md` holds a table naming the invocation for each of the
  five commands.
- The Upgrade, Remove, and Troubleshooting headings exist.
- The catalog section names the issue template, no numbered step edits a
  file in `github/spec-kit`, and the snippet's `provides` counts match
  `extension.yml` and every other field matches the publishing guide's
  schema appendix.
- GitHub's About panel shows MIT, and `LICENSE`, `CONTRIBUTING.md`, and
  `SECURITY.md` exist at the root.
- `python3 -m pytest tests/test_readme_commands.py` passes, and fails when
  one README command is renamed.

### `copilot-e2e`: item 18

Wait for: `payload-gates`, so the `OPEN_QUESTIONS` fixture lands once, in
the file this block splits. Rebase over `verify-pin` and `speckit-floor`,
because the new dry-run step goes in the `validate` job and the parity test
then needs `verify.sh` to match. This block records Copilot's tool-payload
field names from a real session as a side effect, which is one of the three
prerequisites ADR-0022 names.

Holds: `specflow/scripts/e2e-agent-copilot.sh` (new),
`specflow/scripts/e2e-stages.sh` (new), `specflow/scripts/e2e-agent-claude.sh`,
`.github/workflows/ci.yml`, `verify.sh`, `docs/agent-event-mapping.md`.

Do:

1. Read `e2e-agent-claude.sh` end to end. The seven `title N` calls (grep
   `^title [1-7]`) mark the stages; the `assert_*` functions and the
   dry-run seed from `examples/static-landing-page` sit above them.
2. Move the seven stage bodies, the `assert_*` functions, and the seed
   block into `e2e-stages.sh`, each stage as a function
   `stage_N_<name>` that takes the agent-invocation function name as its
   argument. Have `e2e-agent-claude.sh` source it, define
   `invoke_agent()` around `claude -p`, and call the seven functions.
   Run `E2E_DRY_RUN=1 bash scripts/e2e-agent-claude.sh` and confirm the
   assertion count printed at the end is unchanged.
3. Write `e2e-agent-copilot.sh` in the same shape, with `invoke_agent()`
   around `copilot -p "<prompt>"` and the init line using
   `--integration copilot`. Never pass `--allow-all-tools` on a runner
   that can push.
4. Add a step `E2E_DRY_RUN=1 bash scripts/e2e-agent-copilot.sh` to the
   `validate` job in `ci.yml`, directly after the Claude dry-run step, and
   the same command to `verify.sh` in the same position.
5. Run one real Copilot session in a scratch project with a hook that
   dumps its stdin to a file, and record the field names for the command
   and file path in `docs/agent-event-mapping.md` under "Adapter per
   surface", replacing the sentence that says no source records them.

Done when:

- `E2E_DRY_RUN=1 bash scripts/e2e-agent-copilot.sh` exits 0 in CI.
- `E2E_DRY_RUN=1 bash scripts/e2e-agent-claude.sh` still exits 0 with the
  same assertion count as before the split.
- `python3 -m pytest tests/test_ci_parity.py` passes.
- `docs/agent-event-mapping.md` names the Copilot field for the command
  and for the file path.

### `reviewer-bodies`: item 35

Wait for: `payload-gates`, which settles the schema path each reviewer
cites. N-18. `critic.md` is 18 lines and `maintainability-reviewer.md` is
16; the BDD squad runs 30 to 75 lines with a median near 33, and every squad
file has When to invoke, Process, and Output format headings. The standards
linter already passes on the directory, so it proves nothing here.

Holds: `.claude/agents/*-reviewer.md`, `.claude/agents/critic.md`.

Do:

1. Read `.claude/agents/code-reviewer.md` as the model for the three
   headings and their depth.
2. In each of `conformance-reviewer.md`, `correctness-reviewer.md`,
   `maintainability-reviewer.md`, `performance-reviewer.md`,
   `security-reviewer.md`, `threat-model-reviewer.md`,
   `spec-red-team-reviewer.md`, and `critic.md`, add `## When to invoke`
   with two worked triggers, `## Process` with numbered steps, and
   `## Output format` naming `specflow/references/findings-schema.json`
   and stating that a finding without `file:line` is dropped.
3. Run `python3 specflow/scripts/lint-standards.py .claude/agents/`.

Done when:

- `grep -L '^## Process' .claude/agents/*-reviewer.md .claude/agents/critic.md`
  prints nothing.
- `grep -L 'findings-schema.json' .claude/agents/*-reviewer.md .claude/agents/critic.md`
  prints nothing.

### `rewrite-changelog`: item 34, third of six

Wait for: `first-tag`, so `prose-rephraser` reads the CHANGELOG with the
release heading in place.

Holds: `specflow/CHANGELOG.md` and its row in `reference.md`.

Do: the four steps under `rewrite-after-tasks`, with `prose-rephraser` on
`CHANGELOG.md`.

Done when the Waiting on cell is empty for the row and
`divergence-auditor` reports every guard passing.

## Wave 3: two merges away

### `register-gates`: items 19 and 20

Wait for: `payload-gates` (item 16 clears the largest ADR-0022 block),
`copilot-e2e` (item 18 records the field names), and `first-tag` (item 20
installs the release ZIP).

Holds: `specflow/extension.yml` (the `events:` block), frontmatter
`scripts:` blocks in all six files under `specflow/commands/`,
`specflow/scripts/e2e-smoke.sh`, both validators if the frontmatter trips
them, `decisions.md`.

19. **Register the gates on both hook systems.** G-26 T262 and T263, and
    backlog 28. An `events:` entry names a command, not a script: the
    dispatcher reads that command's frontmatter `scripts:` block, and our
    command files carry none. `docs/agent-event-mapping.md` gives the
    `events:` shape, the event each gate registers on, and the adapter per
    surface; follow it.
20. **Walk the upgrade path.** Backlog 26. Every user who installed 1.0.2
    upgrades through a path that has never run.

Do:

1. Read `docs/agent-event-mapping.md` in full. Its "What blocks the block"
   section names three blockers; confirm `payload-gates` and `copilot-e2e`
   cleared the first two and record the `jq` dependency decision as
   ADR-0027 (ship a `jq` check in `write-marker.sh` that prints the
   install command and exits 1 when `jq` is absent).
2. Add a frontmatter `scripts:` block to each command file naming the
   `gates/bash/` script it runs first, in the form spec-kit's core commands
   use (read one under `.specify/templates/commands/` in a scratch
   project).
3. Add the `events:` block to `extension.yml` from the mapping's table,
   one entry per gate, each naming `speckit.specflow.gate`.
4. Run both validators; if the frontmatter trips the metadata validator's
   command-file parse, widen that parse to skip a leading `---` block.
5. In `e2e-smoke.sh`, on the Copilot leg, `assert_file` the hook file the
   install wrote under `.github/` and `assert_grep` each event name in it.
6. Item 20: add a step to `e2e-smoke.sh` after the Claude install that
   installs the `v1.0.2` release ZIP first, then the checkout with
   `--dev`, and asserts with `assert_no_path` that no command file from
   1.0.2 that the checkout no longer ships remains, and with `assert_grep`
   that `.specify/extensions.yml` lists specflow once.

Done when:

- `grep -c '^events:' specflow/extension.yml` prints 1 and both validators
  pass.
- The Copilot leg of `e2e-smoke.sh` finds the hook file the install wrote
  and names the events in it.
- The smoke test reports the upgrade assertions and passes.

### `idempotent-dry-run`: item 26

*New.* Wait for: `copilot-e2e`, so the change lands in `e2e-stages.sh` once
for both surfaces. "Everything is resumable" is the architecture's third
rule and G-38 now validates the progress file, but no test re-enters a stage
after it has already run.

Holds: `specflow/scripts/e2e-stages.sh`, `improvements/roadmap.md`.

Do:

1. Write the `G-nn` group in `roadmap.md`.
2. In `e2e-stages.sh`, add a function `assert_idempotent` that takes a
   stage function name: it copies the feature directory to a temporary
   path, runs the stage function again, runs `diff -r` between the copy
   and the feature directory, passes on an empty diff, and prints the diff
   on a non-empty one.
3. Call it at the end of each of the seven stage functions, and add a
   second counter `IDEMPOTENT` that the summary line prints beside the
   assertion count.
4. Make one stage rewrite `progress.yml` from scratch in a throwaway
   commit, run the dry run, confirm the new check fails, and revert that
   commit in the same PR.

Done when:

- Both dry runs print an idempotence count beside the assertion count.
- The PR history shows one commit that breaks a stage and one that
  reverts it, with the failing run linked in the description.

### `superpowers-range`: items 27 to 32

Wait for: `copilot-e2e`, because items 30 and 32 add dry-run fixtures to
`e2e-stages.sh`. Rebase over `readme-onboarding` (`copilot-cli.md`),
`template-stamp` (`status.md`), and `skill-progress-schema` (`SKILL.md`).

Holds: `specflow/references/superpowers-mapping.md`, the execute row of
`specflow/references/copilot-cli.md`, `specflow/commands/brainstorm.md`,
`specflow/commands/execute.md`, `specflow/commands/status.md`,
`optional_skills` in `specflow/extension.yml`, the status section of
`specflow/SKILL.md`, and two fixtures in `e2e-stages.sh`.

The bridge assumes a skill shape and nothing says which. Superpowers 6.0
rewrote `subagent-driven-development`, 6.2 moved its workspace, and 6.4.1 is
the latest release as of 2026-09-19.

Default for item 27: Claude Code runs `subagent-driven-development` and
the Copilot CLI runs `executing-plans`. The `copilot-cli.md` execute row
already says `[SUBAGENT]` tasks run one at a time on that surface, and 6.x
reserves `executing-plans` for a runtime without subagents.

27. **Route execute by surface.** N-11. The mapping table lists
    `executing-plans` and `subagent-driven-development` for execute with no
    rule. Do: split the two execute rows in the Skill Mapping table by
    surface, add a Surface column, and repeat the rule in one sentence
    under the table. Add the same sentence to the execute row of
    `copilot-cli.md`.
28. **Settle who wins on checkpoints.** *New.* The executing-plans
    adaptation says "Never auto-approve. Always wait for user confirmation"
    (grep it), both execute skills say not to pause between tasks, and the
    same file calls the skill's process the authority. An agent holding
    both instructions picks one at random. Do: replace the two bullets
    with: "Specflow's checkpoint wins at a phase boundary: stop and wait
    for confirmation. Inside a phase the skill's no-pause rule holds.
    Reason: a phase boundary is where `progress.yml` is written and where
    a user can still redirect cheaply."
29. **Classify before questioning.** N-12. `brainstorm.md` does not contain
    the word spike; the dispatcher skill already routes on it. Do: add a
    Process step between the `decisions.md` read and the superpowers
    detection: classify the spec as a spike (a throwaway to learn one
    fact) or a feature, and for a spike ask only the boundary and
    error-handling categories. Renumber the following steps.
30. **Map the six unmapped skills, and say where the list lives.** N-13,
    corrected. `status.md` step 3 says "Check for all superpowers skills"
    and names none, and the only list of six is `optional_skills` in
    `extension.yml`, a block `work-verifier` found no reader for in
    spec-kit's extension loader. Do: add rows to the Skill Mapping table for
    `systematic-debugging` (execute, on a failing test),
    `verification-before-completion` (execute, before ticking a task),
    `using-git-worktrees` (execute, on `[SUBAGENT]` dispatch),
    `dispatching-parallel-agents` (execute, on `[P]` batches),
    `receiving-code-review` (review, after findings are reported), and
    `finishing-a-development-branch` (review, after the merge gate
    passes). Change `status.md` step 3 to "Check for every skill the Skill
    Mapping table in `references/superpowers-mapping.md` names". Above
    `optional_skills` in `extension.yml`, add the comment
    `# spec-kit reads no key under optional_skills; the mapping table is the list.`
31. **Name the two reviews the subagent path runs.** N-14. `execute.md`
    says "follow its dispatch protocol", so a 6.0 run and a 6.3 run
    produce different evidence. Do: in the `[SUBAGENT]` step of
    `execute.md`, name `code-reviewer` as the per-task reviewer and
    `/speckit.specflow.review` as the whole-branch review, and state that
    both run whatever the skill version says.
32. **Record the tested range.** Backlog 35. Do: in `status.md`'s detection
    step, read the superpowers entry's `version` from
    `~/.claude/plugins/installed_plugins.json` when the file exists and
    write it as `version:` in `.specify/superpowers.yml`. Add a "Tested range" sentence to the
    mapping under Detection Logic: `>=6.0.0 <7.0.0`. In `status.md`, print
    `superpowers <version> is outside the tested range <range>` when it
    falls outside. Add a fixture to `e2e-stages.sh` with `version: 5.0.0`
    asserting that line.

Done when:

- The execute rows of the mapping name one skill per surface and
  `copilot-cli.md` agrees.
- The execute adaptation rules state which instruction wins on checkpoints
  and why.
- `grep -c 'spike' specflow/commands/brainstorm.md` prints at least 1.
- The mapping table names 12 skills, `status.md` step 3 cites the table,
  and the dry run's status stage detects all 12 from a fixture.
- `execute.md` names the per-task reviewer and the whole-branch reviewer.
- A fixture with `version: 5.0.0` prints the range warning.

### `rewrite-readme`, `rewrite-extension-yml`, `rewrite-mapping`: item 34, last three

Each waits for the block that last edits its contract: `readme-onboarding`,
`register-gates`, and `superpowers-range` in turn.

Holds: `specflow/README.md`, `specflow/extension.yml`, or
`specflow/references/superpowers-mapping.md`, and the file's row in
`reference.md`.

Do: the four steps under `rewrite-after-tasks`, with `prose-rephraser` on
the file.

Done when the Waiting on cell is empty for the row, the Real cell holds
the new number, and every guard passes.

## Blocked on an API key

No key exists in this environment, so these run in whichever session first
has one. Each is one worktree.

### `live-run`: item 1 and backlog 34

Wait for: `ANTHROPIC_API_KEY`, `readme-onboarding` (the "A complete run"
section), and `copilot-e2e` (the seed path lives in `e2e-stages.sh`).

Holds: `specflow/examples/link-audit/`,
`specflow/examples/static-landing-page/README.md`, the "A complete run"
section of `specflow/README.md`, the seed path in `e2e-stages.sh`,
`specflow/examples/seeded-ambiguity/` (new), `score-artifacts.py` and its
test.

G-19 T191 is ticked, but the snapshot it produced, `examples/link-audit/`,
was built from the templates and gate rules because no API key existed. Its
README says so. The only recorded run in the repository is upstream's
`static-landing-page/`, and that one is no longer verbatim: `.analyzed` was
added by hand in `df50cb8`, four more commits edited the directory, and its
README line 9 still says nothing in the folder is hand-edited.
`specflow/README.md` presents it as this extension's run. The scorer's
golden, the dry run's 30 assertions, and the hook suite all seed from it.
Needs one session and one feature.

Do:

1. With `ANTHROPIC_API_KEY` exported, run `bash scripts/e2e-agent-claude.sh`
   with the link-audit feature description from
   `examples/link-audit/README.md` as the stage 2 prompt. Keep the work
   directory the script reports.
2. Copy `specs/001-*/` from that work directory over
   `examples/link-audit/specs/`, and rewrite `examples/link-audit/README.md`
   to say the run was recorded, with the date, the model, and the script
   version (`git rev-parse HEAD`). Delete the word "constructed".
3. In `examples/static-landing-page/README.md`, replace the sentence that
   says nothing is hand-edited with a list of the hand edits, starting with
   `.analyzed` from `df50cb8`; read `git log --oneline -- specflow/examples/static-landing-page`
   for the other four.
4. In `specflow/README.md`'s "A complete run" section, link
   `examples/link-audit/` and drop the claim that `static-landing-page/`
   is this extension's run.
5. Point `SNAPSHOT` in `e2e-stages.sh` at `examples/link-audit` and run
   `E2E_DRY_RUN=1 bash scripts/e2e-agent-claude.sh`; fix any assertion
   that named the old snapshot's content.
6. Build `examples/seeded-ambiguity/`: copy the recorded spec, replace one
   sort order with an unspecified one, run stage 3 (brainstorm) on it with
   the key, and keep the output. Add `score_seeded_ambiguity` to
   `score-artifacts.py` (100 when the Open Questions table names the sort
   order) with a test.

Done when:

- `examples/link-audit/README.md` no longer contains "constructed", and
  the README section links it.
- The static-landing-page README lists its hand edits.
- `E2E_DRY_RUN=1 bash scripts/e2e-agent-claude.sh` seeds from the new
  snapshot and exits 0.
- The seeded-ambiguity golden scores 100 and the unseeded variant scores
  below.

### `delete-upstream-example`: item 41

Wait for: `live-run`. G-19 T194. The notes under T194 price the move: the
hook suite reads `static-landing-page/specs` at `run.sh` line 110,
`test_score_artifacts.py` defines the seeded-bug golden as that snapshot
minus one row, `e2e-agent-claude.sh` seeds from it, and
`validate-extension-metadata.py` line 107 lists `examples/sample-workflow.md`.

Holds: `specflow/examples/static-landing-page/`,
`specflow/examples/sample-workflow.md`, `.claude/hooks/tests/run.sh`,
`specflow/scripts/tests/test_score_artifacts.py`,
`specflow/scripts/validate-extension-metadata.py`, `specflow/SKILL.md`.

Do:

1. Run `git rm -r specflow/examples/static-landing-page specflow/examples/sample-workflow.md`.
2. Change the `EX=` path in `run.sh` line 110 to `examples/link-audit/specs`.
3. Rebuild `examples/seeded-bug/` from `link-audit/` minus one
   traceability row, and repoint the golden in `test_score_artifacts.py`.
4. Remove `examples/sample-workflow.md` from the list in
   `validate-extension-metadata.py`, and repoint the `SKILL.md` line that
   cites the old example (grep `static-landing-page`).
5. Run both dry runs, `python3 -m pytest specflow/scripts/tests/`, and
   `bash .claude/hooks/tests/run.sh`.

Done when `grep -rn 'static-landing-page\|sample-workflow' specflow/ .claude/`
prints nothing and both dry runs, the scorer tests, and the hook suite pass.

## After the tag, not yet worktree-shaped

None of these has a file list a worktree can hold. Each needs a `G-nn` group
before it is claimed.

42. **Upstream the resync-safe moves.** Backlog 36. Four Tighten moves tagged
    "breaks resync: rarely": the after-tasks progress read (D-01), the
    status marker column (D-07), the compound-task rule (D-06), and the
    Copilot fallback rows (D-03). Every accepted one shrinks the diff
    `upstream-drift.yml` reports. Do: write the group, then open one pull
    request per move against WangX0111/superspec and record each PR link
    beside its bullet in `reference.md`.
43. **Replace `execute.md` with a squad dispatcher.** Deferred; the one
    Replace move worth taking, and only once `live-run` gives it a snapshot
    to assert against on both surfaces. Do: write the group after
    `live-run` merges.
44. **Ship a spec-kit workflow and bundle.** N-06 and N-08, deferred on
    2026-09-20. Do: reprice after `register-gates` merges. Most of the
    workflow's value was running the gates on the Copilot CLI, which items
    16 and 19 buy for less.

## Closed since the scoped list was written

Do not re-verify these when picking a worktree above.

| Item | Closed by |
|------|-----------|
| Every wave-1 block | merged 2026-09-20: `deck-edits`, `first-tag`, `manifest-schema`, `skill-progress-schema`, `template-stamp`, `merge-gate-steps`, `payload-gates`, `verify-pin`, `speckit-floor`, `test-gate`, `telemetry-budget`, `scorer-dimensions`, `reviewer-scorecard`, `rewrite-after-tasks`, `rewrite-metadata-validator` |
| Every wave-2 block | merged 2026-09-20: `readme-onboarding`, `copilot-e2e`, `reviewer-bodies`, `rewrite-changelog` |
| Every wave-3 block | merged 2026-09-20: `register-gates` (items 19 and 20 partly open, see the note under Start here), `idempotent-dry-run`, `superpowers-range`, `rewrite-readme`, `rewrite-extension-yml`, `rewrite-mapping` |
| N-03, ship the gate scripts | `payload-gates`, ADR-0025: they ship under `specflow/gates/` |
| N-04, ship the findings contract | `payload-gates`: the schema moved to `references/findings-schema.json`, not the name N-04 proposed |
| N-05, the current manifest schema | `manifest-schema`: `category`, `effect`, and a hook `priority` |
| Item 34, all six rewrite rows | no row in either `reference.md` table waits on an item |
| N-07, templates as a preset | G-25, ADR-0021: they stay extension templates |
| N-10, counts derived from the manifest | G-24 T241 |
| N-19, N-20, N-21, N-22 | G-24 T248, T243 and T244, T247, T249 |
| N-23, skip the mutation cases without mutmut | `run.sh` line 660; the suite reports 223 passed, 8 skipped on a checkout without mutmut |
| N-24, pin `@anthropic-ai/claude-code` | `merge-gate.yml` line 54 pins 2.1.278 |
| Backlog 24, release workflow | G-36 |
| Backlog 29, merge gate reads feature findings | G-37 |
| Backlog 30, progress-file contract | G-38 |
| Backlog 23's download URL | G-42; the catalog entry itself waits on `first-tag` |
| Stray root files | `git ls-files output diff.md` already prints nothing; both are gitignored |

## The gap this sweep closes

Upstream superspec ships five command prompts, five templates, three hook
prompts, two references, one recorded example, two manifest validators, a
structural smoke test, an agent e2e script, and a CI workflow that runs the
validators and one live install. It targets a spec-kit version that no longer
resolves templates the way its commands assume, and nothing in it enforces a
gate: its markers, its review, and its checkpoints are prose an agent reads.

This fork keeps the five commands and the inherited scripts and adds what a
machine can check: 30 dry-run assertions in the agent e2e, a Copilot leg in
the smoke test, an artifact scorer with two goldens, a standards linter, ten
hook scripts (five registered in `.claude/settings.json`) with a 231-case
suite, a findings schema and a progress-file validator, a merge gate, a
release workflow that rebuilds and checks the install archive, an upstream
drift watch, and 34 agents. The blocks above are the gap between "it has
these" and "a stranger can trust these on day one".

## Ready to announce when every line holds

Run each line on `main` the day of the tag. One false line means the release
is not ready, whatever the wave above says.

- A tag exists, `release.yml` ran green for it, and the release carries the
  ZIP and the validator report.
- `specify extension add specflow --from <release zip>` installs in a fresh
  project on both surfaces, and `specify extension list` prints the command
  and hook counts `extension.yml` declares, the check `ci.yml` already
  makes (grep `expected_hooks`).
- The root `README.md` exists and every command in `specflow/README.md` ran
  in CI on this commit.
- `examples/` holds one recorded run of this fork's pipeline, and the README
  links it.
- `bash verify.sh` reports 0 failed and 0 skipped with Ruff installed, `bash
  .claude/hooks/tests/run.sh` reports 0 failed, and both e2e dry runs exit 0.
- `open-questions.md` lists nothing, and `git status --porcelain` prints
  nothing on `main` after this file is committed.
- `CHANGELOG.md` has no `[Unreleased]` entries left; every one moved under
  the tag's heading with the version the rule in that file picks.
