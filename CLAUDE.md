@AGENTS.md
@decisions.md
@open-questions.md
@standards/code.md
@standards/documentation.md
@standards/presentations.md

## Claude Code specifics

### The BDD squad

A `.claude/agents/` squad (`bdd-orchestrator` + 16 phase agents) exists for driving
a single feature task through a full BDD lifecycle: Gherkin scenarios → step defs →
RED → task decomposition (`task-decomposer`) → GREEN → REFACTOR → review → docs →
adversarial verification (`work-verifier`).

**Dispatch patterns:**
- Use `bdd-orchestrator` as the entry point; it dispatches the rest in sequence.
  Don't invoke the phase agents standalone unless the user explicitly asks for one phase.
- `work-verifier` also stands alone: dispatch it any time a completion claim (yours,
  another agent's, or a prior session's) needs independent, adversarial re-checking
  before it's trusted, not only inside the BDD pipeline.
- Follow `superpowers:test-driven-development` for any code task that ISN'T routed
  through the BDD squad. That skill covers RED-GREEN-REFACTOR for a single test or
  scenario; the squad covers end-to-end feature delivery.

**Related squad:**
- `prose-rephraser`, `script-refactorer`, `divergence-renamer`, and `divergence-auditor`
  rewrite one shipped file under `specflow/` to `standards/` and measure the result
  against upstream. The open option and the measured divergence per file live in
  `improvements/roadmap.md`.

### Before editing command or template files

Before editing a command file under `specflow/commands/`, read its current Process
steps in full. These are behavior contracts other tooling (`e2e-smoke.sh`,
`e2e-agent-claude.sh`) asserts against structurally. A changed step breaks the contract
and stops CI. Similarly, before editing a template under `specflow/templates/`, read
the whole file first and check whether your change affects output that downstream
tooling or validators grep for.

### Memory and standards

Memory layer: `decisions.md` (ADR-lite) and `open-questions.md` are imported
above, so they are in context every session. Record a non-obvious choice as an
ADR when you make it; add a question when you find one you can't resolve.
Keep both files short: context is a finite attention budget, and recall
degrades as it grows. Prefer deleting resolved items over archiving them.

### Presentation and readiness

Ignore `presentation/` when researching whether the project is ready to be
used or shipped. It holds slide decks and diagrams, not runtime payload or
its tests; its state says nothing about the extension's readiness.
