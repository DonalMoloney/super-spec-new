# Hook: after_clarify

The hook fires once `/speckit.clarify` finishes. It writes the feature's
`.clarified` marker through `/speckit.specflow.gate`, so no later command has to
infer that clarification ran.

## Preconditions

1. **Constitution gate**: Check that `.specify/memory/constitution.md` exists. If
   it is missing, the hook stops with `CONSTITUTION_REQUIRED`, names the missing
   path, and tells the user to run `/speckit.constitution`.
2. **Unresolved markers**: Count the `NEEDS CLARIFICATION` markers left in
   `specs/NNN-feature-name/spec.md`. A count above zero stops the hook with
   `CLARIFY_INCOMPLETE` and the count.
3. **Write the marker**: With no marker left, write
   `specs/NNN-feature-name/.clarified` and print its path.

## Gate

The hook is not optional. A spec that still holds a `NEEDS CLARIFICATION` marker
gets no marker file, so `/speckit.specflow.status` keeps naming
`/speckit.clarify` as the next step.
