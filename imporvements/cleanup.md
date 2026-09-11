# Cleanup

This file lists hygiene debt: work that needs no design, only a session short
enough to run one `Verify:` line. Read it when a roadmap group in `tasks.md`
is too large for the time you have. The first cleanup wave, Q-01 to Q-28,
merged in PR #53. Every number below was measured on `main` at `df50cb8` on
2026-09-11.

Every check the repo ships passes today:

| Check | Result |
|-------|--------|
| `validate-extension-metadata.py` | OK |
| `validate-release-archive.py` | within every limit |
| `.claude/hooks/tests/run.sh` | 145 passed, 0 failed |
| `pytest scripts/tests .claude/review/tests .claude/divergence` | 80 passed |
| `lint-standards.py` | 56 files, 0 findings |
| `shellcheck -S warning` over hooks and scripts | 0 findings |
| `e2e-smoke.sh` | 23/23 passed |
| `E2E_DRY_RUN=1 e2e-agent-claude.sh` | exit 0 |
| `ruff check` | not verified locally; `ruff` is not installed here and CI runs it |

Each item below is one outcome, ends with a `Verify:` line, and carries a
`Claimed by:` line so a worktree can claim it the way `tasks.md` groups are
claimed. The `D-0N-*` worktrees are live claims by other sessions, not debt;
`divergence-by-part.md` lists them.

## C-01 to C-02: branches left behind

- **C-01** Delete the remote feature branches whose PR has merged. 17 are
  ancestors of `origin/main`; the rest were squash-merged, so match them with
  `gh pr list --state merged --json headRefName`. Turn on "Automatically
  delete head branches" in the repository settings so the list stops growing.
  Verify: `git branch -r` lists only `origin/main`, `origin/HEAD`, and
  branches with an open PR. Claimed by: none.
- **C-02** Delete the local `g-09-merge-gate-ci` and `g-15-differential`
  branches; both PRs merged. Verify: `git branch --merged main` lists only
  `main` and the live `D-0N-*` branches. Claimed by: none.

## C-03 to C-04: stale names

- **C-03** Rename the `imporvements/` directory to `improvements/`. The typo
  is cited from `AGENTS.md`, `CLAUDE.md`, `decisions.md`, three agent files,
  `measure-divergence.py`, `risk-classifier.sh`, `lint-standards.py` and its
  test, the deck's speaker notes, and the Claude memory files: about 30
  lines. Do it in one PR when no D-item or group worktree is open, because
  every one of them edits a file in the folder. Verify: `grep -rn
  imporvements . --exclude-dir=.git` prints nothing. Claimed by: none.
- **C-04** Retitle `presentation/use-guide/use-guide.md`. The H1 is a path,
  and "Prerequisites and Install" is title case, which
  `standards/presentations.md` rejects for the deck and
  `standards/documentation.md` rejects for prose. Verify: the H1 is a noun
  phrase and no header carries a capital after its first word except a
  proper noun. Claimed by: none.

## C-05 to C-06: scripts leave things behind

- **C-05** Delete the e2e work directory on a passing run. Both
  `e2e-smoke.sh` and `e2e-agent-claude.sh` print "Workdir kept at" and leave
  a directory under `$TMPDIR` every time they pass. Keep it only on failure or
  when `KEEP_WORKDIR=1`. Verify: after a passing run the printed path does
  not exist. Claimed by: none.
- **C-06** Print an assertion count at the end of the agent dry run. Q-13
  made the dry run assert against the snapshot, and the summary still ends
  with the API-key hint rather than a count. Verify: the last line of
  `E2E_DRY_RUN=1 e2e-agent-claude.sh` reads `N assertions, 0 failed`.
  Claimed by: none.

## C-07: the playbook is a reference, not a tracker

- **C-07** Move `imporvements2.md` Parts 3, 6, and 7 (the review research,
  team operation, and anti-pattern catalog) to `docs/` and delete the rest,
  which Part 4 implemented and Part 5 duplicates from `specflow/README.md`.
  The deck's speaker notes, ADR-0001, and `risk-classifier.sh` cite it by
  part or section number, so those citations move with it. Verify: `grep
  -rn imporvements2 presentation/ decisions.md .claude/ AGENTS.md` prints
  nothing. Claimed by: none.

## Suggested order

1. C-02 now; it is one `git` command.
2. C-05 and C-06 before the next script change, so the change lands on a
   clean base.
3. C-03 in its own PR, once the D-item worktrees have merged.
4. C-01, C-04, C-07 whenever a session is short.

Pick the item whose `Verify:` line you can run before you start. An item
whose check you cannot run today is a design task and belongs in `tasks.md`.
