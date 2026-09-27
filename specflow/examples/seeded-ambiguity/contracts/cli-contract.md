# CLI Contract: `link-audit`

The only interface this feature exposes is the command-line surface and its
exit-code / stdout / stderr contract (Constitution Principle II). This
document is the source of truth `tasks.md` and `test_cli.py` implement
against.

## Invocation

```text
link-audit [PATH]
```

- `PATH` (optional, positional): directory to run from; defaults to the
  current working directory. Must be inside a git repository (Assumptions).
- No other flags are required by the spec. Any additional flags (e.g.
  `--help`) are standard `argparse` behavior and out of scope for this
  contract.

## Exit Codes (Constitution Principle II)

| Code | Meaning | Triggered by |
|------|---------|---------------|
| `0` | Scan completed, zero unresolved links | No `Finding` was produced (FR-007). |
| `1` | Scan completed, one or more unresolved links | At least one `Finding` was produced (FR-007). |
| `2` | Scan could not complete | `git ls-files` fails or is unavailable (US3 Scenario 3); a tracked file cannot be opened or decoded (FR-012). |

No other exit code is ever returned (Principle II — exit-code semantics are
a stability contract).

## stdout Contract

- On exit 0: no findings are printed (an optional summary line, e.g. "no
  unresolved links found", MAY be printed but is not required by any FR).
- On exit 1: one line per `Finding`, each identifying:
  - the source file (`Finding.source_file`)
  - the line number (`Finding.line_number`)
  - the unresolved target (`Finding.target`)
  - the reason (`Finding.reason`: `missing-file` or `missing-anchor`)

  Example line shapes (exact format is an implementation choice for
  `tasks.md`, but every field below MUST be present per FR-006):

  ```text
  docs/guide.md:12: missing-file target 'setup.md' (link '[docs](setup.md)')
  docs/guide.md:20: missing-anchor 'old-heading' in 'reference.md' (link '[ref](reference.md#old-heading)')
  ```

- Output MUST be deterministic: identical input MUST produce identical
  output text and ordering on every run (constitution Quality Standards).

## stderr Contract

- On exit 2: exactly one error message naming the specific file (or git
  command) and the reason (permission denied / decode error / git failure),
  per Constitution Principle IV. No `Finding` is printed on exit 2 — the
  scan did not complete, so partial results are not reported.

## Non-Goals (explicitly out of contract)

- No JSON or machine-structured output format is required by the spec;
  exit code is the sole machine-readable contract (SC-003).
- No `--fix` or auto-remediation behavior — the tool only reports.
- No configuration file support — invocation takes no flags beyond an
  optional path argument.
