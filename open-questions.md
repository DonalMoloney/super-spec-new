# Open questions

Re-read at every session start. An empty list is the goal: resolve an item and
delete it, or promote it to an ADR in `decisions.md`.

## A CI merge-gate finding has no rebuttal path

ADR-0006 blocks a merge until every Critical and Important finding is `fixed`
or `rebutted`. G-09's workflow writes the headless reviewer's findings to
`.claude/review/headless-ci.json`, which `.gitignore` excludes, so the file
exists only inside the job that wrote it. An author cannot edit a status they
cannot commit, which leaves a false-positive Important finding with no way to
clear the gate short of changing the code.

Owner: whoever revisits ADR-0006. Resolve by giving CI findings a rebuttal
path (a committed rebuttal file the gate reads, or a label the gate honors),
or by scoping the CI reviewer to Critical only, then deleting this entry.
