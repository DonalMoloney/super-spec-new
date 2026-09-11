# Open questions

Re-read at every session start. An empty list is the goal: resolve an item and
delete it, or promote it to an ADR in `decisions.md`.

- [ ] Q: `specflow/scripts/validate-extension-metadata.py` fails on `main`. Its
  `^    - name:` regex also matches `provides.templates` entries, so
  `constitution-template` is reported as a badly namespaced command. Scope the
  regex to the `commands:` block, or rename templates? (raised by: PR #2, 2026-09-11)
- [ ] Q: `specflow/scripts/e2e-smoke.sh` fails on `main`. Current spec-kit
  `specify init` rejects `--no-git`. Drop the flag, or pin the spec-kit ref the
  script installs? (raised by: PR #2, 2026-09-11)
