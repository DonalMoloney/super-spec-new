# Copilot instructions: super-spec-new

This repo is our own fork/reimplementation of **Specflow** ("Superpowers Bridge"), a
[spec-kit](https://github.com/github/spec-kit) extension bridging spec-kit's governance
workflow (constitution → spec → plan → tasks → checklist) with
[obra/superpowers](https://github.com/obra/superpowers) agent skills. The upstream
reference implementation (`WangX0111/superspec`) is vendored read-only at `specflow/`,
rebranded. Treat it as the spec to diverge from, not a dependency. `AGENTS.md` at the repo root is the source of truth
for commands, architecture, and gotchas; this file is a Copilot-CLI-facing summary of
the same facts. Keep the two in sync when either changes.

**Target surface**: once complete, this project is scoped to run only via the
**Claude CLI (Claude Code)** and the **GitHub Copilot CLI**. Do not add Codex CLI or
other agent-integration paths.

This is a **prompt/spec repo, not an application**: the "source" is Markdown command
contracts and YAML metadata, plus a few Python/bash validation scripts. There is no
package.json or Makefile.

## Commands (run from inside `specflow/`)

- `python3 scripts/validate-extension-metadata.py`: checks `extension.yml`'s
  `extension.id` matches the `speckit.<id>.*` command/hook namespace.
- `python3 scripts/validate-release-archive.py [git-ref]`: rebuilds the `git archive`
  ZIP spec-kit's catalog downloads and checks it against spec-kit's size limits.
- `bash scripts/e2e-smoke.sh`: structural end-to-end test, no LLM, ~60s.
- `E2E_DRY_RUN=1 bash scripts/e2e-agent-claude.sh`: full agent-driven e2e test, dry run.

Run both validate scripts before committing any change to `extension.yml`, `commands/`,
or `templates/`. CI runs the same checks.

## Architecture

- `specflow/extension.yml`: manifest, 5 commands, 5 templates, 3 hooks.
- `specflow/commands/*.md`: one file per `/speckit.specflow.*` command; each is an
  Input/Output/Process behavior contract, not code.
- `specflow/templates/*.md`: document templates spec-kit resolves at command time
  from `.specify/extensions/specflow/templates/`, above core and below presets.
- `specflow/references/`: fallback protocols and superpowers skill mapping.
- `specflow/examples/`, `specflow/assets/`: teaching material and doc media, not runtime payload.

## Gotchas

- `extension.id` must equal the `speckit.<id>.*` prefix on every command/hook name.
- `.gitattributes` marks `assets/`, `examples/`, `scripts/`, `.github/` as
  `export-ignore`, so none of these exist in an installed extension.
- Release archive limits: 50 MiB total, 512 entries, 10 MiB/member, 50 MiB uncompressed.
- `specs/NNN-*/` lives at the consuming project's **root**, never under `.specify/specs/`.
- `.specify/memory/constitution.md` is a hard gate: every command must verify it
  exists before doing anything else.
- Superpowers skills are always optional: every command needs a working built-in
  fallback when a skill isn't found at `.agents/skills/` or `~/.agents/skills/`.
- State is resumable via `progress.yml` and `.specify/superpowers.yml`: commands must
  read these before assuming a fresh start.

## Task decomposition

Whenever a task gets broken into smaller items (`tasks.md`, a BDD-squad step, a plan
step), each item must be **singular and crisp**: one outcome per item (split on "and"),
concrete and verifiable without a follow-up question, no bundled fix+refactor+test in
one item, and real ordering dependencies stated explicitly rather than merged together.

## BDD agent squad

`.claude/agents/` holds 28 agents: a 17-agent BDD squad, the 8-agent review panel
named in ADR-0014, and the 3 rewrite agents. The BDD squad (orchestrator + 16 phase
agents) drives one feature task through a full BDD lifecycle (Gherkin → step defs →
RED → task decomposition → GREEN → REFACTOR → review → docs → adversarial
verification), entered via `bdd-orchestrator`. This is Claude-CLI-specific tooling (Copilot CLI has no
equivalent subagent mechanism). When working from Copilot CLI, follow the same phase
order manually: requirements → scenarios → step defs → red → task breakdown into
singular crisp items → implement → green → refactor → unit tests → review → spec audit
→ regression → docs → adversarial re-verification → report.

Before reporting any task done from Copilot CLI, adversarially re-check your own
completion claims the way `work-verifier` would: re-run the actual test/build command
from a clean state yourself, don't accept "it should work" or a stale log as evidence,
and call out anything unverifiable instead of rounding it up to a pass.
