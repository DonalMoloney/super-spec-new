[
  {
    "id": "intent",
    "chapter": "A feature, end to end",
    "title": "Intent becomes<br>inspectable.",
    "description": "Spec-kit defines the artifacts. Specflow adds commands, gates, and resumable execution.",
    "detail": "Six commands · five templates · nine shipped scripts · six workflow hooks.",
    "focus": -1,
    "camera": [
      10,
      11,
      16
    ],
    "target": [
      0,
      0,
      0
    ],
    "gate": 0,
    "caption": "One persistent scene. Every boundary has a reason.",
    "note": "Spec-kit owns the constitution, spec, plan, tasks, and checklist. Specflow adds six commands, five extension templates, nine scripts under specflow/gates/, and six hooks in extension.yml. Superpowers skills remain optional; built-in protocols cover missing skills. The extension targets Claude Code and GitHub Copilot CLI. The 3D scene explains the contracts, it does not call an agent or execute a feature.",
    "source": "../../specflow/extension.yml",
    "proof": [
      [
        "SPEC-KIT",
        "Constitution · spec · plan · tasks · checklist."
      ],
      [
        "SPECFLOW",
        "Commands · gates · templates · hooks."
      ],
      [
        "SUPERPOWERS",
        "Optional skills with built-in fallbacks."
      ]
    ],
    "spread": 0,
    "trace": 0
  },
  {
    "id": "example",
    "chapter": "The feature we will follow",
    "title": "Find the<br>broken link.",
    "description": "A local Markdown link checker must report missing targets and return a CI failure.",
    "detail": "Input path + line + target → JSON finding and exit 1.",
    "focus": 1,
    "camera": [
      -5,
      8,
      11
    ],
    "target": [
      -3,
      0,
      0
    ],
    "gate": 0,
    "caption": "Worked example: link-audit, not a recorded agent run.",
    "note": "The example defines three stories: missing file targets, stale heading anchors, and scans restricted to team-owned files. It skips http, https, and mailto links without network access, accepts directory targets, supports repeatable --ignore GLOB, and caps scans at 5,000 files. The scanner is a proposed consuming project: the snapshot contains no implementation and was constructed by hand.",
    "source": "../../specflow/examples/link-audit/README.md",
    "proof": [
      [
        "INPUT",
        "docs/setup.md links to docs/install.md."
      ],
      [
        "FINDING",
        "Source file · 1-based line · target · reason · fix."
      ],
      [
        "EXIT CODE",
        "1 with findings · 0 when the report is empty."
      ]
    ],
    "spread": 0,
    "trace": 0
  },
  {
    "id": "constitution",
    "chapter": "The first boundary",
    "title": "Rules constrain<br>the solution.",
    "description": "Commands check the consuming project's constitution before their work begins.",
    "detail": "Path: .specify/memory/constitution.md · absent file: CONSTITUTION_REQUIRED.",
    "focus": 0,
    "camera": [
      -7,
      7,
      12
    ],
    "target": [
      -5,
      0,
      0
    ],
    "gate": 0,
    "caption": "CONSTITUTION_REQUIRED stops execution before code changes.",
    "note": "Execute, tasks, and gate check .specify/memory/constitution.md before proceeding. The constitution sets principles the plan, task breakdown, implementation, and review must follow. In the example, the offline rule means external URL schemes are skipped. The check proves that a file exists; it cannot prove that the team's rules are complete or suitable.",
    "source": "../../specflow/commands/execute.md",
    "proof": [
      [
        "RULE",
        "Resolve targets from the local checkout."
      ],
      [
        "DESIGN EFFECT",
        "Skip external URL schemes; never fetch."
      ],
      [
        "CHECK",
        "Fail CI when a relative target is missing."
      ]
    ],
    "spread": 0,
    "trace": 0
  },
  {
    "id": "clarify",
    "chapter": "Resolve uncertainty",
    "title": "A question is<br>unfinished work.",
    "description": "Brainstorm turns edge cases into decisions before the task breakdown starts.",
    "detail": "OPEN_QUESTIONS counts unresolved rows; .clarified checks text markers.",
    "focus": 1,
    "camera": [
      -5,
      8,
      11
    ],
    "target": [
      -3,
      0,
      0
    ],
    "gate": 0,
    "caption": "Open questions and clarification markers are different checks.",
    "note": "The fallback brainstorm groups prompts under boundaries, error scenarios, scale and performance, security and privacy, and user experience. /speckit.specflow.tasks stops when any Open Questions row has a Status other than Resolved. The .clarified marker is a separate check written after clarify finds no NEEDS CLARIFICATION marker. Resolving a row and removing a text marker are distinct artifact checks.",
    "source": "../../specflow/commands/tasks.md",
    "proof": [
      [
        "EDGE CASE",
        "Does a directory target count as resolved?"
      ],
      [
        "DECISION",
        "Yes; a directory is an existing target."
      ],
      [
        "STOP CODE",
        "OPEN_QUESTIONS reports the unresolved row count."
      ]
    ],
    "spread": 0,
    "trace": 0
  },
  {
    "id": "plan",
    "chapter": "Choose the implementation",
    "title": "Decisions become<br>constraints.",
    "description": "The plan fixes the technical approach before tasks turn it into work units.",
    "detail": "Template lookup: project override → preset → extension → core.",
    "focus": 2,
    "camera": [
      -1,
      9,
      12
    ],
    "target": [
      -1,
      0,
      0
    ],
    "gate": 0,
    "caption": "Project overrides → presets → extension templates → core.",
    "note": "The installed resolver chooses a template from project overrides, presets, extension templates, then core templates. If the resolver fails, tasks stops with RESOLVER_REQUIRED; reading the core template directly would silently drop Specflow's sections. The manifest requires spec-kit 0.16.2 or newer. This repository is a prompt and spec extension, not an application package.",
    "source": "../../specflow/commands/tasks.md",
    "proof": [
      [
        "SPEC",
        "Acceptance scenarios and measurable criteria."
      ],
      [
        "PLAN",
        "Architecture, stack, and implementation strategy."
      ],
      [
        "TEMPLATE",
        "Resolver selects the correct governance layer."
      ]
    ],
    "spread": 0,
    "trace": 0
  },
  {
    "id": "tasks",
    "chapter": "Make work verifiable",
    "title": "One outcome.<br>One stable ID.",
    "description": "Each task carries one outcome, stable ID, execution markers, and verification evidence.",
    "detail": "[TDD] · [P] · [REVIEW] · [SUBAGENT] · one Verify row per task.",
    "focus": 3,
    "camera": [
      1,
      10,
      10
    ],
    "target": [
      0,
      0,
      0
    ],
    "gate": 0,
    "caption": "Completed task IDs must not disappear without confirmation.",
    "note": "Task IDs use TNNN. Regeneration matches tasks by outcome, preserves matched IDs, assigns new IDs above the highest used value, and never reuses a retired ID. Before writing, the command reports added, removed, and renumbered IDs. It stops for confirmation when that diff would remove or renumber a completed task. A task line that needs 'and' to state its outcome should split into separate tasks.",
    "source": "../../specflow/commands/tasks.md",
    "proof": [
      [
        "T001 [TDD]",
        "Failing test for a missing target."
      ],
      [
        "T002 [REVIEW]",
        "Report its source, line, and target."
      ],
      [
        "VERIFY",
        "Name the test command or direct observation."
      ]
    ],
    "spread": 1,
    "trace": 0
  },
  {
    "id": "gate",
    "chapter": "Operate the prerequisite",
    "title": "Evidence opens<br>the gate.",
    "description": "The analyze marker unlocks execute only after the report contains zero CRITICAL rows.",
    "detail": "/speckit.analyze → gate analyzed → specs/NNN-feature/.analyzed.",
    "focus": 3,
    "camera": [
      3,
      8,
      12
    ],
    "target": [
      1,
      0,
      0
    ],
    "gate": 0,
    "caption": "ANALYZE_REQUIRED names the missing marker and next command.",
    "note": "The actual gate command reads the analysis report from standard input. gates/bash/write-marker.sh refuses analyzed while the report contains CRITICAL rows; on success it writes .analyzed. Execute checks that marker again after a resume. Clear .analyzed when the spec, plan, tasks, or constitution changes, or old evidence could authorize new inputs. This exercise simulates one prerequisite and writes no files.",
    "source": "../../specflow/commands/gate.md",
    "proof": [],
    "spread": 0,
    "trace": 0
  },
  {
    "id": "trace",
    "chapter": "Trace the requirement",
    "title": "Connect the rule<br>to the test.",
    "description": "Traceability joins a functional requirement to a named test and a review finding.",
    "detail": "FR-004 → reports_missing_target → R-001 → CHK row.",
    "focus": 1,
    "camera": [
      2,
      14,
      17
    ],
    "target": [
      0,
      0,
      0
    ],
    "gate": 1,
    "caption": "Spec requirement → named test → finding → checklist item.",
    "note": "FR-004 requires each broken target to report the source path, 1-based line, and raw target. The example links that criterion to tests/test_scanner.py::reports_missing_target. The review can then cite a file:line, evidence, and fix. The scorer reads test names from the Traceability table, but a score over constructed artifacts is not proof that the test ran.",
    "source": "../../specflow/examples/link-audit/specs/001-link-audit/spec.md",
    "proof": [
      [
        "FR-004",
        "Report source, line, and target."
      ],
      [
        "TEST",
        "reports_missing_target"
      ],
      [
        "REVIEW",
        "Check the test against the acceptance scenario."
      ]
    ],
    "spread": 1,
    "trace": 1
  },
  {
    "id": "execute",
    "chapter": "Run the task protocol",
    "title": "Failure first.<br>Evidence next.",
    "description": "Execution follows RED-GREEN-REFACTOR, records progress, and reviews completed work.",
    "detail": "Claude can dispatch subagents; Copilot runs the tasks in sequence.",
    "focus": 4,
    "camera": [
      7,
      7,
      11
    ],
    "target": [
      3,
      0,
      0
    ],
    "gate": 1,
    "caption": "A passing test is evidence about the behavior it checks.",
    "note": "For [TDD], write a behavior test, observe the failure, implement the smallest passing change, then refactor. Claude Code may use Task dispatch and Agent Teams when available. Copilot CLI executes [P] and [SUBAGENT] work in sequence in the same session. The workflow keeps its built-in fallback if a superpowers skill is absent. The command calls code-reviewer after tasks and runs the feature review at each phase end.",
    "source": "../../specflow/commands/execute.md",
    "proof": [
      [
        "RED",
        "Fail the named behavior test."
      ],
      [
        "GREEN",
        "Implement until that test passes."
      ],
      [
        "REFACTOR",
        "Keep the behavior checks passing."
      ]
    ],
    "spread": 0,
    "trace": 0
  },
  {
    "id": "checkpoint",
    "chapter": "Bound the work",
    "title": "A phase ends<br>with a person.",
    "description": "Every execution phase ends with tests, a concise handoff, and explicit human approval.",
    "detail": "The next phase cannot begin until the user approves its checkpoint.",
    "focus": 4,
    "camera": [
      7,
      9,
      14
    ],
    "target": [
      2,
      0,
      0
    ],
    "gate": 1,
    "caption": "Phase approval is separate from final merge approval.",
    "note": "At a phase boundary, execute summarizes completed work, runs applicable tests, and writes specs/NNN/handoff.md capped at five lines. It waits for explicit user approval before the next phase. progress.yml tracks the current phase and task states. This phase checkpoint is a workflow control; spec approval and merge approval are separate decisions.",
    "source": "../../specflow/commands/execute.md",
    "proof": [
      [
        "CHECK",
        "Run the phase's applicable tests."
      ],
      [
        "RECORD",
        "Update progress.yml and handoff.md."
      ],
      [
        "APPROVE",
        "Wait before starting the next phase."
      ]
    ],
    "spread": 0,
    "trace": 0
  },
  {
    "id": "risk",
    "chapter": "Choose review depth",
    "title": "Risk changes<br>the review.",
    "description": "The classifier selects HIGH review for large diffs, sensitive paths, or recognized dependency files.",
    "detail": "HIGH if additions + deletions > 400, files > 15, or a path rule matches.",
    "focus": 5,
    "camera": [
      10,
      9,
      14
    ],
    "target": [
      4,
      0,
      0
    ],
    "gate": 1,
    "caption": "Strict thresholds: more than 400 lines or 15 files.",
    "note": "The risk-classifier compares BASE_REF...HEAD with git diff --numstat. Added and deleted lines are summed; a binary file counts as a file but contributes no line count. The strict cutoffs are greater than 400 changed lines or more than 15 files, so 400 and 15 remain STANDARD without another trigger. Sensitive directories match auth, payments, billing, migrations, infra, secrets, or crypto. Recognized dependency names are package-lock.json, yarn.lock, Cargo.lock, poetry.lock, go.sum, and requirements*.txt. A HIGH result enables extra review stages; this slider models the rule and does not inspect the current checkout.",
    "source": "../../specflow/gates/bash/risk-classifier.sh",
    "proof": [
      [
        "SIZE",
        "401 lines or 16 files → HIGH."
      ],
      [
        "PATH",
        "Sensitive directory → HIGH."
      ],
      [
        "MANIFEST",
        "Recognized dependency filename → HIGH."
      ]
    ],
    "spread": 0,
    "trace": 0
  },
  {
    "id": "review",
    "chapter": "Inspect the decision",
    "title": "A finding needs<br>checkable evidence.",
    "description": "A validated findings document blocks unresolved Critical and Important findings.",
    "detail": "Finding fields include severity · location · evidence · fix · status.",
    "focus": 5,
    "camera": [
      10,
      7,
      11
    ],
    "target": [
      5,
      0,
      0
    ],
    "gate": 1,
    "caption": "The gate reads findings, not reassurance.",
    "note": "The JSON contract requires schema_version 1.0, reviewer, verdict, and findings. Each finding needs id, severity, location, evidence, and fix. merge-gate.sh validates each document, then blocks Critical or Important unless status is fixed or rebutted; accepted or rejected remains unresolved for this gate. Minor never blocks. jq is an install-time dependency. A missing or invalid findings document fails closed. The exercise shows one finding; the real gate reads JSON files from configured review paths.",
    "source": "../../specflow/references/findings-schema.json",
    "proof": [],
    "spread": 0,
    "trace": 0
  },
  {
    "id": "feedback",
    "chapter": "Review can change the spec",
    "title": "A gap returns<br>to the question.",
    "description": "Critical and Important findings that expose spec gaps return to Open Questions.",
    "detail": "Review joins failed CHK IDs to R-NNN findings in the checklist.",
    "focus": 1,
    "camera": [
      2,
      14,
      17
    ],
    "target": [
      0,
      0,
      0
    ],
    "gate": 1,
    "caption": "R-001 → Open Question → resolution → verification.",
    "note": "The review command writes review-findings.json and adds missing, ambiguous, or contradicted requirements to the spec's Open Questions table under the finding ID. When a checklist has a Review Findings table, it links each failed CHK identifier to its R-NNN finding and status. Resolve the requirement, update behavior and tests, then rerun review. This feedback loop changes both the implementation evidence and the statement of intent.",
    "source": "../../specflow/commands/review.md",
    "proof": [
      [
        "FINDING",
        "Name the missing or contradicted requirement."
      ],
      [
        "SPEC",
        "Add an Open Questions row keyed by R-NNN."
      ],
      [
        "CHECKLIST",
        "Join CHK-NNN to the finding status."
      ]
    ],
    "spread": 1,
    "trace": 1
  },
  {
    "id": "resume",
    "chapter": "Recover the session",
    "title": "State outlives<br>the conversation.",
    "description": "Commands reconstruct the next action from feature artifacts and two YAML state files.",
    "detail": "specs/NNN-*/progress.yml · .specify/superpowers.yml.",
    "focus": 3,
    "camera": [
      0,
      15,
      16
    ],
    "target": [
      0,
      0,
      0
    ],
    "gate": 1,
    "caption": "Saved state is readable; stale gate markers still need care.",
    "note": "progress.yml records the current phase, status, and task states. If absent, status can infer progress from constitution.md, spec.md, Brainstorm Log entries, plan.md, and tasks.md checkboxes. .specify/superpowers.yml caches detected skills and an optional plugin version. Every command reads saved progress before continuing. Execute still checks .analyzed on resume; changes to upstream artifacts require invalidating stale markers.",
    "source": "../../specflow/commands/status.md",
    "proof": [
      [
        "FEATURE STATE",
        "specs/NNN-feature/progress.yml"
      ],
      [
        "SKILL CACHE",
        ".specify/superpowers.yml"
      ],
      [
        "RESUME",
        "First unchecked task in the current phase."
      ]
    ],
    "spread": 0,
    "trace": 0
  },
  {
    "id": "runtimes",
    "chapter": "Same contracts, different dispatch",
    "title": "Two CLIs.<br>One workflow.",
    "description": "Both CLIs share command contracts, with different agent dispatch and native hook setup.",
    "detail": "Claude Code: Task tool and Agent Teams · Copilot CLI: sequential task execution.",
    "focus": -1,
    "camera": [
      10,
      11,
      16
    ],
    "target": [
      0,
      0,
      0
    ],
    "gate": 1,
    "caption": "Shipping a gate script does not register a native hook.",
    "note": "The extension manifest declares six optional hooks: after_clarify, after_analyze, after_tasks, before_tasks, before_implement, and after_implement. Claude event wiring lives in .claude/settings.json; Copilot uses .github/hooks/hooks.json plus adapter.sh. Copilot's preToolUse handler can deny a command; postToolUse can only add context after the edit. The native Copilot config registers block-main-commit before tools, test-gate and artifact-lint after tools, and session-start on sessionStart. G-26's spec-kit events registration remains open.",
    "source": "../../specflow/commands/execute.md",
    "proof": [
      [
        "CLAUDE CODE",
        "Task dispatch; optional parallel Agent Teams."
      ],
      [
        "COPILOT CLI",
        "P and SUBAGENT tasks run in sequence."
      ],
      [
        "HOOKS",
        "Native settings are separate from extension.yml."
      ]
    ],
    "spread": 0,
    "trace": 0
  },
  {
    "id": "adopt",
    "chapter": "Exercise the whole chain",
    "title": "Make one feature<br>auditable.",
    "description": "Install the extension, approve the constitution, and follow one real feature to merge.",
    "detail": "Observe a refusal, clear its evidence, resume, and inspect the final findings.",
    "focus": -1,
    "camera": [
      10,
      11,
      16
    ],
    "target": [
      0,
      0,
      0
    ],
    "gate": 1,
    "caption": "Human approval accepts the evidence for shipping.",
    "note": "The extension archive ships the nine shared gate scripts under specflow/gates/. Native hook configuration and the companion .claude agents require separate setup. The default spec-kit catalog does not list this fork; use the checkout or release-asset instructions in specflow/README.md. CI runs structural validation, hook tests, the review workflow, and a dry-run agent workflow. No constructed example or passing schema check proves that an agent run produced correct product behavior.",
    "source": "../../specflow/README.md",
    "proof": [
      [
        "INSTALL",
        "Use Claude Code or GitHub Copilot CLI integration."
      ],
      [
        "EXERCISE",
        "Run the named gates and review."
      ],
      [
        "DECIDE",
        "Approve the feature against its evidence."
      ]
    ],
    "spread": 0,
    "trace": 0
  }
];

