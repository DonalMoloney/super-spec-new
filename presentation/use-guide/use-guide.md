# presentation/marp-deck use guide

How to view, edit, and export the Marp slide deck at `presentation/marp-deck/deck.md`.

## Prerequisites and Install

Rendering or exporting the deck needs the Marp CLI (`@marp-team/marp-cli` on npm).
Run it through `npx` with no install, or install it globally or as a dev dependency.
The "Marp for VS Code" extension (`marp-team.marp-vscode` in the VS Code Marketplace)
gives a live preview and export inside the editor without any CLI install.

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
`--pdf` or `--pptx` flag plus `-o` for the output path. PDF and PPTX export render
each slide through headless Chrome, because the Marp CLI uses Puppeteer. A local
Chrome or Chromium install must exist. If none is found, install one or set
`PUPPETEER_EXECUTABLE_PATH` (or `CHROME_PATH`) to an existing browser.

```bash
# Render to PDF:
npx @marp-team/marp-cli@latest presentation/marp-deck/deck.md --pdf -o deck.pdf

# Render to PPTX:
npx @marp-team/marp-cli@latest presentation/marp-deck/deck.md --pptx -o deck.pptx
```

## Live Preview / Editing Workflow

While writing `presentation/marp-deck/deck.md`, run the Marp CLI in watch mode to
get a browser preview that reloads on every save. If you already edit in VS Code,
the "Marp for VS Code" preview pane needs no terminal process. Per this repo's
AGENTS.md, the deck is a single `.md` file with Marp front matter (`marp: true`),
with no build step and no framework.

```bash
npx @marp-team/marp-cli@latest -w presentation/marp-deck/deck.md
```

## Deck Conventions Used in This File

Conventions `presentation/marp-deck/deck.md` follows. Keep these when editing it:

- **Front matter**: the file opens with Marp front matter setting `marp: true`,
  `theme: gaia`, `paginate: true`, and `size: 16:9`.
- **Slide separator**: a `---` horizontal-rule line on its own separates slides.
- **Speaker notes**: each slide ends its content with an HTML comment
  (`<!-- speaker notes: ... -->`). Marp treats a plain HTML comment on a slide as
  that slide's presenter-view note, so the comments work in presenter mode with no
  conversion.
- **Single file, no build step**: per this repo's `AGENTS.md`, the deck is one
  `.md` file with no separate framework or build tooling.

## Troubleshooting

Common problems rendering or exporting `presentation/marp-deck/deck.md`, and fixes:

- **PDF/PPTX export fails, Chrome/Chromium not found**: see the
  `PUPPETEER_EXECUTABLE_PATH`/`CHROME_PATH` fix under "Rendering the Deck" above.
- **Front matter not picked up (deck renders as plain markdown, no slide breaks)**:
  `marp: true` is missing or malformed in the YAML front matter, or the front
  matter is not the first thing in the file. No blank line or content may precede
  the opening `---`.
- **Slides not splitting where expected**: the `---` separator must be on its own
  line, with a blank line both before and after it.
