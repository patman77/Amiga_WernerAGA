# WernerAGA — browser port

A browser port of **WernerAGA 1.0** (Patrick Klie, 21.5.1995), the 68k assembler
game in `../src`. The goal was to stay as close to the original as the web
allows: the rules are a line-by-line port of `Werner.asm`, and the graphics,
palette, fonts, title screen and levels are extracted from the original Amiga
data files rather than redrawn.

## Running it

Any static web server will do — ES modules and `<img>` loading do not work from
`file://`:

```sh
cd web
python3 -m http.server 8000
# then open http://localhost:8000/
```

## Controls

| | |
|---|---|
| Arrow keys / WASD | move Werner (the joystick port) |
| Click the canvas, or `F` | fire button (starts the title screen / a level) |
| `Space` | give up the current life (`Tot`) |
| `Esc` | end the game (`Game_over2`) |
| `Return` | skip the level (`gepackt` — it is a cheat in the original too) |
| `P` | pause (added; there is no pause on the Amiga) |

## Rules

Werner has to reach the bottle (`f`, drawn as a white "F") before the clock runs
out. Dirt is eaten as he walks through it; walls and stones block him — he
cannot push them. Touching a cop, being hit by a falling stone or running out of
time costs a life; solving a level awards one and adds the remaining seconds to
the score.

Stones fall into empty space below them, and roll off sideways when they come to
rest on another stone (right first, then left). Cops walk with one hand on the
wall: they try straight ahead, then a clockwise turn, then counter-clockwise,
then back the way they came.

The world is a 20×14 grid of bytes, simulated 10 times a second (the original
runs one pass per 5th vertical blank on a 50 Hz PAL machine), and the clock
counts down once every 10 passes.

## Level sets

Like the original — which reads a `levelset` file named by a tool type on its
icon — the port takes a level set file whose size is a multiple of 280 bytes
(20 × 14). One level is 280 characters, row by row:

```
m Mauer (wall)      d Dreck (dirt)         w Werner (exactly one per level)
s Stein (stone)     f Flasche (goal)       ' ' empty
b / r / u / l  Bulle (cop) initially walking up / right / down / left
```

Use the file picker below the canvas; "use built-in levels" restores the nine
levels compiled into `Werner.asm`.

## Layout

```
index.html
css/style.css
js/game.js       the port of Spiel / WorkonStone / WorkonBull* / WorkonWerner
js/gfx.js        blitting, the two colour fonts, the HUD, fades
js/main.js       Title -> Main -> Tot / gepackt / fertig, input, level sets
js/levels.js     generated — the `levels:` block from Werner.asm
js/fontdata.js   generated — font metrics and the ColorSpec palettes
assets/          generated — sprites, title images, the two fonts as PNG
tools/extract_assets.py   regenerates everything above from ../src
```

`tools/extract_assets.py` needs Pillow and is run from the repository root:

```sh
python3 web/tools/extract_assets.py
```

It decodes the Amiga planar `.raw` files (5 bitplanes, plane after plane, rows
padded to 16 pixels) through the `ColorSpec1`/`ColorSpec3` palettes in
`Werner.asm`, and parses the level and font-metric tables out of the sources.

## Where it differs from the Amiga original

Deliberate, and as small as they could be kept:

* **Two missing assets had to be recreated.** `src` has no bottle tile, so it is
  drawn as the white "F" the repository README describes. And the N–Z glyphs of
  the 32px `Werner.font` are still blank placeholder blocks in
  `Zeichensatz1.raw` (`Font2.asm` points at a finished `Zeichensatz2.raw` that
  was never committed), so they are synthesised in the style of the drawn
  glyphs — otherwise the status line could not spell "SCORE".
* **Lives start at 10.** `Werner.asm` initialises `lives` to 1000, which looks
  like a debugging leftover; 10 is the value `Game_over` resets it to.
* **Fades are a black veil**, not a palette ramp — the browser has no copper.
* **"PRESS FIRE" prompt** while a level waits for the fire button, and a `P`
  pause key. The original just sits there.
* **Title screen**: the scroll text is rendered with the same proportional
  colour font and scrolls at the same 2 pixels per 50 Hz frame, but as a plain
  scroller rather than through the double-buffered `BltBitMap` machinery.
  The `Start`/`Exit` graphic is part of the original title picture; the original
  never implemented that menu either — any fire button starts the game.
* **No sound.** The original opens `medplayer.library` but never plays anything.
* The screen is 680 × 512 like the Amiga screen, so the playfield's 640 pixels
  leave the same black strip on the right that the original has.
