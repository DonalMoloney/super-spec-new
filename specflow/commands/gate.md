# speckit.specflow.gate

Write a feature's `.clarified` or `.analyzed` marker, or report why the gate refused.

## Usage

```
/speckit.specflow.gate clarified|analyzed [spec-number|spec-path]
```

**Marker**: `clarified` after `/speckit.clarify`, `analyzed` after `/speckit.analyze`.

## Process

1. **Constitution gate**: Check that `.specify/memory/constitution.md` exists. If
   it is missing, stop with `CONSTITUTION_REQUIRED`, name the missing path, and
   tell the user to run `/speckit.constitution`.
2. Find the target feature under the project root's `specs/NNN-feature-name/`
   from the supplied spec number or path. With no argument, take the feature
   furthest along. If the target is ambiguous, ask the user to pick one.
3. Run `gates/bash/write-marker.sh <feature-directory> <marker>` from the
   installed extension directory. For `analyzed`, pass the analysis report on
   the script's standard input. The script refuses `clarified` while `spec.md`
   holds a `NEEDS CLARIFICATION` marker, and refuses `analyzed` while the report
   holds a CRITICAL row. It exits 0 after writing the marker, 1 when it refuses,
   and 2 on a bad argument.
4. Report the outcome: on exit 0 print the marker path the script wrote; on any
   other exit print the script's message unchanged, which names the count found,
   the count expected, and the command to run next.

## Output

The command writes `specs/NNN-feature-name/.clarified` or
`specs/NNN-feature-name/.analyzed`, and prints the path.

A refused gate writes nothing and prints `CLARIFY_INCOMPLETE` or
`ANALYZE_CRITICAL` with the count that blocked it.

## Markers

| Marker | Written after | Refused while |
|--------|---------------|---------------|
| `.clarified` | `/speckit.clarify` | `spec.md` holds a `NEEDS CLARIFICATION` marker |
| `.analyzed` | `/speckit.analyze` | the analysis report holds a CRITICAL row |

`/speckit.specflow.execute` reads `.analyzed` and stops with `ANALYZE_REQUIRED`
while it is absent. Remove `.clarified` when the spec changes, and `.analyzed`
when the spec, plan, tasks, or constitution changes.

See `references/workflow-guide.md` for the Gate markers protocol both markers follow.
