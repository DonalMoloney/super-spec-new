# speckit.specflow.brainstorm

Probe edge cases and refine a spec document with the brainstorming skill.

## Usage

```
/speckit.specflow.brainstorm [spec-path] [focus-topic]
```

**Sample command**: `/speckit.specflow.brainstorm specs/001-develop/spec.md "Discuss the Edge Cases in the requirements document and confirm how to resolve these scenarios."`

## Process

1. Read the target spec file
2. Read the constitution for the project's constraints
3. Read `decisions.md` at the project root if it exists. Treat every recorded
   decision as settled and do not raise it as a question again
4. **Superpowers detection**: Check for the `brainstorming` skill
   - **If found**: Read the brainstorming SKILL.md, follow its questioning protocol,
     and adapt every output to the target spec file
   - **If not found**: Use the built-in 5-category questioning protocol:
     - Boundary conditions (minimum and maximum values, empty states, the edges of a range)
     - Error scenarios (a downed service, malformed input, partial failures)
     - Scale & performance (heavy load, concurrent use, rate limits)
     - Security & privacy (injection, authorization, exposed data)
     - User experience (points of confusion, accessibility, unintended usage)
5. Ask questions **one at a time** and prefer multiple-choice format
6. After each answer, fold the outcome into the spec:
   - A new requirement → enters Functional Requirements
   - A resolved question → closes in the Open Questions table
   - A new edge case → enters the Edge Cases section
7. When the user confirms the spec is ready, update the "Brainstorm Log" with a
   dated summary of the insights found

## Output

The command returns an updated spec file with refined edge cases, resolved open
questions, and brainstorm log entries.

## Iteration

Run this command any number of times on the same spec. Each session appends to
the brainstorm log and skips previously explored categories.

## Superpowers Adaptation

When the `brainstorming` skill produces output, redirect it:
- Design documents → merge their insights into the existing `spec.md`
- Output location → save results to `specs/NNN/spec.md`, never `docs/superpowers/`

See `references/superpowers-bridge.md` for the full adaptation rules.