const artifacts = [
  ['Constitution','Rules every command must check.','.specify/memory/constitution.md'],
  ['Spec','Desired behavior, edge cases, and open questions.','specs/NNN-feature/spec.md'],
  ['Plan','Implementation choices and execution strategy.','specs/NNN-feature/plan.md'],
  ['Tasks','One verifiable outcome per task.','specs/NNN-feature/tasks.md'],
  ['Execute','Implement under TDD and recorded checkpoints.','/speckit.specflow.execute'],
  ['Review','Check the result against the spec and constitution.','specs/NNN-feature/review-findings.json']
];
const byId = id => document.getElementById(id);
const chapterButtons = slides.map((slide, index) => {
  const button = document.createElement('button');
  button.className = 'chapter';
  button.setAttribute('aria-label', `Slide ${index + 1}: ${slide.chapter}`);
  button.addEventListener('click', () => navigate(index));
  byId('chapters').append(button);
  return button;
});
const labels = artifacts.map((artifact, index) => {
  const button = document.createElement('button');
  button.className = 'artifact-label';
  button.textContent = artifact[0];
  button.addEventListener('click', () => {
    byId('artifact-title').textContent = artifact[0];
    byId('artifact-description').textContent = artifact[1];
    byId('artifact-path').textContent = artifact[2];
    byId('inspection').hidden = false;
  });
  byId('labels').append(button);
  button.style.left = `${12 + index * 15}%`;
  button.style.top = `${40 + (index % 2) * 20}%`;
  return button;
});
let index = 0;
let world;

