# Render and edit the Specflow decks

Use the Marp deck for PDF, PowerPoint, and presenter notes. Use the
[SuperDeck example](../super-deck/README.md) for an interactive browser talk.
Both explain the workflow in this checkout, checked on 27 September 2026.

Run these commands from the repository root. Node.js and npm run the Marp
CLI without adding a package manifest. The presentation workflow pins Marp
4.2.3; the commands below use the same version.

```bash
npx --yes @marp-team/marp-cli@4.2.3 --version
```

HTML export needs the custom theme. Keep the output beside the SVG files so
relative image links resolve. Marp embeds the theme CSS, but references the
local diagram files. Share the HTML with those SVGs, or share a PDF instead.

```bash
npx --yes @marp-team/marp-cli@4.2.3 \
  --theme-set presentation/marp-deck/global.css \
  --bespoke.transition=false presentation/marp-deck/deck.md \
  -o presentation/marp-deck/deck.html
```

PDF and PowerPoint export need a browser. Install Chrome, Edge, or Firefox;
use `--browser-path /absolute/path/to/browser` if discovery fails. Local SVG
access needs the flag shown below. See the [Marp CLI reference](https://github.com/marp-team/marp-cli#readme).

```bash
npx --yes @marp-team/marp-cli@4.2.3 \
  --theme-set presentation/marp-deck/global.css \
  --pdf --pdf-notes --allow-local-files \
  presentation/marp-deck/deck.md -o /tmp/specflow-deck.pdf

npx --yes @marp-team/marp-cli@4.2.3 \
  --theme-set presentation/marp-deck/global.css \
  --pptx --allow-local-files \
  presentation/marp-deck/deck.md -o /tmp/specflow-deck.pptx
```

For editing, keep the HTML open while watch mode rebuilds it. Reload the
browser after a change. Arrow keys navigate; the presentation controls open
presenter view. Plain HTML comments in the Markdown supply speaker notes.

```bash
npx --yes @marp-team/marp-cli@4.2.3 \
  --theme-set presentation/marp-deck/global.css \
  --bespoke.transition=false --watch presentation/marp-deck/deck.md \
  -o presentation/marp-deck/deck.html
```

The front matter names `theme: specflow`, with pagination and a 16:9 size.
Keep each Mermaid source beside its SVG export. Rebuild changed diagrams
before exporting the deck; Marp reads the SVG, not the Mermaid source.

```bash
npx --yes @mermaid-js/mermaid-cli@11.17.0 \
  -i presentation/marp-deck/commands.mmd \
  -o presentation/marp-deck/commands.svg -b transparent
python3 specflow/scripts/lint-standards.py presentation
git diff --check
```

Inspect all 18 slides for clipping and readable labels after rendering.
Check claims against the manifest, command contracts, and native hook settings.
Use [presentation standards](../../standards/presentations.md) for slide layout.
Generated HTML stays ignored; commit the Markdown, CSS, Mermaid, and SVG sources.
