# Hooks

## Telemetry queries

`log-phase.sh` runs on `Stop` and appends one JSON line per turn to
`.claude/telemetry.jsonl`. That file is gitignored, so every checkout builds its
own history. Each line carries the `phase` and the `feature` read from the
newest `specs/*/progress.yml`, or `unknown` when the project has none. Query it
with `jq`.

Count the turns spent in each phase:

```bash
jq -s 'group_by(.phase) | map({phase: .[0].phase, n: length})' .claude/telemetry.jsonl
```

Total the cost of the runs that recorded one. A headless run writes a
`total_cost_usd` field; a turn logged by the Stop hook does not, so the total
covers headless runs only.

```bash
jq -s 'map(select(.total_cost_usd)) | (map(.total_cost_usd)|add) as $t | {total_usd: $t}' .claude/telemetry.jsonl
```

`cost-report.sh` runs on `Stop` after `log-phase.sh` and prints that total per
feature as `<feature> <spend> / <ceiling>`. It exits 1 and names each feature
whose spend passes the ceiling. `SPECFLOW_BUDGET_USD` sets the ceiling and
defaults to `1.00`, the figure the headless example in `workflow-guide.md`
passes to `--max-budget-usd`. Run it against a higher ceiling:

```bash
SPECFLOW_BUDGET_USD=5.00 .claude/hooks/cost-report.sh
```

Compare reviewers by the share of their findings the team accepted. No line
carries `event: "finding"` yet, so the query prints an empty list until a
reviewer logs one.

```bash
jq -s 'map(select(.event=="finding")) | group_by(.reviewer)
       | map({reviewer: .[0].reviewer, precision: ((map(select(.status=="accepted"))|length)/(length))})' .claude/telemetry.jsonl
```

A query whose filter matches no line prints an empty result instead of failing.

## Run the gate locally

The `Merge gate` workflow runs two of these hooks on every pull request. Run the
same two from a feature branch before you push:

```bash
.claude/hooks/risk-classifier.sh main
.claude/hooks/merge-gate.sh
```

Both paths are two-line scripts that exec the shipped gate under
`specflow/gates/bash/`, where ADR-0025 moved the code so a catalog install
carries it. Edit the shipped copy, not the shim.

The classifier prints `HIGH` or `STANDARD` for the diff between `main` and
`HEAD`. `HIGH` turns on the security review and the mutation score in CI. The
gate reads `.claude/review/*.json` and `specs/*/review-findings.json`, then
exits 1 when a Critical or
Important finding is neither fixed nor rebutted. A branch carrying no findings
file passes and leaves `.claude/review/.merge-approved` behind.

`test-gate.sh` runs on `Edit|Write` and blocks a task ticked `[x]` in
`tasks.md` when the project's test command fails. It picks the command in
this order: `SPECFLOW_TEST_CMD` when set, else the text after `Test command:`
in `.specify/memory/constitution.md` when that file exists and carries the
line, else it prints a message to stderr and exits 0 without running
anything. A consuming project names its command with a `Test command:` line
under the constitution's Code Review Rules section; `constitution-template.md`
carries the placeholder.

`mutation-gate.sh` runs mutmut 3 on a project directory and exits 1 when the
share of mutants the tests kill is below `MUTATION_THRESHOLD`, which defaults
to 80. No workflow calls it yet. Run it on the sample project to see it pass:

```bash
.claude/hooks/mutation-gate.sh specflow/examples/mutation-gate-sample
```
