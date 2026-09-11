# Roadmap task groups

Derived from `imporvements2.md` Part 2 (items 1–22), Part 4 (implementation kit),
and Part 8 (30-60-90). Items already merged (PR template, item 2, item 13, item 4)
are omitted; see the Progress checklist at the top of `imporvements2.md`.

## How to use this file

- **One group = one git worktree = one PR.** Groups are independent of each other
  unless a `Depends on:` line says otherwise. Work them in any order.
- Tasks inside a group are sequential. Each task is singular and has a `Verify:`
  line that proves it is done. Task IDs are `T<group><n>`, so `T011` is
  group 01 task 1; tick the box when its Verify line passes.
- Every group names two executors. Pick one per group; do not run both on the
  same worktree.
  - **Claude**: the `.claude/agents/` subagent (or built-in agent type) to dispatch
    from Claude Code.
  - **Codex**: how to hand the same group to Codex. Codex is an *executor* only;
    nothing Codex-specific is added to `specflow/` (AGENTS.md target-surface rule).
- After merge: remove the worktree, tick the item in the `imporvements2.md`
  Progress checklist, and record any non-obvious choice in `decisions.md`.
- Paths follow ADR-0001 (hooks under `.claude/hooks/`, not `.specify/scripts/hooks/`)
  and ADR-0002 (quality rules under `standards/`).

## Executor legend

| Label | What it is | When to use |
|---|---|---|
| `bdd-orchestrator` | Full BDD squad, 16 phases, ends with `work-verifier` | Any group that adds or changes a script, hook, or CI job (behavior that can be tested) |
| `general-purpose` | Single Claude agent, all tools | Doc, template, and frontmatter edits with no runnable test beyond the validate scripts |
| `documentation-scribe` | README / CHANGELOG / guide updates | Trailing docs task in a group |
| `work-verifier` | Adversarial re-check of a completion claim | Final step of every group before opening the PR |
| `code-reviewer` | Review the diff of a finished group | Pre-PR review when `bdd-orchestrator` was not used |
| `claude-code-guide` | Looks up current Claude Code hook / flag / frontmatter facts | Any step marked *verify against current docs* |
| `codex:codex-rescue` | Claude Code subagent that forwards one write-capable `task` to the Codex companion runtime (`--write`, prefer `--background` for multi-step groups) | Codex implementation of a group |
| `codex review --base main` | Codex CLI cross-model review of the worktree diff (run from the shell, read-only) | Codex review of any group, and the cross-vendor stage in G-06 / G-15 |
| `codex exec "<prompt>"` | Headless Codex run without the plugin | Only when the plugin runtime is unavailable |

Rule for Codex handoffs: the prompt text is the group's task list below, pasted
verbatim, plus `Read AGENTS.md, decisions.md, standards/code.md first.` Model and
effort flags stay unset unless the group says otherwise.

---

## G-01 — Repair the two known `main` failures

Source: `open-questions.md` (both items). Effort: low. Depends on: none.
Claude: `bdd-orchestrator` (the fix is script behavior; hook tests exist as a pattern).
Model: `bdd-orchestrator` runs `opus`.
Codex: `codex:codex-rescue --wait` with the two tasks below; then `codex review --base main`.

- [x] T011 Scope the namespace regex to the `commands:` block

1. Read `specflow/scripts/validate-extension-metadata.py` and find the `^    - name:` regex.
2. Write a failing test: a minimal `extension.yml` with a `provides.templates` entry named `constitution-template` must pass validation. Put it in `specflow/scripts/tests/test_validate_extension_metadata.py` (create the dir).
3. Change the parser so only names under `provides.commands` and `provides.hooks` are namespace-checked.
4. Run the test and the script on the real `extension.yml`.

Verify: `cd specflow && python3 scripts/validate-extension-metadata.py` exits 0 and the new test passes.

- [x] T012 Make `e2e-smoke.sh` work with current spec-kit

