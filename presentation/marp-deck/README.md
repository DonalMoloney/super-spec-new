# Present the Specflow workflow

`deck.md` contains 18 Marp slides with presenter notes and sourced claims.
The talk opens with why self-review can't prove independence, then moves
through governance mechanics, implementation proof, and adoption. The title
slide is dated 28 September 2026. Repository checks qualify historical claims
in the notes.

## Slide sequence

| Slide | Message | Visual |
|-------|---------|--------|
| 1 | Specflow connects governance and execution. | `specflow-mark.svg` |
| 2 | Self-review can't prove independence. | `review-independence.svg` |
| 3 | Specflow assigns responsibility across the workflow. | `workflow.svg` |
| 4 | Without a recorded gate, approval depends on judgment. | `gates.svg` |
| 5 | Six commands connect the workflow. | `commands.svg` |
| 6 | The constitution gates every command. | `artifacts.svg` |
| 7 | Execution skills work inside agreed rules. | `skills.svg` |
| 8 | Checks confirm compliance, not product correctness. | `correctness-gap.svg` |
| 9 | An install wires the gates into both CLIs. | `roadmap.svg` |
| 10 | Four default layers precede additional review. | `review-stack.svg` |
| 11 | Risk rises above the size limits. | `risk.svg` |
| 12 | Findings make decisions inspectable. | Text |
| 13 | The companion kit needs deliberate installation. | `kit.svg` |
| 14 | Checks run at distinct workflow boundaries. | `hooks.svg` |
| 15 | Installation ends with a readiness check. | CLI sequence |
| 16 | Adoption proceeds in three 30-day steps. | `adoption.svg` |
| 17 | Humans approve intent; review stays bounded. | Text |
| 18 | Adopt the constitution-and-hooks baseline on one feature. | Action |

The roadmap diagram traces a shipped gate to the install that registers it.
The review diagram describes the proposed policy. Its notes
separate that policy from the committed CI behavior. The hook diagram shows
work boundaries, not a literal chain of hook events. The notes name the
Copilot adapter and the contract the headless review reads.

## Edit and render

Keep diagram sources beside their SVG exports. Each diagram uses labeled
edges, a neutral scale, and one blue emphasis. The custom Specflow theme lives in `global.css`.
It sets typography, spacing, diagram panels, and the print layout. Slides carry the
claim; notes carry the explanation, limitations, and sources.

Render a changed diagram from its matching Mermaid source. The version is
pinned: Mermaid 12 lays the same source out differently, so an unpinned
re-render restyles one diagram out of step with the other fifteen.

```bash
npx --yes @mermaid-js/mermaid-cli@11.17.0 -i presentation/marp-deck/workflow.mmd -o presentation/marp-deck/workflow.svg -b transparent
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

Generate `deck.html`, then open it in a browser. Share the local SVGs beside
the HTML. Marp embeds the theme but references those diagram files.
The centered title icon represents a spec passing through a check into code.
Arrow keys change slides; the presentation controls provide fullscreen and
presenter views. The source remains `deck.md`.

Regenerate HTML with the same theme:

```bash
marp --theme-set presentation/marp-deck/global.css --bespoke.transition=false presentation/marp-deck/deck.md -o presentation/marp-deck/deck.html
```

Regenerate after changing the stylesheet. The generated HTML is ignored by
Git. The [usage guide](../use-guide/use-guide.md) includes commands pinned to
CI's Marp version, PowerPoint export, and troubleshooting. The
[SuperDeck example](../super-deck/README.md) presents the same workflow as an
interactive browser scene.

## Research references

The self-review slide retains these primary sources in its presenter notes.
These studies motivate review choices; they do not measure Specflow's
performance. The model-separation rule is an engineering recommendation,
not a guarantee of independent errors.

- [Zheng et al., Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena](https://arxiv.org/abs/2306.05685), NeurIPS 2023. Documents position, verbosity, and self-enhancement biases in model evaluation.
- [Panickssery, Bowman, and Feng, LLM Evaluators Recognize and Favor Their Own Generations](https://arxiv.org/abs/2404.13076), 2024. Studies self-recognition and preference for a model's own generated text.
- [Huang et al., Large Language Models Cannot Self-Correct Reasoning Yet](https://arxiv.org/abs/2310.01798), 2023 preprint, ICLR 2024. Studies the limits of reasoning self-correction without external feedback.
