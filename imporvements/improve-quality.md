# Quality improvements

This file lists the ways the repository falls short of its own `standards/` and
what closes each gap. Read it when choosing the next quality item after the
D-01 to D-05 divergence work. `tasks.md` holds the roadmap; `divergence-by-part.md`
holds the upstream option space; this file holds the debt the standards already
name. Every number was measured on `main` at `a2a97b3` on 2026-09-11.

Every check the repo ships passes today:

| Check | Result |
|-------|--------|
| `validate-extension-metadata.py` | OK |
| `validate-release-archive.py` | within every limit |
| `.claude/hooks/tests/run.sh` | 135 passed, 0 failed |
| `pytest scripts/tests .claude/review/tests` | 46 passed |
| `e2e-smoke.sh` | 21/21 passed |
| `E2E_DRY_RUN=1 e2e-agent-claude.sh` | exit 0, every real assertion skipped |
| `marp --pdf presentation/marp-deck/deck.md` | no warnings |

The debt is in what no check measures. Each item below is one outcome, ends
with a `Verify:` line, and carries a `Claimed by:` line so a worktree can claim
it the way `tasks.md` groups are claimed. Items are ordered by what reaches a
consuming project first: shipped payload, then the checks that guard it, then
this repository's own files.

## Q-01 to Q-04: standards are written but nothing runs them

`standards/documentation.md` bans em-dashes and a table of words. No script,
hook, or CI step checks either. The count today, excluding `specflow/examples/`
and `imporvements/`:

| File | Em-dashes |
|------|-----------|
| `AGENTS.md` | 27 |
| `.github/copilot-instructions.md` | 19 |
| `.claude/agents/bdd-orchestrator.md` | 19 |
| `specflow/references/workflow-guide.md` | 15 |
| `presentation/marp-deck/deck.md` | 12 |
| `specflow/SKILL.md` | 10 |
| `specflow/README.md` | 9 |
| 13 more files | 3 to 9 each |

Five shipped templates carry 25 between them, and a template reaches every
consuming project's spec, plan, and tasks files.

- **Q-01** Add `scripts/lint-standards.py` that exits non-zero on any em-dash
  or banned-table word in a tracked Markdown file outside `specflow/examples/`
  and `imporvements/`. The banned table in `standards/documentation.md` is the
  word list; the script reads it rather than copying it. Verify: the script
  exits non-zero on `main` today and lists the files above. Claimed by: none.
- **Q-02** Rewrite the shipped payload until Q-01 passes on `specflow/`:
  five templates, `SKILL.md`, `README.md`, both references, and the five
  commands. Verify: `lint-standards.py specflow/` exits zero. Claimed by: none.
  Depends on Q-01.
- **Q-03** Rewrite the repository's own docs until Q-01 passes everywhere:
  `AGENTS.md`, `CLAUDE.md`, `copilot-instructions.md`, the 25 agent files,
  and `presentation/`. Verify: `lint-standards.py` exits zero with no path
  argument. Claimed by: none. Depends on Q-01.
- **Q-04** Run `lint-standards.py` from `artifact-lint.sh` on every edited
  Markdown file, so an agent is stopped at write time and not at review.
  Verify: a hook test writes an em-dash into a `.md` file and the hook blocks.
  Claimed by: none. Depends on Q-01.

## Q-05 to Q-08: shell and Python have no linter

- **Q-05** Add a `shellcheck` step to `ci.yml` over `.claude/hooks/*.sh`,
  `specflow/scripts/*.sh`, and `.claude/hooks/tests/run.sh`. Today `shellcheck
  -S warning` reports 31 findings: 20 SC2319 (`$?` read after a condition),
  10 SC2164 (`cd` without a failure branch), 1 SC2069. Verify: the CI step
  exists and `shellcheck -S warning` reports 0. Claimed by: none.
- **Q-06** Fix the 31 shellcheck findings. SC2164 is the one that changes
  behavior: a failed `cd` lets the next command run in the wrong directory.
  Verify: `shellcheck -S warning` on the same paths prints nothing. Claimed by:
  none. Depends on Q-05 for the CI check; the fix can land first.
