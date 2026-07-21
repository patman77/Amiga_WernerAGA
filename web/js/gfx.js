// Drawing layer. Everything here mirrors what Werner.asm blits onto the
// 680x512 AGA screen (SA_Width 640+maxScrollSpeed+maxWidth, SA_Height 512).

import { FONT32, FONT38 } from './fontdata.js';
import { XSIZE, YSIZE } from './game.js';

export const SCREEN_W = 680;
export const SCREEN_H = 512;
export const TILE = 32;
export const FIELD_W = XSIZE * TILE; // 640
export const FIELD_H = YSIZE * TILE; // 448

// Source coordinates inside assets/sprites.png. This is Bitmap2, the 320x64
// off-screen bitmap the game blits its 32x32 tiles out of; the numbers are the
// SrcX/SrcY pairs used by `Darstellen` and the movement routines.
const SPRITE = {
  m: [0, 0],       // Mauer
  s: [32, 0],      // Stein
  x: [32, 0],      // falling Stein
  y: [32, 0],
  d: [64, 0],      // Dreck
  f: [96, 0],      // Flasche
  b: [256, 0],     // Bulle hoch
  r: [288, 0],     // Bulle rechts
  u: [0, 32],      // Bulle runter
  n: [0, 32],
  l: [32, 32],     // Bulle links
};
const WERNER = { up: [128, 0], right: [160, 0], down: [192, 0], left: [224, 0] };
const KREUZ = [96, 32];

const IMAGES = {
  sprites: 'assets/sprites.png',
  font32: 'assets/font32.png',
  font38: 'assets/font38.png',
  title1: 'assets/title1.png',
  title2: 'assets/title2.png',
  title3: 'assets/title3.png',
  title4: 'assets/title4.png',
};

// TitleImage1..4: x-pos, y-pos taken from the Image structures in Werner.asm.
export const TITLE_POS = {
  title1: [38, 0], title2: [129, 169], title3: [72, 250], title4: [304, 341],
};

export function loadAssets() {
  const out = {};
  return Promise.all(Object.entries(IMAGES).map(([key, src]) => new Promise((res, rej) => {
    const img = new Image();
    img.onload = () => { out[key] = img; res(); };
    img.onerror = () => rej(new Error(`cannot load ${src}`));
    img.src = src;
  }))).then(() => out);
}

export class Screen {
  constructor(canvas, assets) {
    this.ctx = canvas.getContext('2d');
    this.ctx.imageSmoothingEnabled = false;
    this.a = assets;
  }

  // Clear_Screens
  clear() {
    this.ctx.fillStyle = '#000';
    this.ctx.fillRect(0, 0, SCREEN_W, SCREEN_H);
  }

  tile(sx, sy, col, row) {
    this.ctx.drawImage(this.a.sprites, sx, sy, TILE, TILE, col * TILE, row * TILE, TILE, TILE);
  }

  // Darstellen: draw the whole 20x14 buffer.
  drawLevel(game, deadAt = -1) {
    const ctx = this.ctx;
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, SCREEN_W, FIELD_H);
    for (let i = 0; i < game.buf.length; i++) {
      const col = i % XSIZE, row = (i / XSIZE) | 0;
      if (i === deadAt) { this.tile(KREUZ[0], KREUZ[1], col, row); continue; }
      const c = game.buf[i];
      const s = c === 'w' ? WERNER[game.wernerDir] : SPRITE[c];
      if (s) this.tile(s[0], s[1], col, row);
    }
  }

  // Werner.font: 32x32 monospaced colour font, ASCII 32..95, baseline 31.
  text32(str, x, baseline) {
    const y = baseline - FONT32.baseline;
    for (let i = 0; i < str.length; i++) {
      let code = str.charCodeAt(i);
      if (code >= 97 && code <= 122) code -= 32; // no lower case in this font
      if (code < FONT32.lo || code > FONT32.hi) code = 32;
      this.ctx.drawImage(this.a.font32, (code - FONT32.lo) * 32, 0, 32, 32,
        x + i * 32, y, 32, 32);
    }
  }

  // Werner2.font: proportional colour font, ASCII 32..127, baseline 37.
  text38(str, x, baseline) {
    const y = baseline - FONT38.baseline;
    let cx = x;
    for (const ch of str) {
      let code = ch.charCodeAt(0);
      if (code < FONT38.lo || code > FONT38.hi) code = 32;
      const [sx, w] = FONT38.loc[code - FONT38.lo];
      this.ctx.drawImage(this.a.font38, sx, 0, w, FONT38.height, cx, y, w, FONT38.height);
      cx += FONT38.space[code - FONT38.lo];
    }
    return cx - x;
  }

  text38Width(str) {
    let w = 0;
    for (const ch of str) {
      let code = ch.charCodeAt(0);
      if (code < FONT38.lo || code > FONT38.hi) code = 32;
      w += FONT38.space[code - FONT38.lo];
    }
    return w;
  }

  // decl: turn a number into a five character, right aligned, space padded
  // string; the print routines then show a sub-range of it.
  static decl(n) { return String(n).padStart(5, ' ').slice(-5); }

  // PrintTexts, with the exact Move() coordinates from Werner.asm.
  drawHud(game) {
    this.ctx.fillStyle = '#000';
    this.ctx.fillRect(0, FIELD_H, SCREEN_W, SCREEN_H - FIELD_H);
    const d = Screen.decl;
    this.text32('SCORE:', 0, 479);
    this.text32(d(game.score), 192, 479);           // String
    this.text32(' TIME:', 352, 479);
    this.text32(d(game.time).slice(2), 544, 479);   // String+2, 3 chars
    this.text32('LIVES:', 0, 511);
    this.text32(d(game.lives).slice(1), 192, 511);  // String+1, 4 chars
    this.text32(' LEVEL:', 320, 511);
    this.text32(d(game.levelnumber + 1).slice(2), 544, 511);
  }

  // Title: the four title images blitted at their Image-structure positions.
  drawTitleImages() {
    this.clear();
    for (const [key, [x, y]] of Object.entries(TITLE_POS)) {
      this.ctx.drawImage(this.a[key], x, y);
    }
  }

  // Fadein/Fadeout are palette ramps on the Amiga; here a black veil over the
  // finished frame gets the same result.
  veil(alpha) {
    if (alpha <= 0) return;
    this.ctx.fillStyle = `rgba(0,0,0,${Math.min(1, alpha)})`;
    this.ctx.fillRect(0, 0, SCREEN_W, SCREEN_H);
  }

  centeredPrompt(str, baseline) {
    const w = str.length * 32;
    this.text32(str, Math.round((SCREEN_W - w) / 2), baseline);
  }
}
