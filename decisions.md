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

## ADR-0017: Open work lives in one roadmap; the option space is reference

- Date: 2026-09-20
- Status: accepted
- Context: `tasks.md`, `cleanup.md`, and `divergence-by-part.md` each tracked
  status, so a claimed divergence bullet was stated twice and the copies
  drifted. Five entries were stale on `main` at `ff774c2`, including a task
  PR #70 had already done.
- Decision: `improvements/roadmap.md` holds every open item and is the only
  place a claim or a checkbox lives. `improvements/reference.md` holds the
  option space, the measured divergence, and the names table, and names a
  roadmap item instead of repeating its tasks. `docs/review-research.md` holds
  the review evidence moved out of the v2 playbook.
- Consequences: a claim is recorded once. `lint-standards.py` skips the
  research file by name, because it quotes its sources verbatim.

## ADR-0018: `divergence-renamer` owns a name cited in more than one file

- Date: 2026-09-20
- Status: accepted
- Context: `prose-rephraser` freezes every path and identifier in the one file
  it edits; `script-refactorer` freezes every behavior in the one script it
  edits. Neither can move a name that other files cite, so G-30's rename of
  `references/superpowers-bridge.md`, cited by two validators, a test
  fixture, and 16 files, had no agent to run it.
- Decision: a fourth rewrite agent, `divergence-renamer`, takes an old name
  and a new one, finds every citation repository-wide, classifies each as
  current state or historical record, and moves only the current ones.
  `divergence-auditor` still measures and runs the guards afterward.
- Consequences: a rename with a stated old and new value has a dispatch
  target. `improvements/reference.md`'s Names table cites it for G-30.

## ADR-0019: A missing template resolver stops the command; it has no fallback

- Date: 2026-09-20
- Status: accepted
- Context: G-24 repointed `commands/tasks.md` and five `SKILL.md` steps at
  spec-kit's `resolve-template` script. T242 specified reading
  `.specify/templates/<name>.md` when the resolver is absent, citing
  constraint 2 in `improvements/reference.md`.
- Decision: no fallback. The command stops and reports. Constraint 2 scopes to
  superpowers skills, not to spec-kit's own scripts, and
  `requires.speckit_version: ">=0.16.2"` is enforced at install:
  `install_from_directory` calls `check_compatibility`, which raises
  `CompatibilityError`. Spec-kit 0.16.2 is the first release carrying all three
  resolver variants and the priority-3 layer.
- Consequences: the raised floor replaces the fallback. Reading the raw path
  returns only the core layer and drops this fork's sections, which is the bug
  G-24 fixed. T242's fallback clause is superseded.

## ADR-0020: The extension id stays `specflow`

- Date: 2026-09-20
- Status: accepted
- Context: G-28 settles what a spec-kit catalog entry says. The community
  catalog lists `superpowers-bridge`, `speckit-superpowers-bridge`, and
  `superspec`, so `specflow` collides with no listed id.
  `improvements/reference.md` prices a rename at 27 files and calls it not an
  option.
- Decision: the id stays. Namespace lock-step ties it to all five command
  names and all three hook names, so a rename renames every command a user has
  typed and every line in an installed `.specify/extensions.yml`. The
  description separates specflow from the other three instead.
- Consequences: the catalog submission uses `specflow` and does not reopen the
  question. A later rename needs a major version bump and a migration note.

## ADR-0021: The five templates stay extension templates, not a preset

- Date: 2026-09-20
- Status: accepted
- Context: G-25 asks whether the templates move from priority 3, where an
  extension template always replaces core, to priority 2, where a preset may
  `append` to it. `resolve_template_content` in spec-kit's
  `scripts/python/common.py` composes both layers.
- Decision: they stay. Append only adds at the end, and all five templates
  change core lines it cannot reach: 13 in the constitution, 150 in tasks.
  Core's file would ship verbatim under the addendum, carrying two
  `[NEEDS CLARIFICATION]` markers, five emoji, and a second execution
  strategy. A preset also carries no hooks and installs from its own catalog,
  so the extension stays either way.
