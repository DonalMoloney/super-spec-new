---
marp: true
theme: default
paginate: true
---

<!-- Slides below are appended in order by dedicated subagents. Do not reorder. -->

---

## Specflow: Bridging Spec-Kit Governance with Superpowers Execution

- Specflow (fork of Superspec) wires GitHub Spec Kit's governance artifacts to obra/superpowers' execution skills — hardened with deterministic hooks and cross-model verification
- v2 refreshes verification across Spec Kit, superpowers (v6.3.0), Claude Code hooks, subagents, and Agent Teams
- Adds 10 new improvement items: memory/knowledge layer, N-version implementation, security scanning, test amplification, PR automation, and more
- New adversarial-review research: LLM-as-judge bias catalog, multi-agent debate lineage, reviewer calibration, and risk-classification rules
- Ships a ready-to-paste implementation kit — settings, hooks, templates, findings schema, and a GitHub Actions workflow

<!-- speaker notes: Open by framing Specflow as a thin but useful bridge between Spec Kit's governance workflow and superpowers' execution skills — the goal isn't to fork Spec Kit but to wrap it in stronger guardrails. Emphasize that v2 keeps everything from v1 and layers on ten new improvement items plus fresh adversarial-review research. Mention that this deck's scope is Claude Code and GitHub Copilot CLI only, not Codex. Close by noting the implementation kit is copy-paste ready, so teams can adopt it immediately. -->

---

## Where Specflow is Today + the Improvement Roadmap

- Today: 5 commands (`status`, `brainstorm`, `tasks`, `execute`, `review`) bridging Spec Kit governance artifacts to superpowers execution skills, with resumable state in `.specify/memory/` and `specs/NNN-*/`
- Verified dependencies: Spec Kit's extension mechanism and superpowers v6.3.0, both re-confirmed live on Sept 11, 2026
- Tier 1 (foundation): rewrite the constitution with real project conventions; enforce phase gates deterministically with hooks instead of prompt-level asks
- Tier 2 (parallelism, review, routing): parallelize `[P]` tasks with Agent Teams; layer in differential N-version implementation and objective security scanning for adversarial review
- Tier 3 (scale): close the review loop into a wisdom-accumulating `decisions.md`; add observability via per-phase JSON logging and cost governance

<!-- speaker notes: This slide bridges Part 1 and Part 2 of the roadmap document — ground the audience in what Specflow actually does today before pitching the twenty-two-item improvement backlog. Stress that Tier 1 items are cheap, low-risk foundation work that should land before anything else, while Tier 2 and Tier 3 trade increasing effort for stronger guarantees around parallel execution, adversarial review, and long-term observability. Note that every tier item has documented effort and dependency fields in the source roadmap, so prioritization is already scoped, not guesswork. -->

---

## Supercharging Adversarial Review

- Core problem: a single fresh-context LLM reviewer is prone to rubber-stamping, hallucinated issues, and false consensus — self-correction alone doesn't fix this without external signals
- Recommended stack, ranked by payoff/cost: spec pre-mortem gate, hardened single reviewer, multi-persona panel, and reviewer-writes-failing-tests as the default four layers; critic/debate loop and cross-model review reserved for high-risk changes
- New: LLM-as-judge bias catalog — self-preference, position/order, and verbosity biases mean the reviewing model should differ from the one that wrote the code
- New: multi-agent debate lineage (AI Safety via Debate, multiagent debate factuality work) underpins the mandatory-pushback design that prevents sycophantic convergence
- New: reviewer calibration scorecards track finding precision per persona to catch over-flagging or under-reading reviewers
- New: risk classification rules escalate to critic loop and cross-model review based on touched paths, diff size, dependency changes, and schema/API changes

<!-- speaker notes: Frame this as the deck's deepest v2 research addition — the core insight is that a single-pass LLM reviewer behaves like a sycophantic rubber stamp unless structurally forced into disagreement. Walk through the ranked stack and stress that layers 1-4 are the sane default for every PR, while the expensive critic/debate and cross-model layers are reserved for high-risk paths via the new risk-classification rules. Close on the two most novel v2 additions — the bias catalog explaining why cross-model review matters, and the calibration scorecards that make reviewer quality measurable over time rather than assumed. -->

---

## Implementation Kit — Ready to Paste

- `.claude/settings.json` wiring for SessionStart, PreToolUse, PostToolUse, and Stop hooks
- PreToolUse/PostToolUse hook scripts: `block-main-commit.sh`, `test-gate.sh`, `artifact-lint.sh`
- Phase-transition logging (`log-phase.sh`) plus `jq`-driven dashboard queries for cost and reviewer precision
- Dispatcher `SKILL.md` that routes new/fix/refactor/rules requests to the right pipeline
- `decisions.md` and `open-questions.md` templates, and the review-findings JSON schema
- `merge-gate.sh`, `risk-classifier.sh`, a GitHub Actions merge-gate workflow, and full `.claude/agents/*.md` reviewer definitions

<!-- speaker notes: This slide closes the deck by pointing at Part 4 of the roadmap document — everything here is copy-paste ready, not aspirational. Walk through the artifact list quickly and note it spans the full lifecycle: hook wiring and scripts that enforce gates deterministically, the dispatcher skill that routes work, the decision/question logs and findings schema that give review structure, and the CI workflow plus reviewer agent definitions that close the loop. Tell the audience the paths assume a Spec-Kit project root and to verify hook event names, budget flags, and model IDs against their installed versions before adopting. -->


---

## Get Started — 30-60-90 Roadmap

- Install path: `specify init` → `/plugin install superpowers` → `specify extension add superspec` → verify with `specify check` and `/speckit.superspec.status`
- Days 0–30: rewritten constitution, `## Code Review Rules`, deterministic gate hooks, and a hardened single reviewer with mandatory findings
- Days 30–60: Agent Teams parallelism, multi-persona review panel, STRIDE spec lens, model routing, and a mutation-testing gate on core modules
- Days 60–90: headless CI merge gate (cross-model + SAST + mutation), critic/AR loop for HIGH-risk changes, and PR automation
- Anti-pattern to avoid: don't adopt heavy orchestrators or run 5+ reviewers before native primitives (worktrees, Agent Teams, a single hardened reviewer) prove insufficient
- Anti-pattern to avoid: never skip the two human gates — spec approval and merge approval stay manual even as everything between them is automated

<!-- speaker notes: Close the deck on the practical path forward — install is three commands plus a verify step, and the 30-60-90 roadmap sequences from cheap foundation work to CI-scale automation so teams don't over-invest before validating the basics. Reiterate the two anti-patterns worth remembering: don't reach for heavy orchestration before native primitives fail, and never let automation absorb the two human gates. Send the audience off with a clear next action — start Day 0 this week with the constitution rewrite and gate hooks, since everything else in the roadmap builds on that foundation. -->
