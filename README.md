# super-spec-new

super-spec-new builds specflow, a [spec-kit](https://github.com/github/spec-kit)
extension. Specflow adds edge-case brainstorming, task decomposition, test-driven
execution, and spec review to the constitution, spec, plan, tasks, checklist
workflow. Each command follows an
[obra/superpowers](https://github.com/obra/superpowers) skill when that skill is
installed, and a built-in protocol when it is not.

One set of command files runs on both target agents:

- On Claude Code, spec-kit registers each command under `.claude/skills/`.
- On the GitHub Copilot CLI, spec-kit registers each command under `.github/skills/`.

To install specflow into a spec-kit project, follow
[specflow/README.md](specflow/README.md#installation).

| Directory | Who reads it |
|-----------|--------------|
| `specflow/` | A user. It holds everything the extension installs. |
| `improvements/` | The maintainers. It holds the roadmap and the divergence measurements. |
| `standards/` | The maintainers. It holds the rules for code, prose, and slides. |
| `presentation/` | The maintainers. It holds the Marp deck and its diagram sources. |
| `docs/` | The maintainers. It holds the research behind two design decisions. |
| `.claude/` | The maintainers. It holds the agents and gate scripts for this checkout. |

Check a change to this repository before pushing:

```bash
bash verify.sh
```

The script runs the steps `.github/workflows/ci.yml` runs, in that order, and
stops at the first failure.

Read [AGENTS.md](AGENTS.md) for the architecture and the conventions every
contributor follows here. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening
a pull request.
