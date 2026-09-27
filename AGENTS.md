# super-spec-new

Our own fork/reimplementation of **Specflow**, a
[spec-kit](https://github.com/github/spec-kit) extension that runs
[obra/superpowers](https://github.com/obra/superpowers) agent skills (brainstorming,
writing-plans, TDD, subagent-driven-development, code review) inside spec-kit's
governance workflow (constitution → spec → plan → tasks → checklist). The upstream
reference implementation is vendored at `specflow/`. Treat it as the spec to diverge
from, not a dependency to import.

This is a **prompt/spec repo, not an application**: the "source code" is Markdown
command definitions and YAML metadata that define an agent's behavior contract, plus a
handful of Python/bash validation scripts. There is no package.json/Makefile. Don't
invent one.

**Target surface**: once complete, this project is scoped to run only via the
**Claude CLI (Claude Code)** and the **GitHub Copilot CLI**, not the Codex CLI and not the
other spec-kit agent integrations upstream specflow supports. Don't add
Codex-specific paths (`~/.codex/skills/`) or other-agent integration code; the
`AGENTS.md`/`CLAUDE.md`/`.github/copilot-instructions.md` trio here is the full set of
agent-facing docs this repo needs.

## Commands

Run `bash verify.sh` from the repository root before pushing. It walks the steps
`.github/workflows/ci.yml` runs, in that order, stops at the first failure, and
prints the four steps it leaves to CI. `tests/test_ci_parity.py` fails when the
script and the workflow drift apart, so the script cannot fall behind silently.

The rest run from inside `specflow/` (script paths are relative to that directory):

| Command | Description |
|---------|-------------|
| `python3 scripts/validate-extension-metadata.py` | Checks `extension.yml`'s `extension.id` matches the `speckit.<id>.*` command/hook namespace, and that docs stay aligned |
| `python3 scripts/validate-release-archive.py [git-ref]` | Rebuilds the `git archive` ZIP spec-kit's catalog would download and checks it against spec-kit's size/entry limits |
| `bash scripts/e2e-smoke.sh` | Structural end-to-end test (no LLM), ~60s: installs the extension into a fresh spec-kit project and asserts the file layout |
| `E2E_DRY_RUN=1 bash scripts/e2e-agent-claude.sh` | Full agent-driven e2e test across all 7 workflow stages, in dry-run (no API calls) mode |
| `ANTHROPIC_API_KEY=... bash scripts/e2e-agent-claude.sh` | Same, but drives `claude -p` through each stage (costs money) |
| `E2E_DRY_RUN=1 bash scripts/e2e-agent-copilot.sh` | The same seven stages on the GitHub Copilot CLI, in dry-run mode. Both agent scripts source `scripts/e2e-stages.sh`, which holds the stages and the assertions |

CI (`.github/workflows/ci.yml`) runs the two validate scripts, the script, review and
hook test suites, then installs the extension into a real `specify init` project via
`uvx --from git+https://github.com/github/spec-kit.git` and greps the resulting
`.specify/extensions.yml` for the registered commands. Test dependencies are declared
in `requirements-dev.txt`.

`.github/workflows/score-artifacts.yml` is the second workflow: it replays
`score-artifacts.py` over both goldens and fails when a score drops. It is
path-filtered to `specflow/commands/`, `templates/`, `scripts/`, and `examples/`.

Workflows live at the repository root. GitHub reads `.github/workflows/` only from
there, so a workflow under `specflow/` never runs.

## Architecture

- `README.md`: the repository's human-facing entry point. States what specflow
  is, the install command, and links out to `specflow/README.md` for full
  usage; distinct from the agent-facing trio named above.
- `specflow/extension.yml`: the manifest, which declares the 6 commands, 5 templates,
  5 scripts, and 6 hooks (`after_clarify`, `after_analyze`, `after_tasks`,
  `before_tasks`, `before_implement`, `after_implement`) spec-kit's catalog reads.
- `specflow/commands/*.md`: one file per `/speckit.specflow.*` command (`status`,
  `brainstorm`, `tasks`, `execute`, `review`, `gate`). Each is a behavior contract of
  Input, Output, and numbered Process steps, not code.
- `specflow/commands/hooks/*.md`: the 6 hook prompts.
- `specflow/gates/`: the 5 scripts `provides.scripts` declares, under `bash/` and
  `python/`. No `export-ignore` rule strips this directory, so a catalog install
  carries them and the Copilot CLI can run them (ADR-0025). A two-line script
  under `.claude/hooks/` execs each shipped bash gate, so `.claude/settings.json`
  and `merge-gate.yml` keep their paths.
- `specflow/templates/*.md`: the 5 document templates (`constitution`, `spec`,
  `plan`, `tasks`, `checklist`) spec-kit installs to
  `.specify/extensions/specflow/templates/` and resolves at command time. The
  resolver layers project overrides, presets, extension templates, then core,
  so these win over core without replacing `.specify/templates/`.
- `specflow/references/`: `workflow-guide.md` (built-in fallback protocols) and
  `superpowers-mapping.md` (skill detection/mapping details).
- `specflow/examples/`: teaching material, not runtime payload. `link-audit/`
  is a recorded run of this fork's pipeline and the scorer's golden. Each
  `seeded-*/` directory copies that run's feature directory with one planted
  flaw the scorer must report, and `mutation-gate-sample/` feeds the mutation
  gate.
- `specflow/assets/`: workflow diagrams (~12 MiB); documentation media, not runtime payload.
- `presentation/`: the Marp deck (`marp-deck/`) with its Mermaid and SVG
  diagram sources, and `use-guide/` explaining how to render it.
- **Namespace lock-step**: `extension.yml`'s `extension.id` must equal the prefix on
  every command/hook name (`speckit.<id>.*`). Drift fails
  `validate-extension-metadata.py` and CI, and breaks catalog install.
- **`.gitattributes` `export-ignore`**: `assets/`, `examples/`, `scripts/`, `.github/`,
  `.gitattributes`, `.gitignore` are stripped from the `git archive` ZIP
  that `specify extension add specflow` downloads. An installed extension
  never has these, so don't reference them from a command file as if it will.
- **Archive size limits**: spec-kit's `_download_security.py` enforces 50 MiB total
  download, 512 max ZIP entries, 10 MiB per member, 50 MiB total uncompressed. A single
  oversized asset (this happened with a 12 MiB PNG, issue #6) breaks install for every
  user, which is why `assets/` is `export-ignore`d rather than shrunk. Run
  `validate-release-archive.py` after adding any binary asset.
- **`specs/NNN-*/` lives at the consuming project's root**, never under
  `.specify/specs/`. This path drifted once and `e2e-smoke.sh` now asserts against it.
- **Constitution is a hard gate**: `.specify/memory/constitution.md` must exist before
  any other command runs; every command file should verify this first.
- **Superpowers is optional, always**: every command must work with a built-in fallback
  protocol when the corresponding superpowers skill isn't found at `.agents/skills/` or
  `~/.agents/skills/`. Never make a command hard-require a superpowers skill.
- **Everything is resumable**: state lives only in `progress.yml` (per feature) and
  `.specify/superpowers.yml` (skill detection cache) as plain YAML. A command must be
  safe to re-run after an interruption by reading these first, not by assuming a fresh start.

Four agents rewrite shipped files without changing their contracts: `prose-rephraser`
for prose, `script-refactorer` for scripts, `divergence-renamer` for a name cited in
more than one file, and `divergence-auditor` to measure the change against upstream
and run the guards. The file table and dispatch order live in
`improvements/reference.md` under "Rewrite status".

## Task decomposition

Any time a task (a `tasks.md` entry, a BDD-squad task, a plan step) gets broken down,
each resulting item must be **singular and crisp**:

- One outcome per item: if describing it needs "and", split it into two items.
- Concrete and verifiable: a reader can check it's done without asking a follow-up
  question ("add input validation" is not crisp; "reject empty `email` with a 400" is).
- No bundled scope: a fix, a refactor, and a test addition are three items, not one,
  even when they touch the same file.
- Independently completable where possible: flag real ordering dependencies
  explicitly instead of merging dependent steps into one item to avoid stating the dependency.

This applies to `specflow/templates/tasks-template.md` output, `/speckit.specflow.tasks`,
and every phase of the `.claude/agents/` BDD squad. `requirements-analyst`'s
Given/When/Then blocks and `bdd-orchestrator`'s checklist items both follow this rule.

## Conventions

- Command files follow the existing Input/Output/Process shape (see any file in
  `specflow/commands/`). Match it exactly when adding or editing a command.
- Documentation is English only (`standards/documentation.md`). Do not add or
  maintain a translated copy of `README.md` or any other doc.
- When a change touches `extension.yml`, `commands/`, or `templates/`, run both
  validate scripts before committing. CI will otherwise fail on the same checks.

## Standards

Every agent, on either target surface, produces work against the three files under
`standards/`. Read the one that matches the output before starting; reviewers and
`work-verifier` reject against them.

- [`standards/code.md`](standards/code.md): how code is developed. TDD order, scope
  discipline, naming, error handling, comments, tests, commits, and a list of
  patterns rejected on sight.
- [`standards/documentation.md`](standards/documentation.md): how prose is written.
  Structure, tone, a banned-phrase table, and per-document rules for README,
  CHANGELOG, ADR, PR description, and hand-off report.
- [`standards/presentations.md`](standards/presentations.md): how slide decks are
  formatted. Marp front matter, per-slide limits, deck shape, and a render check.

## Code Review Rules

- Review code against [standards/code.md](standards/code.md).
- Run both extension validators from `specflow/` before approving a change:

  ```bash
  python3 scripts/validate-extension-metadata.py
  python3 scripts/validate-release-archive.py
  ```

- Require the hook tests to pass. Run from the repository root:

  ```bash
  bash .claude/hooks/tests/run.sh
  ```

- Reject an unresolved `[NEEDS CLARIFICATION]` marker in a shipped template,
  except on an example line that teaches the syntax (ADR-0015).
- Reject a translated copy of any document, per the Language rule in
  [standards/documentation.md](standards/documentation.md).

## Agent behavior guidelines

Adapted from [andrej-karpathy-skills CLAUDE.md](https://github.com/multica-ai/andrej-karpathy-skills/blob/main/CLAUDE.md).
These apply to any agent working this repo, not only Claude Code. The **GitHub
Copilot CLI** target has no equivalent of `~/.claude/CLAUDE.md` to fall back on, so
this is the one place both surfaces read:

- **Surface confusion instead of guessing**: if a command file's Process step, a
  spec's requirement, or a task's scope is ambiguous, name the ambiguity and ask
  rather than silently picking one interpretation.
- **State a verification plan before multi-step edits**: e.g. "1. Edit
  `extension.yml` → verify: `validate-extension-metadata.py` passes. 2. Update the
  matching command doc → verify: namespace still matches." Don't call a change done
  without naming the check that proves it.
- **No speculative scope**: this reinforces the [Task decomposition](#task-decomposition)
  rule above. Implement exactly the requested item, not adjacent "while we're at it"
  improvements.

## Roadmap execution workflow

**Main branch stays clean:**
- All roadmap work (G-19 onward; G-01 to G-18 merged) runs in background git worktrees.
- Main branch is always on the latest merge; no feature branches here.
- Each group = one worktree in `~/PycharmProjects/worktrees/<group-name>` with its own agent run.
- After completion, worktree is deleted and the PR is merged to main.

**Coordination:** Before creating a worktree for a group, mark it as "working on" in `improvements/roadmap.md`:
- Append `(working on)` to the end of the group's header line
- Commit this change to main immediately so other worktrees see it
- When the group completes and merges, remove "(working on)" marker
- This prevents simultaneous development of the same group across multiple worktrees

**Agent dispatch pattern:**
- Create worktree: `git worktree add ~/PycharmProjects/worktrees/G-01-<name> -b <branch-name>`
- Dispatch agent: e.g., `bdd-orchestrator` for groups with script/hook/CI changes
- Agent runs in background (`--background` flag where applicable)
- User remains on `main` and can continue to other worktrees or tasks
- Pull latest when ready; clean up worktree after merge

See `improvements/roadmap.md` for item definitions, executors, and Verify conditions.

## Claude Code

@specflow/references/superpowers-mapping.md is the map between this project's
commands and the obra/superpowers skills they map to. Read it before editing
any command file's superpowers-detection logic.

<!-- CLAUDE.md at the repo root imports this file with `@AGENTS.md`. Keep this file the
     single source of truth; add Claude-only notes to CLAUDE.md itself, not here. -->
