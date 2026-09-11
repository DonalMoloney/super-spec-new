# Presentation standards

These rules apply to the Marp deck under `presentation/`, to any slides an agent
produces, and to any slide-shaped summary such as a status readout or review
report. The tone rules and banned-phrase table in `standards/documentation.md`
apply in full.

## Format

- One Markdown file per deck with Marp front matter: `marp: true`, a named `theme`,
  `paginate: true`, and `size: 16:9`. No build step and no framework.
- One theme for the whole deck. Per-slide class overrides are allowed only on the
  title slide and section dividers.
- File names are kebab-case and carry no date. The date belongs on the title slide.
- Diagrams are Mermaid blocks or an SVG checked in beside the deck. Never a
  screenshot of a diagram.

## Each slide

- One message per slide. The title states the claim, not the topic. "Install fails
  above 50 MiB, so assets are export-ignored", not "Assets".
- Body: at most six lines and at most ten words per line. If the content does not
  fit, it is two slides or it belongs in the speaker notes.
- Speaker notes (HTML comments) carry the detail, the caveats, and the sources. The
  slide carries the point.
- At most one visual per slide: a diagram, a table, a code block, or a single number.
- Code blocks: at most eight lines, tagged with a language, showing only the lines the
  point depends on.
- Tables: at most four columns and five rows.
- Diagrams: labeled edges, at most ten nodes, one direction of flow.
- Numbers: same unit and precision throughout the deck, rounded to what changes the
  decision, source in the notes.
- Titles in sentence case. No title case, no capitals for emphasis.

## Deck shape

- Title slide: deck name, one-line claim, date, author.
- No agenda slide. No "Key takeaways", "Recap", or "Overview" slide that restates
  earlier slides. No "Questions?" or "Thank you" slide.
- Section dividers only when the deck exceeds fifteen slides.
- The last content slide states in one line what the audience should do or decide.

## Forbidden on sight

- Emoji, decorative icons, clip art, stock imagery, gradients, drop shadows.
- Bullets that are three-word fragments. Write a full statement or nothing.
- A slide that only repeats the title in the body.
- Walls of text meant to be read rather than presented.
- Unsourced numbers.
- Animated transitions or build-in effects.

## Before you hand off

1. Render the deck and confirm no warnings and no overflow at the default size:

   ```bash
   npx @marp-team/marp-cli --pdf presentation/<deck>.md
   ```

2. Confirm every slide title is a claim and every number has a source in its notes.
3. Search the deck for every entry in the documentation banned table and for emoji.
4. Confirm the final slide names one action or decision.
