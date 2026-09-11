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
