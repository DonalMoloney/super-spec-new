# Agent event mapping

Read this before changing how a gate script runs from spec-kit's `events:` block. Each surface sends a different payload, and one handler, `agent-event.sh`, reaches every gate from both.

Measured against spec-kit 1.0.9.dev0 at `d4229c0`. The Copilot field names come from `@github/copilot` 1.0.86; the string form of `toolArgs` and the write argument names come from 1.0.54's `app.js`.

## How a handler resolves

An `events:` entry names a command, not a script path:

```yaml
events:
  pre_tool_use:
    command: "speckit.specflow.agent-event"
    matcher: "Bash"
    timeout: 30
```

Spec-kit writes a dispatcher invocation into the agent's native config and the dispatcher does the rest:

1. `validate_events` at `events.py` line 1864 rejects an event name outside `CANONICAL_EVENTS` at line 60: `session_start`, `pre_tool_use`, `post_tool_use`, `session_end`, `user_prompt_submit`, `stop`.
2. `_find_command_template` in the dispatcher locates the command by its entry in `provides.commands`, or by a file in `commands/` whose stem equals the command name minus its `speckit.` prefix.
3. `_extract_scripts` reads the `scripts:` block from that file's YAML frontmatter and picks the `sh`, `ps`, or `py` variant the project recorded.
4. `_script_under_base` resolves the script path under `.specify/extensions/specflow/` and rejects a path that leaves the project.
5. The dispatcher runs the script with the hook payload on stdin, the project root as the working directory, and returns the script's exit code.

A missing command file, a missing `scripts:` block, or a missing script all return 0, so a broken entry passes every tool call instead of failing loudly.

## The events and handlers

| Event | Claude Code | Copilot CLI | Handler script | What it does |
|---|---|---|---|---|
| `pre_tool_use` | `PreToolUse`, matcher `Bash`, timeout 35 s | `preToolUse`, no matcher, timeout 35 s | `agent-event.sh` → `block-main-commit.sh` | Block a commit that would land on main or master |
| `post_tool_use` | `PostToolUse`, matcher `Edit\|Write`, timeout 125 s | `postToolUse`, no matcher, timeout 125 s | `agent-event.sh` → `test-gate.sh`, then `artifact-lint.sh` | Run the test command and check the edited artifact against its template |
| `session_start` | `SessionStart`, timeout 20 s | `sessionStart`, timeout 20 s | `agent-event.sh` → `session-start.sh` | Print open questions and progress at session start |

## Payload format

The dispatcher sends hook payloads on stdin. Each surface names the same values differently.

### Claude Code payload

```json
{
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash",
  "tool_input": {
    "command": "git commit -m x"
  }
}
```

The `tool_name` field names the agent's tool. The `tool_input` object carries the tool's arguments.

### Copilot CLI payload

```json
{
  "sessionId": "s123",
  "timestamp": 1726326742,
  "cwd": "/project",
  "toolName": "bash",
  "toolArgs": {
    "command": "git commit -m x"
  }
}
```

Or, on `postToolUse`:

```json
{
  "sessionId": "s123",
  "timestamp": 1726326742,
  "cwd": "/project",
  "toolName": "edit",
  "toolArgs": {
    "path": "specs/001-x/tasks.md",
    "old_str": "old",
    "new_str": "new"
  },
  "toolResult": {
    "resultType": "success"
  }
}
```

Copilot's `toolArgs` arrives as either an object or a JSON string. The `agent-event.sh` handler parses both.

## Normalization

Claude Code payloads pass unchanged. For a Copilot payload, `agent-event.sh`
normalizes to `{tool_input: {command?, file_path?}}`:

- `.tool_input.command` receives `.toolArgs.command` when present.
- `.tool_input.file_path` receives `.toolArgs.path` only when `toolArgs` also
  carries `file_text`, `old_str`, or `new_str` (the write-shaped arguments of
  Copilot's edit and create tools). A read operation, which carries a path but
  no write fields, has no file_path.

This write-argument filter prevents a post_tool_use gate from running on reads,
where Copilot's lack of a matcher would otherwise trigger it on a read of
tasks.md.

## Exit code contract

- **Exit 0**: gates passed (or the event has no gate).
- **Exit 1**: stdin was not valid JSON, or a required tool like `jq` is missing. The handler names the problem on stderr.
- **Exit 2**: a gate blocked the call. On pre/post events, `agent-event.sh` writes a Copilot-readable JSON object to stdout and the reason to stderr. Claude Code reads the exit code and stderr; Copilot reads stdout.

Pre block:

```json
{
  "permissionDecision": "deny",
  "permissionDecisionReason": "BLOCKED: the commit would land on main"
}
```

Post block:

```json
{
  "additionalContext": "TEST GATE FAILED: ..."
}
```

## Timeout rules

Spec-kit declares `timeout: 30` (pre_tool_use), `timeout: 120` (post_tool_use),
and `timeout: 15` (session_start) in the `events:` block. The install step
writes each declared timeout plus 5 s into the agent's native hook config, on
both surfaces. The dispatcher kills the script at the declared timeout and
returns exit 2 with empty stdout. Claude Code reports that exit as a blocking
"timed out" message. Copilot 1.0.54 finds no JSON on stdout, shows stderr as a
warning, and lets the tool call stand. A project raises the ceiling in
`.specify/integration-events.yml`.

## Superpowers and fallback

Neither surface provides a superpowers skill for event handling. `agent-event.sh` runs its gates directly, with no fallback protocol. The gates themselves are the fallback: they encode the check without requiring any LLM.
