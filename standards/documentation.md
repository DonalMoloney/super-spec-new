# Documentation standards

These rules apply to every piece of prose a person or agent writes for this
repository or for a project the specflow pipeline drives: README files, CHANGELOG
entries, ADRs, command files, spec, plan, and task documents, pull request
descriptions, hand-off reports, and docstrings. The same tone rules govern
`standards/presentations.md`.

## Principles

- Write for the reader who has the problem, not for the author who solved it. The
  first sentence tells them whether this page is for them.
- Lead with the action or the answer. Background follows, if it is needed at all.
- One idea per sentence, about 20 words, active voice, present tense.
- Every claim is checkable: a command, a path, a number, or a link. Do not write
  "should work", "generally", or "typically" unless you name the exception.
- Cut until the text breaks. Then put one word back.

## Structure

- No headers in a document under about 500 words. Above that, at most three levels.
- Bullets only for parallel items: steps, options, files. Each bullet is a complete
  sentence or a complete instruction, never a two-word fragment.
- Commands, error text, and sequences of paths go in fenced code blocks with a
  language tag. Prose names at most one file or flag per sentence.
- Tables for comparisons of three or more rows. Never for prose.
- No "Overview", "Introduction", "Summary", or "Conclusion" sections. The document is
  the overview. It ends when the content ends.
- Do not describe the document ("this section covers"). Cover it.

## Tone

- Plain, direct, specific. No enthusiasm, no apology, no hedging, no praise for the
  reader, the tool, or the team.
- No emoji. No exclamation marks.
- No em-dashes. Use a comma, a full stop, or a colon.
- No rhetorical questions. No "let's". No "we'll explore".
- No triplets written for rhythm ("fast, reliable, and secure"). Name the property
  that matters.
- No "not only X but also Y". Say X and Y.

## Banned words and phrases

Reject any draft containing these. They signal generated filler, not information.

| Category | Banned |
|----------|--------|
| Verbs | delve, leverage, utilize, streamline, empower, unlock, harness, elevate, foster, navigate (figurative), dive into |
| Adjectives | robust, seamless, comprehensive, cutting-edge, state-of-the-art, powerful, elegant, holistic, best-in-class, game-changing, crucial, vital, key (as adjective) |
| Nouns | journey, landscape, ecosystem (unless literal), synergy, deep dive, testament, tapestry, realm, paradigm |
| Openers | "In today's", "In the world of", "It's worth noting", "It's important to note", "Note that", "Please note", "As mentioned above", "At its core", "Great question" |
| Closers | "In conclusion", "In summary", "To sum up", "Hope this helps", "Feel free to", "Let me know if" |
| Softeners | simply, just, easily, basically, essentially, actually, very, really, quite |
| Hedges | "may or may not", "somewhat", "arguably", "it could be said", "generally speaking" |

## Specific documents

- **README**: what the thing is in one paragraph, how to run it, how to verify it
  ran, and where to go next. Nothing else at the top level.
- **CHANGELOG**: Keep a Changelog format. Each entry states the user-visible effect,
  not the implementation.
- **ADR**: Context, Decision, Consequences. Under 150 words. Dated, with a status.
- **Pull request description**: what changed and why, how it was verified with the
  command and its result, and what was deliberately left out. Uses the repo template.
- **Hand-off report**: outcome first, verification evidence second, open items last.
  No narrative of the process.
- **Docstrings**: see `standards/code.md`.

## Before you hand off

1. Read it aloud. Any sentence you would not say to a colleague gets rewritten.
2. Search the draft for every entry in the banned table and for em-dashes.
3. Run every command the document contains. Confirm every path it names exists.
4. Confirm the first sentence answers "is this page for me".
5. Delete the last paragraph if it restates the document.
