# Open questions

Re-read at every session start. An empty list is the goal: resolve an item and
delete it, or promote it to an ADR in `decisions.md`.

## What does "review Stage 1" mean in `spec-template.md`'s Traceability guidance?

G-10 added the line "Every FR and SC criterion needs at least one named test
before review Stage 1" to `spec-template.md`, copied verbatim from
`imporvements/tasks.md` T102. `specflow/commands/review.md` has no numbered
stages, "Stage 1" already names something else in the shipped extension
(`Stage 0/1/2/3` in G-05's review-stack docs vs a different "constitution
stage" elsewhere in `specflow/`), and the roadmap's own Stage 0/1 vocabulary
lives in `imporvements/` and `.claude/`, neither of which ships in the `git
archive` a consuming project installs.

Owner: whoever gives `specflow/commands/review.md` numbered stages, or
rewords the guidance line to not depend on a stage number. Resolve by picking
one and deleting this entry.

## Does the landing-page example meet the differential-implementation trigger?

G-15's protocol runs a differential implementation only when
`.claude/hooks/risk-classifier.sh` prints `HIGH` or the spec lists more than
three open questions. The `static-landing-page` golden has exactly three open
questions and a docs-only diff, which classifies `STANDARD`. T153 asks for a
dry run on that example, so the example the roadmap picked cannot trigger the
rule the same group wrote.

T153 is also blocked on a Codex account usage limit, verified 2026-09-11 at
11:40: `codex exec` and the `codex:codex-rescue` agent both return "You've hit
your usage limit", reset at 15:12.

Owner: whoever retries T153. Resolve by either running the protocol on a spec
that meets the trigger, or recording that the dry run deliberately overrides
the trigger rule, then deleting this entry.

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
