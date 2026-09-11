# Open questions

Re-read at every session start. An empty list is the goal: resolve an item and
delete it, or promote it to an ADR in `decisions.md`.

## Which column shape does the `## Traceability` table use?

G-13's scorer reads `cells[0]` as the criterion ID and `cells[1]` as the trace
target. The `static-landing-page` golden uses a two-column table. G-10 T102
specifies three columns: `Criterion ID`, `Test name`, `Status`. Both parse, so
nothing fails loudly, but the golden and the template will describe different
shapes until one is chosen.

Until G-10 lands, any spec built from `specflow/templates/spec-template.md`
scores `traceability: 0.0` with every criterion untraced, because the template
has no `## Traceability` heading. Verified against `main` at `fd99a49`:
10 criteria, 0 traced.

Owner: whoever finishes G-10. Resolve by picking one shape, updating the golden
to match, and deleting this entry.