- **Q-07** Add `ruff` to `requirements-dev.txt` and a `ruff check` step to
  `ci.yml` over `specflow/scripts/` and `.claude/review/`. Verify: the step
  exists and passes. Claimed by: none.
- **Q-08** Remove the check-mark emoji from the `e2e-smoke.sh` summary line.
  `standards/code.md` forbids emoji in output. Verify: a grep for the
  check-mark character in `specflow/scripts/e2e-smoke.sh` prints 0. Claimed
  by: none.

## Q-09 to Q-13: the scripts CI trusts have thin or no tests

The 46 pytest cases split as 44 for `score-artifacts.py`, 1 for
`validate-extension-metadata.py`, 3 for `validate-findings.py`, and 0 for
`validate-release-archive.py`. The two validators are the checks
`AGENTS.md` tells every reviewer to run before approving a change.

- **Q-09** Add `scripts/tests/test_validate_release_archive.py` with one test
  per limit the script enforces: 50 MiB download, 512 entries, 10 MiB per
  member, 50 MiB uncompressed, and each `export-ignore` path. Each test builds a
  ZIP in a temp directory; none reads the real archive. Verify: the file exists
  and CI's Script tests step runs it. Claimed by: none.
- **Q-10** Extend `test_validate_extension_metadata.py` past its one regex test
  to cover an id that does not match a command name, a command the manifest
  lists but no file provides, and a README that omits a command. Verify: three
  new tests, each failing when the matching check is deleted. Claimed by: none.
- **Q-11** Add hook tests for the `risk-classifier.sh` boundaries: exactly 400
  changed lines, exactly 15 files, and a binary file's numstat dash. The
  classifier has three test cases today against twelve for
  `block-main-commit.sh`. Verify: `run.sh` reports the three new cases.
  Claimed by: none.
- **Q-12** Add hook tests for `artifact-lint.sh` and `log-phase.sh`, which
  have three and two mentions in `run.sh`. Verify: each hook has a test for
  its pass path and its block path. Claimed by: none.
- **Q-13** Make the `e2e-agent-claude.sh` dry run assert against the
  `examples/static-landing-page/` snapshot instead of skipping. Today the dry
  run ends with "All real assertions skipped", so a broken assertion passes CI
  until someone pays for a live run. Verify: the dry run prints an assertion
  count greater than zero. Claimed by: none.

## Q-14 to Q-17: shipped docs point at files the archive strips

`.gitattributes` strips `assets/`, `examples/`, and `scripts/` from the ZIP
`specify extension add specflow` downloads. `specflow/README.md` links into all
three.

- **Q-14** Replace the `assets/workflow-overview-en.png` image on README line 17
  with a Mermaid block, so the installed README renders. Verify: `git archive
  HEAD:specflow | tar -t` lists no path the README links. Claimed by: none.
- **Q-15** Rewrite README lines 145 to 155 to link the example and the e2e
  script by GitHub URL, not relative path. Verify: same check as Q-14.
  Claimed by: none.
- **Q-16** Add a "verify it ran" section to `specflow/README.md` naming the
  `/speckit.specflow.status` output a user sees after install. The README rule
  in `standards/documentation.md` requires it and no section provides it.
  Verify: the section exists and names the command. Claimed by: none.
- **Q-17** Tighten `e2e-smoke.sh` to assert every Gate markers row in
  `workflow-guide.md` appears in at least one command file. Today the guide
  names `.clarified` and `.analyzed`; the commands name only `.analyzed`.
  Verify: the smoke test fails when a marker is removed from every command.
  Claimed by: none. D-04 claims the step-count assertion; this is the marker
  assertion.

## Q-18 to Q-21: the deck breaks the presentation standard

`standards/presentations.md` sets the front matter, title style, and deck
shape. `presentation/marp-deck/deck.md` predates the standard.

- **Q-18** Set the front matter to a named theme and `size: 16:9`. Today it is
  `theme: default` with no size, which the standard names as the one theme
  not to leave unmodified. Verify: the front matter carries both fields and
  `marp --pdf` renders without warnings. Claimed by: none.