function navigate(next) {
  const bounded = Math.max(0, Math.min(slides.length - 1, next));
  if (location.hash === `#/${slides[bounded].id}`) showSlide(bounded);
  else location.hash = `/${slides[bounded].id}`;
}

function showSlide(next) {
  index = next;
  const slide = slides[index];
  byId('chapter').textContent = `${String(index + 1).padStart(2,'0')} / ${slide.chapter}`;
  byId('title').innerHTML = slide.title;
  for (const key of ['description','detail']) byId(key).textContent = slide[key];
  byId('scene-caption').textContent = slide.caption;
  byId('counter').textContent = `${String(index + 1).padStart(2,'0')} / ${String(slides.length).padStart(2,'0')}`;
  byId('note-copy').textContent = slide.note;
  byId('source-link').href = slide.source;
  byId('gate-controls').hidden = slide.id !== 'gate';
  byId('action').hidden = slide.id !== 'adopt';
  byId('byline').hidden = index !== 0;
  byId('inspection').hidden = true;
  byId('analyzed').checked = false;
  byId('gate-result').textContent = 'Illustrative gate: the constitution is already present.';
  byId('previous').disabled = index === 0;
  byId('next').disabled = index === slides.length - 1;
  chapterButtons.forEach((button, current) => {
    if (current === index) button.setAttribute('aria-current','step');
    else button.removeAttribute('aria-current');
  });
  labels.forEach((label,current) => label.classList.toggle('selected', current === slide.focus));
  byId('risk-controls').hidden = slide.id !== 'risk';
  byId('review-controls').hidden = slide.id !== 'review';
  byId('proof').replaceChildren(...(slide.proof || []).map(([label, text]) => {
    const row = document.createElement('div');
    const heading = document.createElement('span');
    heading.textContent = label;
    const value = document.createElement('p');
    value.textContent = text;
    row.append(heading, value);
    return row;
  }));
  byId('proof').hidden = !slide.proof?.length;
  updateRisk();
  updateReview();
  world?.applyState(slide);
}

