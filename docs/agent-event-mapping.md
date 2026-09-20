# Agent event mapping

Read this before wiring the gate scripts under `.claude/hooks/` into spec-kit's
`events:` block. The table below names the event each gate registers on and the
adapter each target surface needs. The manifest declares no `events:` block
today, and the last section states what blocks it.

Measured against spec-kit 1.0.9.dev0 at `d4229c0`.

## How a handler resolves

An `events:` entry carries a command name, not a script path:

```yaml
events:
  pre_tool_use:
    command: "speckit.specflow.gate"
    matcher: "Bash"
    timeout: 30
```

Spec-kit writes a dispatcher invocation into the agent's native config and the
dispatcher does the rest:

1. `validate_events` at `events.py` line 1864 rejects an event name outside
   `CANONICAL_EVENTS` at line 60: `session_start`, `pre_tool_use`,
   `post_tool_use`, `session_end`, `user_prompt_submit`, `stop`.
2. `_find_command_template` in the dispatcher locates the command by its entry
   in `provides.commands`, or by a file in `commands/` whose stem equals the
   command name minus its `speckit.` prefix.
3. `_extract_scripts` reads the `scripts:` block from that file's YAML
   frontmatter and picks the `sh`, `ps`, or `py` variant the project recorded.
4. `_script_under_base` resolves the script path under
   `.specify/extensions/specflow/` and rejects a path that leaves the project.
5. The dispatcher runs the script with the hook payload on stdin, the project
   root as the working directory, and returns the script's exit code.

A missing command file, a missing `scripts:` block, or a missing script all
return 0, so a broken entry passes every tool call instead of failing loudly.

## The mapping

| Gate | Event | Claude Code | Copilot CLI | Adapter |
|---|---|---|---|---|
| `block-main-commit.sh` | `pre_tool_use` | `PreToolUse`, matcher `Bash` | `preToolUse`, no matcher | Read the tool name from the payload and skip a non-shell call, because Copilot drops the matcher. Write the deny object to stdout and exit 2. |
| `test-gate.sh` | `post_tool_use` | `PostToolUse`, matcher `Edit\|Write` | `postToolUse`, no matcher | Same tool-name filter. Exit 2 with the failing tail on stderr. |
| `artifact-lint.sh` | `post_tool_use` | `PostToolUse`, matcher `Edit\|Write` | `postToolUse`, no matcher | Same tool-name filter. A second handler on one event is appended, not replaced, so both gates run. |
| `session-start.sh` | `session_start` | `SessionStart`, plain stdout | `sessionStart`, `additionalContext` | None. Spec-kit wraps stdout in the Copilot envelope on this event. |

## Adapter per surface

Claude Code blocks a tool call by exit code 2 and feeds stderr back to the
model. Copilot CLI blocks by a JSON object on stdout and does not read the exit
code. The dispatcher writes the script's stdout before it returns the exit
code, and its `pre_tool_use` envelope is plain passthrough, so one script
satisfies both: write the Copilot deny object to stdout, write the reason to
stderr, exit 2. Claude Code reads the exit code and the stderr and discards the
stdout; Copilot reads the stdout.

Two differences bite harder than the deny shape:

- Copilot's `copilot-json` writer at `events.py` line 1426 emits `type`,
  `bash`, `powershell`, `timeoutSec`, and an ownership marker. It emits no
  matcher. Claude's `json-nested` writer at line 1569 groups handlers by
  matcher. A gate that relies on a matcher fires on every tool call under
  Copilot.
- `timeoutSec` is the declared timeout plus a five-second buffer.

## What blocks the block

Three things, in order of cost.

The script must sit inside the archive. `_script_under_base` resolves it under
`.specify/extensions/specflow/`, and `.gitattributes` strips both `.claude/`
and `specflow/scripts/` from the `git archive` ZIP a catalog install downloads.
Pointing a command template at `../../../.claude/hooks/` resolves and runs when
that directory exists, and returns 0 when it does not, so an installed user
gets a gate that never fires. Making the gate real means shipping the four
scripts under `specflow/`, which reverses ADR-0001 for those files.

The gates read the Claude Code payload schema. `block-main-commit.sh` reads
`.tool_input.command`; `test-gate.sh` and `artifact-lint.sh` read
`.tool_input.file_path`. No source in this repository records the field names
Copilot sends. A wrong name yields an empty string and the gate exits 0, which
is the failure this page exists to prevent.

The gates call `jq`. Shipping them adds an install-time dependency the
extension does not have today.
