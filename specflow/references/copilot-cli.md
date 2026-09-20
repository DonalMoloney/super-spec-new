# Copilot CLI Reference

Specflow runs on Claude Code and on the GitHub Copilot CLI. The six commands
and five hooks are prompt contracts, so both agents read the same files. The
Copilot CLI lacks four things Claude Code has, and each command names what it
does instead.

| Missing on Copilot | Effect |
|--------------------|--------|
| Subagents (the Task tool) and Agent Teams | `[P]` and `[SUBAGENT]` tasks run in order in the session |
| Agent hooks (`PreToolUse`, `PostToolUse`, `SessionStart`, `Stop`) | The agent runs each gate itself as a step in the command |
| The reviewer definitions and `model:` frontmatter under `.claude/agents/`, in this repository only | One agent runs every review dimension; there is no panel and no critic |
| The repository-only hooks, such as `test-gate.sh` and `artifact-lint.sh` | The command applies the prose rule the script encodes |

## Invoking a command

Spec-kit registers each command as a Copilot CLI skill at
`.github/skills/speckit-specflow-<name>/SKILL.md`, and a skill name carries
hyphens where the Claude Code command carries dots. GitHub's
[skills documentation](https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-skills)
states the rule: to run a specific skill, put its name in the prompt behind a
forward slash.

| Command | What to type on the Copilot CLI |
|---------|---------------------------------|
| `/speckit.specflow.status` | `/speckit-specflow-status` |
| `/speckit.specflow.brainstorm` | `/speckit-specflow-brainstorm` |
| `/speckit.specflow.tasks` | `/speckit-specflow-tasks` |
| `/speckit.specflow.execute` | `/speckit-specflow-execute` |
| `/speckit.specflow.review` | `/speckit-specflow-review` |

The right column repeats the skill directory name spec-kit creates at install.

## Fallback per command

| Command | On the Copilot CLI |
|---------|--------------------|
| `/speckit.specflow.status` | No change. The command reads files and prints. |
| `/speckit.specflow.brainstorm` | No change. The questioning protocol needs no subagent. |
| `/speckit.specflow.tasks` | No change. Markers are written to `tasks.md` as text. |
| `/speckit.specflow.execute` | `[P]` and `[SUBAGENT]` tasks run one at a time in order. `[TDD]` tasks follow the inline write-test, fail, implement, pass loop. Before ticking a task, the agent runs the constitution's test command itself, which `test-gate.sh` does on Claude Code. Claude Code runs `subagent-driven-development` for execute; the Copilot CLI has no subagents, so it runs `executing-plans` instead. |
| `/speckit.specflow.review` | The built-in five-dimension protocol runs once in the session. The risk tier comes from `gates/bash/risk-classifier.sh`, which the install carries. |
| `/speckit.specflow.gate` | No change. The command runs `gates/bash/write-marker.sh` and prints what it wrote or why it refused. |

## Gate scripts

`gates/` ships in the extension archive, so a Copilot user gets the same five
scripts a Claude Code user gets (ADR-0025). The bash gates read only git, the
feature directory, and standard input; the Python gates need only the standard
library. Run one from the install:

```bash
.specify/extensions/specflow/gates/bash/risk-classifier.sh main
```

The rest of `.claude/hooks/`, such as `test-gate.sh` and `diff-impl.sh`, exists
in this repository only. Nothing in a command needs those.
