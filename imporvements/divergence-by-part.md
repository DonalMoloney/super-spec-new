# How specflow/ can diverge from upstream, by part

This file lists, for each part of the extension measured in `diff.md`, the ways
it can diverge from upstream superspec without breaking spec-kit's install
contract. Read it when choosing where the next roadmap item lands. `tasks.md`
holds the committed work; this file holds the option space. Percentages are the
real (rebrand-normalized) change measured 2026-09-11 against the vendored
upstream at the root commit (`bda4ef0`, upstream `c20ac6c`). No `diff.md`
exists; the Measured state section below holds the per-file numbers.

Three constraints apply to every part. A move that violates one is not an
option.

1. **Namespace lock-step.** The extension id and every command or hook name
   match, or `validate-extension-metadata.py` fails.
2. **Superpowers optional.** Every command keeps a built-in fallback when the
   skill is absent.
3. **Both targets.** Anything shipped in `specflow/` runs on the Copilot CLI as
   well as Claude Code. A shipped file may not depend on `.claude/` hooks,
   agents, or `model:` frontmatter, which Copilot cannot execute.

## Five moves

The same five moves apply to every part. Each bullet below is tagged with its
move, whether it is reversible, and whether it breaks a later upstream resync.

| Move | Meaning | Reversible | Breaks resync |
|------|---------|------------|---------------|
| Tighten | Same steps, stricter gate or stricter output shape | yes | rarely |
| Extend | New step, section, or placeholder appended to the upstream shape | yes | sometimes |
| Add | New file with no upstream counterpart | yes | no |
| Replace | Same file name, different process | no | yes |
| Remove | Drop a file or step upstream still ships | no | yes |

Tighten and Add are the cheap moves. Replace and Remove are where the fork
stops being a fork; take them only when the upstream shape is wrong for the two
targets.

Each bullet ends with a `Verify:` line naming the check that proves it done, and
a `Claimed by:` line naming the roadmap group or "none".

## commands/hooks/ (21.9% real)

Three hook prompts spec-kit runs around its own commands. Most divergent part
today because `before-execute.md` gained two gates.

- **Tighten** `after-tasks.md` to read `progress.yml` before writing, as
  `before-execute.md` already does at its step 6. It is the one hook that
  assumes a fresh run. Verify: the hook's Process lists a progress-state read
  step. Claimed by: D-01 (working on).
- **Extend** `after-execute.md` to write a findings file the review command
  reads, closing implement to review. Today it only suggests running review.
  Verify: `review.md` names the file as an input. Claimed by: D-02 (working on).
  G-17 closes the other direction, review to spec.
- **Add** a `before_tasks` hook that stops when the spec's Open Questions table
  has unresolved rows. Spec-kit fires `hooks.before_tasks`, and upstream never
  registered one. Not cheap: it changes the hook count that
  `e2e-smoke.sh` (lines 118 and 127), `ci.yml` (line 43), and the hard-coded
  hook tuple in `validate-extension-metadata.py` (line 86) all assert. Same
  cost class as a sixth command. Verify: all three assertions updated and
  green. Claimed by: none.
- **Replace**: not warranted. The hooks are thin and spec-kit fixes their order.

## commands/ (11.4% real)

The five behavior contracts. Command names are asserted in `e2e-smoke.sh`,
`e2e-agent-claude.sh`, and `ci.yml`, and the namespace is derived in
`validate-extension-metadata.py`. Every Process-step change needs a smoke-test
update.

- **Tighten** `status.md` to report `.clarified` and `.analyzed` per feature.
  It infers phase from file presence and has zero real change today. Verify:
  `e2e-smoke.sh` asserts the marker column in status output. Claimed by: none.
- **Tighten** `tasks.md` to reject a generated task line containing " and ",
  enforcing the singular-task rule from `AGENTS.md` at generation time. Verify:
  a fixture with a compound task fails the command. Claimed by: none.
- **Extend** `review.md` with a risk tier (LOW, MEDIUM, HIGH) that selects which
  review dimensions run. Constraint 3 applies: G-06 builds its classifier under
  `.claude/hooks/`, so the shipped command needs a prose rule (file count, path
  patterns) it can apply on Copilot, and may use the script only when present.
  Verify: the fallback tier rule is in the command file. Claimed by: G-06
  built the script; D-03 (working on) adds the command rule.
- **Extend** `brainstorm.md` to write resolved questions to `decisions.md` as
  ADR-lite entries, not only read them. Verify: a resolved question appears in
  `decisions.md` after a run. Claimed by: none. G-17 T172 covers the read.
- **Replace** `execute.md` with a dispatcher over the `.claude/agents/` squad on
  Claude Code, keeping the sequential walk as the Copilot fallback. The one
  Replace worth considering, and only after G-14. Verify: both paths pass the
  agent e2e in dry-run. Claimed by: G-14, partially.
- **Add** a sixth command: not an option. It changes `extension.yml`, README,
  and command-name assertions in four files.

## SKILL.md (part of root files, 1.2% real)

The largest single behavior contract in the extension and the file a
`~/.agents/skills/` install reads first. It has no moves in the roadmap.