1. Read `specflow/scripts/e2e-smoke.sh` and locate the `specify init ... --no-git` call.
2. Run `uvx --from git+https://github.com/github/spec-kit.git specify init --help` and confirm which git flag exists today.
3. Replace `--no-git` with the current flag, or drop it and run `git init` after `specify init` if no equivalent exists.
4. Do not pin a spec-kit ref unless step 2 shows the flag set is unstable; if you pin, record it as an ADR.

Verify: `cd specflow && bash scripts/e2e-smoke.sh` exits 0.

- [x] T013 Close the open questions

1. Delete both resolved items from `open-questions.md`.
2. If T012 pinned a ref, append ADR-0003 to `decisions.md`.

Verify: `open-questions.md` has no unchecked item about these scripts.

---

## G-02 — Item 1: Code Review Rules in the constitution and AGENTS.md (merged: PR #10)

Source: Part 2 item 1, Part 8 days 0–30. Effort: low. Depends on: none.
Claude: `general-purpose`, then `work-verifier`.
Model: `general-purpose` inherits the session model (not routed by ADR-0003); `work-verifier` runs `opus`.
Codex: `codex:codex-rescue`; then `codex review --base main`.

- [x] T021 Add `## Code Review Rules` to the constitution template

1. Read `specflow/templates/constitution-template.md` in full.
2. Append a `## Code Review Rules` section with placeholder bullets for: error-handling convention, test command, forbidden dependencies, security rules, and the two human gates (spec approved, merge approved).
3. Match the existing heading and placeholder style of the template.

Verify: `grep -n '^## Code Review Rules' specflow/templates/constitution-template.md` prints one line.

- [x] T022 Add the same section to root `AGENTS.md`

1. Add `## Code Review Rules` to `AGENTS.md` after `## Standards`.
2. Fill it with this repo's real rules: run both validate scripts, hook tests pass, no `[NEEDS CLARIFICATION]` in shipped templates.
3. Reference `standards/code.md` rather than repeating its content.

Verify: `grep -n '^## Code Review Rules' AGENTS.md` prints one line; `python3 specflow/scripts/validate-extension-metadata.py` still exits 0 (it checks docs alignment).

- [x] T023 Mirror the template change in the README

1. Update `specflow/README.md` where templates are described.

Verify: the README mentions the Code Review Rules section.

---

## G-03 — Item 3: clarify, analyze, and checklist gates (merged: PR #11)

Source: Part 2 item 3. Effort: low. Depends on: none (artifact-lint already checks `NEEDS CLARIFICATION` after a `.clarified` marker).
Claude: `bdd-orchestrator` (adds hook-test cases).
Model: `bdd-orchestrator` runs `opus`.
Codex: `codex:codex-rescue --background`; then `codex review --base main`.

- [x] T031 Define the gate markers

1. Read `specflow/references/workflow-guide.md` and `specflow/commands/hooks/before-execute.md` in full.
2. Add a "Gate markers" subsection to `workflow-guide.md`: `/speckit.clarify` writes `specs/NNN/.clarified`; `/speckit.analyze` writes `specs/NNN/.analyzed` only when it reports zero critical inconsistencies; `/speckit.checklist` output lives at `specs/NNN/checklist-*.md`.

Verify: the subsection exists and names all three markers.

- [x] T032 Make `before-execute.md` require the analyze marker

1. Read the Process steps of `specflow/commands/hooks/before-execute.md` in full (they are asserted structurally by `e2e-smoke.sh`).
2. Add one Process step: stop with a named error if `specs/NNN/.analyzed` is missing.
3. Keep the Input / Output / Process shape unchanged.

Verify: `cd specflow && bash scripts/e2e-smoke.sh` still exits 0 (after G-01) and the step is present.

- [x] T033 Make `execute.md` refuse to start without the analyze marker

1. Read `specflow/commands/execute.md` Process steps in full.
2. Add the same check as the first Process step after the constitution gate.

Verify: `grep -n '.analyzed' specflow/commands/execute.md` prints a line; `E2E_DRY_RUN=1 bash scripts/e2e-agent-claude.sh` exits 0.

- [x] T034 Extend `artifact-lint.sh` for the checklist file

1. Add a case for `checklist-*.md`: it must contain at least one checkbox line (unchecked or checked).
2. Add two cases to `.claude/hooks/tests/run.sh`: a valid checklist passes, an empty one exits 2.

