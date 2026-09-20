# Specflow for spec-kit

Specflow is a [spec-kit](https://github.com/github/spec-kit) extension that adds
six commands to the spec-kit workflow. Each command follows an
[obra/superpowers](https://github.com/obra/superpowers) skill when that skill is
installed and a built-in protocol when it is not. Spec-kit owns the documents:
constitution, spec, plan, tasks, checklist. Specflow adds edge-case
brainstorming on the spec, task decomposition with execution markers,
implementation with test-driven development and checkpoints, and a review of
the implementation against the spec. The execute command refuses to run until
`/speckit.analyze` reports zero critical inconsistencies. The same command
files run on Claude Code and on the GitHub Copilot CLI.

## Installation

Specflow installs into a spec-kit project, so create the project first. For
Claude Code:

```bash
specify init --here --integration claude
```

For the GitHub Copilot CLI:

```bash
specify init --here --integration copilot
```

Then add specflow from a release asset. Take the URL from the
[releases page](https://github.com/DonalMoloney/super-spec-new/releases):

```bash
specify extension add specflow --from <release asset URL>
```

To install from a checkout instead, clone the repository and point spec-kit at
the `specflow/` directory:

```bash
git clone https://github.com/DonalMoloney/super-spec-new.git
specify extension add ./super-spec-new/specflow --dev
```

The form spec-kit documents is `specify extension add ./specflow --dev`, run
from the parent of the extension directory. A `--dev` install copies the
directory as it stands on disk, so it also copies the 13 MiB under `assets/`
that the release archive strips.

The catalog form works once the catalog lists specflow:

```bash
specify extension add specflow
```

To use the extension as an agent skill instead, symlink the directory into the
skills path your agent reads:

```bash
# Claude Code
ln -sf "$(pwd)/specflow" ~/.claude/skills/specflow
# Agents that read the common skills path
ln -sf "$(pwd)/specflow" ~/.agents/skills/specflow
```

Specflow works without superpowers. To get the superpowers protocols, install
the obra/superpowers skills under `~/.agents/skills/` or `.agents/skills/` in
the project. Each command checks both paths and records the result in
`.specify/superpowers.yml`.

## Verify the install

Run the spec-kit listing and check the extension's line:

```bash
specify extension list
```

Expected in the output:

```
Commands: 6 | Hooks: 5
```

Then run the status command inside the agent. On a fresh project it reports
the constitution as missing and names `/speckit.constitution` as the next
step; on a project with features it prints one line per feature:

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
| `/speckit.specflow.status` | Print progress per feature and name the next step |
| `/speckit.specflow.brainstorm` | Question the spec for edge cases and record the answers in it |
| `/speckit.specflow.tasks` | Write a phased task breakdown with execution markers |
| `/speckit.specflow.execute` | Implement the tasks with TDD, subagents, and checkpoints |
| `/speckit.specflow.review` | Review the implementation against the spec |
| `/speckit.specflow.gate` | Write a feature's clarify or analyze marker once its gate passes |

The table names the Claude Code form; on the GitHub Copilot CLI each command is
a skill whose name replaces the dots with hyphens, so a user types
`/speckit-specflow-status` there.

The six commands sit beside the core spec-kit commands
(`/speckit.constitution`, `/speckit.specify`, `/speckit.plan`,
`/speckit.tasks`, `/speckit.checklist`), which spec-kit provides.

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

Each phase checks its prerequisites before it starts. Two gates need a person:
approving the spec before implementation and approving the merge after
review.

## Resumable state

Every piece of project state is a plain-text Markdown or YAML file: the
constitution under `.specify/memory/` and, per feature under `specs/NNN-*/`,
the spec, plan, tasks, and `progress.yml`. An interrupted session loses no
progress. Run `/speckit.specflow.status` in a new session to see where the
last one stopped. Each command reads the recorded progress first and skips
completed work, so re-running a command after an interruption is safe.

## Upgrade

Install the new release over the old one. Spec-kit refuses a second install of
the same id, so pass `--force`:

```bash
specify extension add specflow --from <new release asset URL> --force
```

The install replaces `.specify/extensions/specflow/` and the five registered
skill directories. It leaves the project's own files alone: the constitution,
the feature directories under `specs/`, and `.specify/superpowers.yml`.

## Remove

```bash
specify extension remove specflow --force
```

Without `--force` the command asks for confirmation and stops when the answer
is no. It deletes `.specify/extensions/specflow/` and each
`speckit-specflow-*` skill directory, then copies the config to
`.specify/extensions/.backup/specflow/`.

Three things stay behind, because spec-kit treats them as the project's own:
the feature directories under `specs/`, the `.clarified` and `.analyzed`
markers inside them, and `.specify/superpowers.yml`. Delete them by hand when
you want a clean project.

## Troubleshooting

### `CONSTITUTION_REQUIRED`

Every command reads `.specify/memory/constitution.md` first and stops when the
file is absent. Run `/speckit.constitution` to write it, then run the original
command again.

### The template resolver fails

Each command that writes a document resolves its template through the script
spec-kit installs under `.specify/scripts/`, and stops and reports the error
when that script fails. There is no fallback, because reading
`.specify/templates/<name>.md` returns the core layer alone and drops
specflow's sections. Spec-kit 0.16.2 is the first release carrying the
resolver, and `requires.speckit_version` in `extension.yml` holds that floor,
so an older host refuses the install rather than reaching this error.

### `ANALYZE_REQUIRED`

The execute command stops when the target feature carries no `.analyzed`
marker:

```
ANALYZE_REQUIRED
  Feature: specs/001-link-audit
  Missing: specs/001-link-audit/.analyzed
```

Run `/speckit.analyze` for that feature. The analysis has to report zero
critical inconsistencies before the marker is written. Then run
`/speckit.specflow.execute` again.

### `Superpowers <skill> not detected, using built-in fallback`

The command found no `SKILL.md` for that skill under `.agents/skills/` or
`~/.agents/skills/`, so it ran the built-in protocol instead. Nothing is
broken. To get the superpowers protocol, install the skill under one of those
two paths and run the command again. The directory name is case-sensitive and
has to match the name in the
[superpowers-mapping.md](references/superpowers-mapping.md) table.

## Getting started

1. Create the constitution.

   ```
   /speckit.constitution MyProject
   ```

   This creates `.specify/` and asks about principles, technology, and quality
   gates. The [constitution template](templates/constitution-template.md) has a
   Code Review Rules section. Fill in the error-handling convention, the test
   command, forbidden dependencies, and security rules. Record who approves
   the spec and who approves the merge.

2. Write the first spec.

   ```
   /speckit.specify "User authentication with email and password"
   ```

   This writes `specs/001-user-authentication/spec.md` with user stories,
   requirements, success criteria, an optional STRIDE threat model, and a
   traceability table from each requirement to its test.

3. Brainstorm edge cases.

   ```
   /speckit.specflow.brainstorm specs/001-user-authentication/spec.md
   ```

   The agent asks one question at a time about boundaries, errors, security,
   and user experience, and writes the answers back into the spec.

4. Clarify, plan, decompose, analyze, implement, review.

   ```
   /speckit.clarify
   /speckit.plan
   /speckit.specflow.tasks
   /speckit.analyze
   /speckit.specflow.execute
   /speckit.specflow.review
   ```

   The two spec-kit gates are not optional here. `/speckit.clarify` writes the
   `.clarified` marker and `/speckit.analyze` writes `.analyzed`;
   `/speckit.specflow.execute` stops with `ANALYZE_REQUIRED` until the second
   marker exists.

## A complete run

The repository keeps a verbatim snapshot of one full run, a static landing
page driven through all seven stages by Claude Code:
[examples/static-landing-page](https://github.com/DonalMoloney/super-spec-new/tree/main/specflow/examples/static-landing-page).
Its [README](https://github.com/DonalMoloney/super-spec-new/blob/main/specflow/examples/static-landing-page/README.md)
states how the artifacts were produced and how to reproduce them with
[scripts/e2e-agent-claude.sh](https://github.com/DonalMoloney/super-spec-new/blob/main/specflow/scripts/e2e-agent-claude.sh).
The snapshot and the scripts are not part of the installed extension.

## Project structure

After initialization the project holds two directories spec-kit creates:
`.specify/` for tool state and `specs/` for feature artifacts.

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

When a superpowers skill is installed, the matching command follows it and
adapts only the input and output locations to spec-kit's layout.

| Command | Skill | Built-in protocol |
|---------|-------|-------------------|
| `brainstorm` | `brainstorming` | Five-category questioning |
| `tasks` | `writing-plans` | Template-based decomposition |
| `execute` | `executing-plans`, `subagent-driven-development`, `test-driven-development` | Sequential walk with manual checkpoints |
| `review` | `requesting-code-review` | Built-in review checklist |

[superpowers-mapping.md](references/superpowers-mapping.md) states the detection
paths, the adaptation rules, and each fallback.
[copilot-cli.md](references/copilot-cli.md) lists, per command, what runs
differently on the GitHub Copilot CLI.

## Submitting to the spec-kit catalog

To list the extension in the
[spec-kit community catalog](https://github.com/github/spec-kit/tree/main/extensions):

1. Fork `github/spec-kit`.
2. Add an entry to `extensions/catalog.community.json`:

   ```json
   {
     "id": "specflow",
     "name": "Specflow",
     "version": "X.Y.Z",
     "description": "Adds brainstorming, task decomposition, TDD execution, and spec review to spec-kit, following obra/superpowers skills when they are installed. The execute command refuses to run until /speckit.analyze reports zero critical inconsistencies. The same command files run on Claude Code and on the GitHub Copilot CLI.",
     "author": "Specflow Contributors",
     "download_url": "https://github.com/DonalMoloney/super-spec-new/releases/download/vX.Y.Z/specflow-vX.Y.Z.zip",
     "repository": "https://github.com/DonalMoloney/super-spec-new",
     "homepage": "https://github.com/DonalMoloney/super-spec-new#readme",
     "license": "MIT",
     "requires": {
       "speckit_version": ">=0.16.2"
     },
     "verified": false,
     "tags": ["superpowers", "brainstorming", "tdd", "code-review", "subagent", "workflow", "claude-code", "copilot"]
   }
   ```

   Put the released version in place of `X.Y.Z` in all three spots. Every
   other value comes from `extension.yml`, so read it there rather than from
   this page.

   The URL names the release asset `.github/workflows/release.yml` uploads. It
   is not GitHub's tag ZIP at `archive/refs/tags/vX.Y.Z.zip`: that archive holds
   the whole repository, which puts `extension.yml` two levels down under
   `super-spec-new-vX.Y.Z/specflow/`, and the install stops with
   `No extension.yml found in archive`.

3. Add a row to the Community Extensions table in the spec-kit README.
4. Open a pull request with the extension submission template.
5. Automated checks and a manual review take three to seven business days.

The [Extension Publishing Guide](https://github.com/github/spec-kit/blob/main/extensions/EXTENSION-PUBLISHING-GUIDE.md)
has the full procedure.

## License

MIT