- Consequences: a core template improvement reaches this fork only when
  someone ports it. Backlog item 25 reports that drift.

## ADR-0022: The gates stay under `.claude/`; the `events:` block waits

- Date: 2026-09-20
- Status: superseded in part by ADR-0027, which clears both unknowns
- Context: G-26 asked whether spec-kit's `events:` block should register this
  repository's four gates so they run on the Copilot CLI. An `events:` entry
  names a command, not a script: the dispatcher reads that command's
  frontmatter `scripts:` block. Our five command files carry no frontmatter, so
  a block added today is a silent no-op. Pointing a command's script at
  `../../../.claude/hooks/` resolves in this checkout and returns 0 wherever
  `.claude/` is absent, which is every catalog install.
- Decision: keep the gates under `.claude/` per ADR-0001 and ship no `events:`
  block. Shipping them under `specflow/` is the only route that works, and it
  is blocked on two unknowns: Copilot's tool-payload field names are recorded
  nowhere, and a wrong key yields a gate that passes everything; and the gates
  need `jq` at install time.
- Consequences: G-26 keeps T262 and T263 open behind those prerequisites. A
  gate that cannot be shown to fire is worse than no gate.

## ADR-0023: `progress.yml` status holds `complete`, not `done`

- Date: 2026-09-20
- Status: accepted
- Context: `workflow-guide.md`'s "Writing `progress.yml`" table and
  `SKILL.md` told an agent to write `done`; both goldens wrote `complete`.
  Nothing compares a status against `done`. Two shipped readers compare
  against `complete`: `artifact-lint.sh` greps `TNNN: complete`, and
  `validate-progress.py` collects a task whose state is `complete`.
- Decision: the vocabulary is `pending`, `in_progress`, `complete`,
  `skipped`, for the top-level, phase, and task status alike. `done` is
  dropped because the readers pick the winner, not the older document.
  `manual-browser-only` is a reason, not a state; the golden's task lines
  already carry the reason, so those five tasks become `skipped`.
- Consequences: `validate-progress.py` enumerates the four values, so a
  sixth reason word is rejected on write instead of stored.

## ADR-0024: The first tag is 1.1.0, and the floor raise is minor this once

- Date: 2026-09-20
- Status: accepted
- Context: the `[Unreleased]` set holds two changed Process steps, which
  `CHANGELOG.md`'s rule calls minor, and a rename that moves `extension.name`
  and the descriptions rather than an id, command or file. Raising
  `requires.speckit_version` to `>=0.16.2` is the one entry that rule does not
  classify: spec-kit refuses the install below that floor, so the break lands
  on the host, not on a citing project.
- Decision: the first tag is `v1.1.0`. A floor raise counts as minor while no
  id, command, hook or file is renamed with it. The next floor raise is major.
- Consequences: the version question leaves `open-questions.md`.
  `extension.yml` carries `1.1.0` and every `[Unreleased]` entry moves under
  that heading. A later floor raise needs a major bump and a migration note.

## ADR-0025: The gate scripts ship under `specflow/gates/`

- Date: 2026-09-20
- Status: accepted, amends ADR-0001 for four scripts
- Context: `.claude/` is export-ignored, so a catalog install carries no gate
  and the Copilot CLI runs none. The claim that execute refuses to start
  without `.analyzed` then rests on prose alone.
- Decision: `risk-classifier.sh`, `merge-gate.sh`, `validate-findings.py`, and
  `validate-progress.py` move to `specflow/gates/`, which no `export-ignore`
  rule strips, beside the new `write-marker.sh`. `provides.scripts` declares
  all five. A two-line script under `.claude/` execs each shipped bash copy, so
  `settings.json`, `merge-gate.yml`, and the hook tests keep their paths. Every
  other hook stays under `.claude/` per ADR-0001.
