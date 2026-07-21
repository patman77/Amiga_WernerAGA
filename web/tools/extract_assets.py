#!/usr/bin/env python3
"""Rebuild web/assets and web/js/{levels,fontdata}.js from the Amiga sources.

Run from the repository root:

    python3 web/tools/extract_assets.py

Everything the web port draws comes out of ../src:

  * .raw files are Amiga planar bitmaps, plane after plane (the layout
    Intuition Image structures and colour fonts use), 5 bitplanes deep, with
    each row padded to a multiple of 16 pixels.
  * The palettes are the ColorSpec1 (in game) and ColorSpec3 (title screen)
    tables in Werner.asm; only the top byte of each 32 bit component is used.
  * The levels are the `levels:` block in Werner.asm.

One thing is missing from the repository: the "Flasche" (bottle) tile, and the
N..Z glyphs of the 32px Werner.font are still blank placeholder blocks in
Zeichensatz1.raw (Font2.asm points at a finished `Zeichensatz2.raw` that was
never committed).  Both are synthesised here in the style of the originals.
"""

import json
import os
import re
import sys

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, 'src')
WEB = os.path.join(ROOT, 'web')
OUT = os.path.join(WEB, 'assets')
ASM = open(os.path.join(SRC, 'Werner.asm'), 'rb').read().decode('latin-1')

BOLD = '/System/Library/Fonts/Supplemental/Arial Black.ttf'  # for the two stand-ins


def raw(name):
    return open(os.path.join(SRC, name), 'rb').read()


def colorspec(label):
    """Read one of the SA_Colors32 tables; 32 entries of three 32 bit components."""
    longs = []
    for line in ASM[ASM.index(label + ':'):].split('\n')[1:]:
        if len(longs) >= 96:
            break
        m = re.match(r'\s*dc\.l\s+(.*)', line.split(';')[0])
        if m:
            longs += [int(t.strip()[1:], 16) if t.strip().startswith('$') else int(t)
                      for t in m.group(1).split(',')]
    return [tuple((longs[i + c] >> 24) & 0xff for c in range(3)) for i in range(0, 96, 3)]


