# Open questions

Re-read at every session start. An empty list is the goal: resolve an item and
delete it, or promote it to an ADR in `decisions.md`.

- **Does the constitution gate belong in one place or five?** G-50's T520 and
  T521 hand-copied the constitution-gate check into `brainstorm.md` and
  `review.md`, on top of the existing copies in `tasks.md`, `execute.md`,
  `gate.md`, and `workflow-guide.md`'s two matching phase sections. The same
  sweep's T530 removed an equivalent duplication in `tasks-template.md`'s
  Checkpoint Protocol by pointing at `workflow-guide.md` instead of repeating
  its steps. A future wording change to the gate now costs six file edits.
  Decide whether the gate should follow T530's pattern (one canonical
  statement, everything else points at it) and, if so, who owns rewriting the
  five command files and the guide to match.

- **`spec-template.md`'s Brainstorm Prompts dropped two categories a shipped
  example still uses.** T533 removed the "Data integrity" and "Backwards
  compatibility" bullets to match the 5-category fallback protocol documented
  elsewhere, but `specflow/examples/link-audit/specs/001-link-audit/spec.md:83-84`
  still carries both bullets verbatim, so the shipped example now demonstrates
  a template shape the current template no longer offers. Decide whether to
  edit the example to match the trimmed template, or to treat examples as
  point-in-time snapshots exempt from this kind of drift (and say so in
  `reference.md` if it's the latter).

- **`catalog.json`'s top-level `priority`/`install_allowed` fields have no
  counterpart in github/spec-kit's own catalog files.** T610 asked for these
  on the self-hosted `catalog.json`. A live fetch of `github/spec-kit`'s
  `extensions/catalog.json` and `extensions/catalog.community.json` (Sept 25
  2026) shows both keys only inside `.specify/extension-catalogs.yml`'s
  per-source `catalogs:` list, which the installing project writes, not a
  field either catalog file declares about itself. `catalog.json` currently
  carries them at the top level anyway, since T610 asked for it explicitly.
  Decide whether to drop them once a real `specify` CLI run can confirm
  whether the parser rejects, ignores, or errors on unknown top-level keys.
