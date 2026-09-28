---
name: specflow-dispatcher
description: This skill should be used at the start of a new work item, before any /speckit command, to pick the pipeline. Covers requests to add a feature, fix a bug, refactor existing code, or change the rules in the constitution, and questions like "which workflow should I use". It routes only; it does not implement.
---

# Specflow dispatcher

Classify the request by the check named on each route, then follow that route.

- A new capability ("add feature X"): the request names a behavior no test and
  no `specs/` directory covers. Run the full pipeline: `/speckit.specify`,
  `/speckit.clarify`, review stage 0 with `spec-red-team-reviewer` and
  `threat-model-reviewer`, `/speckit.specflow.brainstorm`, `/speckit.plan`,
  `/speckit.specflow.tasks`, `/speckit.analyze`, `/speckit.specflow.execute`,
  then `/speckit.specflow.review`.
- A defect ("fix bug Y"): the request names an observed result that differs
  from a specified one. Run `systematic-debugging`, then
  `test-driven-development` with the failing test written first, then
  `/speckit.specflow.review`.
- A restructuring ("refactor Z"): the request changes code and names no change
  in observable behavior. Run `/speckit.plan`, `/speckit.specflow.tasks`,
  `/speckit.specflow.execute`, then `/speckit.specflow.review` with mutation
  tests.
- A governance change ("tighten the rules", "change the rules"): the request
  changes a principle in `.specify/memory/constitution.md`. Run
  `/speckit.constitution`, then `/speckit.analyze`.

Then classify the size as spike, bounded, or architectural. A spike is a
throwaway that learns one fact, per `/speckit.specflow.brainstorm` step 5, and
skips `/speckit.specflow.brainstorm`. No route skips the merge gate. Record
every non-obvious choice in `decisions.md`.

When the request matches no check above, or matches two, report
`NO ROUTE: <request>` with the routes it touched and stop. Do not guess.
