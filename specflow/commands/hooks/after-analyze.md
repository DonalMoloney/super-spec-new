# Hook: after_analyze

The hook fires once `/speckit.analyze` finishes. It writes the feature's
`.analyzed` marker through `/speckit.specflow.gate`, the marker
`/speckit.specflow.execute` refuses to start without.

## Preconditions

1. **Constitution gate**: Check that `.specify/memory/constitution.md` exists. If
   it is missing, the hook stops with `CONSTITUTION_REQUIRED`, names the missing
   path, and tells the user to run `/speckit.constitution`.
2. **Critical findings**: Pass the analysis report to the gate on standard
   input. A report holding a CRITICAL row stops the hook with
   `ANALYZE_CRITICAL` and the count.
3. **Write the marker**: With no CRITICAL row, write
   `specs/NNN-feature-name/.analyzed` and print its path.

## Gate

The hook is not optional. An interrupted analysis and a report with a CRITICAL
row both leave `.analyzed` absent, so `/speckit.specflow.execute` stops with
`ANALYZE_REQUIRED` until the findings are fixed and the analysis is rerun.
