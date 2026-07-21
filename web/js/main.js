// Screen flow of Werner.asm: Title -> Main -> Spiel -> Tot / gepackt / fertig.

import { Game, BPL } from './game.js';
import { Screen, loadAssets, SCREEN_W, SCREEN_H, FIELD_H } from './gfx.js';
import { BUILTIN_LEVELS } from './levels.js';

// Scrolltext, verbatim from Werner.asm (trailing blanks included).
const SCROLLTEXT = 'Welcome to Werner Version 1.0 AGA      written by Patrick Klie for WTS                                                       ';

const TICK_MS = 100;      // one Spiel pass = every 5th VBL on a 50 Hz machine
const SCROLL_PX = 2;      // .ScrollSpeed, per 50 Hz frame
const FADE_MS = 700;
const DEAD_MS = 1000;     // Tot: Delay(50*1)

const canvas = document.getElementById('screen');
const loading = document.getElementById('loading');
const levelinfo = document.getElementById('levelinfo');

let scr, game;
let levels = BUILTIN_LEVELS;
let state, stateT = 0, paused = false;
let scrollX = 0, deadAt = -1, veil = 0;
let pending = null; // key event picked up by the next pass

// --- input ---------------------------------------------------------------
// TestJoy reads the port every pass, so movement is edge-independent: what
// counts is which direction is held when the pass runs.
const held = new Set();
const joy = () => ({
  up: held.has('ArrowUp') || held.has('KeyW'),
  right: held.has('ArrowRight') || held.has('KeyD'),
  down: held.has('ArrowDown') || held.has('KeyS'),
  left: held.has('ArrowLeft') || held.has('KeyA'),
});
let fire = false;
const takeFire = () => { const f = fire; fire = false; return f; };

addEventListener('keydown', (e) => {
  if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space'].includes(e.code)) e.preventDefault();
  if (e.repeat) return;
  held.add(e.code);
  switch (e.code) {
    case 'Space': pending = 'suicide'; break;   // Tot
    case 'Escape': pending = 'quit'; break;     // Game_over2
    case 'Enter': pending = 'skip'; fire = true; break; // gepackt
    case 'KeyF': fire = true; break;
    case 'KeyP': paused = !paused; break;
  }
});
addEventListener('keyup', (e) => held.delete(e.code));
addEventListener('blur', () => held.clear());
canvas.addEventListener('mousedown', (e) => { e.preventDefault(); fire = true; });
canvas.addEventListener('touchstart', (e) => { e.preventDefault(); fire = true; }, { passive: false });

// --- level sets ----------------------------------------------------------
// The original picks its levels up from a `levelset` file whose size is a
// multiple of 280 bytes (xsize*ysize); anything else falls back to the levels
// built into the executable.
function parseLevelset(bytes) {
  if (bytes.length < BPL || bytes.length % BPL !== 0) {
    throw new Error(`size ${bytes.length} is not a multiple of ${BPL}`);
  }
  const out = [];
  for (let i = 0; i < bytes.length; i += BPL) {
    out.push(String.fromCharCode(...bytes.subarray(i, i + BPL)));
  }
  return out;
}

function useLevels(next, label) {
  levels = next;
  levelinfo.textContent = `${label}: ${levels.length} level${levels.length === 1 ? '' : 's'}`;
  game = new Game(levels);
  enter('title');
}

document.getElementById('levelset').addEventListener('change', async (e) => {
  const file = e.target.files[0];
  if (!file) return;
  try {
    useLevels(parseLevelset(new Uint8Array(await file.arrayBuffer())), file.name);
  } catch (err) {
    levelinfo.textContent = `not a levelset (${err.message})`;
  }
});
document.getElementById('builtin').addEventListener('click', () => {
  document.getElementById('levelset').value = '';
  useLevels(BUILTIN_LEVELS, 'built-in levels');
});

// --- state machine -------------------------------------------------------
function enter(next) {
  state = next;
  stateT = 0;
  switch (next) {
    case 'title':
      scrollX = SCREEN_W;
      veil = 1;
      break;
    case 'levelstart':
      game.copyLevel();
      deadAt = -1;
      veil = 1;
      break;
    case 'dead':
      deadAt = game.buf.indexOf('w');
      break;
    case 'running':
      update.acc = 0;
      break;
    case 'gameover':
    case 'finished':
      veil = 1;
      break;
  }
}

