# Open questions

Re-read at every session start. An empty list is the goal: resolve an item and
delete it, or promote it to an ADR in `decisions.md`.

## `lint-standards.py`'s missing-path check misses a gitignored directory that does not exist on disk

`is_gitignored()` in `specflow/scripts/lint-standards.py` calls
`git check-ignore -q -- <path>` with no trailing slash. `.gitignore`'s
`.claude/bdd/` pattern is directory-anchored, and `git check-ignore` only
matches a directory-anchored pattern when it can tell the queried path is a
directory, either from a trailing slash or from the path existing on disk.
Found 2026-09-28: a worktree that has never run the BDD squad has no
`.claude/bdd/` directory on disk, so every citation of `.claude/bdd` in
`.claude/agents/*.md` and `decisions.md` is wrongly flagged as a missing
path. `main`'s checkout passes only because a stray, untracked
`.claude/bdd/.gitkeep` happens to keep the directory materialized there. A
fresh clone or CI checkout would hit the same 39 false findings `verify.sh`
showed in the affected worktree. Fix: pass a trailing slash (or `os.path.isdir`
first) so the ignore check matches regardless of whether the directory exists
yet.