Verify: `bash .claude/hooks/tests/run.sh` reports zero FAIL.

---

## G-04 — Item 7: model routing on every subagent (merged: PR #9)

Source: Part 2 item 7, Appendix B. Effort: low. Depends on: none.
Claude: `general-purpose`; use `claude-code-guide` first to confirm the current `model:` frontmatter aliases.
Model: `general-purpose` and `claude-code-guide` both inherit the session model (neither is routed by ADR-0003 — the ADR they wrote routes only `.claude/agents/*.md`).
Codex: `codex:codex-rescue --wait` (frontmatter-only edit); then `codex review --base main`.

- [x] T041 Confirm the alias set

1. Ask `claude-code-guide`: which values does the `model:` field in `.claude/agents/*.md` accept today, and does it accept `inherit`?
2. Write the answer as a comment block at the top of this task's PR description.

Verify: the PR description names the source page.

- [x] T042 Assign a model to all 17 agents

1. Apply this mapping by editing only the `model:` line of each file's frontmatter:
   - `opus`: `bdd-orchestrator`, `requirements-analyst`, `scenario-critic`, `spec-alignment-auditor`, `work-verifier`, `code-reviewer`
   - `sonnet`: `gherkin-writer`, `step-definition-scaffolder`, `task-decomposer`, `implementation-engineer`, `refactor-specialist`, `unit-test-augmenter`
   - `haiku`: `red-phase-verifier`, `green-phase-verifier`, `regression-runner`, `documentation-scribe`, `release-reporter`
2. Add a `model:` line where none exists; do not touch other frontmatter fields.

Verify: `grep -L '^model:' .claude/agents/*.md` prints nothing; `grep -h '^model:' .claude/agents/*.md | sort | uniq -c` shows only the three aliases.

- [x] T043 Record the routing table

1. Append ADR-0003 (or next number) to `decisions.md`: one paragraph, the mapping above, and the rule "reviewers and verifiers get the strongest model; mechanical runners get the cheapest".

Verify: the ADR exists and `decisions.md` stays under 60 lines.

---

## G-05 — Item 6 / Part 4.13: adversarial review agents and findings schema (merged: PR #13)

Source: Part 3, Part 4.8, Part 4.13. Effort: medium. Depends on: none (G-04 aliases help but are not required).
Claude: `general-purpose` for the agent files, `bdd-orchestrator` for the schema validator.
Model: `general-purpose` inherits the session model; `bdd-orchestrator` runs `opus`; the eight reviewer agents T052 adds are routed by ADR-0003's extension — `opus` (`spec-red-team-reviewer`, `security-reviewer`, `threat-model-reviewer`, `critic`), `sonnet` (`conformance-reviewer`, `correctness-reviewer`, `performance-reviewer`), `haiku` (`maintainability-reviewer`).
Codex: `codex:codex-rescue --background`; then `codex review --base main`.

- [x] T051 Add the findings JSON schema

1. Create `.claude/review/schema.json` with the Part 4.8 schema verbatim.
2. Add `python3 -c 'import json;json.load(open(".claude/review/schema.json"))'` to `.claude/hooks/tests/run.sh` as a check.

Verify: the hook test suite passes and includes the schema parse check.

- [x] T052 Add the eight reviewer agents

1. Create one file per Part 4.13 definition under `.claude/agents/`: `spec-red-team-reviewer`, `conformance-reviewer`, `correctness-reviewer`, `security-reviewer`, `maintainability-reviewer`, `performance-reviewer`, `threat-model-reviewer`, `critic`.
2. Keep the `tools:` lists exactly as written (read-only reviewers have no `Edit`/`Write`).
3. Replace `.specify/review/schema.json` with `.claude/review/schema.json` in every body.
4. Add "Read `standards/code.md` before reviewing" to each body.

Verify: `ls .claude/agents | wc -l` is 25; `grep -l 'specify/review' .claude/agents/*.md` prints nothing.

- [x] T053 Add a schema validator script

