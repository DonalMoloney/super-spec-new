# Follow the evidence in Specflow

Version 3 expands the original deck into 16 chapters. Follow the constructed
link-audit example through requirements, stable task IDs, traceability,
phase approval, review feedback, and resumption.

Run the server from the repository root:

```bash
python3 -m http.server 8000
```

Open [version 3](http://localhost:8000/presentation/super-deck-v3/).
Use arrows, chapter buttons, or swipes to navigate. Notes gives each chapter's
caveats and source. Select an artifact label to inspect its path.

Three exercises expose specific decisions:

- Try execution without analysis evidence, then record a pass and retry.
- Move the risk sliders across 400 lines and 15 files, or select a path trigger.
- Change a finding's severity and status to see whether it blocks merging.

These exercises simulate the documented rules. They run no commands and write
no project files. The gate exercise assumes the constitution exists. The review
exercise assumes a valid findings document and evaluates one finding.

The persistent scene separates document layers when discussing tasks and draws
a requirement-to-review connection during traceability and feedback chapters.
All scene objects are built once. Reduced motion makes transitions immediate.

The link-audit snapshot was constructed, not recorded. Its named tests belong
to a proposed consuming project; no implementation lives in the example.
Content is sourced from the checkout as of 28 September 2026, at tag v1.1.0.

This folder carries its own HTML, CSS, and JavaScript, preserving
[version 2](../super-deck-v2/README.md). It uses SuperDeck's pinned Three.js 0.186.1
and GSAP 3.15.0 through jsDelivr. Network access and WebGL are needed for 3D;
text navigation remains available when the scene cannot load.
