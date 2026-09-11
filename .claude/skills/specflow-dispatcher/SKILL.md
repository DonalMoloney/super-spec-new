---
name: specflow-dispatcher
description: This skill should be used at the start of a new work item, before any /speckit command, to pick the pipeline. Covers requests to add a feature, fix a bug, refactor existing code, or change the rules in the constitution, and questions like "which workflow should I use". It routes only; it does not implement.
---

# Specflow dispatcher

Classify the request, then follow the matching route.

- A new capability ("add feature X") runs the full pipeline:
  `/speckit.specify`, `/speckit.clarify`, review stage 0 with
  `spec-red-team-reviewer` and `threat-model-reviewer`,
  `/speckit.specflow.brainstorm`, `/speckit.plan`, `/speckit.specflow.tasks`,
  `/speckit.analyze`, `/speckit.specflow.execute`, then `/speckit.specflow.review`.
- A defect ("fix bug Y") runs `systematic-debugging`, then
  `test-driven-development` with the failing test written first, then
  `/speckit.specflow.review`.
- A restructuring ("refactor Z") runs `/speckit.plan`,
  `/speckit.specflow.tasks`, `/speckit.specflow.execute`, then
  `/speckit.specflow.review` with mutation tests.
- A governance change ("tighten the rules", "change the rules") runs
  `/speckit.constitution`, then `/speckit.analyze`.

Then classify the size as spike, bounded, or architectural. A spike skips
`/speckit.specflow.brainstorm`. No route skips the merge gate. Record every
non-obvious choice in `decisions.md`.
