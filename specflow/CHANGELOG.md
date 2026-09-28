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

### Changed

- Six section headings read better. In `references/workflow-guide.md`, Phase
  2's `### Process` is `### Steps`, which the other seven phases already
  used, and `### Iteration` is `### Repeat runs`. In `tasks-template.md`,
  `## Superpowers Execution` is `## Execution rules`, because every bullet
  under it also states what to do without superpowers;
  `### Execution Discipline by Marker` is `### What each marker requires`;
  and `### Within Each User Story` is `### Order within a user story`. In
  `plan-template.md`, `## Complexity Tracking` is
  `## Justified constitution violations`, which is what its table holds.

## [1.1.0] - 2026-09-27

### Added

- A `/speckit.specflow.agent-event` command dispatches hook payloads to gate
  scripts: `block-main-commit.sh` on `pre_tool_use`, `test-gate.sh` and
  `artifact-lint.sh` on `post_tool_use`, and `session-start.sh` on
  `session_start`. On install, `specify extension add specflow` registers these
  gates in the agent's native hook system on both Claude Code and the Copilot
  CLI.
- A `before_tasks` hook stops core `/speckit.tasks` on a missing constitution
  or an unresolved Open Question, the same gate `before_implement` already
  enforced.
- A `/speckit.specflow.gate` command writes a feature's `.clarified` marker
  after `/speckit.clarify` and its `.analyzed` marker after `/speckit.analyze`,
  through new `after_clarify` and `after_analyze` hooks. The gate scripts these
  hooks and `/speckit.specflow.execute` depend on now ship inside the
  extension archive, so `execute`'s refusal to run without `.analyzed` holds
  on an installed extension, not only in this repository.
- `catalog.json` at the repository root lets a project point spec-kit at this
  repository directly, by listing it in `.specify/extension-catalogs.yml` or
  setting `SPECKIT_CATALOG_URL`, instead of waiting on the upstream community
  catalog.
- `/speckit.specflow.status` warns when the installed superpowers version
  sits outside the tested `>=6.0.0 <7.0.0` range.
- `/speckit.specflow.status` reads a version stamp from each installed
  template and reports one as stale when it predates the installed extension
  version.

### Changed

- `SKILL.md` links the recorded link-audit run instead of the sample workflow
  walkthrough, which is removed.
- `/speckit.specflow.brainstorm` and `/speckit.specflow.review` now check for
  the constitution before running, the same gate the other three commands
  already enforced.
- `spec-template.md`'s Brainstorm Prompts cover five categories (boundary,
  error, scale, security, user confusion), matching the documented fallback
  protocol. The template carried seven.
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

- `test-gate.sh` reads the project's test command from the `Test command:`
  line in `.specify/memory/constitution.md`. It defaulted to a path that only
  existed inside this repository, so an installed extension blocked every
  ticked task in a consuming project instead of testing it.
- The commit gate blocks four shapes it allowed on main: a global option
  before the subcommand (`git -C . commit`, `git -c user.email=x commit`), a
  grouped command (`(git commit)`, `{ git commit; }`), and the first commit on
  a branch that carries none yet.
- On the Copilot CLI, a tool call whose `toolArgs` the handler cannot read as
  an object is denied under any tool name, not only `bash` and `powershell`. A
  shell under an unrecorded name ran with no command and the commit gate
  allowed it.
- On the Copilot CLI, a tool call carrying a null `toolResult` runs the commit
  gate. It was read as a completed call, so the gate never ran.
- The `CONSTITUTION_REQUIRED` stop names the missing path at all nine sites
  that raise it. The `after_clarify`, `after_analyze`, and `before_tasks`
  hooks and the four phase steps in `workflow-guide.md` omitted it, and the
  guide's execute phase named no constitution stop code at all.
- `README.md` no longer claims every command stops on a missing constitution.
  `status` reports the missing file and continues, and `agent-event` reads
  nothing under `.specify/memory/`.
- The catalog entry reports 7 commands and 6 hooks. It reported 6 and 5,
  written before the `agent-event` command and the `before_tasks` hook
  existed.
- The Stop codes table in `references/workflow-guide.md` lists
  `/speckit.specflow.brainstorm` and `/speckit.specflow.review` as printers of
  `CONSTITUTION_REQUIRED`. Both gained the gate and the table missed them, so
  a reader checking which commands stop got the wrong answer.
- Three section headings read better. The `## Gate` section in five hook
  prompts is `## Stop behavior`, which no longer collides with the Gate
  markers protocol in `references/workflow-guide.md`. `## Iteration` in
  `brainstorm.md` is `## Repeat runs`, and `## File Inference Fallback` in
  `status.md` is `## Phase without progress.yml`.
- `SKILL.md` no longer links `assets/workflow-overview-en.png` or the
  sample workflow walkthrough. `export-ignore` strips both directories from
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
