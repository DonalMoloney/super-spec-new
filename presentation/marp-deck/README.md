# Marp deck: what to show and how to diagram it

This folder holds `deck.md`, the nine-slide Marp deck that gives a project
overview, and the SVG diagrams it embeds. Read this file before editing the
deck or adding a diagram. The rules in `standards/presentations.md` apply in
full; this file says how they land on this deck.

## What each slide shows

Every title is a claim, and every slide carries one visual or none. The deck
runs in this order:

| Slide | Claim | Visual |
|-------|-------|--------|
| 1 | Title, one-line claim, date, author | none |
| 2 | Specflow adds five commands to a spec-kit project | `workflow.svg` |
| 3 | All 18 roadmap groups have merged | none, five bullets |
| 4 | A single LLM reviewer approves its own mistakes | none, four bullets |
| 5 | Four review layers run by default and three on risk | `review-stack.svg` |
| 6 | The kit under .claude is ready to copy | none, five bullets |
| 7 | Install takes three commands and a status check | code block |
| 8 | Adoption runs in three 30-day steps | none, five bullets |
| 9 | Start this week with the constitution rewrite and gate hooks | none |

Slides 2 and 5 are the two that earn a diagram: each describes a flow the
bullets can only list. The other slides state counts or steps and stay as
text. Do not add a diagram to a slide that already has a table or code block.

## How to form a diagram for impact

Write the source as Mermaid in a `.mmd` file beside the deck, render it to
SVG with the Mermaid CLI, and embed the SVG. Marp does not render a Mermaid
fence, and the CI render step fails on an image it cannot find, so commit
both the source and the SVG.

```bash
npx @mermaid-js/mermaid-cli -i presentation/marp-deck/workflow.mmd -o presentation/marp-deck/workflow.svg
npx @marp-team/marp-cli@4.2.3 --pdf presentation/marp-deck/deck.md -o deck.pdf
```

Embed with a width so the diagram stops short of the slide edge:
`![w:1000](workflow.svg)`.

Six rules decide whether a diagram helps or hurts:

- One direction of flow, left to right for a pipeline and top to bottom for
  a gate sequence. A diagram that turns a corner reads as two diagrams.
- At most ten nodes. Slide 2 has seven stages; slide 5 has four layers, one
  risk branch, and one critic node.
- Every edge carries a label that names the artifact or the condition
  crossing it: `spec.md`, `.analyzed`, `HIGH`. An unlabeled arrow is a
  guess the audience has to make.
- One accent color, on the one thing the slide is about. On slide 2 that is
  the four specflow commands in the flow; the spec-kit stages stay neutral.
  On slide 5 it is the critic node the risk branch reaches.
- Node text is the command or file name, not a sentence. The claim is the
  slide title; the diagram shows the mechanism behind it.
- No icons, shadows, gradients, or a second font. The `gaia` theme's
  neutral scale and one accent are the whole palette.

The Mermaid source for slide 2, as a starting point:

```mermaid
flowchart LR
  C[constitution] -->|constitution.md| S[specify]
  S -->|spec.md| B[brainstorm]
  B -->|spec.md| P[plan]
  P -->|plan.md| T[tasks]
  T -->|tasks.md, .analyzed| E[execute]
  E -->|review-scope.md| R[review]
  classDef flow fill:#0b5fff,color:#fff,stroke:none
  class B,T,E,R flow
```

Check the render before handing off: open `deck.pdf`, confirm the diagram
sits inside the slide margin, and confirm the accent is distinguishable from
the neutral nodes under a colorblind simulation. Put the source of every
node name in that slide's speaker note.
