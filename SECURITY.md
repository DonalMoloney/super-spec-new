# Security policy

Report a vulnerability privately to <SECURITY_CONTACT>. Do not open a public
issue for one. Say what you ran, what happened, and the commit you saw it on.

## What is in scope

Specflow ships Markdown command files, YAML metadata, and Python and bash
scripts. Three surfaces take a report:

- The scripts under `specflow/scripts/` and the gate scripts under
  `.claude/hooks/`, which run on a contributor's machine and in CI.
- The install archive that `specify extension add specflow` downloads, covered
  by the size and entry limits `specflow/scripts/validate-release-archive.py`
  checks.
- A command file under `specflow/commands/` that steers an agent into an
  action its user did not ask for.

A command file is a prompt, and the agent reading it runs with the permissions
its user granted. The agent is out of scope: report a flaw in Claude Code or
in the GitHub Copilot CLI to its vendor.

## Versions

No release is tagged yet, so there is no older version to patch. A fix lands
on `main` and reaches a user at the next release.