- Consequences: `validate-release-archive.py` expects `gates/` in the archive.
  The `shellcheck` and `ruff` steps in `ci.yml` still name only the old paths.

## ADR-0026: `verify.sh` states the tool versions it does not match

- Date: 2026-09-20
- Status: accepted
- Context: `verify.sh` runs the commands `ci.yml` runs, and
  `tests/test_ci_parity.py` holds the two together. Neither pins a tool
  version: `ci.yml` takes the shellcheck the runner image carries, and
  `requirements-dev.txt` floors ruff at 0.14. Local shellcheck 0.11.0 lacks
  SC2218, so `verify.sh` reported clean while CI failed, and main was red for
  three pushes.
- Decision: state the limit instead of pinning. The header comment names both
  unpinned tools, and each run prints the local shellcheck and ruff versions
  before the steps that call them.
- Consequences: the gap is visible on every run rather than learned from a red
  main. A check the CI build implements and the local build lacks still passes
  here. Pinning stays open at the cost of an install step per contributor.

## ADR-0027: A shipped gate checks for `jq` before it calls it

- Date: 2026-09-20
- Status: accepted, supersedes ADR-0022's "blocked on two unknowns" clause
- Context: both unknowns cleared. ADR-0025 gave a gate a home under
  `specflow/gates/`, which no `export-ignore` rule strips, so a catalog
  install carries it. `docs/agent-event-mapping.md` records Copilot's
  `toolName`, `toolArgs.command`, and `toolArgs.path`, read from GitHub's
  hooks reference and `@github/copilot` 1.0.86. The third prerequisite held:
  `merge-gate.sh` ships and calls `jq` with no check, so a project without
  `jq` reads "does not parse as a findings document" instead of the cause.
- Decision: a shipped bash gate that calls `jq` checks for it first and, when
  it is absent, names the install command and exits 1.
- Consequences: `jq` is an install-time dependency no manifest field
  declares, so the gate states it. The `events:` block still waits on a
  shipped script that reads a hook payload: `speckit.specflow.gate` resolves
  through its frontmatter to `write-marker.sh`, which exits 2 with no
  argument, so registering it on `pre_tool_use` blocks every Bash call.

## ADR-0028: Sample content inside a shipped template is rewritten, not frozen

- Date: 2026-09-21
- Status: accepted, supersedes the sample-content clause of `bd75111`
- Context: `constitution-template.md` carried upstream's five principle
  examples verbatim, kept in `bd75111` on the grounds that an example is
  sample content. ADR-0015 freezes a `[NEEDS CLARIFICATION]` marker on an
  example line, which reads as the same rule.
- Decision: a marker is frozen because a validator greps it; prose is not. An
  example is the text a reader imitates, so it follows
  `standards/documentation.md` like any other prose. Each example keeps its
  concept, its identifiers, and its bracket placeholders.
- Consequences: ADR-0015 scopes to markers alone. A template's example prose
  is in scope for `prose-rephraser`; its placeholders and markers are not.

## ADR-0029: The whole-change-set review writes gate-readable findings

- Date: 2026-09-21
- Status: accepted
- Context: `bdd-orchestrator` reads `code-reviewer`'s phase 11 result, but the
  merge gate reads JSON files. Prose findings never reached the gate.
- Decision: `code-reviewer` returns one object matching
  `specflow/references/findings-schema.json` and writes the same object to
  `.claude/review/code-reviewer.json`. `bdd-orchestrator` reads the returned
  object. The merge gate reads the file and blocks on unresolved Critical or
  Important findings.
- Consequences: phase 11 keeps its direct result, and its blocking findings
  now join the other reviewer findings at the merge gate.

## ADR-0030: "bridge" stays out of the mechanical banned-word table

