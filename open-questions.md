# Open questions

Re-read at every session start. An empty list is the goal: resolve an item and
delete it, or promote it to an ADR in `decisions.md`.

- Can `bdd-orchestrator` and `implementation-engineer` dispatch subagents when
  they themselves run as subagents? Both list `Task`, and `CLAUDE.md` names the
  orchestrator as the entry point, but nested dispatch on Claude Code is
  unconfirmed. `settings.json` sets `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`,
  which may lift the limit. Test with one live orchestrator run; if nesting
  fails, the orchestrator becomes a skill run in the main session.
