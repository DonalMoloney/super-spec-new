# Roadmap

Every piece of open work on this repository, ranked. Read it to pick the next
thing to build. It is the only file that holds a claim or a checkbox
(ADR-0017). `reference.md` holds the divergence option space each group draws
from and the measured distance to upstream; `docs/review-research.md` holds the
evidence behind the review stack.

A merged or dropped item leaves this file. Every group except G-59 is merged
or closed, as are Q-01 to Q-28, D-01, D-05, and C-01 to C-09;
`git log -- improvements/roadmap.md` holds their text. `v1.1.0` is tagged and released.

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

1. G-59, the upstream comparison, in progress in its own worktree. Its result
   ranks every later divergence item: a gap it finds outranks a heading rename.
2. Backlog item 26, the upgrade path, before the second release.
3. Backlog item 38, a live Copilot CLI run, once the account has quota.

## G-59 — Run upstream and this fork on the same seeded input, and record which catches the flaw (working on)

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

- [ ] T591 Add `examples/seeded-review-bug/`, a copy of `link-audit/` with one planted spec violation the shipped tests miss. A bug a failing test exposes finds itself, so it cannot separate two reviewers. Verify: the copy's own `pytest` passes, one test kept outside the copy fails against it, and its README names the file, line, fault, plus the FR it breaks.
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


## Backlog

Scoped, not decomposed. Claiming one means turning it into a group numbered
G-61 or later. Each keeps the three constraints in `reference.md`.

**26. An upgrade path the smoke test walks.** `e2e-smoke.sh` installs the
`v1.1.0` release ZIP, installs the checkout over it with `--dev`, and asserts
no stale command file or `extensions.yml` entry remains. The release asset
answers 404 to an anonymous download while the repository is private, so the
test fetches it with `gh release download`. Verify: the smoke test reports the
upgrade assertions and passes. Effort: low. Depends on: none.

**38. A Copilot CLI run snapshot under `examples/`.** `e2e-agent-copilot.sh`
has run only in dry-run mode. Record one live run beside `link-audit/`, the
Claude Code run. ADR-0042 records the account quota that blocked the last
attempt. Verify: the snapshot directory exists and `score-artifacts.py` scores
it. Effort: medium. Depends on: Copilot quota.

## Ready to release

Run every line on `main` the day of the tag. One false line means the release
is not ready.

- A tag exists, `release.yml` ran green for it, and the release carries the ZIP
  and the validator report.
- `specify extension add specflow --from <release zip>` installs in a fresh
  project on both surfaces, and `specify extension list` prints the command and
  hook counts `extension.yml` declares. While the repository is private, fetch
  the asset with `gh` and serve it over localhost; spec-kit downloads
  anonymously and gets 404.
- The root `README.md` exists, and every command in `specflow/README.md` ran in
  CI on this commit.
- `bash verify.sh` reports 0 failed and 0 skipped with Ruff installed.
- `bash .claude/hooks/tests/run.sh` reports 0 failed.
- Both e2e dry runs exit 0.
- `open-questions.md` lists nothing.
- `git status --porcelain` prints nothing on `main`.
- `CHANGELOG.md` has no `[Unreleased]` entries left; each one moved under the
  tag's heading with the version the rule in that file picks.

## Dropped on 2026-09-28

Each was open or deferred and is closed without being done.

- **G-57's remaining heading renames.** A heading is one line, so a rename
  cannot move a file's divergence by a printed point. G-59 replaces the
  percentage with a measure of results. ADR-0043's bar still applies to any
  rename a later change needs for its own reasons.
- **Replace `execute.md` with a squad dispatcher.** The squad lives under
  `.claude/agents/`, which the install archive strips, so a shipped command
  cannot dispatch it on either surface.
- **Multi-feature concurrency.** Its trigger, three features run through
  `[P]` dispatch, has not fired on any feature.
- **A spec-kit workflow file (N-06).** Its value was running the gates on the
  Copilot CLI, which the `events:` block (ADR-0034) delivered.
- **A spec-kit bundle (N-08).** It composed that workflow with a preset, and
  ADR-0021 keeps the templates out of a preset.
- **A gate needing a Task Verification row per task (G-60 left out).** The
  recorded golden has 17 rows for 59 tasks, so the gate fails the recorded run.
