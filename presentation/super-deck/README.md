# Present Specflow as a persistent scene

This nine-slide example follows one feature from constitution to review.
It adapts the persistent-scene architecture and clickable artifact labels from
the local SuperDeck project's `templates/poke-the-diagram.html`.
The Specflow copy, scene geometry, navigation, and compact runtime live here.
No file depends on the sibling checkout.

Serve this repository from its root:

```bash
python3 -m http.server 8000
```

Open [the browser deck](http://localhost:8000/presentation/super-deck/).
Use arrow keys, the chapter buttons, or swipe across the diagram. Home and End
jump to the first and last slide. Click an artifact label to inspect its role.
Open Notes for each slide's caveats and source link.

On slide 4, try execution without analysis evidence. The demonstration reports
`ANALYZE_REQUIRED`. Select the checkbox and try again to open the illustrated
gate. This simulates one prerequisite; it runs no agent and writes no files.

The page loads Three.js 0.186.1 and GSAP 3.15.0 from jsDelivr, matching
SuperDeck's pins. It needs network access and WebGL for the scene. Serve over
HTTP rather than opening a file URL. If the scene cannot load, text navigation
and artifact details remain available with a visible error.

The HTML holds selectable text above one persistent canvas. Complete slide
states set the camera, focus, and gate position. Objects are built once.
Rendering stops between transitions and pauses while the tab is hidden.
Reduced-motion preferences make state changes immediate.

The browser format and camera transitions follow the requested SuperDeck
example. The [Marp deck](../marp-deck/deck.md) remains the static export version.
Use [the guide](../use-guide/use-guide.md) for PDF and PowerPoint.
Content was checked against this repository on 27 September 2026.