function update(dt) {
  stateT += dt;
  switch (state) {
    case 'title': {
      veil = Math.max(0, 1 - stateT / FADE_MS);
      scrollX -= SCROLL_PX * (dt / 20); // 2 px per 50 Hz frame
      const w = scr.text38Width(SCROLLTEXT);
      if (scrollX < -w) scrollX = SCREEN_W;
      if (takeFire() && stateT > FADE_MS) enter('titlefade');
      break;
    }
    case 'titlefade':
      veil = stateT / FADE_MS;
      if (stateT >= FADE_MS) { game.score = 0; enter('levelstart'); }
      break;

    case 'levelstart':
      veil = Math.max(0, 1 - stateT / FADE_MS);
      if (stateT >= FADE_MS) enter('waitfire');
      break;

    case 'waitfire':
      if (takeFire()) { pending = null; enter('running'); }
      break;

    case 'running': {
      if (paused) break;
      let acc = (update.acc || 0) + dt;
      while (acc >= TICK_MS) {
        acc -= TICK_MS;
        const r = pass();
        if (r) { acc = 0; break; }
      }
      update.acc = acc;
      break;
    }

    case 'dead':
      if (stateT >= DEAD_MS) enter('deadfade');
      break;
    case 'deadfade':
      veil = stateT / FADE_MS;
      if (stateT >= FADE_MS) enter(game.lives === 0 ? 'gameover' : 'levelstart');
      break;

    case 'won': { // gepackt: .ringring counts the remaining seconds into the score
      for (let n = 0; n < 3 && game.time >= 0; n++) {
        game.time--;
        if (game.time >= 0) game.score++;
      }
      if (game.time < 0) enter('wonfade');
      break;
    }
    case 'wonfade':
      veil = stateT / FADE_MS;
      if (stateT >= FADE_MS) enter(game.finishLevel() ? 'finished' : 'levelstart');
      break;

    case 'gameover':
    case 'finished':
      veil = Math.max(0, 1 - stateT / FADE_MS);
      if (takeFire() && stateT > FADE_MS) { game.newGame(); enter('title'); }
      break;
  }
}

// One `Spiel` pass, including the keyboard checks it does up front.
function pass() {
  if (pending === 'quit') { pending = null; game.lives = 0; enter('deadfade'); return 'quit'; }
  if (pending === 'suicide') { pending = null; onDead(); return 'dead'; }
  if (pending === 'skip') { pending = null; enter('won'); return 'won'; }

  const r = game.step(joy());
  if (r === 'dead') { onDead(); return r; }
  if (r === 'won') { enter('won'); return r; }
  return null;
}

function onDead() {
  game.loseLife();
  enter('dead');
}

// --- rendering -----------------------------------------------------------
function render() {
  switch (state) {
    case 'title':
    case 'titlefade':
      scr.drawTitleImages();
      scr.ctx.fillStyle = '#000';
      scr.ctx.fillRect(0, 473, SCREEN_W, SCREEN_H - 473);
      scr.text38(SCROLLTEXT, Math.round(scrollX), 510);
      break;

    case 'gameover':
      scr.clear();
      scr.centeredPrompt('GAME OVER', 280);
      break;

    case 'finished':
      scr.clear();
      scr.centeredPrompt('WELL DONE', 240);
      scr.centeredPrompt(`SCORE ${game.score}`, 320);
      break;

    default:
      scr.drawLevel(game, deadAt);
      scr.drawHud(game);
      if (state === 'waitfire' && Math.floor(stateT / 400) % 2 === 0) {
        scr.centeredPrompt('PRESS FIRE', FIELD_H / 2 + 16);
      }
      if (paused && state === 'running') scr.centeredPrompt('PAUSE', FIELD_H / 2 + 16);
      break;
  }
  scr.veil(veil);
}

// --- main loop -----------------------------------------------------------
let last = 0;
function frame(now) {
  const dt = Math.min(100, now - last || 0);
  last = now;
  update(dt);
  render();
  requestAnimationFrame(frame);
}

loadAssets().then((assets) => {
  scr = new Screen(canvas, assets);
  loading.remove();
  useLevels(BUILTIN_LEVELS, 'built-in levels');
  requestAnimationFrame(frame);
}).catch((err) => {
  loading.textContent = `${err.message} - serve this folder over http:// (e.g. python3 -m http.server)`;
});