function readHash() {
  const found = slides.findIndex(slide => `#/${slide.id}` === location.hash);
  showSlide(found < 0 ? 0 : found);
}

function updateRisk() {
  const lines = Number(byId('risk-lines').value);
  const files = Number(byId('risk-files').value);
  const sensitive = byId('risk-sensitive').checked;
  const dependency = byId('risk-dependency').checked;
  const reasons = [];
  if (lines > 400) reasons.push('more than 400 changed lines');
  if (files > 15) reasons.push('more than 15 files');
  if (sensitive) reasons.push('a sensitive directory');
  if (dependency) reasons.push('a recognized dependency file');
  byId('risk-line-count').textContent = lines;
  byId('risk-file-count').textContent = files;
  byId('risk-result').textContent = reasons.length ? 'HIGH: ' + reasons.join('; ') : 'STANDARD: no trigger matches.';
}
function updateReview() {
  const severity = byId('finding-severity').value;
  const status = byId('finding-status').value;
  const blocked = severity !== 'Minor' && !['fixed','rebutted'].includes(status);
  byId('review-result').textContent = blocked ? 'MERGE BLOCKED: fix or rebut this finding.' : 'This finding does not block the merge gate.';
  byId('finding-json').textContent = JSON.stringify({id:'R-001',severity,status},null,2);
}
for (const id of ['risk-lines','risk-files','risk-sensitive','risk-dependency']) byId(id).addEventListener('input',updateRisk);
for (const id of ['finding-severity','finding-status']) byId(id).addEventListener('change',updateReview);

