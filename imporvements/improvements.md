=== DELIVERABLE A: SUPERCHARGE-SUPERSPEC.md ===

# Supercharging Superspec: A Focused Roadmap

## What Superspec is today (verified Sept 2026)

Superspec (`WangX0111/superspec`, MIT license — a small, early-stage project with exactly 56 stars, 7 forks, 0 watchers and 10 commits per the live GitHub repo page, retrieved Sep 11 2026) is a **Spec-Kit extension** that bridges GitHub Spec Kit's governance artifacts with obra/superpowers' execution skills. It installs via `specify extension add superspec`, or as an agent skill by symlinking into `~/.claude/skills/` or `~/.agents/skills/`. It works with any Spec-Kit-compatible agent (Claude Code, GitHub Copilot CLI, others).

It adds **5 commands** on top of Spec Kit's core commands: `/speckit.superspec.status`, `/speckit.superspec.brainstorm`, `/speckit.superspec.tasks`, `/speckit.superspec.execute`, `/speckit.superspec.review`. The README describes the flow as **7 stages** (constitution → specify → brainstorm → plan → tasks → execute → review), though the architecture diagram groups them into 6 phases. State is persisted as markdown/YAML under `.specify/memory/` (governance) and `specs/NNN-*/` (per-feature: `spec.md`, `plan.md`, `tasks.md`, `progress.yml`), making runs resumable. When superpowers is installed, Superspec auto-detects and delegates: brainstorm→`brainstorming`, tasks→`writing-plans`, execute→`executing-plans`+`subagent-driven-development`+`test-driven-development`, review→`requesting-code-review`; otherwise it falls back to built-in behavior. The `examples/static-landing-page/` directory is a verbatim disk snapshot of a full Claude Code run, reproducible via `scripts/e2e-agent-claude.sh`.

**Verified dependencies:**
- **GitHub Spec Kit** (`github/spec-kit`): install via `uv tool install specify-cli --from git+https://github.com/github/spec-kit.git` (persistent) or `uvx --from git+... specify init <project> --ai claude` (one-shot). Slash commands (current `speckit.` namespace): `/speckit.constitution`, `/speckit.specify`, `/speckit.clarify`, `/speckit.plan`, `/speckit.checklist`, `/speckit.tasks`, `/speckit.analyze`, `/speckit.implement`. `clarify`, `checklist`, and `analyze` are the quality gates. Independent tasks in `tasks.md` are tagged `[P]`. Note: Spec Kit's CLI surface changes frequently — verify command names in your installed version with `specify --help`.
- **obra/superpowers**: a very active, top-tier project — 277,363 stars and 24,815 forks as of the Aug 26, 2026 SkillsMP catalog refresh (by Jesse Vincent/@obra); GitHub's issues page listed 284k stars, 25.4k forks and 44 contributors on Sep 9, 2026. Install via Claude plugin marketplace `/plugin install superpowers@claude-plugins-official`, or `/plugin marketplace add obra/superpowers-marketplace` then `/plugin install superpowers@superpowers-marketplace`. Supports Claude Code, Cursor, Gemini CLI, Copilot CLI, Devin, Factory Droid, Grok, Kimi, OpenCode, Pi, Hermes, Antigravity. Skills auto-trigger. Verified skill names: `brainstorming`, `using-git-worktrees`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `test-driven-development`, `requesting-code-review`, `receiving-code-review`, `systematic-debugging`, `verification-before-completion`, `dispatching-parallel-agents`, `finishing-a-development-branch`, `writing-skills`, `using-superpowers`.

**Honest assessment of the starting point:** Superspec is a thin, useful bridge but it is early and lightly maintained (10 commits, 56 stars). Its phase gates are prompt-level (not mechanically enforced), execution is serial, and its "review" is a single-pass `requesting-code-review` call. The improvements below add mechanical reliability, parallelism, and a hardened adversarial review layer.

---

## The Focused Improvement List (prioritized)

