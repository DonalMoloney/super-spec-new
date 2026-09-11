@AGENTS.md

## Claude Code specifics

- A `.claude/agents/` squad (`bdd-orchestrator` + 16 phase agents) exists for driving
  a single feature task through a full BDD lifecycle — Gherkin scenarios → step defs →
  RED → task decomposition (`task-decomposer`) → GREEN → REFACTOR → review → docs →
  adversarial verification (`work-verifier`). Use `bdd-orchestrator` as the entry
  point; it dispatches the rest in order. Don't invoke the phase agents standalone
  unless the user explicitly asks for just one phase.
- `work-verifier` also stands alone: dispatch it any time a completion claim (yours,
  another agent's, or a prior session's) needs independent, adversarial re-checking
  before it's trusted — not only inside the BDD pipeline.
- Follow `superpowers:test-driven-development` for any code task that ISN'T routed
  through the BDD squad above.
- Before editing a command file under `specflow/commands/`, read its current Process
  steps in full — these are behavior contracts other tooling (`e2e-smoke.sh`,
  `e2e-agent-claude.sh`) asserts against structurally.
