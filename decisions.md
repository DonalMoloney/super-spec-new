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

## ADR-0006: A finding clears the merge gate only when fixed or rebutted

- Date: 2026-09-11
- Status: accepted
- Context: the findings schema allows five statuses across three severities. The
  Part 4.9 draft blocks only on `open`, so flipping a Critical to `rejected` clears
  the gate with no code change and no argument on record.
- Decision: block every Critical and Important finding until its status is `fixed`
  or `rebutted`. `open`, `accepted`, and `rejected` block, because none of them
  changes the code or records a counter-argument. A missing status reads as `open`,
  the schema default. Minor never blocks. A rebuttal clears any severity, Critical
  included: the gate checks that a finding was handled, and the critic stage judges
  whether the handling holds, filing its own open finding when it does not.
- Consequences: the gate stays a mechanical check. Without a critic stage an author
  can clear a Critical by writing a rebuttal; `risk-classifier.sh` decides when the
  critic stage runs.

## ADR-0007: A task keeps its ID when the outcome matches, not the text or the position

- Date: 2026-09-11
- Status: accepted
- Context: regenerating `tasks.md` after a spec change has to decide which
  regenerated task is the old one. Matching on task text loses the ID on any
  reword. Matching on list position renumbers every task after an insertion,
  which is the failure the stable IDs exist to prevent.
- Decision: identity is the outcome a task names. A regenerated task keeps the
  ID of the existing task with the same outcome, whatever the wording or the
  position. IDs are append-only: a new task takes the next ID above the highest
  ever used, and a retired ID is never handed to a different task.
- Consequences: matching is a judgment the command makes, so the diff summary
  in ADR-0005 is what makes it reviewable. Append-only allocation leaves gaps in
  the numbering, which is the cost of never invalidating `progress.yml`.

## ADR-0008: The tasks diff summary always prints and blocks only on a completed ID

- Date: 2026-09-11
- Status: accepted
- Context: `/speckit.specflow.tasks` prints added, removed, and renumbered IDs
  before writing. Blocking every regeneration on a confirmation prompt stalls
  the automated pipeline; blocking on nothing lets a destructive regeneration
  through unseen.
- Decision: print the summary on every regeneration. Stop for confirmation only
  when a removed or renumbered ID is one that `progress.yml` records as
  complete, because that is the only change that destroys recorded work.
  Additions, removals of unstarted tasks, and reordering write without a prompt.
- Consequences: the common regeneration stays unattended. The destructive case
  needs a human. `artifact-lint.sh` catches the same case after the write, so a
  regeneration that skips the prompt still fails the gate.

## ADR-0009: The `## Traceability` table keeps three columns; `score-artifacts.py` needed no change

- Date: 2026-09-11
- Status: accepted
- Context: `open-questions.md` flagged a shape conflict between G-13's scorer
  (which read a two-column golden table: criterion ID, trace target) and G-10's
  `spec-template.md`, which specifies three columns: `Criterion ID`, `Test name`,
  `Status`.
- Decision: keep three columns. `score-artifacts.py`'s `traced_criteria` reads
  `cells[0]` as the criterion ID and `cells[1]` as the trace target, and ignores
  any cell beyond that. In the three-column shape, `cells[1]` is `Test name`,
  the same trace target the two-column shape held in that position, so the
  scorer needed no change. The `Status` column lands in `cells[2]`, unread.
  `specflow/templates/spec-template.md`, `specflow/templates/checklist-template.md`,
  and the `static-landing-page` golden all now use the three-column shape.
- Consequences: `score-artifacts.py` measures whether a criterion has a named
  test, not whether that test currently passes; `Status` is documentation for a
  human reader, not a scorer input. A future scorer dimension that wants to read
  `Status` reads `cells[2]` by table position, since the column has no separate
  parser.

## ADR-0010: `specflow/README.md` drops its Chinese translation

- Date: 2026-09-11
- Status: accepted
- Context: `AGENTS.md`'s Code Review Rules said "keep the English and Chinese
  README changes in sync," while `standards/documentation.md`'s Language rule
  forbids maintaining a translated copy of any document. `specflow/README_zh.md`
  and an inline Chinese section appended to `specflow/README.md` both existed,
  and `.gitattributes` did not export-ignore either, so the archive shipped both.
- Decision: delete `specflow/README_zh.md` and the inline Chinese section.
  `specflow/README.md` is the one canonical file. `standards/documentation.md`'s
  Language rule wins over the narrower Code Review Rule, which now points to it
  instead of restating a conflicting instruction.
- Consequences: a future README edit touches one file, not two, and cannot drift
  out of sync. Chinese-reading users lose a translated copy; none is planned as
  a replacement.
