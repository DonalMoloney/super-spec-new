# Copilot CLI Reference

Specflow runs on Claude Code and on the GitHub Copilot CLI. The five commands
and three hooks are prompt contracts, so both agents read the same files. The
Copilot CLI lacks four things Claude Code has, and each command names what it
does instead.

| Missing on Copilot | Effect |
|--------------------|--------|
| Subagents (the Task tool) and Agent Teams | `[P]` and `[SUBAGENT]` tasks run in order in the session |
| Agent hooks (`PreToolUse`, `PostToolUse`, `SessionStart`, `Stop`) | The agent runs each gate itself as a step in the command |
| `.claude/agents/` definitions and `model:` frontmatter | One agent runs every review dimension; there is no panel and no critic |
| The scripts under `.claude/hooks/` | The command applies the prose rule the script encodes |

## Fallback per command

| Command | On the Copilot CLI |
|---------|--------------------|
| `/speckit.specflow.status` | No change. The command reads files and prints. |
| `/speckit.specflow.brainstorm` | No change. The questioning protocol needs no subagent. |
| `/speckit.specflow.tasks` | No change. Markers are written to `tasks.md` as text. |
| `/speckit.specflow.execute` | `[P]` and `[SUBAGENT]` tasks run one at a time in order. `[TDD]` tasks follow the inline write-test, fail, implement, pass loop. Before ticking a task, the agent runs the constitution's test command itself, which `.claude/hooks/test-gate.sh` does on Claude Code. |
| `/speckit.specflow.review` | The built-in five-dimension protocol runs once in the session. The risk tier comes from the prose rule in `commands/review.md`, since `risk-classifier.sh` is absent. |

## Gate scripts

`.claude/hooks/` ships with the specflow repository, not with the extension
archive. The scripts are plain bash and read only git and the feature
directory, so a Copilot user can clone the repository and run
`merge-gate.sh` or `risk-classifier.sh` by hand. Nothing in a command
requires them.