- **Tighten** the skill's phase list to name the gate markers each phase
  produces, so it and `workflow-guide.md` cannot drift. Verify: the marker
  names in both files match by grep. Claimed by: none.
- **Extend** with a "Target surface" section stating which steps are Claude
  Code only and what Copilot does instead. Verify: every step marked Claude-only
  has a named fallback. Claimed by: none.
- **Replace**: not warranted. Spec-kit's skill loader expects the upstream
  section shape.

## references/ (5.8% real)

Two prose files the commands cite. Cheap to diverge because nothing asserts
against them structurally.

- **Extend** `workflow-guide.md` with one section per new gate or marker, as it
  did for `.analyzed`. The Gate markers table stays the single source for
  marker names. Verify: every marker named in a command appears in the table.
  Claimed by: G-03 (done), continuing.
- **Extend** `superpowers-bridge.md` to map the review personas under
  `.claude/agents/` to the `requesting-code-review` skill, so Claude Code
  prefers the squad and Copilot the skill. Verify: the mapping table has a row
  per persona. Claimed by: none.
- **Add** a `copilot-cli.md` reference stating what the Copilot runtime lacks
  (no hooks, no subagents, no `model:` frontmatter) and which fallback each
  command uses there. `.github/copilot-instructions.md` covers this repo's
  contributors; nothing in `specflow/references/` covers the runtime. Upstream
  has no Copilot reference. Verify: one row per command. Claimed by: D-03 (working on).

## templates/ (1.3% real)

Five documents copied into the consuming project on `/speckit.constitution`.
Spec-kit's own commands fill them and expect the upstream section names. They
shape every downstream artifact, so a change here has the widest blast radius
of any part.

- **Extend** `spec-template.md` with a STRIDE table and a traceability matrix.
  Verify: G-10's Verify condition. Claimed by: G-10.
- **Extend** `constitution-template.md` with a review-stage table stating which
  model class each stage requires (fast, standard, strongest). Constraint 3:
  per-agent `model:` aliases are a Claude Code mechanism and do not belong in a
  file every consuming project receives. Verify: no agent alias in the
  template. Claimed by: none. G-04 set the routing in `.claude/agents/`.
- **Extend** `tasks-template.md` with a Verify column so each task names its
  check, matching the shape `imporvements/tasks.md` uses. Verify: the template
  table header has the column. Claimed by: none.
- **Tighten** `checklist-template.md` by adding an `R-NNN` column that joins the
  existing `CHK` row ids to review findings. Row ids and confidence scoring
  already exist. Verify: a review run fills the column. Claimed by: none.
- **Replace**: not warranted.

## scripts/ (2.4% real)

Validation and end-to-end scripts. Export-ignored, so divergence here never
reaches an installed extension. G-06's merge gate and risk classifier live under
`.claude/hooks/` per ADR-0001, not here.

- **Add** a `diffstats.py` that regenerates `diff.md` from an upstream clone, so
  the divergence numbers are a command and not a one-off. `diff.md` describes
  the method; the script was never committed. Verify: running it reproduces
  the current table. Claimed by: none.
- **Add** a golden-run scorer that replays `examples/static-landing-page/` and
  diffs the output. Verify: G-13's Verify condition. Claimed by: G-13.
- **Tighten** `e2e-smoke.sh` to assert the Process-step count of each command
  file (on 2026-09-11: status 8, brainstorm 7, tasks 9, execute 9, review 6) and every
  marker in the Gate markers table, so a dropped step fails before merge.
  Verify: deleting one step from any command fails the smoke test. Claimed by:
  D-04 (working on, after D-01 to D-03 merge).

## examples/ (0.9% real)

One full run snapshot plus a sample workflow. Export-ignored. Teaching material
and test fixture, nothing else.

- **Add** a second snapshot for a feature that fails a gate, showing
  `ANALYZE_REQUIRED` and the recovery path. Every example today is a happy
  path; the only failure shown is an intended TDD RED. Verify: the snapshot
  contains the stop code and the rerun. Claimed by: none.
- **Tighten**: regenerate the snapshot spec when `spec-template.md` changes, so
  G-13's golden matches the template. Verify: the scorer passes after a
  template change. Claimed by: G-13, implicitly.
- **Replace**: not warranted.

## assets/ (excluded from line counts)

