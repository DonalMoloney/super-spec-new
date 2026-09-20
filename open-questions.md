# Open questions

Re-read at every session start. An empty list is the goal: resolve an item and
delete it, or promote it to an ADR in `decisions.md`.

## Should `verify.sh` pin the tool versions CI uses?

`verify.sh` runs the same commands `ci.yml` runs, and a parity test fails when
the two diverge. It does not pin the same tool versions. Local shellcheck 0.11.0
does not implement SC2218, so `verify.sh` reported clean while CI failed on it,
and main was red for three pushes.

Pinning is not obviously right: it trades a false green locally for an install
step every contributor pays. Recorded because the parity work claims a guarantee
it does not give, and the limit should be stated rather than learned twice.
