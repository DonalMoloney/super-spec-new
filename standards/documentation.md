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
- Natural voice. The test: a senior engineer would say the sentence aloud to a
  colleague without rephrasing it. If it sounds like a press release or a chatbot,
  rewrite it.
- Crisp over wordy. Cut "in order to", "the case where", "a number of", "various",
  "ensure that", "as needed", "appropriately", "properly", "it is possible to".
- No self-narration. A sentence never announces what the next sentence does
  ("Below, the steps are listed").
- No mirrored structure for its own sake: no sentence that restates the previous
  one in different words, no paragraph that opens with a definition of a term the
  reader already knows.

## Sentence structure

- Subject, verb, object, in that order. Put the actor first and the action second.
  "The validator rejects a mismatched id", not "A mismatched id is rejected by the
  validator" or "Rejection of mismatched ids is performed".
- One clause per sentence where the idea allows it. Two at most. A sentence with
  a third clause becomes two sentences.
- The main point goes in the main clause. Conditions and exceptions go in a short
  leading clause: "If the constitution is missing, the command stops."
- Verbs carry the meaning. Replace a noun built from a verb with the verb:
  "install" not "perform an installation", "decide" not "make a decision",
  "fails" not "results in a failure".
- Strong, specific verbs. "rejects", "writes", "reads", "stops", "retries".
  Reject "is", "has", "does", "gets", "makes", "handles", "deals with",
  "takes care of" when a specific verb exists.
- Concrete nouns. Name the file, the command, the field, the error. Reject
  "things", "stuff", "aspects", "elements", "items", "functionality",
  "capabilities" when the concrete noun is known.
- No stacked modifiers. Two adjectives before a noun is the limit. "A
  lightweight, flexible, easy-to-use validation layer" is four words of opinion.
- Parallel items take parallel form. Every bullet in a list starts with the same
  part of speech: all imperatives, or all nouns, never a mix.
- Numbers and units are digits with a space: "50 MiB", "30 s", "512 entries".
  Spell out only "one" through "nine" when they are not measurements.
- Sentence-final position is for the new information. "The archive fails above
  50 MiB" puts the limit where the reader lands.
- No throat-clearing before the point. Delete a sentence's first clause when the
  sentence still stands without it: "In order to install the extension, run" is
  "Run".
- Contractions are allowed in prose addressed to a reader ("don't", "it's"). They
  are not allowed in error text, log lines, or headings.
- A paragraph is three to five sentences on one point. A one-sentence paragraph
  is a bullet or a heading in disguise. A six-sentence paragraph has two points.

## Word choice

Prefer the short, common, Anglo-Saxon word over the long Latinate one. Prefer the
word a reader would use in a bug report over the word a vendor would use in a
brochure.

| Write | Not |
|-------|-----|
| use | utilize, leverage, employ |
| start, run | initiate, execute (unless the command is `execute`), kick off, spin up |
| stop, end | terminate, cease, wind down |
| show, print | surface, expose, display (unless UI), render (unless UI) |
| check, test | validate that, verify that, make sure, sanity-check |
| fix | resolve, address, remediate, mitigate |
| change | modify, alter, adjust, tweak, update (unless a version bump) |
| build | construct, generate (unless output is generated), craft |
| get, read | retrieve, fetch (unless network), obtain, acquire |
| send, write | emit, dispatch (unless to an agent), transmit, persist |
| add, remove | introduce, incorporate, eliminate, drop |
| need | require, necessitate |
| let | allow, enable, permit, facilitate |
| help | assist, aid, support (unless a support contract) |
| about | regarding, concerning, in relation to, with respect to |
| because | due to the fact that, owing to, as a result of |
| before, after | prior to, subsequent to, following |
| if | in the event that, should it be the case that, provided that |
| so | therefore, thus, hence, consequently, accordingly |
| but | however (mid-sentence), nevertheless, nonetheless, that said |
| also | additionally, furthermore, moreover, in addition |
| now | currently, at this time, at present, at the moment |
| many, most | a number of, a majority of, numerous, a variety of |
| part | component (unless a named component), piece, aspect, element |
| way | approach, methodology, mechanism, paradigm, strategy |
| problem, bug | issue (unless a tracker issue), challenge, concern, pain point |
| result | outcome, deliverable, output (unless literal program output) |
| setting, option | configuration parameter, knob, toggle |
| error | exception (unless the language type), failure mode, fault |
| step | phase (unless the pipeline names phases), stage, milestone |
| tool | tooling, solution, offering, platform |

Other rules:

- One term per concept. Pick "feature directory" or "spec folder" and keep it
  for the whole document. Synonyms for variety confuse the reader.
- Match the code. A thing named `constitution` in the file system is "the
  constitution" in prose, never "the governance file" or "the charter".
- Spell out an acronym at first use unless it is in the project glossary or is
  universal (URL, JSON, YAML, CLI, API).
- No jargon from a discipline the reader is not in. "Idempotent" needs a gloss
  for a product manager; it does not for an engineer. Know the document's reader.
- No metaphor. "Bridges", "glue", "plumbing", "under the hood", "first-class
  citizen", "source of truth" say less than the literal term.
- No intensifier attached to a claim. If the number is 12 MiB, write 12 MiB. Not
  "a huge 12 MiB" or "only 12 MiB".
- No evaluative adjectives about the work itself: "clean", "nice", "proper",
  "correct" (as praise), "careful". State what the code does and let the reader
  judge.

## Banned words and phrases

Reject any draft containing these. They signal generated filler, not information.

| Category | Banned |
|----------|--------|
| Verbs | delve, leverage, utilize, streamline, empower, unlock, harness, elevate, foster, navigate (figurative), dive into, facilitate, showcase, ensure (as filler), handle gracefully |
| Adjectives | robust, seamless, comprehensive, cutting-edge, state-of-the-art, powerful, elegant, holistic, best-in-class, game-changing, crucial, vital, key (as adjective), intuitive, meticulous, innovative, efficient (without a number) |
| Phrases | "a wide range of", "plays a role in", "serves as", "is designed to", "aims to", "in a way that", "when it comes to", "at the end of the day", "moving forward", "going forward" |
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
- **Docstrings and code comments**: see `standards/code.md`. Comments are a
  separate register from documentation and do not follow this file's structure rules.
- **Language**: English only. Do not write or maintain a translated copy of any
  document (a `_zh`, `_fr`, or similar sibling file). A second-language copy is a
  second document that drifts from the first the moment either one changes; keep
  one canonical file per document instead.

## Before you hand off

1. Read it aloud. Any sentence you would not say to a colleague gets rewritten.
2. Search the draft for every entry in the banned table and for em-dashes.
3. Run every command the document contains. Confirm every path it names exists.
4. Confirm the first sentence answers "is this page for me".
5. Delete the last paragraph if it restates the document.
