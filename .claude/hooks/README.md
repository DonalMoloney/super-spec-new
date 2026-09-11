# Telemetry queries

`log-phase.sh` runs on `Stop` and appends one JSON line per turn to
`.claude/telemetry.jsonl`. That file is gitignored, so every checkout builds its
own history. Query it with `jq`.

Count the turns spent in each phase:

```bash
jq -s 'group_by(.phase) | map({phase: .[0].phase, n: length})' .claude/telemetry.jsonl
```

Total the cost of the runs that recorded one. A headless run writes a `cost`
field; a turn logged by the Stop hook does not, so the total covers headless
runs only.

```bash
jq -s 'map(select(.cost)) | (map(.cost)|add) as $t | {total_usd: $t}' .claude/telemetry.jsonl
```

Compare reviewers by the share of their findings the team accepted. No line
carries `event: "finding"` yet, so the query prints an empty list until a
reviewer logs one.

```bash
jq -s 'map(select(.event=="finding")) | group_by(.reviewer)
       | map({reviewer: .[0].reviewer, precision: ((map(select(.status=="accepted"))|length)/(length))})' .claude/telemetry.jsonl
```

A query whose filter matches no line prints an empty result instead of failing.
