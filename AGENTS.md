# super-spec-new

Our own fork/reimplementation of **Specflow** ("Superpowers Bridge"), a
[spec-kit](https://github.com/github/spec-kit) extension that bridges spec-kit's
governance workflow (constitution → spec → plan → tasks → checklist) with
[obra/superpowers](https://github.com/obra/superpowers) agent skills (brainstorming,
writing-plans, TDD, subagent-driven-development, code review). The upstream reference
implementation is vendored at `specflow/` — treat it as the spec to diverge from, not
a dependency to import. No commits exist on `main` yet; this is a fresh checkout.

This is a **prompt/spec repo, not an application**: the "source code" is Markdown
command definitions and YAML metadata that define an agent's behavior contract, plus a
handful of Python/bash validation scripts. There is no package.json/Makefile — don't
invent one.

**Target surface**: once complete, this project is scoped to run only via the
**Claude CLI (Claude Code)** and the **GitHub Copilot CLI** — not the Codex CLI, not
other spec-kit agent integrations upstream specflow supports. Don't add
Codex-specific paths (`~/.codex/skills/`) or other-agent integration code; the
`AGENTS.md`/`CLAUDE.md`/`.github/copilot-instructions.md` trio here is the full set of
agent-facing docs this repo needs.

## Commands

All run from inside `specflow/` (script paths are relative to that directory):

| Command | Description |
|---------|-------------|
| `python3 scripts/validate-extension-metadata.py` | Checks `extension.yml`'s `extension.id` matches the `speckit.<id>.*` command/hook namespace, and that docs stay aligned |
| `python3 scripts/validate-release-archive.py [git-ref]` | Rebuilds the `git archive` ZIP spec-kit's catalog would download and checks it against spec-kit's size/entry limits |
| `bash scripts/e2e-smoke.sh` | Structural end-to-end test (no LLM), ~60s: installs the extension into a fresh spec-kit project and asserts the file layout |
| `E2E_DRY_RUN=1 bash scripts/e2e-agent-claude.sh` | Full agent-driven e2e test across all 7 workflow stages, in dry-run (no API calls) mode |
| `ANTHROPIC_API_KEY=... bash scripts/e2e-agent-claude.sh` | Same, but actually drives `claude -p` through each stage (costs money) |

CI (`specflow/.github/workflows/ci.yml`) runs the two validate scripts, then installs
the extension into a real `specify init` project via `uvx --from git+https://github.com/github/spec-kit.git`
and greps the resulting `.specify/extensions.yml` for the registered commands.

## Architecture

- `specflow/extension.yml` — the manifest: declares the 5 commands, 5 templates, and
  3 hooks (`after_tasks`, `before_implement`, `after_implement`) spec-kit's catalog reads.
- `specflow/commands/*.md` — one file per `/speckit.specflow.*` command (`status`,
  `brainstorm`, `tasks`, `execute`, `review`). Each is a behavior contract: Input,
  Output, numbered Process steps — not code.
- `specflow/commands/hooks/*.md` — the 3 optional hook prompts.
- `specflow/templates/*.md` — document templates copied into a consuming project's
  `.specify/templates/` on `/speckit.constitution`.
- `specflow/references/` — `workflow-guide.md` (built-in fallback protocols) and
  `superpowers-bridge.md` (skill detection/mapping details).
- `specflow/examples/` — a full real-run snapshot (`static-landing-page/`) and
  `sample-workflow.md`; teaching material, not runtime payload.
- `specflow/assets/` — workflow diagrams (~12 MiB); documentation media, not runtime payload.
- `presentation/` — currently empty; this is where the Marp slide deck giving a
  project overview will go once written. Author it as a single `.md` file with Marp
  front matter (`marp: true`) so it renders via the Marp CLI/VS Code extension — don't
  add a build step or framework for it. Draw its content from `imporvements/improvements.md`
  (the project roadmap) and this file, not from re-deriving the project's purpose from scratch.

## Gotchas

- **Namespace lock-step**: `extension.yml`'s `extension.id` must equal the prefix on
  every command/hook name (`speckit.<id>.*`). Drift fails
  `validate-extension-metadata.py` and CI, and breaks catalog install.
- **`.gitattributes` `export-ignore`**: `assets/`, `examples/`, `scripts/`, `.github/`,
  `.gitattributes`, `.gitignore` are stripped from the `git archive` ZIP
  that `specify extension add specflow` actually downloads. An installed extension
  never has these — don't reference them from a command file as if it will.
- **Archive size limits**: spec-kit's `_download_security.py` enforces 50 MiB total
  download, 512 max ZIP entries, 10 MiB per member, 50 MiB total uncompressed. A single
  oversized asset (this happened with a 12 MiB PNG, issue #6) breaks install for every
  user — that's why `assets/` is `export-ignore`d rather than shrunk. Run
  `validate-release-archive.py` after adding any binary asset.
- **`specs/NNN-*/` lives at the consuming project's root**, never under
  `.specify/specs/`. This path drifted once and `e2e-smoke.sh` now asserts against it.
- **Constitution is a hard gate**: `.specify/memory/constitution.md` must exist before
  any other command runs; every command file should verify this first.
- **Superpowers is optional, always**: every command must work with a built-in fallback
  protocol when the corresponding superpowers skill isn't found at `.agents/skills/` or
  `~/.agents/skills/`. Never make a command hard-require a superpowers skill.
- **Everything is resumable**: state lives only in `progress.yml` (per feature) and
  `.specify/superpowers.yml` (skill detection cache) as plain YAML — a command must be
  safe to re-run after an interruption by reading these first, not by assuming a fresh start.

## Task decomposition

Any time a task (a `tasks.md` entry, a BDD-squad task, a plan step) gets broken down,
each resulting item must be **singular and crisp**:

- One outcome per item — if describing it needs "and", split it into two items.
- Concrete and verifiable — a reader can check it's done without asking a follow-up
  question ("add input validation" is not crisp; "reject empty `email` with a 400" is).
- No bundled scope — a fix, a refactor, and a test addition are three items, not one,
  even when they touch the same file.
- Independently completable where possible — flag real ordering dependencies
  explicitly instead of merging dependent steps into one item to avoid stating the dependency.

This applies to `specflow/templates/tasks-template.md` output, `/speckit.specflow.tasks`,
and every phase of the `.claude/agents/` BDD squad — `requirements-analyst`'s
Given/When/Then blocks and `bdd-orchestrator`'s checklist items both follow this rule.

## Conventions

- Command files follow the existing Input/Output/Process shape (see any file in
  `specflow/commands/`) — match it exactly when adding or editing a command.
- Documentation is English only (`standards/documentation.md`). Do not add or
  maintain a translated copy of `README.md` or any other doc.
- When a change touches `extension.yml`, `commands/`, or `templates/`, run both
  validate scripts before committing — CI will otherwise fail on the same checks.

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

- Reject unresolved `[NEEDS CLARIFICATION]` markers in shipped templates.
- Keep the English and Chinese README changes in sync.

## Agent behavior guidelines

Adapted from [andrej-karpathy-skills CLAUDE.md](https://github.com/multica-ai/andrej-karpathy-skills/blob/main/CLAUDE.md).
These apply to any agent working this repo, not only Claude Code — the **GitHub
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
  rule above — implement exactly the requested item, not adjacent "while we're at it"
  improvements.

## Roadmap execution workflow

**Main branch stays clean:**
- All roadmap work (G-01 through G-18) runs in background git worktrees.
- Main branch is always on the latest merge; no feature branches here.
- Each group = one worktree in `~/PycharmProjects/worktrees/<group-name>` with its own agent run.
- After completion, worktree is deleted and the PR is merged to main.

**Coordination:** Before creating a worktree for a group, mark it as "working on" in `imporvements/tasks.md`:
- Change the group header from `## G-NN — [title]` to `## G-NN — [title] (working on)`
- Commit this change to main immediately so other worktrees see it
- When the group completes and merges, remove "(working on)" marker
- This prevents simultaneous development of the same group across multiple worktrees

**Agent dispatch pattern:**
- Create worktree: `git worktree add ~/PycharmProjects/worktrees/G-01-<name> -b <branch-name>`
- Dispatch agent: e.g., `bdd-orchestrator` for groups with script/hook/CI changes
- Agent runs in background (`--background` flag where applicable)
- User remains on `main` and can continue to other worktrees or tasks
- Pull latest when ready; clean up worktree after merge

See `imporvements/tasks.md` for group definitions, executors, and Verify conditions.

## Claude Code

@specflow/references/superpowers-bridge.md is the map between this project's
5 commands and the obra/superpowers skills they bridge to — read it before editing
any command file's superpowers-detection logic.

<!-- CLAUDE.md at the repo root imports this file with `@AGENTS.md`. Keep this file the
     single source of truth; add Claude-only notes to CLAUDE.md itself, not here. -->