1. Write `.claude/review/validate-findings.py`: takes a findings JSON path, validates against the schema with stdlib only (no `jsonschema` dependency), exits 1 on failure with the failing key.
2. Write a failing test first in `.claude/review/tests/test_validate_findings.py` covering: valid file, missing `verdict`, bad `severity`.

Verify: `python3 -m pytest .claude/review/tests -q` passes.

- [x] T054 Document the review stack

1. Add a "Review stack" section to `specflow/references/workflow-guide.md`: Stage 0 spec red-team, Stage 1 conformance, Stage 2 panel, Stage 3 critic (HIGH risk only), max 3 rounds.
2. Note that `/speckit.specflow.review` remains the fallback when the agents are not installed.

Verify: the section exists and names the four stages.

---

## G-06 — Part 4.9 / 4.10: merge gate and risk classifier scripts (working on)

Source: Part 4.9, Part 4.10, Part 3.10. Effort: low-medium. Depends on: G-05 (schema path).
Claude: `bdd-orchestrator`.
Model: `bdd-orchestrator` runs `opus`.
Codex: `codex:codex-rescue --background`; then `codex review --base main`.

- [ ] T061 Add `risk-classifier.sh`

1. Create `.claude/hooks/risk-classifier.sh` from Part 4.10; replace `bc` with pure-bash arithmetic so it runs on a bare macOS shell.
2. Add three cases to `.claude/hooks/tests/run.sh`: a diff touching `auth/` prints `HIGH`; a lockfile change prints `HIGH`; a 2-line doc change prints `STANDARD`.

Verify: `bash .claude/hooks/tests/run.sh` reports zero FAIL.

- [ ] T062 Add `merge-gate.sh`

1. Create `.claude/hooks/merge-gate.sh` from Part 4.9; default glob `.claude/review/*.json`; write the approval marker to `.claude/review/.merge-approved`.
2. Add cases: one open Critical exits 1; one rebutted Important exits 0; no files exits 0.

Verify: `bash .claude/hooks/tests/run.sh` reports zero FAIL.

- [ ] T063 Add `.claude/review/*.json` and the marker to `.gitignore`

1. Append `.claude/review/*.json` and `.claude/review/.merge-approved` to `.gitignore`; keep `schema.json` tracked with a negation line.

Verify: `git check-ignore .claude/review/claude.json` prints the path; `git check-ignore .claude/review/schema.json` prints nothing.

---

## G-07 — Item 9: observability Stop hook (working on)

Source: Part 2 item 9, Part 4.5. Effort: low. Depends on: none.
Claude: `bdd-orchestrator`.
Model: `bdd-orchestrator` runs `opus`.
Codex: `codex:codex-rescue --wait`; then `codex review --base main`.

- [ ] T071 Add `log-phase.sh`

1. Create `.claude/hooks/log-phase.sh` from Part 4.5; read the phase from `.claude/.current-phase`; append to `.claude/telemetry.jsonl`; always exit 0.
2. Add a test case: given `{"session_id":"abc"}` on stdin, one JSON line is appended and it parses.

Verify: hook tests pass; `jq . .claude/telemetry.jsonl` parses the test line.

- [ ] T072 Register the hook

1. Add a `Stop` entry to `.claude/settings.json` calling `bash .claude/hooks/log-phase.sh`.
2. Ignore `.claude/telemetry.jsonl` and `.claude/.current-phase` in `.gitignore`.

Verify: `jq .hooks.Stop .claude/settings.json` prints the entry.

- [ ] T073 Add the `jq` dashboard doc

1. Create `.claude/hooks/README.md` (or extend it) with the three `jq` queries from Part 4.5, paths corrected to `.claude/`.

Verify: each query runs without error against the test line from T071.

---

## G-08 — Intent dispatcher skill (merged: PR #14)

Source: Part 2 "Intent dispatcher", Part 4.6. Effort: low. Depends on: none.
Claude: `general-purpose`; run `plugin-dev:skill-reviewer` on the result.
Model: `general-purpose` inherits the session model; `plugin-dev:skill-reviewer` is a plugin agent, model set by the plugin, not ADR-0003.
Codex: `codex:codex-rescue --wait`; then `codex review --base main`.

