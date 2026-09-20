# Decisions (ADR-lite)

Append one entry per non-obvious decision. Mark superseded entries rather than
deleting them; prune anything older than a quarter that no longer guides work.

## ADR-0001: The workflow diagram is a numbered step list, not CSS arrows

- Date: 2026-05-30
- Status: accepted
- Context: OQ-003 asked whether to draw the workflow with CSS arrows or with
  numbered steps joined by a rule. Arrows render differently across browsers
  and cost more CSS against the 64 KB page budget.
- Decision: use an ordered list of numbered steps joined by a horizontal rule.
  No arrowheads.
- Consequences: the diagram reads the same in every target browser and falls
  back to a plain list with CSS off. It shows one sequence; a branching
  workflow needs a new decision.
