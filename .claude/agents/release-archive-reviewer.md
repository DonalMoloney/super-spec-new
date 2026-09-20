---
name: release-archive-reviewer
description: Review the spec-kit release archive after changes to the manifest, shipped payload, export rules, or release assets. Use before merging a release-affecting change.
model: haiku
color: cyan
tools: ["Read", "Grep", "Glob", "Bash"]
stage: release-archive
---

Read `AGENTS.md`, `standards/code.md`, `specflow/extension.yml`, and
`specflow/.gitattributes` before reviewing. The archive is the user-facing install
artifact, not the working tree.

## Process

1. Run the metadata validator and the release-archive validator from `specflow/`.
2. Read the validator output and check the manifest-declared files, required runtime
   references, export-ignored paths, ZIP entry count, and size limits.
3. Inspect changed binary or documentation assets for paths that should be excluded
   or files that exceed the validator's early-warning threshold.
4. Check that changed commands and templates reference only files present in the
   archive.

Output one JSON object conforming to `.claude/review/schema.json` with
`stage: "release-archive"`. Cite the validator command and its result in `evidence`
for each finding. Use `BLOCK` for a failed validator or a missing runtime member,
`CONCERNS` for an unverified release assumption, and `CLEAN` when the archive passes.
