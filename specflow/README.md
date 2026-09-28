# Specflow for spec-kit

Specflow is a [spec-kit](https://github.com/github/spec-kit) extension. It adds
seven commands to the spec-kit workflow. Each command follows the matching
[obra/superpowers](https://github.com/obra/superpowers) skill if that skill is
installed, and a built-in protocol if it is not. Spec-kit keeps the documents:
constitution, spec, plan, tasks, checklist. Specflow questions the spec for
edge cases and breaks the plan into tasks that carry execution markers. It
implements those tasks with test-driven development and checkpoints, then reads
the finished code back against the spec. The execute command refuses to start
until `/speckit.analyze` reports zero critical inconsistencies. One set of
command files runs on Claude Code and on the GitHub Copilot CLI.
[`pipeline-overview.svg`](../presentation/marp-deck/pipeline-overview.svg) diagrams
the phase pipeline: which command advances each document, and the marker each
gate checks before the next one runs.

## Installation

Specflow needs `jq` on the `PATH`. The shipped merge gate
(`gates/bash/merge-gate.sh`) reads findings JSON with it and refuses to run
without it.

Specflow installs into an existing spec-kit project. Create one first. For
Claude Code:

```bash
specify init --here --integration claude
```

For the GitHub Copilot CLI:

```bash
specify init --here --integration copilot
```

Next, add specflow from a release asset. Copy the URL from the
[releases page](https://github.com/DonalMoloney/super-spec-new/releases):

```bash
specify extension add specflow --from <release asset URL>
```

The repository is private today, and spec-kit downloads an asset without
sending your credentials, so that URL answers 404 and this form fails. Use the
checkout install below until the repository is public. The same applies to the
catalog forms further down, which read `catalog.json` over the same anonymous
path.

To install from a checkout instead, clone the repository and hand spec-kit the
`specflow/` directory:

```bash
git clone https://github.com/DonalMoloney/super-spec-new.git
specify extension add ./super-spec-new/specflow --dev
```

Spec-kit's own documentation writes that as
`specify extension add ./specflow --dev`, run from the parent of the extension
directory. A `--dev` install copies the directory as it sits on disk, including the
`examples/` and `scripts/` directories the release archive strips.

Once the catalog lists specflow, this form works too:

```bash
specify extension add specflow
```

To load the extension as an agent skill instead, symlink the directory into the
skills path your agent reads:

```bash
# Claude Code
ln -sf "$(pwd)/specflow" ~/.claude/skills/specflow
# Agents that read the common skills path
ln -sf "$(pwd)/specflow" ~/.agents/skills/specflow
```

Specflow runs without superpowers. For the superpowers protocols, install the
obra/superpowers skills under `~/.agents/skills/`, or under `.agents/skills/`
in the project. Each command reads both paths and writes what it found to
`.specify/superpowers.yml`.

## Verify the install

Run spec-kit's listing and read the extension's line:

```bash
specify extension list
```

The output carries this line:

```
Commands: 7 | Hooks: 6
```

Then run the status command inside the agent. On a fresh project it reports a
missing constitution and names `/speckit.constitution` as the next step. On a
project with features it prints one line per feature:

```
Specflow Project Status
========================
Constitution: Done (2026-04-22)
Superpowers:  brainstorming (detected), writing-plans (not found)

Features:
  001-user-auth    [####------] execute (Phase 5/6), gates: clarified, analyzed, T012/T019 tasks done
  002-photo-upload [##--------] brainstorm (Phase 2/6), gates: none, 2 open questions
  003-settings     [#---------] specify (Phase 1/6), gates: none, draft

Suggested next step: /speckit.specflow.execute 001
```

## Commands

| Command | What it does |
|---------|-------------|
| `/speckit.specflow.status` | Print each feature's progress and name the next step |
| `/speckit.specflow.brainstorm` | Question the spec for edge cases and write the answers into it |
| `/speckit.specflow.tasks` | Break the plan into phased tasks carrying execution markers |
| `/speckit.specflow.execute` | Implement each task under TDD, subagents, and checkpoints |
| `/speckit.specflow.review` | Read the implementation back against the spec |
| `/speckit.specflow.gate` | Write a feature's clarify or analyze marker once its gate passes |

The table names the Claude Code form. On the GitHub Copilot CLI each command is
a skill whose name swaps the dots for hyphens, so a user types
`/speckit-specflow-status` there.

Those six sit beside the commands spec-kit ships itself
(`/speckit.constitution`, `/speckit.specify`, `/speckit.plan`,
`/speckit.tasks`, `/speckit.checklist`).

## Workflow

```mermaid
flowchart LR
  A[Constitution] --> B[Specify]
  B --> C[Brainstorm]
  C -->|open questions| B
  C --> D[Plan]
  D --> E[Tasks]
  E --> F[Execute]
  F --> G[Review]
```

Every phase checks its prerequisites before it starts. Two gates need a person:
one approves the spec before implementation, the other approves the merge after
review.

## Resumable state

All project state sits in plain-text Markdown or YAML: the constitution under
`.specify/memory/` and, per feature under `specs/NNN-*/`, the spec, plan,
tasks, and `progress.yml`. An interrupted session loses nothing. Run
`/speckit.specflow.status` in a new session to see where the last one stopped.
Each command reads the recorded progress first and skips finished work, so
re-running one after an interruption is safe.

## Upgrade

A new release installs over the old one. Spec-kit refuses a second install of
the same id, so pass `--force`:

```bash
specify extension add specflow --from <new release asset URL> --force
```

The install replaces `.specify/extensions/specflow/` along with the six
registered skill directories. It leaves the project's own files untouched: the
constitution, the feature directories under `specs/`, and
`.specify/superpowers.yml`.

## Remove

```bash
specify extension remove specflow --force
```

Without `--force` the command asks for confirmation and stops on a no. It
deletes `.specify/extensions/specflow/` and every `speckit-specflow-*` skill
directory, then copies the config to `.specify/extensions/.backup/specflow/`.

Three sets of files stay behind, because spec-kit counts them as the project's
own: the feature directories under `specs/`, the `.clarified` and `.analyzed`
markers inside them, and `.specify/superpowers.yml`. Delete them by hand when
the project should carry nothing from specflow.

## Troubleshooting

### `CONSTITUTION_REQUIRED`

The brainstorm, tasks, execute, review, and gate commands read
`.specify/memory/constitution.md` first and stop when that file is missing. Run
`/speckit.constitution` to write it, then start the original command again.
`status` reports the missing file instead of stopping. `agent-event` reads
nothing under `.specify/memory/`.

### The template resolver fails

Each command that writes a document resolves its template through the script
spec-kit installs under `.specify/scripts/`. When that script fails, the
command stops and prints the error. No fallback exists: reading
`.specify/templates/<name>.md` returns the core layer alone and drops
specflow's sections. Spec-kit 0.16.2 is the first release carrying the
resolver, and `requires.speckit_version` in `extension.yml` holds that floor,
so an older host refuses the install before it reaches this error.

### `ANALYZE_REQUIRED`

The execute command stops when the named feature carries no `.analyzed`
marker:

```
ANALYZE_REQUIRED
  Feature: specs/001-link-audit
  Missing: specs/001-link-audit/.analyzed
```

Run `/speckit.analyze` on that feature. The marker appears only after the
analysis reports zero critical inconsistencies. Then run
`/speckit.specflow.execute` again.

### `Superpowers <skill> not detected, using built-in fallback`

The command found no `SKILL.md` for that skill under `.agents/skills/` or
`~/.agents/skills/`, so it ran the built-in protocol instead. Nothing is
broken. For the superpowers protocol, install the skill under one of those two
paths and run the command again. The directory name is case-sensitive, and it
has to match the name in the
[superpowers-mapping.md](references/superpowers-mapping.md) table.

## Getting started

1. Create the constitution.

   ```
   /speckit.constitution MyProject
   ```

   The command creates `.specify/` and asks about principles, technology, and
   quality gates. The
   [constitution template](templates/constitution-template.md) carries a Code
   Review Rules section. Fill in the error-handling convention, the test
   command, the forbidden dependencies, and the security rules. Record who
   approves the spec and who approves the merge.

2. Write the first spec.

   ```
   /speckit.specify "User authentication with email and password"
   ```

   The command writes `specs/001-user-authentication/spec.md`. It holds user
   stories, requirements, success criteria, an optional STRIDE threat model,
   and a traceability table from each requirement to its test.

3. Brainstorm edge cases.

   ```
   /speckit.specflow.brainstorm specs/001-user-authentication/spec.md
   ```

   The agent asks one question at a time, covering boundaries, errors,
   security, and user experience. It writes each answer back into the spec.

4. Clarify, plan, decompose, analyze, implement, review.

   ```
   /speckit.clarify
   /speckit.plan
   /speckit.specflow.tasks
   /speckit.analyze
   /speckit.specflow.execute
   /speckit.specflow.review
   ```

   Neither spec-kit gate is optional here. `/speckit.clarify` writes the
   `.clarified` marker and `/speckit.analyze` writes `.analyzed`. Until that
   second marker exists, `/speckit.specflow.execute` stops with
   `ANALYZE_REQUIRED`.

## A complete run

The repository keeps one recorded run: a broken-link audit CLI Claude Code took
through all seven stages, at
[examples/link-audit](https://github.com/DonalMoloney/super-spec-new/tree/main/specflow/examples/link-audit).
Its [README](https://github.com/DonalMoloney/super-spec-new/blob/main/specflow/examples/link-audit/README.md)
states how the run was recorded and how to reproduce it with
[scripts/e2e-agent-claude.sh](https://github.com/DonalMoloney/super-spec-new/blob/main/specflow/scripts/e2e-agent-claude.sh).
Neither the snapshot nor the scripts ship in the installed extension.

## Project structure

Spec-kit creates two directories at init: `.specify/` for tool state and
`specs/` for feature artifacts.

```
your-project/
  .specify/
    memory/
      constitution.md      # project principles and review rules
    superpowers.yml        # skill detection result, written by the commands
    templates/             # document templates
  specs/
    001-feature-name/
      spec.md
      plan.md
      tasks.md
      progress.yml         # phase progress, written by the commands
      checklist-*.md
  ...                      # your source code
```

## Superpowers skills

If a superpowers skill is installed, the matching command follows it. Only the
input and output locations change, to fit spec-kit's layout.

| Command | Skill | Built-in protocol |
|---------|-------|-------------------|
| `brainstorm` | `brainstorming` | Five-category questioning |
| `tasks` | `writing-plans` | Template-based decomposition |
| `execute` | `executing-plans`, `subagent-driven-development`, `test-driven-development` | Sequential walk with manual checkpoints |
| `review` | `requesting-code-review` | Built-in review checklist |

[superpowers-mapping.md](references/superpowers-mapping.md) states the detection
paths, the adaptation rules, and each fallback.
[copilot-cli.md](references/copilot-cli.md) names, command by command, what
runs differently on the GitHub Copilot CLI.

Maintainers: see [references/publishing.md](references/publishing.md) for the
catalog-submission process.

## License

MIT
