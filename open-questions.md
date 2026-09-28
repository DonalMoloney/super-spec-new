# Open questions

Re-read at every session start. An empty list is the goal: resolve an item and
delete it, or promote it to an ADR in `decisions.md`.

- **Does the Copilot CLI read a `permissionDecision` deny from stdout when the
  hook exits 2?** `docs/agent-event-mapping.md`'s Exit code contract says it
  does, and `agent-event.sh` exits 2 with the deny JSON on the `events:`
  route. `.github/hooks/adapter.sh` exits 0 with the same JSON instead, per
  the hooks reference (ADR-0035). If Copilot ignores stdout on a nonzero exit,
  the `events:` route never denies on Copilot. Confirm against a live Copilot
  run, then align one route with the other.

