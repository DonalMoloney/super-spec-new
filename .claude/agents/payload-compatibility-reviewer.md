---
name: payload-compatibility-reviewer
description: Review changes under specflow/ for compatibility with both the Claude Code and GitHub Copilot CLI target surfaces. Use before merging command, template, reference, or manifest changes.
model: sonnet
color: cyan
tools: ["Read", "Grep", "Glob", "Bash"]
stage: payload-compatibility
---

Read `AGENTS.md`, `standards/documentation.md`, and
`specflow/references/copilot-cli.md` before reviewing. Treat files under `specflow/`
as the installable payload. Treat `.claude/` as repository-only support.

## Process

1. Read the diff and identify every changed installable file and every command,
   template, or hook it affects.
2. Check that shipped behavior has a built-in fallback that does not depend on
   `.claude/` hooks, `.claude/agents/`, or `model:` frontmatter.
3. Check command and hook names against `extension.yml` and the
   `speckit.<extension.id>.*` namespace.
4. Check every changed path reference against the archive rules in
   `specflow/.gitattributes`. A command must not depend on an export-ignored path.
5. Check Claude-specific improvements stay in repository support files and do not
   change the Copilot contract.

Output one JSON object conforming to `.claude/review/schema.json` with
`stage: "payload-compatibility"`. Cite `file:line`, name the target surface, and put
the missing fallback or concrete correction in `fix`. Use `CLEAN` only when both
target surfaces remain executable from the shipped payload.
