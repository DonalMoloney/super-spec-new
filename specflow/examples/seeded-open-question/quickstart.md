# Quickstart: Validating `link-audit`

This guide runs the three user stories end-to-end against a throwaway git
repository. It proves the feature works without duplicating the full test
suite — see `contracts/cli-contract.md` for the exit-code/output contract
and `data-model.md` for the entities referenced below.

## Prerequisites

- Python 3.11
- `git` on PATH
- The project installed in a virtualenv: `pip install -e .` (or
  `pip install -e '.[dev]'` if `pytest` is declared as a dev extra)

## Setup: a scratch repository

```bash
mkdir /tmp/link-audit-demo && cd /tmp/link-audit-demo
git init -q

cat > README.md <<'EOF'
# Demo

[good link](docs/guide.md)
[broken file link](docs/missing.md)
[good anchor](docs/guide.md#setup)
[broken anchor](docs/guide.md#does-not-exist)
[external, skipped](https://example.com)
EOF

mkdir docs
cat > docs/guide.md <<'EOF'
# Guide

## Setup

Some content.
EOF

git add README.md docs/guide.md
git commit -q -m "seed demo repo"
```

## Scenario 1 (P1): catch a broken relative link

```bash
link-audit
echo "exit: $?"
```

**Expected**: output includes a line for `docs/missing.md` (missing-file,
per FR-004), and the exit code is `1`.

## Scenario 2 (P2): catch a broken heading anchor

Still using the same run above:

**Expected**: output also includes a line for `docs/guide.md#does-not-exist`
(missing-anchor, per FR-005), while `docs/guide.md#setup` produces no
finding (the heading `## Setup` slugifies to `setup`).

## Scenario 3 (P3): untracked files are excluded

```bash
cat > docs/untracked.md <<'EOF'
[also broken](nope.md)
EOF
# Deliberately not `git add`ed.

link-audit
echo "exit: $?"
```

**Expected**: the output is unchanged from Scenario 1/2 — no finding
mentions `docs/untracked.md` or `nope.md`, because `git ls-files` does not
report `docs/untracked.md` (FR-001, User Story 3 Scenario 2).

## Scenario 4: a clean repository exits 0

```bash
rm docs/untracked.md
sed -i.bak '/broken/d' README.md && rm README.md.bak

link-audit
echo "exit: $?"
```

**Expected**: no findings are printed and the exit code is `0` (FR-007).

## Scenario 5: a scan that cannot complete exits 2

```bash
cd /tmp && mkdir not-a-repo && cd not-a-repo
link-audit
echo "exit: $?"
```

**Expected**: a single stderr line naming the git failure, and exit code
`2` (User Story 3 Scenario 3).

## Automated equivalent

Every scenario above has a named test in spec.md's Traceability table
(`test_reports_missing_relative_link_target`,
`test_reports_missing_heading_anchor`,
`test_scans_only_git_ls_files_output`,
`test_exit_code_reflects_unresolved_links`). Run the full suite with:

```bash
pytest -q
```

A clean `pytest -q` run is the authoritative pass/fail signal for this
feature — the steps above are for human sanity-checking, not a replacement
for the test suite.
