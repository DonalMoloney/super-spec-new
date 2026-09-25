# Agent standards

These rules apply to every agent definition under `.claude/agents/`. Read this
file before adding an agent or editing one. Reviewers reject against it, and
`.claude/agents/tests/test_agent_contract.py` checks the parts a machine can
check.

An agent definition is a prompt that a separate context reads once. That context
cannot ask the dispatcher what it meant, cannot see the conversation that led to
the dispatch, and cannot see what the previous agent saw. Every fact the agent
needs sits in its own file or in a file the prompt names. A section left out is
a decision the agent makes alone.

## Frontmatter

Five fields, in this order, in one dialect:

```yaml
---
name: red-phase-verifier
description: Use this agent to ...
model: haiku
color: yellow
tools: ["Read", "Bash", "Grep"]
---
```

- `name` is kebab-case and matches the file name without `.md`.
- `description` is routing text. The next section governs it.
- `model` is `opus`, `sonnet`, or `haiku`, fixed per agent by ADR-0003 as
  amended by ADR-0014. A model change needs an ADR, not an edit.
- `color` is one of the Claude Code palette names. It carries no meaning to a
  reader and no meaning to a tool.
- `tools` is a JSON array of strings, smallest set that does the job. An agent
  that writes no file does not list `Write` or `Edit`.

A reviewer that runs at a named stage of the review stack adds a sixth field,
`stage`, last:

```yaml
stage: conformance
```

`stage` is the value the reviewer writes into the `stage` property of the
document `specflow/references/findings-schema.json` describes. The schema's
enum is the whole list of allowed values, so a reviewer declaring a stage
absent from the enum writes a document the merge gate rejects. The property is
optional, so a reviewer outside the stack, such as `code-reviewer`, writes a
findings document and carries no `stage`.

No other field. A field no tool reads and no agent acts on is decoration that
reads as machinery, which is worse than an empty line.

## The description is routing text

A dispatcher matches a request against the description and nothing else. The
body never enters that decision, so a fact that belongs to routing belongs here.

Write 40 to 70 words in three parts:

1. **What it does**, opening with "Use this agent to" and a specific verb.
2. **Typical triggers**, naming the dispatching phase or the words a user says.
3. **Not for**, naming the nearest agent that owns what this one refuses.

The third part carries most of the weight. Two agents whose descriptions both
read "reviews code" collide on every request, and the dispatcher picks by
accident. Name the boundary and the collision stops.

## Body sections

Seven sections, in this order, each with the heading given here.

### Role

Two or three sentences, no heading of its own, directly under the frontmatter.
State what the agent does, then what it is not. The second half matters more:
an agent with no stated anti-goal expands until it runs out of context.

Write "You never open a defect of your own", not "focus on reviewing".

### When to invoke

Bullets, each a complete sentence, each naming a condition a reader can check
from outside the agent. A phase number, a file that exists, a user's words.
Close with the cases that belong to another agent, by name.

### Inputs

What must arrive with the dispatch, and what the agent does when it did not.
Name the artifact and its form: a path, not a summary. An agent handed a
summary where a path belongs reports that and stops, because it cannot check a
claim it cannot read.

### Process

Numbered steps, in order, each one verifiable. A step states an action and the
state it leaves behind, so the next step has something to stand on.

This section replaces a list of capabilities. "Detect the framework, write the
scenarios, place the file" names three abilities and no sequence. Numbered
steps that each end in a checkable state name the work.

### Stop conditions

When the agent halts and reports instead of deciding. At minimum: the inputs
did not arrive, the task needs a judgment the dispatcher reserved, or two
instructions in scope contradict each other.

`AGENTS.md` mandates surfacing confusion instead of guessing. This section is
where that rule becomes a specific line an agent can follow.

### Self-check

The command the agent runs against its own output, and the output that command
prints when the work is right. Both, on the page.

```bash
python3 -m pytest .claude/agents/tests -q
```

Expected output names zero failures. A check whose expected output is unstated
is a command the agent runs and then interprets in its favor.

An agent that writes no file and runs no command states the re-read it does
instead, and what it looks for.

### Output format

The exact shape the agent returns, in the order it returns it, and the named
agent or the caller it hands off to. A report whose shape drifts run to run
cannot be gated on.

## The evidence rule

`standards/code.md` states that a claim without output is not a claim. Every
agent that asserts a result carries that rule in its own words, in its Process
or its Output format. A verifier carries it in both.

An agent reports the command it ran and what the command printed. It does not
report that a suite passed.

## Rejected on sight

- A `## Core responsibilities` heading. The section is a wish list; write
  `## Process`.
- A description outside 40 to 70 words, or one with no "Not for" clause.
- A Process step with no checkable state at its end.
- A Self-check with no expected output.
- A frontmatter field outside the five named above, or a `stage` on an agent
  that writes no findings document.
- An anti-goal written as an emphasis word: "focus on", "primarily", "mainly".
  Name what the agent does not do.
- A tool in `tools` that no Process step calls.
- Prose that restates `standards/code.md` or `standards/documentation.md` rather
  than naming the file and the rule.

## Before you hand off

1. Run `python3 -m pytest .claude/agents/tests -q` and read the failures.
2. Run `python3 specflow/scripts/lint-standards.py` and read the findings. Agent
   files are in scope for the documentation standard.
3. Read the description alone, with the body hidden. Decide from it which
   requests route here and which route to the neighbouring agent.
