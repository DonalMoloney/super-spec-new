# Contributing

Read [AGENTS.md](AGENTS.md) first. It states what this repository is, what
ships to a user under `specflow/`, and what stays here for the maintainers.

## Check a change before pushing

Run the checks from the repository root:

```bash
bash verify.sh
```

The script walks the steps `.github/workflows/ci.yml` runs, in that order, and
stops at the first failure. It prints the four steps it leaves to CI.
`tests/test_ci_parity.py` fails when the script and the workflow drift apart,
so the script cannot fall behind without anyone noticing.

Install the test dependencies once before the first run:

```bash
python3 -m pip install --requirement requirements-dev.txt
```

## Standards

A reviewer checks every change against the file under `standards/` that
matches what the change produces. Read that file before the first edit.

- [`standards/code.md`](standards/code.md) rules the code: the TDD order,
  scope, naming, errors, comments, tests, and commit subjects.
- [`standards/documentation.md`](standards/documentation.md) rules the prose:
  structure, tone, sentence shape, and a banned-word table.
- [`standards/presentations.md`](standards/presentations.md) rules the slides:
  Marp front matter, per-slide limits, and the render check.

## One worktree per block

`improvements/roadmap.md` holds the open work, grouped into blocks. Each block
runs in its own git worktree on its own branch and lands as one pull request.
Main stays on the last merge and carries no feature branch.

Before you start a block, append `(working on)` to its header line in
`improvements/roadmap.md` and commit that to main, so a second worktree does
not pick up the same block. Remove the marker when the pull request merges.

```bash
git worktree add ~/PycharmProjects/worktrees/G-NN-name -b branch-name
```

Delete the worktree after the merge.

## Pull requests

Fill in [`.github/pull_request_template.md`](.github/pull_request_template.md).
State what changed, why it changed, the command that checked it, and the
result of that command. A claim with no output is not a claim.
