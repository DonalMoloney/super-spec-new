# Code standards

These rules apply to every line of code a person or agent adds or changes, in this
repository and in any project the specflow pipeline drives. Read this file before the
first edit. Reviewers reject against it.

## Order of work

1. Read the surrounding code first. Match its naming, layering, and error-handling
   style. Where one convention already exists, do not introduce a second.
2. Write the failing test before the implementation. Run it and confirm it fails for
   the expected reason. Write the smallest change that makes it pass. Refactor only
   while the suite is green.
3. Run the project's test command before claiming anything passes. Report the command
   and its result. A claim without output is not a claim.

## Scope

- Change only what the task names. No drive-by refactors, renames, reformatting of
  untouched lines, or dependency bumps.
- No speculative generality. Do not add configuration options, abstractions, plugin
  points, or parameters that no current caller needs.
- One concern per commit. A fix, a refactor, and a new test are three commits.
- Delete dead code. Never comment it out.

## Naming and structure

- Names use the domain's vocabulary and say what the thing is or does. Reject
  `data`, `info`, `helper`, `manager`, `utils`, `misc`, `temp`, `new`, `v2` unless the
  codebase already established that term.
- Boolean names read as predicates: `is_ready`, `has_key`. Not `ready_flag`.
- A function does one thing and fits on one screen. A file holds one cohesive unit.
- No `utils` or `helpers` dumping-ground modules. Place a function beside its only
  caller, or in a module named for its concern.

## Errors

- Never swallow an exception. A handler either handles the case fully, re-raises with
  added context, or does not exist.
- No blanket `except Exception` or empty `catch` without a one-line comment stating
  why every error is safe to ignore at that point.
- Validate at boundaries: input parsing, file and network IO, external calls. Trust
  internal invariants. Do not re-validate the same value at every layer.
- An error message states what was expected, what was found, and what the caller can
  do about it.

## Comments and docstrings

- A comment explains why. It never restates what the code does. If a line needs a
  comment to be understood, rename or restructure the line instead.
- Every public function has a docstring stating its purpose, any parameter whose
  meaning is not obvious from its name and type, and the errors it raises. Nothing
  more.
- Forbidden: comments that narrate the edit ("added for clarity", "updated to handle
  X"), section banner comments, TODOs without an owner and an issue reference, and
  any comment addressed to a reviewer or user.

## Tests

- Test behavior through the public interface. Do not test private helpers directly.
- One behavior per test. Name the test for that behavior: `rejects_empty_email`,
  never `test_1` or `test_works`.
- No sleeps, no real network, no dependence on execution order, no shared mutable
  fixtures between tests.
- A test that cannot fail is deleted.

## Commits and pull requests

- Subject line: imperative mood, under 72 characters, states the change and not the
  activity. "Reject empty email with 400", not "Fixed validation stuff".
- Body: why the change exists and anything a reviewer cannot infer from the diff. No
  file list, no restatement of the diff.
- Pull request descriptions follow `.github/pull_request_template.md` and state how
  the change was verified, with the command and its result.
- No emoji in commit subjects, PR titles, or PR prose. Tool-generated attribution
  trailers are exempt.

## Forbidden on sight

- Commented-out code.
- `print` or `console.log` debugging left in.
- Catch-all exception handlers with no explanation.
- Magic numbers and strings without a named constant.
- Boolean parameters that switch a function between two behaviors. Write two functions.
- Wrapper functions that only call another function with the same arguments.
- Type annotations of `Any`, `object`, or `unknown` where the real type is known.
- Copy-pasted blocks that differ in one token. Extract the difference.
- Emoji, decorative Unicode, or ASCII art in source, logs, or output.

## Hand-off

Before reporting a task done, state in this order: files changed, the test command run
and its result, and anything not done. Write "not verified" beside anything you did
not run yourself. Do not summarize the process or describe how the work felt.