byId('previous').addEventListener('click', () => navigate(index - 1));
byId('next').addEventListener('click', () => navigate(index + 1));
byId('close-inspection').addEventListener('click', () => { byId('inspection').hidden = true; });
byId('notes-toggle').addEventListener('click', () => {
  byId('notes').hidden = !byId('notes').hidden;
  byId('notes-toggle').setAttribute('aria-expanded', String(!byId('notes').hidden));
});
byId('analyzed').addEventListener('change', () => {
  world?.applyState({...slides[index], gate:0});
  byId('gate-result').textContent = 'Evidence changed. Try execution to check it.';
});
byId('attempt').addEventListener('click', () => {
  const passed = byId('analyzed').checked;
  byId('gate-result').textContent = passed ? 'Analysis prerequisite satisfied. Continue to the remaining checks.' : 'ANALYZE_REQUIRED: run /speckit.analyze, then record its passing report.';
  world?.applyState({...slides[index], gate:passed ? 1 : 0});
});
window.addEventListener('hashchange', readHash);
window.addEventListener('keydown', event => {
  if (event.target.closest('button,input,a,textarea,select,[contenteditable]') || event.shiftKey || event.metaKey || event.ctrlKey || event.altKey) return;
  if (['ArrowRight','ArrowDown','PageDown',' '].includes(event.key)) { event.preventDefault(); navigate(index + 1); }
  if (['ArrowLeft','ArrowUp','PageUp'].includes(event.key)) { event.preventDefault(); navigate(index - 1); }
  if (event.key === 'Home') navigate(0);
  if (event.key === 'End') navigate(slides.length - 1);
  if (event.key === 'Escape') { byId('notes').hidden = true; byId('notes-toggle').setAttribute('aria-expanded','false'); byId('inspection').hidden = true; }
});
let touchOrigin;
byId('world').addEventListener('touchstart', event => {
  if (event.target.closest('button')) return;
  touchOrigin = event.touches[0].clientX;
}, {passive:true});
byId('world').addEventListener('touchend', event => {
  if (touchOrigin === undefined) return;
  const distance = event.changedTouches[0].clientX - touchOrigin;
  if (Math.abs(distance) > 60) navigate(index + (distance < 0 ? 1 : -1));
  touchOrigin = undefined;
}, {passive:true});
readHash();
try {
  const {createWorld} = await import('./scene.js');
  world = createWorld(byId('scene'), labels);
  world.applyState(slides[index]);
  window.addEventListener('pagehide', event => {
    if (!event.persisted) world.dispose();
  });
} catch (error) {
  // Navigation remains usable when CDN access or WebGL is unavailable.
  byId('fallback').hidden = false;
  byId('render-status').hidden = false;
  byId('render-status').textContent = `3D unavailable: ${error.message}. Check WebGL and CDN access, then reload. Text navigation remains available.`;
}
