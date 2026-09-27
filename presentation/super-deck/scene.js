import * as THREE from 'three';
import gsap from 'gsap';

const PAPER = 0x0c111a;
const ACCENT = 0x84b5ff;
const NEUTRAL = 0x52647d;
const STAGE_SPACING = 2.5;
const STAGE_COUNT = 6;
const STILL = window.matchMedia('(prefers-reduced-motion: reduce)');

/** Create one persistent scene, driven by complete slide states. */
export function createWorld(canvas, labels) {
  const renderer = new THREE.WebGLRenderer({canvas, antialias:true, alpha:false});
  renderer.setPixelRatio(Math.min(window.devicePixelRatio,2));
  renderer.setClearColor(PAPER);
  const scene = new THREE.Scene();
  const camera = new THREE.PerspectiveCamera(44,1,0.1,100);
  const cameraBase = new THREE.Vector3(10,11,16);
  const cameraTarget = new THREE.Vector3();
  const projected = new THREE.Vector3();
  scene.add(new THREE.HemisphereLight(0xffffff,0x29374f,2));
  const key = new THREE.DirectionalLight(0xffffff,3);
  key.position.set(-3,8,6);
  scene.add(key);
  const grid = new THREE.GridHelper(34,34,0x364357,0x202b3d);
  grid.position.y = -0.65;
  scene.add(grid);
  const plates = [];
  const plateGeometry = new THREE.BoxGeometry(1.85,0.22,2.4);
  const sheetGeometry = new THREE.BoxGeometry(1.4,0.04,1.8);
  const ruleGeometry = new THREE.BoxGeometry(0.85,0.015,0.045);
  const baseGeometry = new THREE.BoxGeometry(16,0.25,4.2);
  const base = new THREE.Mesh(baseGeometry,new THREE.MeshStandardMaterial({color:0x182333,roughness:.8}));
  base.position.y = -0.4;
  scene.add(base);
  for (let index = 0; index < STAGE_COUNT; index++) {
    const group = new THREE.Group();
    group.position.x = (index - 2.5) * STAGE_SPACING;
    const material = new THREE.MeshStandardMaterial({color:NEUTRAL,roughness:.65,metalness:.2});
    const plate = new THREE.Mesh(plateGeometry,material);
    group.add(plate);
    for (let layer = 0; layer < 3; layer++) {
      const sheet = new THREE.Mesh(sheetGeometry,new THREE.MeshStandardMaterial({color:0xb8c6da,roughness:.8}));
      sheet.position.set(0,0.2 + layer * .12,0);
      group.add(sheet);
    }
    for (let line = 0; line < 5; line++) {
      const rule = new THREE.Mesh(ruleGeometry,new THREE.MeshBasicMaterial({color:0x44566e}));
      rule.position.set(-.1,.47,-.55 + line * .23);
      rule.scale.x = line === 4 ? .5 : 1;
      group.add(rule);
    }
    scene.add(group);
    plates.push({group,material});
    if (index < STAGE_COUNT - 1) {
      const arrow = new THREE.ArrowHelper(new THREE.Vector3(1,0,0),new THREE.Vector3(group.position.x+1,.15,0),.55,0x84b5ff,.18,.13);
      scene.add(arrow);
    }
  }
  const gate = new THREE.Group();
  const gateMaterial = new THREE.MeshStandardMaterial({color:ACCENT,roughness:.5,metalness:.3});
  for (const side of [-1,1]) {
    const post = new THREE.Mesh(new THREE.BoxGeometry(.12,2.6,.12),gateMaterial);
    post.position.set(0,1.1,side*1.5);
    gate.add(post);
  }
  const beam = new THREE.Mesh(new THREE.BoxGeometry(.12,.12,3.12),gateMaterial);
  beam.position.y = 2.4;
  gate.add(beam);
  const barrier = new THREE.Mesh(new THREE.BoxGeometry(.08,1.7,2.8),new THREE.MeshBasicMaterial({color:ACCENT,transparent:true,opacity:.25,depthWrite:false}));
  barrier.position.y = 1.3;
  gate.add(barrier);
  gate.position.x = STAGE_SPACING;
  scene.add(gate);
  const evidence = new THREE.Mesh(new THREE.OctahedronGeometry(.28),new THREE.MeshStandardMaterial({color:ACCENT,roughness:.2,metalness:.3}));
  evidence.position.set(-STAGE_SPACING,1.2,0);
  scene.add(evidence);
  const live = {gate:0};
  let currentState;
  let timeline;
  let width = 1;
  let height = 1;
  let isDisposed = false;

  function render() {
    if (isDisposed || document.hidden) return;
    camera.position.copy(cameraBase);
    camera.lookAt(cameraTarget);
    camera.updateMatrixWorld();
    barrier.scale.y = Math.max(.01,1-live.gate);
    barrier.position.y = 2.15 - .85 * (1-live.gate);
    evidence.position.x = STAGE_SPACING - .8 + live.gate * 1.8;
    renderer.render(scene,camera);
    plates.forEach(({group}, index) => {
      projected.set(group.position.x,group.position.y+.55,1.65).project(camera);
      const label = labels[index];
      label.style.left = `${(projected.x*.5+.5)*width}px`;
      label.style.top = `${(-projected.y*.5+.5)*height}px`;
      label.hidden = width >= 500 && (Math.abs(projected.x) > 1 || Math.abs(projected.y) > .92 || projected.z > 1);
    });
  }

  function resize() {
    width = canvas.clientWidth;
    height = canvas.clientHeight;
    renderer.setSize(width,height,false);
    camera.aspect = width/height;
    camera.fov = width < 500 ? 58 : 44;
    camera.updateProjectionMatrix();
    render();
  }

  function applyState(state) {
    currentState = state;
    timeline?.kill();
    const duration = STILL.matches ? 0 : .65;
    timeline = gsap.timeline({onUpdate:render,onComplete:render});
    timeline.to(cameraBase,{x:state.camera[0],y:state.camera[1],z:state.camera[2],duration,ease:'power2.inOut'},0);
    timeline.to(cameraTarget,{x:state.target[0],y:state.target[1],z:state.target[2],duration,ease:'power2.inOut'},0);
    timeline.to(live,{gate:state.gate,duration},0);
    plates.forEach(({group,material}, index) => {
      const active = index === state.focus;
      material.color.set(active ? ACCENT : NEUTRAL);
      timeline.to(group.position,{y:active ? .6 : 0,duration},0);
    });
    if (document.hidden) timeline.pause();
    render();
  }

  function onVisibility() {
    if (document.hidden) timeline?.pause();
    else { timeline?.resume(); render(); }
  }
  function onMotionChange() { if (currentState) applyState(currentState); }
  const observer = new ResizeObserver(resize);
  observer.observe(canvas);
  document.addEventListener('visibilitychange',onVisibility);
  STILL.addEventListener('change',onMotionChange);
  resize();
  return {
    applyState,
    dispose() {
      isDisposed = true;
      timeline?.kill();
      observer.disconnect();
      document.removeEventListener('visibilitychange',onVisibility);
      STILL.removeEventListener('change',onMotionChange);
      const geometries = new Set();
      const materials = new Set();
      scene.traverse(object => {
        if (object.geometry) geometries.add(object.geometry);
        if (object.material) materials.add(object.material);
      });
      geometries.forEach(geometry => geometry.dispose());
      materials.forEach(material => material.dispose());
      renderer.dispose();
    }
  };
}
