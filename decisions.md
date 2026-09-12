# Decisions (ADR-lite)

Append one entry per non-obvious decision. Mark superseded entries rather than
deleting them; prune anything older than a quarter that no longer guides work.

## ADR-0001: Claude Code hooks live in `.claude/hooks/`, not `.specify/scripts/hooks/`

- Date: 2026-09-11
- Status: accepted
- Context: this repo is the extension and has no `.specify/`.
- Decision: harness-specific hooks and `settings.json` live under `.claude/`;
  `specflow/` stays harness-neutral runtime payload.
- Consequences: hooks under `.claude/` are outside the spec-kit `git archive`,
  so a consuming project copies them by hand.

## ADR-0002: Quality standards live in `standards/`, not `.claude/rules/` or agent prompts

- Date: 2026-09-11
- Status: accepted
- Context: `.claude/rules/` is Claude-only, and 17 pasted copies drift.
- Decision: three harness-neutral files under `standards/`. `CLAUDE.md`
  imports them, `AGENTS.md` links them, and `bdd-orchestrator` passes the
  relevant path on each dispatch.
- Consequences: a rule change is one edit. `standards/` is not in the archive.

## ADR-0003: Route subagents by judgment and execution cost

- Date: 2026-09-11
- Status: accepted
- Context: 17 agents inherited one model.
- Decision: `opus`: `bdd-orchestrator`, `requirements-analyst`,
  `scenario-critic`, `spec-alignment-auditor`, `work-verifier`, `code-reviewer`.
  `sonnet`: `gherkin-writer`, `step-definition-scaffolder`, `task-decomposer`,
  `implementation-engineer`, `refactor-specialist`, `unit-test-augmenter`.
  `haiku`: `red-phase-verifier`, `green-phase-verifier`, `regression-runner`,
  `documentation-scribe`, `release-reporter`.
- Consequences: routing names model families; cost savings are unmeasured.

## ADR-0004: The main-commit gate evaluates the landing branch, not HEAD

- Date: 2026-09-11
- Status: accepted
- Context: a PreToolUse hook fires before the command runs, so HEAD is the
  wrong branch.
- Decision: `block-main-commit.sh` splits the command on `&&`, `||`, `;`, and
  `|`, tracks the branch each `switch` or `checkout` leaves behind, and judges
  a commit against it. Only a segment starting with `git <subcommand>` counts,
  so prose quoting git does not steer the gate. A move it cannot name, such as
  `git switch -`, blocks.
- Consequences: a switch inside a conditional goes unseen, which errs toward
  blocking.

## ADR-0005: `risk-classifier.sh` scores with integer counts, not `bc`

- Date: 2026-09-11
- Status: accepted
- Context: macOS bash 3.2 has no floating point; `bc` is not guaranteed.
- Decision: sum `git diff --numstat` per-file counts in `$(( ))` against 400
  lines and 15 files. A binary file counts as a file with no lines.
- Consequences: a ratio rule compares two integer products, never a decimal.

## ADR-0006: A finding clears the merge gate only when fixed or rebutted

- Date: 2026-09-11
- Status: accepted
- Context: blocking only on `open` let a Critical flip to `rejected` unfixed.
- Decision: a Critical or Important finding blocks unless its status is `fixed`
  or `rebutted`; `accepted` and a missing status block too. Minor never
  blocks. A rebuttal clears any severity; the critic stage judges whether it
  holds.
- Consequences: `risk-classifier.sh` decides when the critic stage runs.

## ADR-0010: `specflow/README.md` drops its Chinese translation

- Date: 2026-09-11
- Status: accepted
- Context: `README_zh.md` and an inline Chinese section broke the Language rule
  in `standards/documentation.md`.
- Decision: delete both; `specflow/README.md` is canonical.
- Consequences: a README edit touches one file. No translation is planned.

## ADR-0011: The T153 dry run overrides the differential-implementation trigger

- Date: 2026-09-11
- Status: accepted
- Context: the trigger needs `HIGH` risk or more than three open questions;
  the golden meets neither.
- Decision: T153 runs the protocol on the golden anyway, checking its steps,
  not the trigger.
- Consequences: a real feature still follows the trigger; PR #50 records the
  divergences.

## ADR-0012: A CI finding is rebutted by a PR label, not by editing the findings file

- Date: 2026-09-11
- Status: accepted, amends ADR-0006
- Context: `.claude/review/headless-ci.json` is gitignored, so its status
  cannot be committed.
- Decision: the `findings-rebutted` label is the rebuttal: the workflow runs
  `rebut-findings.sh` before the gate, marking every finding `rebutted`, and
  reruns on `labeled` and `unlabeled`. The rebuttal text lives in the PR
  description. Committed findings files keep the per-finding status path.
- Consequences: the label clears the whole document; a partial rebuttal still
  needs the code fixed.

## ADR-0013: A rewrite for divergence changes prose and structure, never the contract

- Date: 2026-09-11
- Status: accepted
- Context: `e2e-smoke.sh`, both validators, and the hook tests grep headings
  and step counts.
- Decision: `prose-rephraser` and `script-refactorer` take one file each and
  keep headings, numbered
  steps, code blocks, paths, markers, exit codes, and output lines verbatim;
  `divergence-auditor` measures and runs every guard.
- Consequences: a rewrite never adds or removes a step.

## ADR-0014: Panel personas run one model class below the judgment agents

- Date: 2026-09-11
- Status: accepted, amends ADR-0003
- Context: eight reviewers landed after ADR-0003 with mixed models.
- Decision: final-verdict agents run on opus: `critic`, `security-reviewer`,
  `threat-model-reviewer`, `spec-red-team-reviewer`, and the ADR-0003 list.
  Stage 2 panel personas (`conformance-reviewer`, `correctness-reviewer`,
  `maintainability-reviewer`, `performance-reviewer`) run on sonnet because
  `critic` reviews their review. Mechanical runners and the divergence
  measurer stay on haiku.
- Consequences: a new reviewer picks its class by whether another agent checks
  its output.

## ADR-0015: A template placeholder is not an unresolved marker

- Date: 2026-09-11
- Status: accepted
- Context: `spec-template.md` teaches `[NEEDS CLARIFICATION]` on its FR-006
  example line.
- Decision: the Code Review Rule applies to a filled artifact, which
  `artifact-lint.sh` blocks once `.clarified` exists. A marker on an example
  line of a shipped template stays.
- Consequences: a marker on any other template line is still rejected.

## ADR-0016: The compound-task lint is blunt by design

- Date: 2026-09-11
- Status: accepted
- Context: `artifact-lint.sh` rejects a `tasks.md` line with a whole-word "and"
  outside backticks.
- Decision: keep the rule; a false positive costs one reword, a false negative
  lets a bundled task through.
- Consequences: an enumeration in a task line is a comma list without "and". A
  task that needs "and" is split.
