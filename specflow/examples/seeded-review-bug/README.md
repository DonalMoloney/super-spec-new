# Example: Link Audit with Planted Review Bug

This directory holds a copy of `link-audit/` with one planted specification violation. The shipped test suite passes, but the planted_violation_oracle, which the test runner never collects, catches the fault. Use this example to verify the code review probe's ability to find review-stage gaps the tests miss.

## The planted fault

The planted file is `src/link_audit/resolver.py` at line 87. A fault in the exception handler narrows its catch clause to miss undecodable bytes. The handler changes from `except (OSError, UnicodeDecodeError) as exc:` to `except OSError as exc:`, allowing a `UnicodeDecodeError` to escape uncaught when a Markdown target file holds invalid UTF-8 bytes. This violates FR-012, which requires the CLI to abort the scan with an actionable error and exit 2.

## How to run it

The copied test suite passes:

```bash
cd specflow/examples/seeded-review-bug
python3 -m pytest -q
```

The oracle detects the fault:

```bash
LINK_AUDIT_SRC=src/link_audit python3 -m pytest -q ../../scripts/tests/planted_violation_oracle.py
```

The oracle never runs in a plain `pytest` invocation because test discovery skips it by design, leaving the fault hidden from the shipped suite.
