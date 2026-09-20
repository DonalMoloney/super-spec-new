# Present the Specflow workflow

`deck.md` contains 18 Marp slides with presenter notes and sourced claims.
The talk opens with why self-review can't prove independence, then moves
through governance mechanics, implementation proof, and adoption. The title
slide is dated 20 September 2026. Repository checks qualify historical claims
in the notes.

## Slide sequence

| Slide | Message | Visual |
|-------|---------|--------|
| 1 | Specflow connects governance and execution. | `specflow-mark.svg` |
| 2 | Self-review can't prove independence. | `review-independence.svg` |
| 3 | Specflow assigns responsibility across the workflow. | `workflow.svg` |
| 4 | Without a recorded gate, approval depends on judgment. | `gates.svg` |
| 5 | Five commands connect the workflow. | `commands.svg` |
| 6 | The constitution gates every command. | `artifacts.svg` |
| 7 | Execution skills work inside agreed rules. | `skills.svg` |
| 8 | Checks confirm compliance, not product correctness. | `correctness-gap.svg` |
| 9 | The first 18 roadmap groups have merged. | `roadmap.svg` |
| 10 | Four default layers precede additional review. | `review-stack.svg` |
| 11 | Risk rises above the size limits. | `risk.svg` |
| 12 | Findings make decisions inspectable. | Text |
| 13 | The companion kit needs deliberate installation. | `kit.svg` |
| 14 | Checks run at distinct workflow boundaries. | `hooks.svg` |
| 15 | Installation ends with a readiness check. | CLI sequence |
| 16 | Adoption proceeds in three 30-day steps. | `adoption.svg` |
| 17 | Humans approve intent; review stays bounded. | Text |
| 18 | Adopt the constitution-and-hooks baseline on one feature. | Action |

The roadmap diagram groups adjacent group numbers; it does not imply dated
merge order. The review diagram describes the proposed policy. Its notes
separate that policy from the committed CI behavior. The hook diagram shows
work boundaries, not a literal chain of hook events. Slide 2 merges the two
review-independence slides from the earlier outline; slide 17 merges the two
closing-principles slides. Slides 4 and 8 replace their earlier text-only
form with a diagram, so each now shows the contrast it argues for instead of
asserting it.

## Edit and render

Keep diagram sources beside their SVG exports. Each diagram uses labeled
edges, a neutral scale, and one blue emphasis. The custom Specflow theme lives in `global.css`.
It sets typography, spacing, diagram panels, and the print layout. Slides carry the
claim; notes carry the explanation, limitations, and sources.

Render a changed diagram from its matching Mermaid source:

```bash
npx @mermaid-js/mermaid-cli -i presentation/marp-deck/workflow.mmd -o presentation/marp-deck/workflow.svg -b transparent
```

Render the deck with local SVG access and presenter notes:

```bash
marp --theme-set presentation/marp-deck/global.css --pdf --pdf-notes --allow-local-files presentation/marp-deck/deck.md -o /tmp/specflow-deck.pdf
python3 specflow/scripts/lint-standards.py presentation/marp-deck/deck.md presentation/marp-deck/README.md
```

Check all 18 rendered pages for clipping and readable labels. Keep the body
to two short statements plus one visual. Follow the full rules in
`standards/presentations.md`. The install slide mixes terminal commands and
Claude Code slash commands; its notes explain where each runs.

## HTML presentation

Open `deck.html` in a browser. Keep `global.css` beside the HTML when sharing
it. The diagrams are embedded, and the presentation needs no network access.
The centered title icon represents a spec passing through a check into code.
Arrow keys change slides; the presentation controls provide fullscreen and
presenter views. The source remains `deck.md`.

Regenerate HTML with the same theme:

```bash
marp --theme-set presentation/marp-deck/global.css --bespoke.transition=false presentation/marp-deck/deck.md -o presentation/marp-deck/deck.html
```

Marp embeds the theme in its export. The delivered HTML also links the local
stylesheet and embeds the diagram SVGs; a raw re-export references the SVGs
beside the deck. Regenerate after changing the stylesheet to keep Marp's
scoped theme in sync.

## Research references

The self-review slide retains these primary sources in its presenter notes.
These studies motivate review choices; they do not measure Specflow's
performance. The model-separation rule is an engineering recommendation,
not a guarantee of independent errors.

- [Zheng et al., Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena](https://arxiv.org/abs/2306.05685), NeurIPS 2023. Documents position, verbosity, and self-enhancement biases in model evaluation.
- [Panickssery, Bowman, and Feng, LLM Evaluators Recognize and Favor Their Own Generations](https://arxiv.org/abs/2404.13076), 2024. Studies self-recognition and preference for a model's own generated text.
- [Huang et al., Large Language Models Cannot Self-Correct Reasoning Yet](https://arxiv.org/abs/2310.01798), 2023 preprint, ICLR 2024. Studies the limits of reasoning self-correction without external feedback.

Zheng et al. supplies the traceable citation for position and verbosity bias.
The requested outline named Wang and Saito without paper titles. Use the
linked primary source rather than repeating an ambiguous attribution.