def planar(data, w, h, pal, depth=5, transparent0=False):
    """Planar (plane sequential) bitmap -> RGBA image."""
    bpr = ((w + 15) // 16) * 2
    plane = bpr * h
    img = Image.new('RGBA', (w, h))
    px = img.load()
    for y in range(h):
        for x in range(w):
            byte, bit = y * bpr + (x >> 3), 7 - (x & 7)
            idx = 0
            for p in range(depth):
                if data[p * plane + byte] >> bit & 1:
                    idx |= 1 << p
            px[x, y] = (*pal[idx], 0 if transparent0 and idx == 0 else 255)
    return img


# --------------------------------------------------------------------------
PAL_GAME = colorspec('ColorSpec1')
PAL_TITLE = colorspec('ColorSpec3')
os.makedirs(OUT, exist_ok=True)

# Bitmap2, the 320x64 tile sheet: SrcX/SrcY of every tile as used by Darstellen.
TILES = [
    ('Mauer.raw', 0, 0), ('Kugel.raw', 32, 0), ('Dreck.raw', 64, 0),
    ('Werner_hoch.raw', 128, 0), ('Werner_rechts.raw', 160, 0),
    ('Werner_runter.raw', 192, 0), ('Werner_links.raw', 224, 0),
    ('Bulle_hoch.raw', 256, 0), ('Bulle_rechts.raw', 288, 0),
    ('Bulle_runter.raw', 0, 32), ('Bulle_links.raw', 32, 32), ('Kreuz.raw', 96, 32),
]
sheet = Image.new('RGBA', (320, 64), (0, 0, 0, 0))
for name, x, y in TILES:
    sheet.paste(planar(raw(name), 32, 32, PAL_GAME), (x, y))

# Flasche (96,0): asset missing; the README describes it as a stylized
# pictogram showing a white "F" (German "Flasche").
bottle = Image.new('RGBA', (32, 32), (*PAL_GAME[0], 255))
ImageDraw.Draw(bottle).text((16, 16), 'F', font=ImageFont.truetype(BOLD, 30),
                            fill=(*PAL_GAME[31], 255), anchor='mm')
sheet.paste(bottle, (96, 0))
sheet.save(os.path.join(OUT, 'sprites.png'))

for i, (w, h) in enumerate([(565, 121), (383, 36), (496, 48), (54, 49)], 1):
    planar(raw('TitlePic%d.raw' % i), w, h, PAL_TITLE, transparent0=True) \
        .save(os.path.join(OUT, 'title%d.png' % i))

font32 = planar(raw('Zeichensatz1.raw'), 2048, 32, PAL_GAME, transparent0=True)
planar(raw('Zeichensatz2(prop).raw'), 1984, 38, PAL_TITLE, transparent0=True) \
    .save(os.path.join(OUT, 'font38.png'))


# --- the unfinished half of Werner.font ------------------------------------
RAMP = [31, 29, 26, 21, 20, 9, 8, 7]  # white -> blue, as in the drawn glyphs
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def synth_glyph(ch):
    big = Image.new('L', (128, 128), 0)
    ImageDraw.Draw(big).text((64, 64), ch, font=ImageFont.truetype(BOLD, 112),
                             fill=255, anchor='mm')
    m = Image.new('L', (32, 32), 0)
    m.paste(big.crop(big.getbbox()).resize((26, 29), Image.LANCZOS), (3, 1))
    m = m.point(lambda v: 255 if v > 110 else 0)
    mp = m.load()
    out = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    op = out.load()

    def on(x, y):
        return 0 <= x < 32 and 0 <= y < 32 and mp[x, y]

    for y in range(32):
        for x in range(32):
            if not on(x, y):
                if on(x - 1, y) or on(x, y - 1) or on(x - 1, y - 1):
                    op[x, y] = (*PAL_GAME[7], 255)      # dark blue rim
                continue
            if not on(x - 1, y) or not on(x, y - 1):
                op[x, y] = (*PAL_GAME[31], 255)         # top/left highlight
                continue
            f = ((x / 31.0) * 0.45 + (y / 31.0) * 0.55) * (len(RAMP) - 1)
            i = int(f)
            i = min(len(RAMP) - 1, i + ((f - i) * 16 > BAYER[y % 4][x % 4]))
            op[x, y] = (*PAL_GAME[RAMP[i]], 255)
    return out


for ch in 'NOPQRSTUVWXYZ':
    x = 32 * (ord(ch) - 32)
    font32.paste(Image.new('RGBA', (32, 32), (0, 0, 0, 0)), (x, 0))
    font32.paste(synth_glyph(ch), (x, 0))
font32.save(os.path.join(OUT, 'font32.png'))


# --- levels ----------------------------------------------------------------
body = ASM[ASM.index('levels:'):ASM.index('levels_end:')]
rows = re.findall(r'dc\.b\s+"(.{20})"', body)
assert rows and len(rows) % 14 == 0, 'unexpected level data'
levels = [''.join(rows[i:i + 14]) for i in range(0, len(rows), 14)]
for lv in levels:
    assert len(lv) == 280 and lv.count('w') == 1
with open(os.path.join(WEB, 'js', 'levels.js'), 'w') as fh:
    fh.write('// Levels extracted verbatim from src/Werner.asm (label `levels:`)\n'
             "// 20x14 chars: m=Mauer d=Dreck w=Werner b/r/u/l=Bulle s=Stein f=Flasche ' '=leer\n"
             'export const BUILTIN_LEVELS = ' + json.dumps(levels, indent=2) + ';\n')


# --- font metrics ----------------------------------------------------------
f3 = open(os.path.join(SRC, 'Font3(prop).asm'), 'rb').read().decode('latin-1')
loc = [[int(a), int(b)] for a, b in
       re.findall(r'dc\.w\s+(\d+),(\d+)', f3[f3.index('fontLoc:'):f3.index('fontSpace:')])]
space = [int(a) for a in
         re.findall(r'dc\.w\s+(\d+)', f3[f3.index('fontSpace:'):f3.index('fontKern:')])]
with open(os.path.join(WEB, 'js', 'fontdata.js'), 'w') as fh:
    fh.write(f'''// Generated from src/Font3(prop).asm (Werner2.font, proportional, 38px) and
// the ColorSpec tables in src/Werner.asm. Do not edit by hand.

// [x, width] of every glyph in assets/font38.png, for ASCII 32..127
export const FONT38 = {{
  lo: 32, hi: 127, height: 38, baseline: 37,
  loc: {json.dumps(loc)},
  space: {json.dumps(space)},
}};

// Werner.font (assets/font32.png) is a 32x32 monospaced colour font, ASCII 32..95.
export const FONT32 = {{ lo: 32, hi: 95, width: 32, height: 32, baseline: 31 }};

export const PALETTE_GAME  = {json.dumps([list(c) for c in PAL_GAME])};
export const PALETTE_TITLE = {json.dumps([list(c) for c in PAL_TITLE])};
''')

print(f'{len(levels)} levels, {len(TILES) + 1} tiles, fonts and title images written to web/',
      file=sys.stderr)