- Date: 2026-09-22
- Status: accepted
- Context: T493 asked whether "bridge" joins `standards/documentation.md`'s
  banned table, now that G-49 T492 makes the check match "bridges" and
  "bridging" too. Every current occurrence outside the excluded directories is
  a literal citation of the product's old name: `superpowers-bridge.md`
  (renamed under G-30), the `superpowers-bridge` catalog id ADR-0020 kept out
  of, and `CHANGELOG.md` entries recording "Superpowers Bridge" as what the
  extension used to be listed as. None is the metaphorical use
  `standards/documentation.md`'s "No metaphor" bullet already bans in prose.
  `table_rows` drops a qualified entry such as "bridge (as metaphor)" from the
  mechanical check by design, and the banned-word rule has no per-entry
  exclusion file the way the word-choice rule does, so a plain entry would
  flag every historically accurate citation in `decisions.md` and
  `CHANGELOG.md`.
- Decision: leave "bridge" out of the table. The "No metaphor" bullet stays
  the enforcement for a live metaphorical use; a reviewer applies it by
  reading, the way `AGENTS.md` and `reference.md`'s stale rows were fixed
  before G-49 existed.
- Consequences: a future metaphorical "bridge" in prose is caught by review,
  not by `lint-standards.py`. Revisit if the banned-word rule gains a
  per-entry exclusion file, the mechanism T492's "bridging" fix did not need.

## ADR-0031: Copilot CLI hooks live under `.github/hooks/`, not `.claude/`

- Date: 2026-09-25
- Status: accepted
- Context: G-26's `events:` route stays blocked (ADR-0022). G-54 takes a
  second route: Copilot's own hook loader, confirmed at
  `docs.github.com/en/copilot/reference/hooks-reference` to read
  `.github/hooks/*.json` directly, no spec-kit dispatcher involved.
  `.github/hooks/hooks.json` registers `block-main-commit.sh` under
  `preToolUse`; `test-gate.sh` and `artifact-lint.sh` under `postToolUse`, the
  event each already declares in its own header comment and in
  `docs/agent-event-mapping.md`'s table (the G-54 task text grouped
  `test-gate.sh` with `preToolUse` instead; both sources contradict that
  grouping, so it is not followed); and `session-start.sh` under
  `sessionStart`. Each entry carries a `bash` and a `powershell` command; the
  `powershell` form shells out to the same `bash` command, since no script
  here has a native PowerShell port.
- Decision: the four scripts stay under `.claude/hooks/` (ADR-0001), unmoved
  and unduplicated. `.github/hooks/adapter.sh` reads the Copilot payload on
  stdin, builds `{tool_input: {command, file_path}}` from `toolArgs.command`
  and `toolArgs.path` per `docs/agent-event-mapping.md`'s table, and runs the
  named gate against it. On exit 2 it prints a `preToolUse` deny
  (`permissionDecision`, `permissionDecisionReason`) or, for a `postToolUse`
  gate, `additionalContext`, since Copilot's contract has no post-hoc deny. No
  entry declares a `matcher`: Copilot's literal tool-name strings are
  unconfirmed, and each gate already treats an absent field as no match.
- Consequences: two hook directories now exist, one per target surface. A
  future gate script needs an adapter call added to both
  `.claude/settings.json` and `hooks.json`.

## ADR-0032: A headless e2e stage runs on a shell allowlist and answers itself

- Date: 2026-09-27
- Status: accepted
- Context: the G-19 live run found three gaps in `e2e-agent-claude.sh`.
  `acceptEdits` approves no shell command, so `/speckit.plan` waited on
  `setup-plan.sh`. Brainstorm and execute wait for a user `claude -p` lacks.
  An unpinned run put two stages on Haiku, which read core's spec template and
  dropped this fork's sections. Outside CI a `claude` login replaces
  `ANTHROPIC_API_KEY`.
- Decision: `invoke_agent` passes an `--allowedTools` list, not
  `bypassPermissions`, so a stage cannot run a command outside it. The stage 3
  and stage 6 prompts state that no user answers. `E2E_MODEL` pins the model.
- Consequences: a stage that needs a new command stops on approval until the
  list grows. The command contracts stay interactive.
