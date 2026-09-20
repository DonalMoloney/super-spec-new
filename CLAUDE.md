@AGENTS.md
@decisions.md
@open-questions.md
@standards/code.md
@standards/documentation.md
@standards/presentations.md

## Claude Code specifics

- A `.claude/agents/` squad (`bdd-orchestrator` + 16 phase agents) exists for driving
  a single feature task through a full BDD lifecycle: Gherkin scenarios → step defs →
  RED → task decomposition (`task-decomposer`) → GREEN → REFACTOR → review → docs →
  adversarial verification (`work-verifier`). Use `bdd-orchestrator` as the entry
  point; it dispatches the rest in order. Don't invoke the phase agents standalone
  unless the user explicitly asks for one phase.
- `work-verifier` also stands alone: dispatch it any time a completion claim (yours,
  another agent's, or a prior session's) needs independent, adversarial re-checking
  before it's trusted, not only inside the BDD pipeline.
- `prose-rephraser`, `script-refactorer`, and `divergence-auditor` rewrite one shipped
  file under `specflow/` to `standards/` and measure the result against upstream. The
  file table and dispatch order live in `imporvements/reference.md`.
- Follow `superpowers:test-driven-development` for any code task that ISN'T routed
  through the BDD squad above.
- Before editing a command file under `specflow/commands/`, read its current Process
  steps in full. These are behavior contracts other tooling (`e2e-smoke.sh`,
  `e2e-agent-claude.sh`) asserts against structurally.
- Memory layer: `decisions.md` (ADR-lite) and `open-questions.md` are imported
  above, so they are in context every session. Record a non-obvious choice as an
  ADR when you make it; add a question when you find one you can't resolve.
  Keep both files short: context is a finite attention budget, and recall
  degrades as it grows. Prefer deleting resolved items over archiving them.
