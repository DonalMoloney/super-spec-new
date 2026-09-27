# Changelog

Each entry names one change a specflow user can see. The newest release comes
first.

The format comes from [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the version numbers follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

The extension ships prompts, not code. Pick the version part from the change:

| Change | Version part |
|--------|--------------|
| A renamed marker, command, hook or file | Major |
| A changed Process step or template section | Minor |
| Wording, with every step and name unchanged | Patch |

A release that carries more than one of these takes the highest part.

## [Unreleased]

### Added

- A `/speckit.specflow.agent-event` command dispatches hook payloads to gate
  scripts: `block-main-commit.sh` on `pre_tool_use`, `test-gate.sh` and
  `artifact-lint.sh` on `post_tool_use`, and `session-start.sh` on
  `session_start`. On install, `specify extension add specflow` registers these
  gates in the agent's native hook system on both Claude Code and the Copilot
  CLI.

## [1.1.0] - 2026-09-20

### Changed

- The extension needs spec-kit 0.16.2 or later. On an older spec-kit,
  `specify extension add specflow` refuses the install.
- A `/speckit.specflow.tasks` artifact now carries this extension's sections.
  The command resolves its template through the resolver spec-kit installs
  under `.specify/scripts/`, in the bash, PowerShell or python variant the
  project was initialized with. Before, the command read the core layer alone,
  so an artifact could come out without Open Questions, Threat Model,
  Traceability or Brainstorm Log, and nothing reported the gap. The command
  stops and reports when the resolver is absent.
- `/speckit.constitution` no longer copies this extension's templates over
  `.specify/templates/`. That copy overwrote the core templates in place and
  discarded whatever a preset contributed.
- The extension is listed as Specflow, not Superpowers Bridge. Its catalog
  description, and the description of every command and template, state what
  the command or template does instead of calling it enhanced.

### Fixed

- `SKILL.md` no longer links `assets/workflow-overview-en.png` or
  `examples/sample-workflow.md`. `export-ignore` strips both directories from
  an install, so both links led nowhere.

## [1.0.2] - 2026-08-07

### Fixed

- `specify extension add specflow` installs again. On v1.0.1 it failed. The
  catalog downloads GitHub's generated tag ZIP, and spec-kit checks that ZIP
  before unpacking it: `_download_security.py` allows 10 MiB per member,
  50 MiB total and 512 entries. The archive carried
  `assets/workflow-overview-en.png` at about 12 MiB, so the install stopped
  with `ZIP member ... exceeds maximum size of 10485760 bytes` (issue #6). The
  archive now holds the runtime payload alone: 0.04 MiB downloaded, 25 entries,
  largest member 0.02 MiB.

### Changed

- The extension a user downloads no longer carries `assets/`, `examples/`,
  `scripts/` or `.github/`. `.gitattributes` marks the four `export-ignore`, so
  `git archive`, and GitHub's tag ZIP with it, leaves them out. A clone, the
  rendered README images and a `--dev` install keep all four; nothing was
  deleted or recompressed.
- The documentation names spec-kit's real feature layout, `specs/NNN-*/`, where
  it named `.specify/specs/` before.

### CI / Tooling

- `scripts/validate-release-archive.py` rebuilds the published archive on every
  CI run. It fails the build when the archive nears a spec-kit install limit,
  drops a file `extension.yml` declares, or picks an export-ignored path back
  up.
- Two end-to-end tests check a real spec-kit install: `scripts/e2e-smoke.sh`
  covers the structure, and `scripts/e2e-agent-claude.sh` drives an agent
  through the workflow.

## [1.0.1] - 2026-05-30

### Changed

- Every command name changed, so a call to an old name breaks:
  `/speckit.superpowers.{status,brainstorm,tasks,execute,review}` became
  `/speckit.specflow.{status,brainstorm,tasks,execute,review}`.
- `extension.id` changed from `superpowers` to `specflow`, which matches the
  repository name and the catalog id spec-kit's registry validator needs.
- The three lifecycle hooks `after_tasks`, `before_implement` and
  `after_implement` point at the `speckit.specflow.*` commands.
- The README install line reads `specify extension add specflow`.

### Fixed

- `specify extension add superpowers-bridge` failed on v1.0.0 because the
  catalog id and the command namespace disagreed: `Validation Error: Command
  'speckit.superpowers.status' must use extension namespace
  'superpowers-bridge'`. v1.0.1 matches the namespace to the renamed catalog
  id.

### CI / Tooling

- `scripts/validate-extension-metadata.py` builds the expected namespace from
  `extension.yml`'s `id`, so a namespace or slug that drifts fails CI before it
  reaches the catalog. It runs three checks:
  - every `commands[].name` and every `hooks[].command` starts with
    `speckit.<extension.id>.`;
  - the slug in the README install line equals `extension.id`;
  - no document still names `speckit.superpowers.*`.

## [1.0.0] - 2026-04-22

### Added

- `extension.yml` declares the extension to spec-kit's extension registry.
- Five superpowers-bridge commands drive the workflow: status, brainstorm,
  tasks, execute, review.
- Three lifecycle hooks ship: after-tasks, before-execute, after-execute.
- Five templates cover the constitution, the spec, the plan, the tasks and the
  checklist.
- `progress.yml` and `superpowers.yml` hold the state a command reads to resume
  a session.
- Each command looks for an installed superpowers skill and falls back to a
  built-in protocol when it finds none.
- The built-in brainstorming protocol asks about five categories.
- The built-in review checklist stands in for `requesting-code-review`.
- The task templates carry the `[TDD]`, `[REVIEW]` and `[SUBAGENT]` execution
  markers.
- The documentation ships in English and Chinese.
- The architecture diagrams ship in English and Chinese.
- The reference set holds the workflow guide and the superpowers bridge.
- One sample walks a feature end to end.
