<!-- Sections below are appended in order by dedicated subagents. Do not reorder. -->

# presentation/marp-deck use guide

How to view, edit, and export the Marp slide deck at `presentation/marp-deck/deck.md`.

## Prerequisites & Install

Rendering or exporting the deck needs the Marp CLI (`@marp-team/marp-cli` on npm).
Run it ad hoc via `npx` (no install), or install it globally/as a dev dependency.
Alternatively, install the "Marp for VS Code" extension (`marp-team.marp-vscode`
in the VS Code Marketplace) to get a live preview and export inside the editor
without installing any CLI tooling.

```bash
# Ad hoc, no install:
npx @marp-team/marp-cli@latest --version

# Render the deck to HTML:
npx @marp-team/marp-cli@latest presentation/marp-deck/deck.md -o deck.html

# Or install globally:
npm install -g @marp-team/marp-cli
```

## Rendering the Deck

Export `presentation/marp-deck/deck.md` to PDF or PowerPoint with the Marp CLI's
`--pdf`/`--pptx` flags plus `-o` for the output path. PDF and PPTX export render
each slide through headless Chrome (Marp CLI uses Puppeteer), so a local
Chrome/Chromium install must be available — if none is found, install one or set
`PUPPETEER_EXECUTABLE_PATH` (or `CHROME_PATH`) to point at an existing browser.

```bash
# Render to PDF:
npx @marp-team/marp-cli@latest presentation/marp-deck/deck.md --pdf -o deck.pdf

# Render to PPTX:
npx @marp-team/marp-cli@latest presentation/marp-deck/deck.md --pptx -o deck.pptx
```

## Live Preview / Editing Workflow

While writing `presentation/marp-deck/deck.md`, run the Marp CLI in watch mode to
get a live-reloading browser preview that updates as you save. If you're already
editing in VS Code, the "Marp for VS Code" extension's built-in preview pane is a
lower-friction alternative — no terminal process to manage. Per this repo's
AGENTS.md, the deck is a single `.md` file with Marp front matter (`marp: true`) —
no build step or framework involved either way.

```bash
npx @marp-team/marp-cli@latest -w presentation/marp-deck/deck.md
```

## Deck Conventions Used in This File

Conventions `presentation/marp-deck/deck.md` follows — keep these when editing it:

- **Front matter**: the file opens with Marp front matter setting `marp: true`,
  `theme: default`, and `paginate: true`.
- **Slide separator**: individual slides are separated by a `---` horizontal-rule
  line on its own.
- **Speaker notes**: each slide ends its content with an HTML comment
  (`<!-- speaker notes: ... -->`). This is Marp's actual, native presenter-notes
  syntax — Marp CLI/VS Code render a plain trailing HTML comment on a slide as that
  slide's presenter-view note, so no conversion is needed for these to work in
  presenter mode.
- **Single file, no build step**: per this repo's `AGENTS.md`, the deck is authored
  as one `.md` file — no separate framework or build tooling.

## Troubleshooting

Common problems rendering/exporting `presentation/marp-deck/deck.md`, and fixes:

- **PDF/PPTX export fails, Chrome/Chromium not found**: see the
  `PUPPETEER_EXECUTABLE_PATH`/`CHROME_PATH` fix under "Rendering the Deck" above.
- **Front matter not picked up (deck renders as plain markdown, no slide breaks)**:
  usually `marp: true` is missing or malformed in the YAML front matter, or the
  front matter isn't the very first thing in the file — no blank lines or content
  may precede the opening `---`.
- **Slides not splitting where expected**: the `---` separator must be on its own
  line, with a blank line both before and after it.
