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

Twenty-five of the twenty-seven blocks this sweep planned merged to `main` on
2026-09-20. "Closed since the scoped list was written" lists each one. Two
remain, both under "Blocked on an API key": `live-run`, then
`delete-upstream-example`, which waits for it.

Two items inside merged blocks stayed open, each for a reason no worktree can
fix: item 19's `events:` block would deny every Bash call until a shipped
script reads a hook payload (G-26 T262 records the reproduction), and item
20's upgrade test needs a published release, which waits on the first tag.

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
