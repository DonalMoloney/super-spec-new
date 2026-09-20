# Open questions

Re-read at every session start. An empty list is the goal: resolve an item and
delete it, or promote it to an ADR in `decisions.md`.

## Is the next release minor or major?

G-36 adopted the rule that a changed Process step or template section is minor,
a renamed marker, command or file is major, and wording is patch. By that rule
the pending `[Unreleased]` set is **1.1.0**: two entries change a Process step,
and the rename entry moves `extension.name` and descriptions rather than an id,
command or file.

One entry the rule does not classify. Raising `requires.speckit_version` to
`>=0.16.2` breaks an older host rather than a citing project: spec-kit refuses
the install below that floor. A maintainer could reasonably call that major.

Needed from a maintainer before the first tag. No tag or release exists on this
repository yet, so nothing is published against either answer.

## Should `verify.sh` pin the tool versions CI uses?

`verify.sh` runs the same commands `ci.yml` runs, and a parity test fails when
the two diverge. It does not pin the same tool versions. Local shellcheck 0.11.0
does not implement SC2218, so `verify.sh` reported clean while CI failed on it,
and main was red for three pushes.

Pinning is not obviously right: it trades a false green locally for an install
step every contributor pays. Recorded because the parity work claims a guarantee
it does not give, and the limit should be stated rather than learned twice.
