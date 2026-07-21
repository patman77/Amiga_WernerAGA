// Faithful port of the game logic in src/Werner.asm.
//
// The original keeps the level in a 20x14 byte buffer (`Puffer`) and runs one
// simulation pass per signal from the vertical-blank interrupt server, which
// fires every 5th VBL -> 10 passes per second on a PAL machine. One pass is:
//
//   Spiel   -> read keyboard, wait for the VBL signal
//   Loop    -> walk the buffer from offset 0 upwards and move every stone/cop
//   Korrigieren -> "n" becomes "u", "y" becomes "x"
//   TestJoy -> sample the joystick
//   WorkonWerner -> move Werner
//   prüfzeit -> count the clock down (every 10th pass = once per second)
//
// Cell contents, straight from the comment above `levels:` in Werner.asm:
//   m Mauer (wall)   d Dreck (dirt)     w Werner        s Stein (resting stone)
//   f Flasche (goal) ' ' empty
//   b/r/u/l Bulle (cop) walking up/right/down/left
// plus two markers the pass uses internally so that a piece is not moved twice:
//   x stone that is currently falling, y stone that just fell this pass
//   n cop that just moved down this pass

export const XSIZE = 20;
export const YSIZE = 14;
export const BPL = XSIZE * YSIZE; // bytes per level
export const START_TIME = 120;
export const START_LIVES = 10; // Game_over: `move.w #10,(a0)`

const DEAD = -1; // internal marker: this pass ran into `Tot`

const DELTA = { up: -XSIZE, right: 1, down: XSIZE, left: -1 };

// Bulle_hoch/rechts/runter/links write these characters into the target cell.
// Note that `runter` writes "n", not "u", so the very same pass does not walk
// the cop down a second time; Korrigieren turns it into "u" afterwards.
const BULL_CHAR = { up: 'b', right: 'r', down: 'n', left: 'l' };

// The order in which a cop probes its surroundings: straight ahead, then a
// clockwise turn, then counter-clockwise, then back the way it came
// (WorkonBullup / -right / -down / -left).
const BULL_ORDER = {
  b: ['up', 'right', 'left', 'down'],
  r: ['right', 'down', 'up', 'left'],
  u: ['down', 'left', 'right', 'up'],
  l: ['left', 'up', 'down', 'right'],
};

export class Game {
  constructor(levels) {
    this.levels = levels;
    this.newGame();
  }

  newGame() {
    this.levelnumber = 0;
    this.lives = START_LIVES;
    this.score = 0;
    this.time = START_TIME;
    this.copyLevel();
  }

  // CopyLevel
  copyLevel() {
    this.buf = this.levels[this.levelnumber].split('');
    this.wernerDir = 'down'; // Darstellen draws Werner_runter
    this.zeitzaehler = 10; // AddIntServer1
  }

  get levelanzahl() {
    return this.levels.length;
  }

  // One pass of `Spiel`. `joy` mirrors the bits TestJoy returns.
  // Returns null, 'dead' (Tot) or 'won' (gepackt).
  step(joy) {
    const b = this.buf;

    for (let i = 0; i < BPL; i++) {
      let r;
      switch (b[i]) {
        case 's': r = this.workStone(i, false); break;
        case 'x': r = this.workStone(i, true); break;
        case 'b': case 'r': case 'u': case 'l': r = this.workBull(i); break;
        default: continue;
      }
      if (r === DEAD) return 'dead';
      i = r;
    }

    this.korrigieren();

    const r = this.workWerner(joy);
    if (r) return r;

    return this.pruefzeit();
  }

  // WorkonStone (falling === false) and WorkonfallingStone (falling === true).
  workStone(i, falling) {
    const b = this.buf;
    const below = i + XSIZE;

    if (falling && b[below] === 'w') return DEAD;

    if (b[below] === ' ') {
      b[i] = ' ';
      b[below] = 'y';
      return i;
    }

    // A stone resting on another stone rolls off to the side.
    if (b[below] === 's') {
      if (b[i + 1] === ' ' && b[below + 1] === ' ') {
        b[i] = ' ';
        b[below + 1] = 'y';
        return i;
      }
      if (b[i - 1] === ' ' && b[below - 1] === ' ') {
        b[i] = ' ';
        b[below - 1] = 'y';
        return i;
      }
    }

    if (falling) b[i] = 's'; // .wandeln - it comes to rest
    return i;
  }

  // WorkonBullup / -right / -down / -left.
  workBull(i) {
    const b = this.buf;
    for (const dir of BULL_ORDER[b[i]]) {
      const j = i + DELTA[dir];
      if (b[j] === 'w') return DEAD;
      if (b[j] === ' ') {
        b[i] = ' ';
        b[j] = BULL_CHAR[dir];
        // Bulle_rechts skips the cell it just moved into (`lea 1(a4),a4`).
        return dir === 'right' ? i + 1 : i;
      }
    }
    return i;
  }

  korrigieren() {
    const b = this.buf;
    for (let i = 0; i < BPL; i++) {
      if (b[i] === 'n') b[i] = 'u';
      else if (b[i] === 'y') b[i] = 'x';
    }
  }

  // WorkonWerner. Right beats left beats up beats down; if the horizontal move
  // is blocked, Werner_right/-left retry the vertical direction once.
  workWerner(joy) {
    const b = this.buf;
    const i = b.indexOf('w');
    if (i < 0) return null;

    const tryDir = (dir) => {
      const c = b[i + DELTA[dir]];
      if (c === 'f') return 'won';           // gepackt
      if (c === 'b' || c === 'r' || c === 'u' || c === 'l') return 'dead'; // Tot
      if (c === ' ' || c === 'd') {          // .bewege - dirt is eaten
        b[i] = ' ';
        b[i + DELTA[dir]] = 'w';
        this.wernerDir = dir;
        return 'moved';
      }
      return 'blocked';
    };

    const dirs = [];
    if (joy.right) dirs.push('right');
    else if (joy.left) dirs.push('left');

    if (dirs.length) {
      if (joy.up) dirs.push('up');
      else if (joy.down) dirs.push('down');
    } else if (joy.up) dirs.push('up');
    else if (joy.down) dirs.push('down');

    for (const dir of dirs) {
      const r = tryDir(dir);
      if (r === 'won' || r === 'dead') return r;
      if (r === 'moved') break;
    }
    return null;
  }

  // prüfzeit: the clock ticks down once every 10 passes, i.e. once per second.
  pruefzeit() {
    if (--this.zeitzaehler === 0) {
      this.zeitzaehler = 10;
      if (--this.time === 0) return 'dead';
    }
    return null;
  }

  // Tot: one life gone, the clock is reset and the level starts over.
  // Returns true when that was the last life (Game_over).
  loseLife() {
    this.lives--;
    this.time = START_TIME;
    return this.lives === 0;
  }

  // gepackt: the remaining seconds are added to the score one by one.
  // Returns true when the last level was solved (fertig).
  finishLevel() {
    this.time = START_TIME;
    this.lives++;
    this.levelnumber++;
    return this.levelnumber > this.levelanzahl - 1;
  }
}