Workflow diagrams, 12 MiB, export-ignored because one oversized PNG broke
install for every user (upstream issue #6).

- **Remove** the PNGs and check in the Mermaid or SVG source beside the deck
  under `presentation/`, per `standards/presentations.md`. Verify:
  `validate-release-archive.py` passes and the README renders the diagram from
  source. Claimed by: none.
- **Add** or **Extend**: not an option. Any new binary here needs
  `validate-release-archive.py` run first, and there is no reason to ship a
  binary the archive strips.

## Root files and .github/ (1.2% and 0.0% real)

`README.md`, `README_zh.md`, `CHANGELOG.md`, `extension.yml`, `SKILL.md`
(above), `.gitattributes`, `.gitignore`, `LICENSE`, and the CI workflow.

- **Remove** `README_zh.md`, the inline Chinese section at the end of
  `README.md`, and the sync rule in `AGENTS.md`. The documentation standard
  forbids translated copies, and `.gitattributes` stopped export-ignoring the
  file, so the archive ships it now. Verify: `git archive HEAD:specflow` lists
  no `README_zh.md` and README has one language. Claimed by: `fix-readme-language-policy`, done.
- **Remove** the `~/.codex/skills/` install instructions from `README.md`.
  `AGENTS.md` forbids Codex paths; upstream targets Codex. G-18 records the
  scope decision but edits only the playbook, not `specflow/`. Verify: grep
  for `codex` in `specflow/README.md` is empty. Claimed by: D-05 (working on).
- **Tighten** CI to run `e2e-smoke.sh`. CI validates metadata, the archive, and
  a live install, and never runs the smoke test, which is the only check that
  catches a Process-step regression. Verify: a CI run shows the smoke step.
  Claimed by: D-04 (working on).
- **Extend** `CHANGELOG.md` with an Unreleased section every merged group
  appends to. The file opens at 1.0.2 and records nothing since. Verify: the
  section exists and each merged PR adds a line. Claimed by: D-05 (working on).
- **Replace** `extension.yml`: not an option. Its schema belongs to spec-kit.

## Measured state, 2026-09-11

Every roadmap group G-01 to G-18 is merged, so every `Claimed by` bullet above
is done and every `Claimed by: none` bullet is still open. Diffing the vendored
upstream against `specflow/` with the rename normalized gives these per-file
change rates. Files not listed are byte-identical after the rename: `SKILL.md`,
`extension.yml`, `CHANGELOG.md`, `status.md`, both `after-*` hooks,
`plan-template.md`, and `tasks-template.md`.

| File | Changed lines |
|------|---------------|
| `commands/hooks/before-execute.md` | 51% |
| `commands/execute.md` | 31% |
| `README.md` | 23%, nearly all the removed Chinese section |
| `references/workflow-guide.md` | 17% |
| `commands/tasks.md`, `templates/spec-template.md` | 12% |
| `commands/brainstorm.md`, `commands/review.md` | 10%, 7% |

The installable payload stays close to upstream. The fork's divergence lives
in `.claude/`, `standards/`, `scripts/`, and CI, which the archive strips.

Open bullets with the smallest blast radius, in order: the `after-tasks.md`
progress read, the `after-execute.md` findings file, the `review.md` prose
risk tier, the CI smoke step, the CHANGELOG Unreleased section, and the Codex
lines in `specflow/README.md` (lines 9, 41, 47, 48).

## Renames

D-05 (working on) renames the manifest display name and rewrites the manifest
strings listed in the table below.

Names are asserted in more files than behavior is. Each row states where a
rename lands, so the cost is known before the move.

| Name | Asserted in | Cost |
|------|-------------|------|
| Extension id `specflow` | 27 files: manifest, 5 commands, 3 hooks, `SKILL.md`, 4 templates, both e2e scripts, `ci.yml`, validator test, dispatcher skill, repo docs | Not an option |
| `name: "Superpowers Bridge"` and the manifest description | `extension.yml`, `README.md`, `CHANGELOG.md`, `superpowers-bridge.md`, validator test, `AGENTS.md`, `copilot-instructions.md` | Cheap; "bridges" is a banned metaphor |
| Manifest strings "Enhanced" (6), "Deep-dive" (2), "Intelligent" (1) | Nothing greps them | Free Tighten |
| `references/superpowers-bridge.md` | 10 citations in commands, `SKILL.md`, README; both validators; the `CLAUDE.md` import | About 8 files |
| `commands/hooks/*.md` file names | Nothing; the manifest maps hooks to commands | Free |
| `commands/*.md` file names | The `file:` field in `extension.yml` | Cheap |
| `templates/*.md` file names | Spec-kit reads `.specify/templates/<name>`; `e2e-smoke.sh` lines 82 to 84 | Not an option |

Stale upstream names to fix regardless of any rename:

- `presentation/marp-deck/deck.md` line 64 says `specify extension add superspec`
  and `/speckit.superspec.status`. Verify: grep for `superspec` in the deck is
  empty. Claimed by: D-05 (working on).
- `.claude/review/schema.json` line 3 titles the schema `SuperspecReviewFindings`.
  Verify: the hook tests pass after the rename. Claimed by: D-05 (working on).
- `validate-extension-metadata.py` line 147 checks the README for a
  `superpowers-bridge --from` string that no README has carried since the
  rename. Verify: the check is deleted and the validator passes. Claimed by: D-05 (working on).
- `specflow/LICENSE` keeps "Superspec Contributors". Keep it; MIT requires the
  original notice.

## Choosing

Pick by blast radius, not by the percentage. The percentage measures past
divergence; it says nothing about what a new change costs. Order of preference:

1. A reference or example, which nothing asserts against.
2. A script, which never ships.
3. A template, which reaches every downstream artifact once and needs no smoke
   test change.
4. A command or hook, which changes what the user sees and needs the smoke test,
   CI, and the validators updated together.

When two parts both reach the goal, change the one further from the user.