- **Q-19** Rewrite the five slide titles as sentence-case claims. Today they
  are title-case topics ("Supercharging Adversarial Review" and the like),
  two carry an em-dash, and the first carries the "Bridging" metaphor. Verify: no title
  contains a capital after the first word except a proper noun, and Q-01 passes
  on the deck. Claimed by: none.
- **Q-20** Delete the HTML comment "Slides below are appended in order by
  dedicated subagents. Do not reorder." from the deck and its twin from
  `use-guide.md`. A comment addressed to a reader is forbidden in
  `standards/code.md`. Verify: `grep -c 'Do not reorder' presentation/ -r`
  prints 0. Claimed by: none.
- **Q-21** Add the render check from the standard to `ci.yml`: `npx
  @marp-team/marp-cli --pdf` on every push touching `presentation/`. Verify:
  the step exists and is path-filtered. Claimed by: none.

## Q-22 to Q-24: decisions disagree with the files they govern

- **Q-22** Reconcile ADR-0003 with the 25 agents that exist. The ADR names 17
  and routes reviewers to the strongest model. Four reviewer agents sit below
  it: `maintainability-reviewer` on haiku, and `correctness-reviewer`,
  `conformance-reviewer`, `performance-reviewer` on sonnet. Either amend the
  ADR to say why a Stage 2 persona runs cheaper, or reroute the four. Verify:
  every `*-reviewer.md` model matches a line in the ADR. Claimed by: none.
- **Q-23** Fix the cross-reference in ADR-0007. It cites "the diff summary in
  ADR-0005"; ADR-0005 is the integer scoring rule and the diff summary is
  ADR-0008. Verify: `grep -n 'ADR-0005' decisions.md` matches only ADR-0005's
  own heading. Claimed by: none.
- **Q-24** Decide whether the `[NEEDS CLARIFICATION]` placeholder on
  `spec-template.md` line 118 breaks the Code Review Rule that rejects
  unresolved markers in shipped templates. The scorer's golden test expects
  exactly one marker in the example spec, so removing it changes a test. Add
  the exemption to the rule or remove the line and update the test. Verify:
  the rule names the exemption, or the line and the test expectation are gone.
  Claimed by: none. Record the answer as an ADR.

## Q-25 to Q-28: repository hygiene

- **Q-25** Untrack the six `.idea/` files and add `.idea/` to `.gitignore`.
  Verify: `git ls-files .idea` prints nothing. Claimed by: none.
- **Q-26** Untrack `.claude/claude-md-drift.json` and ignore it. Something
  outside this repo appends to it every session, so `git status` is never
  clean after a session and every PR risks carrying the churn. No hook in
  `.claude/hooks/` or `settings.json` writes it. Verify: `git status --short`
  is empty after a session start. Claimed by: none.
- **Q-27** Delete the 14 local branches already merged into `main`. Verify:
  `git branch --merged main` lists only `main` and the five active worktree
  branches. Claimed by: none.
- **Q-28** Reword the comment at `e2e-agent-claude.sh` line 145, which opens
  with "Note:", a rejected opener in `standards/code.md`. Verify: the grep for
  rejected openers over `specflow/scripts/` and `.claude/hooks/` prints
  nothing. Claimed by: none.

## Suggested order

1. Q-01, Q-05, Q-07 first. Each adds a check that measures the rest and none
   changes shipped behavior.
2. Q-02, Q-06, Q-08, Q-14, Q-15 next. They fix what a consuming project
   receives.
3. Q-09, Q-10, Q-13 before any further command change, so the validators the
   reviewers trust are themselves tested.
4. Q-18 to Q-21 together in one worktree; the deck is one file.
5. Q-22 to Q-24 need a decision each; record it in `decisions.md`.
6. Q-03, Q-04, Q-11, Q-12, Q-16, Q-17, Q-25 to Q-28 whenever a session is
   short.

Pick the item whose `Verify:` line you can run before you start. An item whose
check you cannot run today is a design task, not a quality task, and belongs in
`tasks.md`.
