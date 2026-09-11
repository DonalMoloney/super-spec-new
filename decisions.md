# Decisions (ADR-lite)

Append one entry per non-obvious decision. Mark superseded entries rather than
deleting them; prune anything older than a quarter that no longer guides work.

## ADR-0001: Claude Code hooks live in `.claude/hooks/`, not `.specify/scripts/hooks/`

- Date: 2026-09-11
- Status: accepted
- Context: the v2 playbook (`imporvements/imporvements2.md` Part 4) places gate
  hooks in `.specify/scripts/hooks/`, which assumes a consuming spec-kit project.
  This repo is the extension itself and has no `.specify/` directory.
- Decision: harness-specific hooks and `settings.json` live under `.claude/`;
  `specflow/` stays harness-neutral runtime payload.
- Consequences: hooks are not part of the `git archive` spec-kit installs, so a
  consuming project copies them deliberately. `specflow/` stays free of
  Claude-only files, which keeps the Copilot CLI target unaffected.

## ADR-0002: Quality standards live in `standards/`, not `.claude/rules/` or agent prompts

- Date: 2026-09-11
- Status: accepted
- Context: subagents need one source of truth for how code, documentation, and
  presentations are produced. `.claude/rules/` is read only by Claude Code, and
  pasting rules into 17 agent prompts duplicates text that drifts.
- Decision: three harness-neutral files under `standards/`. `CLAUDE.md` imports
  them so every Claude subagent has them in context; `AGENTS.md` links them for
  the Copilot CLI; `bdd-orchestrator` passes the relevant path on each dispatch.
- Consequences: a rule change is one edit. `standards/` is documentation for this
  repo, not runtime payload, so it is not part of the spec-kit archive.

## ADR-0003: Route subagents by judgment and execution cost

- Date: 2026-09-11
- Status: accepted

Context: all 17 agents inherit the session model despite different responsibilities.
Decision: reviewers and verifiers get the strongest model; mechanical runners get
the cheapest. This rule applies to final judgment; red/green phase checks are
mechanical. Assign `opus` to `bdd-orchestrator`, `requirements-analyst`,
`scenario-critic`, `spec-alignment-auditor`, `work-verifier`, and `code-reviewer`.
Assign `sonnet` to `gherkin-writer`, `step-definition-scaffolder`, `task-decomposer`,
`implementation-engineer`, `refactor-specialist`, and `unit-test-augmenter`.
Assign `haiku` to `red-phase-verifier`, `green-phase-verifier`, `regression-runner`,
`documentation-scribe`, and `release-reporter`. Consequences: routing uses explicit
model families; alias versions can change. Actual cost savings remain unmeasured.

## ADR-0004: The main-commit gate evaluates the landing branch, not HEAD

- Date: 2026-09-11
- Status: accepted
- Context: `block-main-commit.sh` read `git rev-parse --abbrev-ref HEAD` at
  PreToolUse time. A PreToolUse hook fires before the command runs, so that
  reading answers the wrong question. `git switch -c feat && git commit` was
  blocked on main, and `git switch main && git commit` was allowed from a
  feature branch.
- Decision: split the command on `&&`, `||`, `;`, and `|`, walk the segments in
  execution order, and track the branch each `switch` or `checkout` leaves
  behind. Evaluate that branch when a segment commits. A segment counts as a
  command only when it starts with `git <subcommand>`, so prose quoting git does
  not steer the gate. A segment that moves HEAD somewhere the gate cannot name,
  such as `git switch -`, blocks.
- Consequences: the gate now blocks a commit it used to allow. It reads the
  command text, not the shell's parse, so a switch written inside a conditional
  or a function body goes unseen and the commit is judged against the branch at
  hook time. That direction blocks rather than allows.

## ADR-0005: `risk-classifier.sh` scores with integer counts, not `bc`

- Date: 2026-09-11
- Status: accepted
- Context: the Part 4.10 draft pipes `git diff --shortstat` through `bc` to add
  insertions and deletions. macOS ships bash 3.2, which has no floating-point
  arithmetic, and `bc` is absent from a bare shell.
- Decision: the classifier reads `git diff --numstat` and sums the per-file counts
  in `$(( ))`. Changed lines and changed files are both whole numbers, and both
  thresholds (400 lines, 15 files) are whole numbers, so no fractional score exists
  to lose precision on. A binary file reports a dash in numstat; it counts as a file
  and contributes no lines.
- Consequences: the script needs only git and bash. A later rule that wants a ratio
  must compare two integer products, such as `a * 100 -gt b * 30`, never a decimal.