I have kept the strong items from the original 10, **merged** the three orchestration-tool items (#2 flow file, #3 multi-feature, and parts of #1) into a single "orchestration" track because they overlap heavily and carry the same over-engineering risk, **cut** nothing outright but **demoted** the bespoke `.flow` file and `cco` ideas in favor of Claude Code's now-native primitives, and **added** five high-payoff items the original list missed (clarify/analyze gates, model routing, CI headless gate, artifact linting, cost budgets).

### Tier 1 — Do first (cheap, high reliability payoff)

**1. Rewrite the constitution + add project skills** *(was #6)*
- **What:** Replace the generic constitution at `.specify/memory/constitution.md` with your real conventions (error-handling style, test framework/command, directory layout, forbidden dependencies, security rules). Add your own skills alongside superpowers' (`deploy`, `migrate`, `lint-fix`).
- **Why it matters:** Every downstream phase reads the constitution; `/speckit.plan` and `/speckit.analyze` check compliance against it automatically. This is the single highest-leverage change because everything else inherits it.
- **How:** Run `/speckit.constitution` and answer with specifics. Add a `## Code Review Rules` section (this is the source Claude Code and Copilot CLI reviewers both read from the nearest `AGENTS.md`). Put team-wide rules in root `AGENTS.md`/`CLAUDE.md`, service-specific rules in nested files.
- **Effort:** Low (1–2 hrs). **Dependencies:** none.

**2. Enforce gates with hooks** *(was #5)*
- **What:** Convert prompt-level gates into mechanical ones using Claude Code hooks in `.claude/settings.json`.
- **Why it matters:** Claude Code is probabilistic; hooks run deterministically every time. This is the cheapest reliability win available.
- **How (verified hook events + exit-code semantics):** `PreToolUse` is the only event where **exit code 2 blocks the tool call** and feeds stderr back to Claude. `Stop` exit code 2 forces Claude to keep working. `SessionStart` runs at startup/resume/clear/compact and can inject context. Example config:
```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash",
        "hooks": [ { "type": "command", "command": "bash .claude/hooks/block-main-commit.sh" } ] }
    ],
    "PostToolUse": [
      { "matcher": "Edit|Write",
        "hooks": [ { "type": "command", "command": "bash .claude/hooks/test-gate.sh" } ] }
    ],
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "cat .specify/memory/constitution.md" } ] }
    ]
  }
}
```
  - `block-main-commit.sh`: read stdin JSON, `jq -r '.tool_input.command'`; if it matches `git commit` and current branch is `main`, `exit 2` with a reason on stderr.
  - `test-gate.sh`: refuse to let a task be marked done in `tasks.md` unless the test command exits 0.
  - `SessionStart`: injects the constitution so every spawned agent/teammate inherits the rules.
- **Effort:** Low–Medium. **Dependencies:** #1 (constitution to inject). **Note:** the hook event list is large and evolving (SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, Stop, SubagentStop, plus newer TeammateIdle/TaskCompleted); verify names against the official hooks reference for your version.

**3. Add clarify + analyze + checklist gates** *(NEW — original list's biggest omission)*
- **What:** Insert Spec Kit's own quality gates into the Superspec flow: `/speckit.clarify` (structured refinement of underspecified areas) after specify; `/speckit.analyze` (cross-artifact consistency check) after tasks and before implement; `/speckit.checklist` ("unit tests for English" — validates requirements completeness/clarity).
- **Why it matters:** These are *free* adversarial-spec checks GitHub already ships. `clarify` surfaces `[NEEDS CLARIFICATION]` markers; `analyze` catches directory mismatches, missing requirements, and pagination-style assumptions before code is written. Catching a spec defect here is orders of magnitude cheaper than catching it in review.
- **How:** Wire them into the phase order (see roadmap). Gate `implement` on `analyze` reporting no critical inconsistencies.
- **Effort:** Low. **Dependencies:** none (built into Spec Kit).

**4. Artifact linting** *(NEW)*
- **What:** A `PostToolUse` hook (or CI step) that validates `spec.md`/`plan.md`/`tasks.md` structure — required sections present, no leftover `[NEEDS CLARIFICATION]` markers past the clarify gate, every `tasks.md` line has a stable ID, `[P]` markers well-formed.
- **Why it matters:** Structural drift in artifacts silently breaks resumability and downstream parsing. Cheap to lint, expensive to debug.
- **Effort:** Low. **Dependencies:** #2 (hook plumbing).

### Tier 2 — Do next (biggest speed + quality gains)

**5. Parallelize `[P]` tasks with Agent Teams** *(was #1, updated)*
- **What:** Replace serial `subagent-driven-development` execution with parallel workers for tasks tagged `[P]`, each in its own git worktree, rejoining at a single review gate.
- **Why it matters:** Wall-clock time drops in proportion to how many tasks are truly independent.
- **How (verified):** Claude Code now has **native Agent Teams**. Enable with `export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. One session is the **lead** (coordinates, assigns, synthesizes); **teammates** are full independent Claude Code sessions with their own context windows that self-claim tasks from a shared task list and message each other. Teammates do **not** inherit the lead's conversation history — brief them explicitly. Keep scopes non-overlapping (two teammates editing the same file overwrite each other). Give each its own worktree via superpowers' `using-git-worktrees`. Use **delegate mode** to restrict the lead to coordination only. The docs snapshot describes this as of v2.1.178; before that, teams were created via `TeamCreate`/`TeamDelete` tools. Agent Teams are token-heavy — use only when tasks genuinely parallelize.
- **Alternative for large sweeps:** Claude Code's **Workflow tool** (the harness executes a JavaScript orchestration script that fans out to fresh subagents) is better than teams when you need deterministic, resumable control flow over many tasks ("review all 40 files, don't stop early"). Control flow in code, judgment in models.
- **Effort:** Medium. **Dependencies:** #2 (worktree/commit hooks help), #1.

**6. Supercharge adversarial review** *(was #7, massively expanded — see dedicated section below)*
- This is the single highest-quality-leverage item and gets its own section.

**7. Model routing per phase** *(NEW)*
- **What:** Use a cheaper/faster model for mechanical phases (tasks decomposition, straightforward implementation) and a stronger model (or a different vendor) for brainstorm, spec review, and adversarial review.
- **Why it matters:** Review and brainstorm are where reasoning quality pays off; task execution is where cost dominates. Subagents accept a per-agent `model` field; Agent SDK/headless runs accept `--model`.
- **How:** Set `model` in `.claude/agents/*.md` frontmatter per reviewer/worker; in headless CI, pass `--model`. Use a stronger model as reviewer of a cheaper model's output (e.g. Opus reviews Sonnet — see adversarial section).
- **Effort:** Low–Medium. **Dependencies:** #6 helps.

### Tier 3 — Do as you scale

**8. Close the review loop / wisdom accumulation** *(was #7 loop part)*
- **What:** Have the review phase write findings back into `spec.md` as open questions and maintain a `decisions.md` the brainstorm phase reads.
- **Why:** Turns one-shot reviews into accumulating institutional knowledge. This is the "wisdom accumulation" pattern.
- **Effort:** Medium. **Dependencies:** #6.

**9. Observability** *(was #8)*
- **What:** Emit one JSON line per phase transition (`feature, phase, duration, tokens`) to a log; inspect with `jq` or a tiny dashboard.
- **Why:** Shows where time/tokens go (usually brainstorm and review dominate) so you know where to tighten prompts. Set cost budgets per phase in headless runs.
- **How:** `Stop`/`SubagentStop`/`TaskCompleted` hooks append events; in headless mode use `--output-format json` (returns `total_cost_usd`) and the approximate dollar-budget cap flag.
- **Effort:** Low–Medium. **Dependencies:** #2.

**10. CI integration via headless Claude Code** *(NEW)*
- **What:** Run spec-conformance checks and adversarial review in CI on every PR using headless mode.
- **Why:** Moves gates from "the agent remembered to" to "the pipeline enforces it."
- **How (verified):** `claude -p "<prompt>" --output-format json --allowedTools "Read,Bash(git diff:*)" --max-turns 5`. Keep the review pass **read-only** (no Edit/Write). Wrap in `timeout`. Check the exit code before parsing stdout.
- **Effort:** Medium. **Dependencies:** #6.

**11. Multi-feature concurrency** *(was #3, demoted)*
- **What:** Run one Claude Code instance per unapproved spec under `.specify/specs/`, constitution as shared contract, a final integration agent rebases and runs the suite.
- **Why demoted:** High coordination risk and cost; only worth it once single-feature runs are boring. Claude Code's native multi-session/worktree support (desktop parallel sessions under `.claude/worktrees/`) now covers most of this without a bespoke orchestrator like `mohsen1/claude-code-orchestrator` ("cco" — a Director/EM/Worker hierarchy over the Agent SDK; exists but adds a heavy dependency).
- **Effort:** High. **Dependencies:** #5.

**12. Golden examples + regression suite** *(was #10, strengthened)*
- **What:** Add a golden `examples/` run per project shape you build (API service, CLI, data pipeline). Turn these into a regression/eval harness ("golden runs") you replay to detect prompt/skill regressions.
- **Why:** New teammates and new agents learn expected artifacts by reading them; the eval harness catches quality regressions when you change prompts. Superpowers itself uses a "drill" eval harness (`superpowers-evals`).
- **Effort:** Medium. **Dependencies:** none.

### Multi-harness hygiene (was #9 — keep as a constraint, not a feature)
Keep `.specify/` harness-neutral; store harness-specific bits under `.claude/` and `.github/` (Copilot CLI). Have the flow/dispatcher call abstract phase names, not `/superpowers:*` slash commands directly, so the pipeline survives a harness switch.

### On the "intent dispatcher" (was #4 — keep, simplify)
A routing layer in front of the pipeline is worth it: not every request needs all 7 phases. Implement it as a lightweight **skill** whose description triggers on request shape, or as a `UserPromptSubmit` hook, mapping: "Add feature X" → full pipeline; "Fix bug Y" → `systematic-debugging` → TDD; "Refactor Z" → plan → tasks → execute (skip spec); "Tighten the rules" → `/speckit.constitution` only. Do **not** build a bespoke `.flow` DSL for this unless you already run `mbruhler/claude-orchestration` (which is real — it has `@review`, `@schedule`, dry-run, and `.orchestration/state.json` resume — but is a small single-maintainer project). Prefer native primitives.

---

## Supercharging Adversarial Review

This is the highest-quality-leverage upgrade to Superspec. The default `requesting-code-review` is a single fresh-context reviewer with severity buckets — good, but a single LLM reviewer is prone to **rubber-stamping** (sycophancy), **hallucinated issues**, and **false consensus** when it reviews work it (or a sibling model) produced.

### Principles (evidence-based)

1. **Fresh context, work-product only.** Reviewers must see the diff + spec + requirements, never the author's session history or rationale (blind review). Superpowers' `requesting-code-review` already does this via `code-reviewer.md` with `DESCRIPTION`, `PLAN_OR_REQUIREMENTS`, `BASE_SHA`, `HEAD_SHA` placeholders.
2. **Independent multiple lenses.** Run several reviewers with distinct personas (correctness, security, spec-conformance, performance, maintainability) in separate contexts. Anthropic's "Building Effective Agents" calls this **parallelization/voting** and explicitly cites reviewing code for vulnerabilities with several prompts as a canonical use.
3. **Structured disagreement beats naive consensus.** The academic finding that anchors this: the **Adversarial Review (AR)** protocol (arXiv 2608.18167) pairs a reviewer with a *critic* that audits the review; the artifact is frozen while review text iterates. The paper reports that "On LiveCodeBench, AR achieves the highest pass rate among tested methods, outperforming a five-agent baseline while using only three agents." The core failure mode it fixes, verbatim: "when two LLM agents are asked to agree on a joint output, they tend to agree with each other. They do not always find the truth. So the protocol must include explicit pushback."
4. **Cross-model review.** Have a stronger model review a cheaper one's output (Opus review Sonnet, or vice versa). Different models catch different defects and cross-validation filters false positives.
5. **Reviewer proves bugs with failing tests**, rather than only commenting. A finding backed by a red test is non-negotiable; a prose comment is arguable.
6. **Adversarial SPEC review before implementation.** Pre-mortem the spec: "how would this spec fail?", challenge assumptions, find ambiguities and missing acceptance criteria. Spec Kit's `/speckit.clarify` and `/speckit.analyze` are the built-in first pass.
7. **Anti-sycophancy prompting.** Force each reviewer to find issues; use evidence-guided reasoning. LLM reviewers are highly sensitive to framing — Rahman et al., "Mitigating LLM Sycophancy in Code Smell Detection Using Evidence-Guided Reasoning Prompts" (arXiv 2607.10411), report "Decision Flip Rates reaching up to 72% and False Alignment Rates exceeding 90%" (FAR reached 100% for Feature Envy on Qwen2.5) — so never tell the reviewer the author thinks the code is good.
8. **Bounded debate.** Cap rounds for cost. Optimal team size is small: Chan et al.'s ChatEval (arXiv 2308.07201, ICLR 2024) found "This pattern reaches an apex with an Acc. of 62.5% at role numbers 3 and 4 before declining at role number 5," and performance "peaked at around 2 turns and then declined." AR beats a five-agent baseline using only three agents.

### The recommended adversarial review stack for Superspec (ranked by payoff/cost)

| Rank | Layer | What it is | Payoff | Cost |
|---|---|---|---|---|
| 1 | **Spec pre-mortem gate** | `/speckit.clarify` + `/speckit.analyze` + a "red-team the spec" reviewer prompt | Very high — kills defects before code exists | Very low |
| 2 | **Hardened single reviewer** | superpowers `requesting-code-review` with anti-sycophancy + mandatory-finding prompt, fresh context | High | Low |
| 3 | **Multi-persona panel (3 lenses)** | correctness, security, spec-conformance reviewers in parallel, fresh contexts | High | Medium |
| 4 | **Reviewer-writes-failing-tests** | conformance reviewer given only the spec, writes tests, runs against impl | High — turns opinions into evidence | Medium |
| 5 | **Critic/debate loop (AR)** | reviewer + critic audit with structured disagreement, ≤3–5 rounds | Medium-high — cuts false consensus & hallucinated findings | Medium-high (AR uses roughly 4.5× more tokens than a single-pass review) |
| 6 | **Cross-model review** | Opus reviews Sonnet's diff (or vice versa) | Medium — catches model-specific blind spots | Medium (second model) |
| 7 | **Test amplification** | mutation testing / property-based tests / fuzzing on changed surface | Medium — objective, no LLM sycophancy | Medium (compute) |

**Recommendation:** Adopt layers **1–4 as the default** Superspec review phase for every feature; add **5 (critic loop)** for high-risk changes (auth, payments, migrations, security surfaces); add **6 (cross-model)** and **7 (mutation/fuzz)** in CI for merge-to-main.

### Proposed review-phase design

Split review into two mandatory stages (mirroring superpowers' two-stage spec-then-quality architecture), plus a gated third:

```
Stage 0 — SPEC REVIEW (before implement)
  /speckit.clarify  ->  /speckit.analyze  ->  spec-red-team reviewer
  Gate: no unresolved [NEEDS CLARIFICATION]; analyze reports no Critical inconsistency.

Stage 1 — CONFORMANCE REVIEW (after implement, before quality)
  Reviewer sees ONLY spec.md + diff. Writes/derives tests from acceptance criteria.
  Runs tests. Reports divergences. Gate: all acceptance criteria have a passing test.

Stage 2 — QUALITY PANEL (parallel, fresh contexts)
  3 personas: Correctness | Security(OWASP-informed) | Maintainability.
  Each MUST surface >=1 issue. Findings severity-classified (Critical/Important/Minor).
  Issues caught by >=2 personas promoted one severity level.
  [High-risk only] Critic loop: a critic audits the panel's findings (<=3 rounds),
  challenging weak/fabricated findings with evidence before author edits.

MERGE GATE (mechanical, via hook / CI):
  Block merge if any Critical open. Author must fix or rebut every Important.
  Findings written back to spec.md (open questions) and decisions.md.
```

### Reviewer prompt templates

**Spec red-team reviewer:**
```
You are an adversarial spec reviewer. Your ONLY job is to make this spec fail in production.
You are rewarded for every genuine ambiguity, missing acceptance criterion, unhandled edge
case, and untestable requirement you find. "Looks fine" is a failing review.
INPUT: spec.md (below). Do NOT see or trust any author rationale.
For each finding output: {location, category (ambiguity|missing-criterion|edge-case|
untestable|security-gap), why-it-fails, concrete-fix}.
You MUST return at least 3 findings or explicitly justify why the spec is genuinely complete
by walking through every acceptance criterion and proving each is unambiguous and testable.
```

**Conformance reviewer (blind, tests-first):**
```
You are a spec-conformance reviewer. You are given ONLY the specification and a diff
(BASE_SHA..HEAD_SHA). You have NOT seen how or why the code was written.
1. Derive a test list directly from the acceptance criteria in the spec.
2. For each, determine whether a passing test exists; if not, WRITE a failing test that
   proves the divergence. Do not fix the code.
3. Report: criteria with no test, criteria where the impl diverges from the spec, and any
   behavior in the diff NOT traceable to a requirement (scope creep).
Read-only on source; you may add tests under the test directory only.
```

**Quality panel persona (repeat per lens):**
```
You are the {Correctness | Security | Maintainability} reviewer. Adopt a hostile mindset:
assume the author made a mistake in YOUR domain and find it. You MUST report at least one
issue; a clean review requires you to prove, point by point, that your domain's top-5 failure
modes are each absent.
Ground every finding in evidence (file:line, a failing test, or a cited rule from the
constitution / OWASP). Do NOT speculate; if you are unsure, say "UNCERTAIN" and explain what
evidence would resolve it rather than issuing an approval.
Output findings as {severity: Critical|Important|Minor, location, evidence, fix}.
End with a verdict: BLOCK | CONCERNS | CLEAN.
```

**Critic (audits the panel — AR pattern):**
```
You are a critic. You did NOT review the code; you review THE REVIEW.
For each finding: is it evidence-grounded and reproducible, or speculative/fabricated?
Challenge every finding that lacks a file:line or failing test. Downgrade or reject
unsupported findings. Promote any real issue the reviewers understated. Structured
disagreement is required — do not simply agree. Return the corrected, deduplicated finding list.
```

### Gating rules (mechanical)
- Merge blocked if any **Critical** is open (enforced by a `PreToolUse` hook on `git merge`/`git push` to main, or a CI check that parses the review JSON).
- Every **Important** must be fixed or explicitly rebutted (superpowers' `receiving-code-review` treats feedback as evidence to verify, not a command to obey — good default).
- Reviewer output must be structured JSON so the gate can parse severity deterministically.

### Cost controls
- Cap debate/critic rounds (≤3 for most, ≤5 hard cap as in AR). Note AR uses roughly 4.5× more tokens than a single-pass review — reserve the full critic loop for high-risk diffs.
- Keep the panel to 3 personas (evidence: ChatEval gains peak at 3–4 reviewers and decline at 5).
- Run reviewers with a cheaper model where the lens is mechanical; reserve the strong model for security/correctness and the critic.
- In CI, use `--max-turns` and the dollar-budget cap; keep reviewers read-only (`--allowedTools "Read,Bash(git diff:*)"`).
- Reuse/cache the spec context across personas rather than re-deriving it.

### Pitfalls
- **False consensus / sycophancy:** the dominant failure. Mitigations: mandatory findings, blind review, the critic loop, cross-model review.
- **Hallucinated issues:** require evidence (file:line or failing test); the critic rejects unsupported findings.
- **Over-orchestration:** more agents ≠ better past ~4; a 5-agent panel can score *worse* than 3 (ChatEval declined at role number 5).
- **Context contamination:** never let a reviewer see the author's rationale or session.
- **Cost blowups:** the critic loop and cross-model review are expensive — gate them on risk, don't run them on every trivial diff.
- **Existing skills are community/unverified:** plugins like `alirezarezvani/claude-skills` (adversarial-reviewer: Saboteur/New-Hire/Security-Auditor personas, mandatory findings, severity promotion) and `wan-huiyan/agent-review-panel` (4–6 reviewers + judge, budget mode ~20–25% cost) are useful starting points but are third-party and lightly maintained — vet before adopting.

---

## Revised roadmap (30-60-90 day)

**Days 0–30 (reliability foundation):**
1. Rewrite constitution + add `## Code Review Rules` (#1).
2. Add gate hooks: test-gate, main-branch guard, constitution injection (#2).
3. Wire in `/speckit.clarify` + `/speckit.analyze` + `/speckit.checklist` (#3).
4. Add artifact linting (#4).
5. Harden the single reviewer with anti-sycophancy + blind context (adversarial layers 1–2).

**Days 30–60 (speed + quality):**
6. Parallelize `[P]` tasks with Agent Teams + worktrees (#5).
7. Stand up the multi-persona panel + conformance/tests-first reviewer (adversarial layers 3–4).
8. Model routing per phase (#7).
9. Observability + per-phase cost budgets (#9).

**Days 60–90 (scale):**
10. CI headless gate with cross-model review (#10, adversarial layer 6).
11. Critic/debate loop for high-risk changes (adversarial layer 5).
12. Golden examples + regression eval harness (#12).
13. Only if single-feature runs are boring: multi-feature concurrency (#11).

## What NOT to do (over-orchestration risks)
- **Don't build a bespoke `.flow` DSL or adopt a heavy multi-agent orchestrator** (`cco`, ccswarm, Gastown) before native Agent Teams / Workflow tool prove insufficient. Anthropic's own guidance: add complexity only when it demonstrably improves outcomes; start simple.
- **Don't run 5+ reviewers or unbounded debate.** Gains plateau at 3–4; cost and false-consensus rise.
- **Don't parallelize dependent tasks.** Two agents editing the same file overwrite each other; isolation stops at the filesystem (shared DBs/MCP servers still collide).
- **Don't trust green tests as "done."** Spec Kit is silent on post-implementation validation; that gap is exactly what the conformance reviewer and acceptance-criteria tests fill.
- **Don't skip the human gates.** Keep humans at the two points they add most value: spec approval and merge.

---

=== DELIVERABLE B: INSTALL-AND-USAGE-GUIDE (for PDF) ===

# Superspec Supercharged: Install & Usage Guide

> Practical, engineering-focused setup and usage for Superspec + Spec Kit + superpowers + the supercharging enhancements. Commands are copy-pasteable. Anything version-sensitive is marked **verify in your version** because these tools' CLI surfaces change frequently.

## 1. Prerequisites

- **Python 3.11+** (Spec Kit CLI is Python-based).
- **[uv](https://github.com/astral-sh/uv)** package manager: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **Git** (with worktree support — standard in modern git).
- **Node.js** (for Claude Code): `npm install -g @anthropic-ai/claude-code` (verify current install method).
- At least one coding agent: **Claude Code** and/or **GitHub Copilot CLI**.
- `jq` (for hook scripts and observability).

## 2. Installing Spec Kit

```bash
# Persistent install (recommended if you scaffold multiple projects)
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Verify
specify version
specify check

# Initialize a project with Claude Code as the agent
specify init my-project --ai claude
cd my-project
# ...or in the current directory:
specify init . --ai claude
```
One-shot without a persistent install:
```bash
uvx --from git+https://github.com/github/spec-kit.git specify init my-project --ai claude
```
Pin a release for reproducibility: append `@vX.Y.Z` to the git URL (**verify the tag** in the repo's Releases). Non-interactive/CI runs default to GitHub Copilot unless you pass `--integration`/`--ai`. Init creates the `.specify/` directory (templates, scripts, `memory/constitution.md`) and writes agent-specific command files.

## 3. Installing superpowers

Per-harness (install separately for each harness you use).
```bash
# Claude Code — official marketplace
/plugin install superpowers@claude-plugins-official
# or the superpowers marketplace:
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace

# Gemini CLI
gemini extensions install https://github.com/obra/superpowers
```
Skills auto-trigger — you don't invoke them by name. Verify with a brainstorming request. Disable optional telemetry with `export SUPERPOWERS_DISABLE_TELEMETRY=1`.

## 4. Installing Superspec

```bash
# Via Spec-Kit CLI (recommended)
specify extension add superspec

# From source
git clone https://github.com/WangX0111/superspec.git
specify extension add ./superspec --dev

# Or as an agent skill (symlink)
ln -sf "$(pwd)/superspec" ~/.claude/skills/superspec     # Claude Code
ln -sf "$(pwd)/superspec" ~/.agents/skills/superspec      # other agents
```
Superspec works standalone but auto-detects superpowers when present. Confirm with `/speckit.superspec.status`.

## 5. Installing the enhancements

### 5a. Hooks (`.claude/settings.json`)
```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "cat .specify/memory/constitution.md" } ] }
    ],
    "PreToolUse": [
      { "matcher": "Bash",
        "hooks": [ { "type": "command", "command": "bash .claude/hooks/block-main-commit.sh" } ] }
    ],
    "PostToolUse": [
      { "matcher": "Edit|Write",
        "hooks": [ { "type": "command", "command": "bash .claude/hooks/artifact-lint.sh" } ] }
    ],
    "Stop": [
      { "hooks": [ { "type": "command", "command": "bash .claude/hooks/log-phase.sh" } ] }
    ]
  }
}
```
`.claude/hooks/block-main-commit.sh`:
```bash
#!/usr/bin/env bash
input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // ""')
branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if echo "$cmd" | grep -qE 'git\s+commit' && [ "$branch" = "main" ]; then
  echo "Refusing to commit on main; use a feature branch." >&2
  exit 2   # exit 2 on PreToolUse blocks the tool call
fi
exit 0
```
`.claude/hooks/test-gate.sh` (attach to `Edit|Write` on `tasks.md`, or run before marking done):
```bash
#!/usr/bin/env bash
# Only allow a task to be marked [X] if the test command passed.
if ! npm test --silent; then
  echo "Tests failing — cannot mark task complete." >&2
  exit 2
fi
exit 0
```
> **verify in your version:** exact hook event names and exit-code behavior. Confirmed today: `PreToolUse` + exit 2 blocks; `Stop` + exit 2 forces continuation; `SessionStart` re-runs on resume/compact.

### 5b. Agent Teams config (parallel `[P]` tasks)
```bash
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1   # verify env var name in your version
```
Then prompt the lead (see §8). Optionally define reusable teammates under `.claude/agents/`.

### 5c. Adversarial reviewers (`.claude/agents/`)
Create one markdown file per reviewer. Minimal frontmatter: `name`, `description` (this is the trigger — make it keyword-rich), optional `tools`, `model`. Read-only reviewers should omit `Edit`/`Write`. Example `.claude/agents/security-reviewer.md`:
```markdown
---
name: security-reviewer
description: Hostile OWASP-informed security reviewer. Use to review diffs before merge.
tools: Read, Grep, Bash
model: claude-opus-4  # verify model id in your version; strong model for security lens
---
You are the Security reviewer. Adopt a hostile mindset... (paste the persona template from
Deliverable A). You MUST report >=1 issue or prove the top-5 OWASP failure modes are absent.
Ground every finding in file:line or a failing test. End with BLOCK | CONCERNS | CLEAN.
```
Repeat for `correctness-reviewer.md`, `conformance-reviewer.md`, `critic.md`. For cross-model review, define a reviewer agent pinned to a different model (e.g. `model: claude-opus-4`) and dispatch the same diff to it.

### 5d. Flow file / dispatcher (optional)
Prefer native primitives. If you want an explicit flow, `mbruhler/claude-orchestration` (`.flow` syntax with `@review`, `@schedule`, dry-run, `.orchestration/state.json` resume) is the closest real tool — **verify it's maintained** before depending on it. A dispatcher is best implemented as a routing skill or a `UserPromptSubmit` hook (see Deliverable A).

### 5e. Observability
`.claude/hooks/log-phase.sh` appends one JSON line per phase:
```bash
#!/usr/bin/env bash
input=$(cat)
echo "{\"ts\":\"$(date -Iseconds)\",\"event\":\"stop\",\"cwd\":\"$(pwd)\"}" >> .specify/telemetry.jsonl
```
Inspect: `jq -s 'group_by(.event) | map({event: .[0].event, n: length})' .specify/telemetry.jsonl`. In headless CI, capture `total_cost_usd` from `--output-format json`.

## 6. Verifying the install

```bash
specify check                          # Spec Kit environment
specify version
/speckit.superspec.status              # inside your agent — should print project status
```
- Superpowers: start a brainstorming request; confirm the skill triggers.
- Hooks: edit a file / attempt a commit on main; confirm the gate fires.
- Agent Teams: ask the lead to spawn a teammate; confirm a second context starts.
- Reviewers: run `@security-reviewer` (or `/agents` to list) on a small diff.

## 7. How it works (end to end)

Artifacts live under `.specify/memory/` (constitution) and `specs/NNN-*/` (`spec.md`, `plan.md`, `tasks.md`, `progress.yml`, `checklist-*.md`). The supercharged pipeline:

```mermaid
flowchart TD
  A[/speckit.constitution/] -->|constitution.md| B[/speckit.specify/]
  B -->|spec.md| C[/speckit.clarify/]
  C --> D[spec red-team reviewer]
  D -->|Stage 0 gate: no NEEDS-CLARIFICATION| E[/speckit.superspec.brainstorm/]
  E --> F[/speckit.plan/]
  F -->|plan.md| G[/speckit.superspec.tasks/  -> tasks.md with P markers]
  G --> H[/speckit.analyze cross-artifact check/]
  H -->|Stage 0 gate: no Critical inconsistency| I{Parallel execute}
  I -->|worktree, teammate 1| T1[task P1 TDD]
  I -->|worktree, teammate 2| T2[task P2 TDD]
  I -->|worktree, teammate 3| T3[task P3 TDD]
  T1 --> J[Stage 1: conformance reviewer - blind, tests-first]
  T2 --> J
  T3 --> J
  J --> K[Stage 2: quality panel - correctness / security / maintainability]
  K --> L{High risk?}
  L -->|yes| M[critic loop <=3 rounds AR]
  L -->|no| N[merge gate]
  M --> N[merge gate: block on Critical]
  N -->|findings -> spec.md + decisions.md| O[/speckit.superspec.finish -> merge/PR/]
```

**Where each enhancement plugs in:**
- Constitution/skills (#1) feed every phase; injected at `SessionStart`.
- `clarify`/`analyze`/`checklist` gates (#3) sit around specify and before execute.
- Hooks (#2) enforce test-gate, main-branch guard, artifact lint mechanically.
- Agent Teams + worktrees (#5) run the `[P]` tasks in the "Parallel execute" node.
- The adversarial stack (#6) is Stages 0/1/2 + critic + merge gate.
- Model routing (#7): cheap model on task nodes, strong model on security/critic.
- Observability (#9): `Stop`/`TaskCompleted` hooks log each transition.
- CI headless (#10): re-runs Stage 1/2 read-only on every PR.

**Artifacts per phase:** constitution → `constitution.md`; specify → `spec.md`; clarify → resolved `[NEEDS CLARIFICATION]` markers; plan → `plan.md`; tasks → `tasks.md` (`[P]` tags); execute → source + tests + updated `progress.yml`; review → structured findings + `decisions.md` updates.

## 8. Day-to-day usage

### New feature
```
/speckit.constitution                       # once per project (or when rules change)
/speckit.specify "User authentication with email and password"
/speckit.clarify                             # resolve underspecified areas
@spec-red-team-reviewer                      # adversarial spec pre-mortem (Stage 0)
/speckit.superspec.brainstorm specs/001-user-authentication/spec.md
/speckit.plan
/speckit.superspec.tasks
/speckit.analyze                             # cross-artifact consistency gate
/speckit.superspec.execute                   # implement (parallel if teams enabled)
/speckit.superspec.review                    # then run the panel below
```

### Running parallel tasks (Agent Teams)
```
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
```
Then, in the lead session:
```
Create an agent team to implement the [P] tasks in specs/001-*/tasks.md.
Spawn one teammate per independent task, each in its own git worktree
(use the using-git-worktrees skill). Brief each teammate fully — they do NOT
inherit my context. Keep file scopes non-overlapping. Enable delegate mode so
you only coordinate. Rejoin at a single review gate before merge.
```

### Running adversarial review
Interactive:
```
# Stage 1 — conformance, blind + tests-first
@conformance-reviewer  review specs/001-*/spec.md against HEAD~N..HEAD; write failing tests for gaps
# Stage 2 — quality panel (parallel)
@correctness-reviewer / @security-reviewer / @maintainability-reviewer  on the same diff
# High-risk only — critic audit
@critic  audit the panel's findings; reject unsupported ones, promote understated ones
# Cross-model (optional) — dispatch the same diff to a reviewer agent pinned to a different model
@opus-reviewer  challenge the caching/retry design
```
Headless / CI (read-only, bounded):
```bash
claude -p "Review the diff origin/main...HEAD against specs/*/spec.md. Report findings as
JSON {severity,location,evidence,fix}. Do not edit files." \
  --output-format json \
  --allowedTools "Read,Bash(git diff:*)" \
  --max-turns 5
# gate:
timeout 180 claude -p "..." --output-format json | jq -e '[.result[]?|select(.severity=="Critical")]|length==0'
```

### Bug fix
```
# route to debugging, not the full pipeline
Use systematic-debugging to find root cause of <symptom>, then TDD the fix.
# then a targeted review:
@correctness-reviewer on the fix diff
```

### Refactor
```
/speckit.plan     # skip specify
/speckit.superspec.tasks
/speckit.superspec.execute
@maintainability-reviewer + mutation tests on changed surface
```

### Constitution change
```
/speckit.constitution        # edit rules
# analyze will now re-check existing specs/plans against the new rules
/speckit.analyze
```

### Approving gates & finishing a branch
- **Spec gate:** approve after `clarify`/`analyze`/red-team return clean.
- **Merge gate:** approve only when no Critical is open and every Important is fixed or rebutted.
- **Finish:** superpowers' `finishing-a-development-branch` presents merge/PR/keep/discard and cleans up the worktree. Findings are written back to `spec.md` (open questions) and `decisions.md`.

## 9. Troubleshooting / FAQ
- **Slash commands don't appear:** you opened the wrong folder — open the repo root where `.specify/` (and `.github/prompts` for Copilot) live.
- **`uvx: command not found`:** install `uv` first.
- **Superpowers skills don't trigger:** reinstall per-harness; on Hermes/long sessions that compacted, start a fresh session (bootstrap can be lost).
- **Teammate asks basic questions:** it didn't inherit your context — put everything it needs in the spawn brief.
- **Hook didn't block:** confirm the event supports blocking (only `PreToolUse` exit 2 blocks a tool call), the matcher targets the tool name (not prompt text), and your settings file is the one being read; test the script directly with sample JSON.
- **Headless run "succeeded" but stdout is empty:** a hard failure (auth/rate-limit) can still exit non-zero with no JSON — check the exit code before parsing; always wrap in `timeout`.
- **Reviewer rubber-stamps everything:** enforce mandatory findings, blind context, and add the critic loop; never tell the reviewer the author's opinion.
- **Too expensive:** cut panel to 3 personas, cap critic rounds, route cheap models to mechanical phases, gate the AR critic loop on high-risk diffs only (~4.5× token cost).
- **Parallel agents clobber each other:** ensure separate worktrees and non-overlapping file scopes; give them separate DBs/test resources.

## 10. Quick-reference command cheat sheet
```
# Install
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
specify init . --ai claude
/plugin install superpowers@claude-plugins-official        # Claude Code
specify extension add superspec

# Spec Kit core
/speckit.constitution   /speckit.specify   /speckit.clarify   /speckit.plan
/speckit.checklist      /speckit.tasks     /speckit.analyze    /speckit.implement

# Superspec
/speckit.superspec.status | .brainstorm | .tasks | .execute | .review

# Parallelism
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# Adversarial review (interactive)
@spec-red-team-reviewer  @conformance-reviewer  @correctness-reviewer
@security-reviewer  @maintainability-reviewer  @critic

# Headless review gate
claude -p "<prompt>" --output-format json --allowedTools "Read,Bash(git diff:*)" --max-turns 5
```

**Key repos/docs:** github.com/WangX0111/superspec · github.com/github/spec-kit · github.com/obra/superpowers · code.claude.com/docs (hooks, sub-agents, agent-teams, headless) · anthropic.com/research/building-effective-agents. Treat all version-specific commands as **verify in your version**.

---

### Sourcing & uncertainty notes (not part of the deliverables — for your awareness)
- **Verified against live sources (Sept 2026):** Superspec repo (56★/7 forks/10 commits, MIT, 5 commands, 6/7-phase flow, install methods); Spec Kit install + slash commands + `[P]` tags; superpowers install per-harness + full skill list + two-stage review architecture; Claude Code hooks (events, exit-code semantics), subagents (`.claude/agents`, frontmatter, description-as-trigger), Agent Teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`, lead/teammate model), headless `-p`/`--output-format json`; Anthropic evaluator-optimizer & orchestrator-worker patterns; AR paper (arXiv 2608.18167), ChatEval (arXiv 2308.07201), sycophancy study (arXiv 2607.10411).
- **Could NOT verify / flagged in-text:** the popular "3–7 agents = best accuracy-to-cost" claim is unsupported by primary sources — ChatEval's measured optimum is 3–4 roles, declining at 5; I used that instead. Exact model IDs, the Agent Teams env-var name, and Spec Kit's exact command roster are version-sensitive and marked "verify in your version." `mbruhler/claude-orchestration` and `mohsen1/claude-code-orchestrator` exist but are small single-maintainer projects; native Claude Code primitives are recommended over them.