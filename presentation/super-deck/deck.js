const slides = [
  { id:'intent', chapter:'The whole workflow', title:'From intent<br>to evidence.', description:'A specification becomes code through explicit, reviewable steps.', detail:'Spec-kit governance. Optional superpowers skills. Specflow checks.', focus:-1, camera:[10,11,16], target:[0,0,0], gate:0, caption:'One feature. A visible chain of evidence.', note:'Specflow targets Claude Code and GitHub Copilot CLI. The scene is an explanatory model, not a live pipeline or a recorded run. Each solid plate represents an artifact or an execution boundary.', source:'../../specflow/extension.yml' },
  { id:'constitution', chapter:'Agree on the rules', title:'Rules before<br>the first task.', description:'Every Specflow command checks for a constitution.', detail:'A missing constitution stops the command with CONSTITUTION_REQUIRED.', focus:0, camera:[-7,7,12], target:[-5,0,0], gate:0, caption:'Constitution → constraints for every later decision.', note:'The required file is .specify/memory/constitution.md. The team approves its rules before starting a feature. Existence checks enforce a prerequisite; they do not prove the rules are suitable.', source:'../../specflow/commands/execute.md' },
  { id:'spec', chapter:'Make intent explicit', title:'Resolve the<br>unknowns.', description:'Brainstorm edge cases. Clarify what the feature must do.', detail:'The gate writes .clarified only when clarification markers are absent.', focus:1, camera:[-5,8,11], target:[-3,0,0], gate:0, caption:'The spec records behavior before implementation.', note:'Brainstorm uses the optional skill or built-in protocol. Tasks also checks the Open Questions table for unresolved rows. Clearing text markers alone is not evidence that every product ambiguity has been found.', source:'../../specflow/commands/brainstorm.md' },
  { id:'gate', chapter:'Try the boundary', title:'No analysis.<br>No execution.', description:'The execute command needs a recorded analysis pass.', detail:'Toggle the evidence, then try the same command.', focus:3, camera:[3,8,12], target:[1,0,0], gate:0, caption:'An explicit check decides whether work can proceed.', note:'This demonstration isolates ANALYZE_REQUIRED. Real execution also checks the constitution and other prerequisites. /speckit.specflow.gate analyzed writes .analyzed after checking the analysis report for CRITICAL rows. The control simulates evidence; it writes no project files.', source:'../../specflow/commands/gate.md' },
  { id:'tasks', chapter:'Decompose the plan', title:'One task.<br>One outcome.', description:'Each task names a result that someone can verify.', detail:'State real dependencies. Keep fixes, refactors, and tests distinct.', focus:3, camera:[1,10,10], target:[0,0,0], gate:1, caption:'A plan becomes singular, checkable units of work.', note:'The task contract requires crisp outcomes and Verify rows. Optional writing-plans skills do not remove the fallback. Task markers identify parallel work, TDD, review, and subagent dispatch.', source:'../../specflow/templates/tasks-template.md' },
  { id:'execute', chapter:'Build against evidence', title:'Fail. Pass.<br>Refactor.', description:'A failing behavior check comes before implementation.', detail:'Optional superpowers skills follow the same governance constraints.', focus:4, camera:[7,7,11], target:[3,0,0], gate:1, caption:'RED → GREEN → REFACTOR', note:'Execution uses the selected strategy and checkpoints. Superpowers detection reads .agents/skills/ and ~/.agents/skills/. When skills are absent, the built-in workflow supplies the protocol.', source:'../../specflow/references/workflow-guide.md' },
  { id:'review', chapter:'Inspect the result', title:'Evidence earns<br>the approval.', description:'Findings name severity, location, evidence, and a fix.', detail:'Critical and Important findings block until fixed or rebutted.', focus:5, camera:[10,7,11], target:[5,0,0], gate:1, caption:'A structured finding can be checked and challenged.', note:'The merge gate validates findings against the shipped schema. Minor findings do not block. Review supports human judgment; a CLEAN verdict does not prove product correctness or independent review. Native hooks and CI need configuration.', source:'../../specflow/gates/bash/merge-gate.sh' },
  { id:'resume', chapter:'Keep the evidence', title:'Resume from<br>saved state.', description:'The next session reads progress before continuing.', detail:'Feature progress and skill detection live in plain YAML.', focus:3, camera:[0,15,16], target:[0,0,0], gate:1, caption:'progress.yml + .specify/superpowers.yml', note:'Feature artifacts live under specs/NNN-*/ at the consuming project root. Status reports progress and gate markers. The command set is status, brainstorm, tasks, execute, review, and gate. Copilot exposes hyphenated skill names.', source:'../../specflow/commands/status.md' },
  { id:'adopt', chapter:'Start with a real feature', title:'Make one<br>change auditable.', description:'Install Specflow. Approve the constitution. Run one feature.', detail:'Exercise a blocked gate, a cleared check, and a resumed session.', focus:-1, camera:[10,11,16], target:[0,0,0], gate:1, caption:'Claude Code + GitHub Copilot CLI', note:'The manifest declares six commands, six workflow hooks, five templates, and nine scripts. Shared gates ship in the archive; native CLI settings remain separate. The default catalog does not list this fork. Use the checkout installation route in the README. G-26 automatic events registration remains open.', source:'../../specflow/README.md' }
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
  byId('counter').textContent = `${String(index + 1).padStart(2,'0')} / 09`;
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
  world?.applyState(slide);
}

function readHash() {
  const found = slides.findIndex(slide => `#/${slide.id}` === location.hash);
  showSlide(found < 0 ? 0 : found);
}

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
  window.addEventListener('pagehide', () => world.dispose(), {once:true});
} catch (error) {
  // Navigation remains usable when CDN access or WebGL is unavailable.
  byId('fallback').hidden = false;
  byId('render-status').hidden = false;
  byId('render-status').textContent = `3D unavailable: ${error.message}. Check WebGL and CDN access, then reload. Text navigation remains available.`;
}