- [x] T081 Write the skill

1. Create `.claude/skills/specflow-dispatcher/SKILL.md` from Part 4.6.
2. Rename every `/speckit.superspec.*` command to `/speckit.specflow.*` (this repo's namespace).
3. Replace `@spec-red-team-reviewer` etc. with the names from G-05; if G-05 is not merged, reference `/speckit.specflow.review` instead.
4. Use `claude-code-guide` to confirm the current SKILL.md frontmatter fields, then set `name` and `description`.

Verify: `grep -c 'superspec' .claude/skills/specflow-dispatcher/SKILL.md` prints 0.

- [x] T082 Review the trigger description

1. Dispatch `plugin-dev:skill-reviewer` on the new skill.
2. Apply only the description-wording findings.

Verify: reviewer output attached to the PR; description mentions "add", "fix", "refactor", "rules".

---

## G-09 — Items 10, 15, 17: CI merge-gate workflow

Source: Part 4.11, Part 2 items 10, 15, 17. Effort: medium. Depends on: G-05, G-06.
Claude: `bdd-orchestrator`; use `claude-code-guide` to verify headless flag names.
Model: `bdd-orchestrator` runs `opus`; `claude-code-guide` inherits the session model.
Codex: `codex:codex-rescue --background`; then `codex review --base main`.
Note: the Codex CI step from Part 4.11 is omitted; cross-model review runs locally with `codex review` (see G-15). This keeps `OPENAI_API_KEY` out of repo secrets and honors the AGENTS.md target surface.

- [ ] T091 Add the workflow file

1. Create `.github/workflows/merge-gate.yml` from Part 4.11 minus the Codex step; paths changed to `.claude/hooks/` and `.claude/review/`.
2. Wrap the `claude -p` call in `timeout 300`; pass `--max-turns 6`, `--output-format json`, `--allowedTools "Read,Grep,Bash(git diff:*)"`.
3. Pin `anthropics/claude-code-security-review` to a release tag, not `@main`.
4. Add `concurrency` and `timeout-minutes: 25` as in the source.

Verify: `python3 -c 'import yaml,sys;yaml.safe_load(open(".github/workflows/merge-gate.yml"))'` exits 0.

- [ ] T092 Confirm the headless flags

1. Ask `claude-code-guide` for the current names of the budget-cap flag, `--permission-mode` values, and `--json-schema`.
2. Correct the workflow if any flag differs.

Verify: the PR description lists each flag and its source.

- [ ] T093 Gate expensive steps on risk

1. Make the security-review action and mutation step conditional on `steps.risk.outputs.level == 'HIGH'`.
2. Make the merge gate step always run.

Verify: `grep -c "level == 'HIGH'" .github/workflows/merge-gate.yml` prints 2.

- [ ] T094 Document the local equivalent

1. Add a "Run the gate locally" subsection to `.claude/hooks/README.md`: `risk-classifier.sh main`, then `merge-gate.sh`.

Verify: both commands run from a clean feature branch.

---

## G-10 — Item 21: STRIDE lens and traceability matrix in the spec template (working on)

Source: Part 2 item 21, Part 3.10. Effort: low-medium. Depends on: none.
Claude: `general-purpose`, then `work-verifier`.
Model: `general-purpose` inherits the session model; `work-verifier` runs `opus`.
Codex: `codex:codex-rescue --wait`; then `codex review --base main`.

- [ ] T101 Add a `## Threat Model` section to `spec-template.md`

1. Read `specflow/templates/spec-template.md` in full.
2. Insert `## Threat Model` after `## Requirements`: a six-row STRIDE table (threat, abuse case, mitigation, or `N/A + reason`).
3. Mark it optional, not `*(mandatory)*`, so `artifact-lint.sh` does not fail existing specs.

Verify: `grep -n '^## Threat Model' specflow/templates/spec-template.md` prints one line.

- [ ] T102 Add a `## Traceability` table

1. Insert `## Traceability` after `## Success Criteria`: columns `Criterion ID`, `Test name`, `Status`.
2. Add one guidance line: every criterion needs at least one named test before review Stage 1.

Verify: the table header exists with the three columns.

- [ ] T103 Update `checklist-template.md`

1. Add two items: "STRIDE table filled or each row marked N/A" and "every criterion has a test in Traceability".

Verify: both items appear in the template.

- [ ] T104 Update the example and README

1. Add the two sections to `specflow/examples/static-landing-page/` spec so the example stays a golden run.
2. Mention the sections in `README.md`.
3. Run both validate scripts.

Verify: `cd specflow && python3 scripts/validate-extension-metadata.py && python3 scripts/validate-release-archive.py` exits 0.

---

## G-11 — Item 18: spec change management (working on)

Source: Part 2 item 18. Effort: medium. Depends on: none.
Claude: `bdd-orchestrator` (for the tasks diff check) then `documentation-scribe`.
Model: `bdd-orchestrator` runs `opus`; `documentation-scribe` runs `haiku`.
Codex: `codex:codex-rescue --background`; then `codex review --base main`.

- [ ] T111 Add `## Changelog` to `spec-template.md`

1. Append `## Changelog` with one row template: version, date, summary.

Verify: the section exists at the end of the template.

- [ ] T112 Make `tasks.md` regeneration preserve stable IDs

1. Read `specflow/commands/tasks.md` Process steps in full.
2. Add a Process step: when `tasks.md` exists, read existing `TNNN` IDs and reuse them for unchanged tasks; only new tasks get new IDs.
3. Add a Process step: print a diff summary (added / removed / renumbered) before writing.

Verify: `E2E_DRY_RUN=1 bash scripts/e2e-agent-claude.sh` exits 0.

- [ ] T113 Add the hotfix path to `workflow-guide.md`

1. Add a "Hotfix path" subsection: skips brainstorm, still runs `/speckit.analyze`, still runs the merge gate, appends a Changelog row.

Verify: the subsection names the merge gate as non-skippable.

- [ ] T114 Lint stable IDs across regeneration

1. Extend `artifact-lint.sh`: if `tasks.md` and `progress.yml` both exist, every completed ID in `progress.yml` must still appear in `tasks.md`; exit 2 otherwise.
2. Add a passing and a failing case to the hook tests.

Verify: `bash .claude/hooks/tests/run.sh` reports zero FAIL.

---

## G-12 — Item 20: resumable sessions via `SessionStart` (merged: PR #22)

Source: Part 2 item 20. Effort: medium. Depends on: none.
Claude: `bdd-orchestrator`; use `claude-code-guide` for the `SessionStart` matcher values.
Model: `bdd-orchestrator` runs `opus`; `claude-code-guide` inherits the session model.
Codex: `codex:codex-rescue --background`; then `codex review --base main`.

- [x] T121 Add `session-start.sh`

1. Create `.claude/hooks/session-start.sh`: on `compact` or `resume`, print `open-questions.md`, the current feature's `progress.yml` summary, and the current task line; exit 0 always.
2. Add a test: with a fixture `progress.yml`, stdout contains the current task ID.

Verify: hook tests pass.

- [x] T122 Register with a matcher

1. Add a `SessionStart` entry to `.claude/settings.json` with matcher `compact|resume`.
2. Confirm the matcher syntax with `claude-code-guide`.

Verify: `jq .hooks.SessionStart .claude/settings.json` prints the entry.

- [x] T123 Add the handoff note convention

1. Add to `workflow-guide.md`: `execute` writes `specs/NNN/handoff.md` (5 lines max) at every checkpoint; `session-start.sh` prints it if present.
2. Add the matching Process step to `specflow/commands/execute.md`.

Verify: `grep -n 'handoff.md' specflow/commands/execute.md specflow/references/workflow-guide.md` prints two lines.

---

## G-13 — Items 12 and 19: golden-run scorer and eval replay (merged: PR #20)

Source: Part 2 items 12, 19. Effort: medium-high. Depends on: G-01 (smoke test must pass).
Claude: `bdd-orchestrator`.
Model: `bdd-orchestrator` runs `opus`.
Codex: `codex:codex-rescue --background`; then `codex review --base main`.

- [x] T131 Write `score-artifacts.py`

1. Create `specflow/scripts/score-artifacts.py`: takes a `specs/NNN/` dir; scores spec sections present, criteria with a traceability row, tasks with stable IDs, `NEEDS CLARIFICATION` count; prints JSON.
2. Write tests first in `specflow/scripts/tests/test_score_artifacts.py` using `examples/static-landing-page/` as the fixture.

Verify: `python3 -m pytest specflow/scripts/tests -q` passes; the example scores 100 on sections.

- [x] T132 Seed one known-bad golden

1. Add `specflow/examples/seeded-bug/` copied from the landing page with one deliberate spec gap (a criterion with no test).
2. The scorer must report that gap.

Verify: `python3 specflow/scripts/score-artifacts.py specflow/examples/seeded-bug` shows one untraced criterion.

- [x] T133 Replay in CI on relevant changes

1. Add a job to `specflow/.github/workflows/ci.yml` that runs the scorer on both examples when `commands/`, `templates/`, or `.claude/` change.
2. Fail if the landing page score drops or the seeded gap goes unreported.

Verify: workflow YAML parses; `paths:` filter lists the three dirs.

---

## G-14 — Item 5: Agent Teams for `[P]` tasks (merged: PR #17)

Source: Part 2 item 5. Effort: medium. Depends on: none.
Claude: `general-purpose`; `claude-code-guide` first for the current env flag and limits.
Model: `general-purpose` and `claude-code-guide` both inherit the session model.
Codex: `codex:codex-rescue --wait` for the docs edits only (Agent Teams is a Claude Code feature; Codex cannot exercise it). Then `codex review --base main`.

- [x] T141 Confirm the feature flag

1. Ask `claude-code-guide` whether `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is still the flag and what the one-team-per-session limits are today.

Verify: answer recorded in the PR description.

- [x] T142 Enable it in settings

1. Add `"env": {"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"}` to `.claude/settings.json`.

Verify: `jq .env .claude/settings.json` prints the key.

- [x] T143 Document the `[P]` dispatch protocol

1. Read `specflow/commands/execute.md` and `workflow-guide.md` Phase 5.
2. Add to Phase 5: for a batch of `[P]` tasks, one teammate per task, each in its own worktree, non-overlapping file scopes stated in the brief, no nested teams, and sequential fallback when the flag is unset.
3. Add the matching Process step to `execute.md` under the existing `[SUBAGENT]` handling.

Verify: `E2E_DRY_RUN=1 bash scripts/e2e-agent-claude.sh` exits 0.

---

## G-15 — Item 14: differential implementation (Claude vs Codex)

Source: Part 2 item 14. Effort: medium-high. Depends on: none. This is the one group where both executors run, by design.
Claude: `bdd-orchestrator` for the script; then `general-purpose` for the protocol doc.
Model: `bdd-orchestrator` runs `opus`; `general-purpose` inherits the session model.
Codex: implementation counterpart in the protocol; `codex:codex-rescue --background` for the second worktree.

- [ ] T151 Write `diff-impl.sh`

1. Create `.claude/hooks/diff-impl.sh <spec-dir>`: creates `worktrees/<feature>-a` and `-b`, prints the two paths and the shared test command.
2. Test: on a temp repo it creates two worktrees on distinct branches.

Verify: hook tests pass.

- [ ] T152 Write the protocol

1. Add "Differential implementation" to `workflow-guide.md`: worktree A via `implementation-engineer`, worktree B via `codex:codex-rescue`, run A's tests on B and B's tests on A, list every divergence as an Open Question in `spec.md`.
2. State the trigger rule: only when `risk-classifier.sh` prints `HIGH` or the spec has more than three open questions.

Verify: the section names the trigger rule and the cross-test step.

- [ ] T153 Dry run on the example

1. Run the protocol once on `examples/static-landing-page/` with both executors.
2. Record the divergences found (or "none") in the PR description.

Verify: PR description contains the divergence list.

---

## G-16 — Item 22: cost governance (working on)

Source: Part 2 item 22, Part 6, Appendix B. Effort: low. Depends on: G-04 (routing table exists).
Claude: `documentation-scribe`.
Model: `documentation-scribe` runs `haiku`.
Codex: `codex:codex-rescue --wait`; then `codex review --base main`.

- [ ] T161 Add the per-phase budget table

1. Add "Budgets" to `workflow-guide.md`: one row per phase with a token ceiling and a model class from Appendix B.
2. Note the headless budget-cap flag by its verified name from G-09.

Verify: the table has a row for each of the 7 workflow stages.

- [ ] T162 Wire budgets into `bdd-orchestrator`

1. Add one line to `.claude/agents/bdd-orchestrator.md`: stop and report if a phase exceeds its Budgets row.

Verify: `grep -n 'Budgets' .claude/agents/bdd-orchestrator.md` prints a line.

---

## G-17 — Item 8: close the review loop (merged: PR #12)

Source: Part 2 item 8. Effort: low. Depends on: none.
Claude: `general-purpose`, then `work-verifier`.
Model: `general-purpose` inherits the session model; `work-verifier` runs `opus`.
Codex: `codex:codex-rescue --wait`; then `codex review --base main`.

- [x] T171 Review writes findings back to the spec

1. Read `specflow/commands/review.md` Process steps in full.
2. Add a Process step after step 5: each Critical or Important finding that is a spec gap is appended to `spec.md` `## Open Questions` with the finding ID.

Verify: `E2E_DRY_RUN=1 bash scripts/e2e-agent-claude.sh` exits 0.

- [x] T172 Brainstorm reads `decisions.md`

1. Read `specflow/commands/brainstorm.md` Process steps in full.
2. Add a Process step before questioning: if `decisions.md` exists at the project root, read it and do not re-ask settled decisions.

Verify: `grep -n 'decisions.md' specflow/commands/brainstorm.md` prints a line.

- [x] T173 Update the bridge doc

1. Add both steps to `specflow/references/superpowers-bridge.md` under the matching command sections.

Verify: both command sections mention the new step.

---

## G-18 — Playbook scope cleanup (merged: PR #15)

Source: the scope note at the top of `imporvements2.md`. Effort: low. Depends on: none.
Claude: `documentation-scribe`.
Model: `documentation-scribe` runs `haiku`.
Codex: not applicable.

Decided 2026-09-11: keep Codex as an executor. Codex is not a runtime target for
`specflow/` and is not part of the shipped extension; it stays an allowed
implementer and cross-model reviewer for this repo's own development. The Codex
executor lines in this file and the G-15 differential group stand unchanged.

- [x] T181 Rewrite the scope note

1. Replace the scope note at the top of `imporvements2.md` with the decision above.
2. Drop the "pending cleanup" framing; the question is settled.

Verify: the note states that Codex is not a runtime target and is an allowed executor.

- [x] T182 Remove the Codex install steps and CI step

1. Remove the Codex install steps from Parts 5.3, 5.10, and Appendix A.
2. Remove the Codex CI step from Part 4.11, matching the note already in G-09.
3. Leave every `codex review` and `codex:codex-rescue` executor reference in place.

Verify: `grep -ci codex imporvements/imporvements2.md` prints a nonzero count and
`grep -n 'OPENAI_API_KEY' imporvements/imporvements2.md` prints nothing.

---

## Deferred (no steps yet)

- **Item 11 multi-feature concurrency**: Part 8 says do this only once single-feature runs are boring. Revisit after G-14 has run on three features.
- **Item 16 mutation-testing gate**: this repo has no application code to mutate; the gate lands in a consuming project's constitution (G-02 Code Review Rules placeholder covers it). The CI step in G-09 stays behind the `HIGH` condition and a missing `stryker` config is a no-op.

## Suggested order

Independent groups can run in parallel worktrees. A workable sequence:

1. G-01 (unblocks the smoke test everything else verifies against)
2. G-02, G-03, G-04, G-08, G-10, G-17 in parallel (small, doc and template heavy)
3. G-05, then G-06, then G-09
4. G-07, G-11, G-12 in parallel
5. G-13, G-14, G-15, G-16
6. G-18 whenever the decision is made
