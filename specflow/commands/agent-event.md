---
description: Dispatch a spec-kit events hook payload to the matching gate
scripts:
  sh: gates/bash/agent-event.sh
---

# speckit.specflow.agent-event

Dispatch a spec-kit `events:` hook payload, from Claude Code or the GitHub
Copilot CLI, to the gate that matches its event and surface.

## Usage

Spec-kit's dispatcher runs this command; a person never invokes it directly.
`extension.yml`'s `events:` block registers it on `pre_tool_use`,
`post_tool_use`, and `session_start`, and the dispatcher feeds the hook
payload to `gates/bash/agent-event.sh` on standard input.

## Process

1. **No constitution gate**: unlike every other specflow command, this one
   checks nothing under `.specify/memory/`. `block-main-commit.sh` guards a
   commit regardless of feature state. `artifact-lint.sh` and `test-gate.sh`
   run against a file already inside a feature whose `.specify/memory/`
   check already gated `/speckit.specflow.tasks` or
   `/speckit.specflow.execute` before that file existed. `session-start.sh`
   runs before any feature work starts, so no feature is there to gate.
2. Read the hook payload from standard input.
3. Classify the payload as `pre_tool_use`, `post_tool_use`, or
   `session_start` from its own shape: Claude Code names the event in
   `hook_event_name`; the Copilot CLI does not, so the classification falls
   back to the fields only its own payloads carry.
4. Normalize a Copilot payload: copy its `.toolArgs.command` field to
   `.tool_input.command` and its `.toolArgs.path` field to `.tool_input.file_path`,
   the shape the gates read. A Claude Code payload passes through unchanged.
5. Dispatch the normalized payload to the sibling gate that event runs:
   `block-main-commit.sh` on `pre_tool_use`; `test-gate.sh` then
   `artifact-lint.sh` on `post_tool_use`, both run so one block does not hide
   the other's reason; `session-start.sh` on `session_start`.
6. On a block (`gate exit 2`), print the blocking gate's stderr, write a
   Copilot-readable JSON object to stdout (`permissionDecision` for
   `pre_tool_use`, `additionalContext` for `post_tool_use`), and exit 2.
   Claude Code reads the exit code and stderr and discards the stdout.
7. On any other gate failure, print that gate's stderr and exit with the
   gate's own code.
8. On `session_start`, pass the gate's stdout through unwrapped; the
   dispatcher wraps it in the Copilot envelope on that event.

## Output

A blocked `pre_tool_use` or `post_tool_use` call prints the refusing gate's
reason and exits 2. A passing call prints nothing and exits 0. A
`session_start` call prints `session-start.sh`'s report.
