"""Outlines the Offlyne wordmark, lockup and endorsement as SVG paths,
mirroring SuiteWordmark/SuiteLockup/SuiteEndorsement spacing."""
import os
import sys

import uharfbuzz as hb
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

ROOT = sys.argv[1]
FONTS = os.path.join(ROOT, 'core_theme/fonts')


def shape(font_file, runs, size, x0=0.0, baseline=0.0):
    """runs: [(text, tracking_em, color)] -> (svg path elements, width)."""
    blob = hb.Blob.from_file_path(font_file)
    face = hb.Face(blob)
    font = hb.Font(face)
    tt = TTFont(font_file)
    gs = tt.getGlyphSet()
    upm = tt['head'].unitsPerEm
    k = size / upm
    order = tt.getGlyphOrder()
    x = x0
    out = []
    for text, tracking, color in runs:
        buf = hb.Buffer()
        buf.add_str(text)
        buf.guess_segment_properties()
        hb.shape(font, buf, {'liga': True, 'kern': True})
        d_parts = []
        for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
            name = order[info.codepoint]
            pen = SVGPathPen(gs, ntos=lambda v: ('%.2f' % v).rstrip('0').rstrip('.'))
            tp = TransformPen(pen, (k, 0, 0, -k, x + pos.x_offset * k, baseline - pos.y_offset * k))
            gs[name].draw(tp)
            d = pen.getCommands()
            if d:
                d_parts.append(d)
            x += pos.x_advance * k + tracking * size
        out.append(f'<path fill="{color}" d="{" ".join(d_parts)}"/>')
    return out, x - x0


def cap_metrics(font_file, size):
    tt = TTFont(font_file)
    upm = tt['head'].unitsPerEm
    os2 = tt['OS/2']
    return os2.sCapHeight * size / upm, os2.sTypoDescender * size / upm


def write(name, w, h, body):
    path = os.path.join(ROOT, 'brand/mark', name)
    with open(path, 'w') as fh:
        fh.write(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w:.2f} {h:.2f}" '
                 f'width="{w:.0f}" height="{h:.0f}">\n  ' + '\n  '.join(body) + '\n</svg>\n')


def mark_paths(color_ink, color_dot, x, y, size):
    import re
    src = open(os.path.join(ROOT, 'brand/mark/offlyne-mark-mono.svg')).read()
    paths = re.findall(r'<path d="([^"]+)" fill="[^"]+"/>', src)
    s = size / 24
    out = []
    for i, d in enumerate(paths):
        c = color_dot if i == len(paths) - 1 else color_ink
        out.append(f'<path transform="translate({x:.2f} {y:.2f}) scale({s:.4f})" fill="{c}" d="{d}"/>')
    return out


DISPLAY = os.path.join(FONTS, 'MonaSansDisplay-SemiBold.ttf')
SIZE = 100
TRACK, YROOM = -0.02, 0.025
cap, _ = cap_metrics(DISPLAY, SIZE)

for name, ink, ycol in (('offlyne-wordmark', '#0E1116', '#0E1116'),
                        ('offlyne-wordmark-white', '#FFFFFF', '#FFFFFF'),
                        ('offlyne-wordmark-accent', '#0E1116', '#0F62D6')):
    runs = [('Offl', TRACK + YROOM, ink), ('y', TRACK + YROOM, ycol), ('ne', TRACK, ink)]
    pad = 0.0
    paths, w = shape(DISPLAY, runs, SIZE, x0=pad, baseline=cap)
    h = cap + 0.22 * SIZE  # room for the y descender
    write(f'{name}.svg', w, h, paths)

    # Lockup: mark 1.1x font size, gap 0.4x, mark centred on cap height.
    m = SIZE * 1.1
    gap = SIZE * 0.4
    top = cap / 2 - m / 2
    mp = mark_paths(ink, ink if ycol == ink else ycol, 0, 0, m)
    wp, w2 = shape(DISPLAY, runs, SIZE, x0=m + gap, baseline=cap - top)
    write(name.replace('wordmark', 'lockup') + '.svg', m + gap + w2, max(m, cap - top + 0.22 * SIZE), mp + wp)

# Endorsement: mark at 1.15x text size, gap 0.4x mark, "by " regular + name semibold.
TEXT_R = os.path.join(FONTS, 'MonaSans-Regular.ttf')
TEXT_B = os.path.join(FONTS, 'MonaSans-SemiBold.ttf')
ES = 48
ecap, _ = cap_metrics(TEXT_R, ES)
for name, ink in (('offlyne-endorsement', '#5B6472'), ('offlyne-endorsement-white', '#FFFFFF')):
    m = ES * 1.15
    top = ecap / 2 - m / 2
    base = ecap - top
    mp = mark_paths(ink, ink, 0, 0, m)
    p1, w1 = shape(TEXT_R, [('by ', 0, ink)], ES, x0=m * 1.4, baseline=base)
    p2, w2 = shape(TEXT_B, [('Offlyne', 0, ink)], ES, x0=m * 1.4 + w1, baseline=base)
    write(f'{name}.svg', m * 1.4 + w1 + w2, max(m, base + 0.22 * ES), mp + p1 + p2)
print('ok')
