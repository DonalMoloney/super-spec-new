# Adversarial review research

Background for the review stack this repository implements: why more than one
reviewer is needed, which biases a single LLM reviewer shows, and how the
stages and personas under `.claude/agents/` were chosen. Read it when changing
a reviewer persona, the critic loop, or the risk thresholds, so a change argues
against the evidence rather than around it.

This is reference material, not a tracker. `improvements/roadmap.md` holds the
open work and `improvements/reference.md` holds the divergence option space.
Parts 3, 6, and 7 and the glossary and sources below were moved here from
`imporvements/imporvements2.md`, which was the v2 playbook; the rest of that
file was either implemented or duplicated `specflow/README.md`. Text is carried
over unchanged, so the quoted findings and the "verify in your version" caveats
still read as they did when they were gathered on 2026-09-11.

## Part 3 — Supercharging Adversarial Review

### 3.1 The core problem (v1)
Superspec's default `requesting-code-review` is a single fresh-context reviewer with severity buckets. A single LLM reviewer is prone to **rubber-stamping (sycophancy)**, **hallucinated issues**, and **false consensus**.

### 3.2 Principles (v1, re-verified)
1. **Fresh context, work-product only** (blind review; superpowers' reviewer uses DESCRIPTION, PLAN_OR_REQUIREMENTS, BASE_SHA, HEAD_SHA).
2. **Independent multiple lenses** (Anthropic "Building Effective Agents").
3. **Structured disagreement beats naive consensus** — the Adversarial Review (AR) protocol (arXiv 2608.18167; **re-confirm ID in your version**): reviewer + critic auditing the review; artifact frozen while review text iterates; "On LiveCodeBench, AR achieves the highest pass rate among tested methods, outperforming a five-agent baseline while using only three agents"; "when two LLM agents are asked to agree on a joint output, they tend to agree with each other... So the protocol must include explicit pushback."
4. **Cross-model / cross-harness review** (Codex reviews Claude, Opus reviews Sonnet).
5. **Reviewer proves bugs with failing tests.**
6. **Adversarial SPEC review before implementation** (pre-mortem; `/speckit.clarify`, `/speckit.analyze`).
7. **Anti-sycophancy prompting** — Rahman et al. (arXiv 2607.10411; **re-confirm ID**) report Decision Flip Rates up to 72% and False Alignment Rates >90% (FAR 100% for Feature Envy on Qwen2.5); never tell the reviewer the author thinks the code is good.
8. **Bounded debate** — ChatEval (arXiv 2308.07201, ICLR 2024): accuracy peaks at 3–4 roles (62.5%) and declines at 5; performance peaked ~2 turns.

### 3.3 LLM-as-judge bias catalog — **NEW in v2**
- **Self-preference bias.** Panickssery, Bowman & Feng, *LLM Evaluators Recognize and Favor Their Own Generations* (NeurIPS 2024, arXiv 2404.13076): LLM evaluators "score their own outputs higher than others' while human annotators consider them of equal quality," and self-preference strength is **linearly correlated with self-recognition capability**. Implication: **use a different-vendor model to review than the one that wrote the code.**
- **Position/order bias** and **verbosity bias** (Wang et al. 2024; Saito et al. 2023): mitigate with **randomized presentation order** and length-normalized rubrics.
- **Narcissistic score inflation** (Liu et al.): don't let a model both write and grade.

### 3.4 Limits of self-correction — **NEW in v2**
Huang et al., *Large Language Models Cannot Self-Correct Reasoning Yet* (ICLR 2024, arXiv 2310.01798): LLMs "struggle to self-correct their responses without external feedback, and at times, their performance even degrades after self-correction." Reviewers therefore need **external signals** — failing tests, SAST tools, other models. Reflexion/Self-Refine help only when grounded in an external verifier; Anthropic's Claude Code best practices echo this ("give Claude a way to verify its work"; explore-plan-code-commit).

### 3.5 Multi-agent debate lineage — **NEW in v2**
- Irving, Christiano & Amodei, *AI Safety via Debate* (arXiv 1805.00899, 2018) — two agents argue, a judge decides.
- Du, Li, Torralba, Tenenbaum & Mordatch, *Improving Factuality and Reasoning through Multiagent Debate* (ICML 2024, arXiv 2305.14325) — instances "propose and debate their individual responses... over multiple rounds," improving factual validity and reducing hallucinations.
- Liang et al. 2023: encouraging divergent thinking **reduces sycophantic convergence** — the basis for AR's mandatory pushback.

### 3.6 CriticGPT lesson — **NEW in v2**
McAleese et al. (OpenAI), *LLM Critics Help Catch LLM Bugs* (arXiv 2407.00215, 2024): "On code containing naturally occurring LLM errors model-written critiques are preferred over human critiques in 63% of cases, and human evaluation finds that models catch more bugs than human contractors paid for code review." **Human+CriticGPT teams** move beyond the model-only frontier with fewer hallucinated bugs. Lessons: (a) a dedicated *critic* role beats a generic reviewer; (b) human-in-the-loop reduces false positives; (c) even trained critics hallucinate — require evidence (file:line, failing test).

### 3.7 The recommended review stack (v1, ranked payoff/cost)
1. **Spec pre-mortem gate** (clarify + analyze + red-team + STRIDE) — very high / very low.
2. **Hardened single reviewer** (anti-sycophancy, mandatory finding, fresh context) — high / low.
3. **Multi-persona panel** (correctness, security, spec-conformance) — high / medium.
4. **Reviewer-writes-failing-tests** (conformance reviewer given only spec) — high / medium.
5. **Critic / debate loop** (AR, ≤3–5 rounds) — medium-high / medium-high (~4.5× tokens).
6. **Cross-model review** — medium / medium.
7. **Test amplification + SAST** — medium / medium.
- **Recommendation:** layers 1–4 default; 5 for high-risk (auth, payments, migrations, security); 6 and 7 in CI for merge-to-main.

### 3.8 Review-phase design (v1)
- **Stage 0 SPEC REVIEW:** clarify → analyze → spec-red-team + STRIDE. Gate: no unresolved `[NEEDS CLARIFICATION]`, no Critical inconsistency.
- **Stage 1 CONFORMANCE:** reviewer sees only `spec.md` + diff; derives tests from acceptance criteria. Gate: every criterion has a passing test.
- **Stage 2 QUALITY PANEL:** 3 personas in parallel fresh contexts — Correctness | Security (OWASP) | Maintainability; each MUST surface ≥1 issue; severity Critical/Important/Minor; issues caught by ≥2 personas promoted one level; high-risk only: critic loop ≤3 rounds.
- **MERGE GATE (mechanical via hook/CI):** block on any open Critical; author fixes or rebuts every Important; findings written to `spec.md` and `decisions.md`.

### 3.9 Reviewer calibration & scorecards — **NEW in v2**
Track **finding precision** per reviewer/persona: accepted ÷ (accepted + rejected-by-critic + rejected-by-human). Keep a **reviewer scorecard** (`.specify/telemetry.jsonl` → weekly `jq` rollup). A persona with precision <0.5 is over-flagging (tighten its "prove the failure mode" requirement); a persona that never gets promoted findings is under-reading (raise its hostility).

### 3.10 Risk classification rules — **NEW in v2**
Escalate to critic loop **and** cross-model review when any of: **paths touched** (`auth/`, `payments/`, `billing/`, `migrations/`, `infra/`, `secrets`, crypto, CODEOWNERS "sensitive"); **diff size** > N lines / > M files (start N=400, M=15); **dependency changes** (lockfiles/manifests); **schema/API** changes. Otherwise run layers 1–4 only. Implemented as `.claude/hooks/risk-classifier.sh`; ADR-0005 records the integer scoring.

### 3.11 Prompt templates (v1), implemented as the agent files under `.claude/agents/`
Spec red-team reviewer (≥3 findings or prove completeness criterion-by-criterion; `{location, category, why-it-fails, concrete-fix}`); Conformance reviewer (blind, tests-first, read-only on source); Quality panel persona (hostile, ≥1 issue or prove top-5 failure modes absent, evidence required, "UNCERTAIN" allowed, verdict BLOCK|CONCERNS|CLEAN); Critic (reviews THE REVIEW; downgrade/reject unsupported; promote understated; structured disagreement required).

### 3.12 Gating rules, cost controls, pitfalls (v1)
- **Gating:** merge blocked on open Critical (PreToolUse hook on `git merge`/`git push` to main, or CI parsing review JSON); every Important fixed or rebutted; structured JSON output.
- **Cost:** cap rounds (≤3, hard ≤5); 3 personas; cheaper model for mechanical lenses; `--max-turns` + dollar budget cap in CI; reviewers read-only; reuse/cache spec context.
- **Pitfalls:** false consensus/sycophancy; hallucinated issues; over-orchestration (>4 agents worse); context contamination; cost blowups.

### 3.13 Adversarial-review plugin comparison — **NEW in v2 (verified this session)**

| Project | Exists / stars | Status | Roles / personas | Install / invoke | Verdict |
|---|---|---|---|---|---|
| `openai/codex-plugin-cc` | Yes; ~32.7k★ (official OpenAI) | **Very active** (Apache-2.0; launched ~Mar 31 2026) | Single steerable **skeptical Codex reviewer** ("break confidence in the change, not validate it"); read-only; optional review gate | `/plugin marketplace add openai/codex-plugin-cc` → `/plugin install codex@openai-codex` → `/codex:setup`; `/codex:adversarial-review [--base <ref>] [--background]` | **De-facto standard for cross-model review inside Claude Code** |
| `alirezarezvani/claude-skills` (adversarial-reviewer) | Yes; ~25–26k★ (**snippets, not page-verified**) | **Active** (MIT; large mono-repo) | 3 hostile personas: **Saboteur** (prod breaks), **New Hire** (maintainability), **Security Auditor** (OWASP); each must find ≥1 issue | `/plugin marketplace add alirezarezvani/claude-skills` → `/plugin install engineering-skills@claude-code-skills`; `/adversarial-review [--diff HEAD~3]` | **Active; good persona set to borrow** |
| `wan-huiyan/agent-review-panel` (`roundtable`) | Yes; **21★** | **Active but niche** (MIT; v3.5.0, Jun 6 2026) | 4–6 reviewers (Correctness Hawk, Security Auditor, Devil's Advocate, Feasibility, Risk) + a **Supreme Judge**; cost tiers ~$3–$20/run | `claude plugin marketplace add wan-huiyan/agent-review-panel` → `claude plugin install roundtable@agent-review-panel`; `/roundtable:agent-review-panel [deep]` | **Claude-only; borrow the judge pattern** |
| `alecnielsen/adversarial-review` | Yes; **37★** | **Stale / prototype** (MIT; only 2 commits) | Claude + GPT Codex, 4-phase debate loop, loops until both report NO_ISSUES | `git clone` then `./adversarial_review.sh ../my-project` (needs `claude`, `codex`, `jq`) | **Reference only; unmaintained** |

**Other 2025–2026 entrants (existence confirmed; stars/dates not individually page-verified):** `ng/adversarial-review` (Optimizer + Skeptic, cost-gated); `robertoecf/adversarial-review` ("review triad," cross-host routing); `mcarlssen/claude-adversarial-review` (pre-commit skeptic-disproof); `pedronauck`/`poteto-noodle` adversarial-review skill (Skeptic/Architect/Minimalist, auto-scaled). **Official Anthropic:** managed **Code Review** research preview (dispatches parallel agents, verifies findings, ranks severity, posts inline; Team/Enterprise; not OSS) and the **`claude-security` plugin** beta (six-phase scanner; findings must clear a **3-voter adversarial panel — REACHABILITY / IMPACT / DEFENSES — with 2-of-3 quorum**; `/plugin install claude-security@claude-plugins-official`). Anthropic reported Claude Code Security launched as a limited research preview for Enterprise/Team on Feb 19–20 2026 and, using Claude Opus 4.6, "found and validated more than 500 high-severity vulnerabilities in production open-source codebases." **All third-party skills are lightly maintained — vet the source before installing.**

---


## Part 6 — Operating It as a Team — **NEW in v2**

**Roles.** **Spec owner** (owns `spec.md`, approves Stage 0, resolves `open-questions.md`); **Reviewer-of-record** (accountable for the merge decision; owns the critic/verdict); **Merge approver** (the human who clears the merge gate — can equal reviewer-of-record on small teams).

**The two human gates (never automated away):** (1) **spec approval** (after Stage 0), (2) **merge approval** (after the merge gate passes mechanically). Everything between can be autonomous.

**Review SLAs.** Standard-risk PRs: automated review within CI runtime (target < 25 min); human merge approval within one business day. HIGH-risk: cross-model + critic loop, human review same day.

**KPIs / metrics (from `.specify/telemetry.jsonl` + git):** review cycle time (spec-approved → merged); defect escape rate (bugs found post-merge ÷ total); reviewer finding precision (per persona — §3.9); cost per feature (sum of `total_cost_usd`); mutation score trend (per module); DORA-style (deployment frequency, lead time, change-fail rate, MTTR).

**Constitution change management / versioning.** Treat `constitution.md` like code: PR + `/speckit.analyze` + reviewer-of-record approval; keep a `## Version` header and changelog; announce breaking rule changes.

**Cost governance.** Per-phase budgets via the headless budget cap; model routing (ADR-0003 and ADR-0014 in `decisions.md`); gate the expensive layers (critic loop, cross-model, mutation) on `risk-classifier.sh`; on a Max flat-rate plan, per-session cost matters less but token volume still affects latency.

**Weekly ritual (30 min).** Prune `decisions.md` (mark superseded ADRs), clear resolved `open-questions.md`, run `bash .claude/review/scorecard.sh` and tune any persona with precision < 0.5 or zero promoted findings, eyeball mutation-score and cost-per-feature trends.

---

## Part 7 — Anti-Patterns & Failure Modes Catalog — **NEW in v2**

| Anti-pattern | Symptom | Cause | Fix |
|---|---|---|---|
| **Sycophantic reviewer** | Every review is "LGTM" | Single LLM, author approval leaked into prompt | Blind context; mandatory ≥1 finding; add critic; different-vendor model (Panickssery self-preference; Rahman sycophancy) |
| **Hallucinated findings** | Reviewer cites bugs that don't exist | No evidence requirement | Require file:line / failing test; allow "UNCERTAIN"; critic rejects unsupported (CriticGPT nitpick lesson) |
| **Over-orchestration** | 6+ agents, slower and worse | "More agents = better" myth | Cap at 3–4 personas + 1 critic (ChatEval peak 3–4; AR beats 5-agent baseline with 3) |
| **Same-file clobbering** | Parallel teammates overwrite each other | Overlapping scopes, shared working tree | Worktrees per teammate; non-overlapping scopes; separate test DBs |
| **Prompt-level gates that silently skip** | Phase skipped, no error | Gate is a suggestion, not enforced | Move gate into a `PreToolUse` hook (exit 2) or CI check |
| **Constitution bloat** | Model ignores rules; context blown | Kitchen-sink constitution | Keep tight; `@import` sub-files; prune (context "finite attention budget"/"context rot") |
| **Stale CLAUDE.md** | Agent follows outdated conventions | Memory never pruned | Weekly ritual; ADR supersession; `#` shortcut discipline |
| **Teammate context starvation** | Teammate does the wrong thing | Didn't inherit the lead's history | Brief teammates fully and explicitly |
| **Unbounded debate** | Cost spikes, no convergence | No round cap | Hard-cap rounds at 3 (≤5); gate the loop on risk |
| **Green tests = done** | Bugs ship through 100% coverage | Coverage ≠ assertion quality | Mutation-score gate; conformance reviewer derives tests from spec |
| **Headless silent failure** | CI "passes" but nothing ran | stdout not JSON / no exit-code check / timed-out prompt | Check exit code + `is_error`; wrap in `timeout`; parse defensively |
| **Hook matcher on prompt text** | Security hook never fires | Matcher expects a tool name, not free text | Match on tool name (`Bash`, `Edit|Write`); FileChanged matches filenames |
| **Same model writes and reviews** | Inflated verdicts | Self-preference bias | Cross-model review (Opus↔Codex) |
| **Skipping human gates** | Bad specs built; bad code merges | Full automation zeal | Keep spec-approval and merge-approval human |
| **Heavy orchestrator too early** | Complexity with no payoff | Adopting cco/ccswarm before native primitives fail | Use worktrees + Agent Teams first |

---


## Part 8 — Revised 30-60-90 Roadmap + What NOT to Do

**Days 0–30 (foundation):** rewrite constitution + `## Code Review Rules`; CLAUDE.md hierarchy with `@import`; gate hooks (block-main-commit, artifact-lint, test-gate); clarify/analyze/checklist gates; hardened single reviewer with anti-sycophancy + mandatory findings; `/security-review` in the loop.

**Days 30–60 (parallelism + review depth):** Agent Teams + worktrees; multi-persona panel + conformance reviewer + traceability matrix; STRIDE spec lens; model routing; observability + reviewer scorecards + per-phase budgets; mutation-testing gate on core modules.

**Days 60–90 (scale + CI):** headless merge-gate workflow (Claude review + Codex cross-model + SAST + mutation); critic/AR loop for HIGH risk; risk-classifier wiring; pipeline eval harness + golden runs; PR automation (`@claude`, PR template); differential/N-version implementation for high-ambiguity specs; multi-feature concurrency **only if single-feature runs are boring.**

**What NOT to do (v1 + extended):** Don't build a bespoke `.flow` DSL or adopt heavy orchestrators (cco, ccswarm, Gastown) before native primitives prove insufficient. Don't run 5+ reviewers or unbounded debate. Don't parallelize dependent tasks. Don't trust green tests as "done" (Spec Kit is silent on post-implementation validation — the conformance reviewer + mutation gate fill the gap). Don't skip the two human gates. **NEW:** don't let the model that wrote the code be its sole reviewer; don't rely on intrinsic self-correction without an external verifier (Huang 2023); don't run the expensive layers on every PR — gate them on risk; don't install unvetted third-party review plugins into a repo with secrets.

---

## Appendix D — Glossary
- **SDD** — Spec-Driven Development.
- **`[P]`** — Spec Kit marker for an independent (parallelizable) task.
- **AR** — Adversarial Review protocol (reviewer + critic auditing the review).
- **STRIDE** — Spoofing/Tampering/Repudiation/Information disclosure/DoS/Elevation of privilege.
- **Mutation score** — % of injected code mutants that tests kill; a test-quality gate.
- **Dual execution agreement** — CodeT's consensus selection across independently generated code+tests.
- **Self-preference bias** — an LLM judge favoring its own generations (Panickssery 2024).
- **Agent Teams** — Claude Code's experimental peer-to-peer multi-session mode (lead + teammates).
- **Conformance reviewer** — a blind reviewer that derives tests from the spec, not the code.

## Appendix E — Sources & Verification Status
**Verified live this session (Sept 11 2026):**
- Superspec repo (id 1217951047), description, install/skill/symlink commands, 5 added commands, delegation, `examples/`, pinned-release URL (tag v1.0.1 on the SpecKit community page).
- Spec Kit extension mechanism: `specify extension search/add/--from/--dev`, `.specify/extensions/`, namespaced `speckit.{ext}.{cmd}`, empty upstream catalog, `SPECKIT_CATALOG_URL`, maintainer non-endorsement.
- superpowers v6.0.0–v6.3.0 (v6.3.0 current; DeepWiki indexed Sept 1 2026), plan-scoped SDD workspace + `git clean -fdx` caveat, Gemini CLI EOL 2026-06-18, harness list, skill list, subagent-driven requirement.
- Claude Code hooks: exit-2 semantics, exit-1-only-warns, JSON-XOR-exit-code, 33 events (Sept 6 2026), five workhorse events.
- Subagents: `.claude/agents/*.md` frontmatter (name, description, tools, disallowedTools, model, permissionMode, maxTurns, skills, mcpServers, memory), `/agents` wizard removed v2.1.198.
- Agent Teams: env var, v2.1.32 (Feb 5 2026), lead/teammate mailbox, ~1M ctx each, resume/rewind caveats, one-team-per-session.
- Headless: `-p`/`--print`, `--output-format json|stream-json` (+`total_cost_usd`, `session_id`, `is_error`), `--allowedTools`, `--permission-mode`, `--max-turns`, `--json-schema`, `--resume`/`--continue`; print-mode dollar-budget cap (name flagged to verify).
- Codex: `codex exec` headless, `codex review --base main --json`, `AGENTS.md` conventions + caching, sandbox flags, `--output-schema` gpt-5 constraint.
- `/security-review` command + `anthropics/claude-code-security-review` Action, **announced Aug 6, 2025** (not 2026).
- GitHub App: `/install-github-app`, `@claude`, `anthropics/claude-code-action@v1`, `claude_args`, managed Code Review preview, `/code-review --fix`.
- Mutation tools + thresholds (Stryker break threshold/exit 1, mutmut `--CI`, PIT `<mutationThreshold>`, cargo-mutants, etc.).
- Research: CodeT (2207.10397; "improves the pass@1 on HumanEval to 65.8%, an increase of absolute 18.8%... and an absolute 20+% improvement over previous state-of-the-art"); Panickssery self-preference (2404.13076, NeurIPS 2024); Huang self-correction (2310.01798, ICLR 2024); Du multiagent debate (2305.14325, ICML 2024); Irving debate (1805.00899); McAleese CriticGPT (2407.00215, "preferred over human critiques in 63% of cases"); Anthropic context-engineering post ("context rot," "attention budget," Sept 2025). Anthropic Code Review Security preview (Feb 19–20 2026; Opus 4.6 "found and validated more than 500 high-severity vulnerabilities").
- Plugin landscape (subagent-verified): `openai/codex-plugin-cc` (~32.7k★, active), `alirezarezvani/claude-skills` (~25–26k★, not page-verified), `wan-huiyan/agent-review-panel` (21★, v3.5.0), `alecnielsen/adversarial-review` (37★, stale).

- **v3 additions (Sept 11 2026):** Copilot CLI hooks reference (`.github/hooks/`, six events, `preToolUse` deny via JSON on stdout, `bash`/`powershell` keys); Copilot CLI programmatic reference (`-p`, `--allow-tool`, `--allow-all-tools` caveat); spec-kit `docs/reference/extensions.md` (catalog JSON schema 1.0, `.specify/extension-catalogs.yml` fields, `SPECKIT_CATALOG_URL` override).

**"Verify in your version" (could not fully pin):** Superspec's exact current command roster and latest tag; the exact Claude headless dollar-budget flag name; exact model IDs/aliases; Agent Teams stability (experimental); Codex hooks/teams equivalents; the arXiv IDs 2608.18167 (AR protocol) and 2607.10411 (Rahman sycophancy) — carried from v1, not re-fetched this session; `alirezarezvani/claude-skills` star count (snippets only).
