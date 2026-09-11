---
marp: true
theme: gaia
paginate: true
size: 16:9
---

<!-- _class: lead -->

# Specflow

Spec-kit governance with superpowers execution skills and adversarial review.

2026-09-11

Donal Moloney

<!-- speaker notes: Specflow is a spec-kit extension. Spec-kit owns the governance artifacts and superpowers owns the execution skills; specflow connects the two and adds deterministic gates around them. The deck covers what specflow is, where the roadmap stands, the adversarial-review design, the kit under .claude/, and the adoption path. Scope is Claude Code and the GitHub Copilot CLI only, per AGENTS.md. Source: AGENTS.md, first section. -->

---

## Specflow adds five commands to a spec-kit project

- Spec-kit owns constitution, spec, plan, tasks, and checklist.
- Superpowers skills run brainstorming, planning, TDD, and code review.
- Specflow connects the two through five commands.
- Every command falls back when a skill is missing.
- State lives in plain YAML, so a run resumes.

<!-- speaker notes: The five commands are status, brainstorm, tasks, execute, and review, each under the speckit.specflow prefix. extension.yml declares five commands, five templates, and three hooks. The constitution at .specify/memory/constitution.md is a hard gate before any command runs. Fallback protocols live in specflow/references/workflow-guide.md. Resumable state is progress.yml per feature and .specify/superpowers.yml for skill detection. Superpowers current version is v6.3.0. Sources: AGENTS.md Architecture and Gotchas; imporvements/imporvements2.md Part 1. -->

---

## All 18 roadmap groups have merged as of 2026-09-11

- Deterministic gate hooks replaced prompt-level asks.
- Adversarial review agents and a findings schema landed.
- A CI merge gate reviews every pull request headlessly.
- Agent Teams run parallel tasks in separate worktrees.
- Cost governance and per-phase logging record every run.

<!-- speaker notes: The count of 18 is the number of G-NN headers in imporvements/tasks.md. G-02 through G-18 carry a merged PR number in the header. G-01 has every task ticked but names no PR. Gate hooks are G-01 and G-06, review agents G-05, the CI merge gate G-09, Agent Teams G-14, cost governance G-16, and logging G-07. Source: imporvements/tasks.md group headers. -->

---

## A single LLM reviewer approves its own mistakes

- A lone reviewer approves by default and invents findings.
- Models score their own output higher than others' output.
- The reviewing model must differ from the writing model.
- Mandatory findings and a fresh context block empty approvals.

<!-- speaker notes: The default requesting-code-review skill is one fresh-context reviewer with severity buckets, which is prone to rubber-stamping, hallucinated issues, and false consensus. Self-preference bias: Panickssery, Bowman and Feng, NeurIPS 2024, arXiv 2404.13076, found evaluators score their own generations higher while humans rate them equal. Position and verbosity bias: Wang et al. 2024 and Saito et al. 2023. Self-correction without an external verifier does not fix this (Huang 2023). Sources: imporvements/imporvements2.md sections 3.1, 3.3, 3.4. -->

---

## Four review layers run by default and three on risk

- Every change runs the four default layers.
- A critic loop runs only on high-risk changes.
- Cross-model review and SAST run in CI before merge.
- Risk escalates on touched paths, diff size, or dependency changes.
- Scorecards track finding precision per reviewer persona.

<!-- speaker notes: The four default layers are the spec pre-mortem gate, the hardened single reviewer, the multi-persona panel, and the reviewer-writes-failing-tests step. Layer five is the critic loop at about 4.5 times the tokens. Layers six and seven are cross-model review and test amplification with SAST. Diff-size thresholds are 400 changed lines or 15 changed files, set in .claude/hooks/risk-classifier.sh and recorded in ADR-0005. Precision is accepted findings divided by all findings; a persona below 0.5 is over-flagging. Sources: imporvements/imporvements2.md sections 3.7, 3.9, 3.10; decisions.md ADR-0005. -->

---

## The kit under .claude is ready to copy

- Nine hook scripts gate commits, tests, artifacts, and merges.
- 28 agent definitions cover the BDD squad and review personas.
- A findings schema and validator structure every review.
- A dispatcher skill routes new, fix, refactor, and rules work.
- Three workflows run CI, the merge gate, and scoring.

<!-- speaker notes: Counts come from the worktree on 2026-09-11: nine shell scripts in .claude/hooks, 28 files in .claude/agents, schema.json and validate-findings.py in .claude/review, the specflow-dispatcher skill in .claude/skills, and ci.yml, merge-gate.yml, and score-artifacts.yml in .github/workflows. Hooks are not part of the spec-kit archive, so a consuming project copies them deliberately (ADR-0001). Check hook event names, budget flags, and model IDs against the installed versions before adopting. Sources: repository listing; decisions.md ADR-0001; imporvements/imporvements2.md Part 4. -->

---

## Install takes three commands and a status check

The status command confirms the constitution and skill detection.

```bash
specify init . --ai claude
/plugin install superpowers@claude-plugins-official
specify extension add specflow
/speckit.specflow.status
```

<!-- speaker notes: Install specify-cli first with uv tool install specify-cli from the spec-kit git URL. The extension id is specflow, so the command and status names carry that prefix; the roadmap document still shows an older extension name. Source: imporvements/imporvements2.md Appendix A, with the extension name corrected to match specflow/extension.yml. -->

---

## Adoption runs in three 30-day steps

- The first 30 days land constitution and gate hooks.
- Days 30 to 60 add Agent Teams and persona reviewers.
- Days 60 to 90 add CI gating and critic review.
- Keep the two human gates: spec approval and merge approval.
- Add heavy orchestrators only after native primitives fail.

<!-- speaker notes: Days 0 to 30 also cover the Code Review Rules section, the clarify, analyze, and checklist gates, and one hardened reviewer with mandatory findings. Days 30 to 60 add the STRIDE spec lens, model routing, and a mutation-testing gate on core modules. Days 60 to 90 add SAST in CI, PR automation, and differential implementation for high-ambiguity specs. Do not run five or more reviewers or unbounded debate, and do not let the model that wrote the code be its sole reviewer. Source: imporvements/imporvements2.md Part 8. -->

---

## Start this week with the constitution rewrite and gate hooks

Everything after day 30 builds on those two changes.

<!-- speaker notes: The constitution rewrite is the first item of the day 0 to 30 step, and the gate hooks are the second. Source: imporvements/imporvements2.md Part 8. -->
