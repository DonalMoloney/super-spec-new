## Summary

<!-- One or two sentences: what changed and why. -->

## Scope

<!-- Link the single task/spec this PR delivers. One task per PR. Split otherwise. -->

## Checklist

- [ ] Task items were singular and crisp before work started (see `AGENTS.md` → Task decomposition)
- [ ] `python3 scripts/validate-extension-metadata.py` passes (if `extension.yml`, `commands/`, or `templates/` changed)
- [ ] `python3 scripts/validate-release-archive.py` passes (if a binary asset was added/changed)
- [ ] `bash scripts/e2e-smoke.sh` passes
- [ ] `extension.id` still matches the `speckit.<id>.*` namespace on every touched command/hook
- [ ] Work was independently re-verified (fresh command output, not a self-report, see `work-verifier`)

## Evidence

<!-- Paste the actual command output that proves the checklist above, not a summary. -->

## Risks / open questions

<!-- Anything a reviewer should decide on. "None" if genuinely none. -->
