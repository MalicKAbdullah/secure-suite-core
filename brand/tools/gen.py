"""Single source of truth for the Secure Suite mark + app glyph geometry.

Emits: Dart geometry (core_ui/lib/src/brand/brand_geometry.dart), SVG masters,
Android vector drawables + adaptive icon XML for every app.
All glyph coordinates live on a 24-unit grid.
"""
import math
import os
import sys

ROOT = sys.argv[1]  # packages-design

STROKE = 2.0  # glyph stroke, grid units
GLYPH = 44    # glyph grid extent on the 108-unit adaptive canvas
OFF = (108 - GLYPH) / 2
SCALE = GLYPH / 24
DOT = 2.0     # the family dot radius, grid units

ACCENTS = {
    'budgetly': ('Budgetly', '0F62D6', '6AA6FF'),
    'vaultly': ('Vaultly', '7341E6', 'B197FF'),
    'openlock': ('OpenLock', '007E9C', '3FD0EE'),
    'reflect': ('Reflect', 'C81E5B', 'FF6B9A'),
    'ledgerly': ('Ledgerly', '4A4FE0', '9298FF'),
    'dosewise': ('DoseWise', '08805F', '3EDDA6'),
    'warden': ('Warden', '457A0C', 'A6E33C'),
}


def f(v):
    s = ('%.3f' % v).rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def circle(cx, cy, r, ccw=False):
    s = 0 if ccw else 1
    return (f'M{f(cx - r)} {f(cy)} A{f(r)} {f(r)} 0 1 {s} {f(cx + r)} {f(cy)} '
            f'A{f(r)} {f(r)} 0 1 {s} {f(cx - r)} {f(cy)} Z')


def rrect(x, y, w, h, r):
    return (f'M{f(x + r)} {f(y)} L{f(x + w - r)} {f(y)} '
            f'A{f(r)} {f(r)} 0 0 1 {f(x + w)} {f(y + r)} '
            f'L{f(x + w)} {f(y + h - r)} '
            f'A{f(r)} {f(r)} 0 0 1 {f(x + w - r)} {f(y + h)} '
            f'L{f(x + r)} {f(y + h)} '
            f'A{f(r)} {f(r)} 0 0 1 {f(x)} {f(y + h - r)} '
            f'L{f(x)} {f(y + r)} '
            f'A{f(r)} {f(r)} 0 0 1 {f(x + r)} {f(y)} Z')


def line(x1, y1, x2, y2):
    return f'M{f(x1)} {f(y1)} L{f(x2)} {f(y2)}'


def capsule(ax, ay, bx, by, r):
    dx, dy = bx - ax, by - ay
    ln = math.hypot(dx, dy)
    nx, ny = -dy / ln * r, dx / ln * r
    return (f'M{f(ax + nx)} {f(ay + ny)} L{f(bx + nx)} {f(by + ny)} '
            f'A{f(r)} {f(r)} 0 0 0 {f(bx - nx)} {f(by - ny)} '
            f'L{f(ax - nx)} {f(ay - ny)} '
            f'A{f(r)} {f(r)} 0 0 0 {f(ax + nx)} {f(ay + ny)} Z')


def polar(cx, cy, r, deg):
    a = math.radians(deg)
    return cx + r * math.cos(a), cy + r * math.sin(a)


# --- The parent mark: the Offlyne O ----------------------------------------
def annulus_sector(cx, cy, r_out, r_in, start, end):
    """Filled ring segment from start to end degrees, clockwise (y-down)."""
    sweep = (end - start) % 360
    large = 1 if sweep > 180 else 0
    o1, o2 = polar(cx, cy, r_out, start), polar(cx, cy, r_out, end)
    i1, i2 = polar(cx, cy, r_in, start), polar(cx, cy, r_in, end)
    return (f'M{f(o1[0])} {f(o1[1])} '
            f'A{f(r_out)} {f(r_out)} 0 {large} 1 {f(o2[0])} {f(o2[1])} '
            f'L{f(i2[0])} {f(i2[1])} '
            f'A{f(r_in)} {f(r_in)} 0 {large} 0 {f(i1[0])} {f(i1[1])} Z')


def annulus(cx, cy, r_out, r_in):
    return circle(cx, cy, r_out) + ' ' + circle(cx, cy, r_in, ccw=True)


GAP_AT = -45     # where the signal would leave: up and to the right
GAP_HALF = 31    # half the break, degrees
MARK_A = [
    ('fill', annulus_sector(12, 12, 10.5, 6, GAP_AT + GAP_HALF, GAP_AT - GAP_HALF), 'ink'),
    ('fill', circle(*polar(12, 12, 8.25, GAP_AT), 2.25), 'dot'),
]
MARK = MARK_A

def glyphs():
    g = {}
    # Budgetly: three budget bars; the family dot marks the headroom left
    # above the shortest.
    g['budgetly'] = [
        ('stroke', line(6, 19.5, 6, 11.5), 'ink'),
        ('stroke', line(12, 19.5, 12, 4.5), 'ink'),
        ('stroke', line(18, 19.5, 18, 15), 'ink'),
        ('fill', circle(18, 8.5, DOT), 'dot'),
    ]
    # Vaultly: a key, turned on the diagonal; the family dot sits in its bow.
    def rot(x, y, deg=-45, cx=12, cy=12):
        r = math.radians(deg)
        dx, dy = x - cx, y - cy
        return (cx + dx * math.cos(r) - dy * math.sin(r),
                cy + dx * math.sin(r) + dy * math.cos(r))

    def pts(*ps):
        return ' '.join(('M' if i == 0 else 'L') + f'{f(rot(*p)[0])} {f(rot(*p)[1])}'
                        for i, p in enumerate(ps))
    bow = rot(6.25, 12)
    g['vaultly'] = [
        ('stroke', circle(bow[0], bow[1], 4.75), 'ink'),
        ('stroke', pts((11, 12), (21.5, 12), (21.5, 15.25)), 'ink'),
        ('stroke', pts((17.75, 12), (17.75, 14.75)), 'ink'),
        ('fill', circle(bow[0], bow[1], 1.5), 'dot'),
    ]
    # OpenLock: shackle and body; the keyhole is the family dot.
    g['openlock'] = [
        ('stroke', 'M8 11 L8 8 A4 4 0 0 1 16 8 L16 11', 'ink'),
        ('stroke', rrect(4.5, 11, 15, 10.5, 3), 'ink'),
        ('fill', circle(12, 16.25, DOT), 'dot'),
    ]
    # Reflect: a crescent, with the family dot rising in its bite.
    c1, r1 = (11, 13), 8.5
    c2, r2 = (16, 8), 6.5
    d = math.hypot(c2[0] - c1[0], c2[1] - c1[1])
    a = (r1 * r1 - r2 * r2 + d * d) / (2 * d)
    h = math.sqrt(r1 * r1 - a * a)
    mx = c1[0] + a * (c2[0] - c1[0]) / d
    my = c1[1] + a * (c2[1] - c1[1]) / d
    p1 = (mx + h * (c2[1] - c1[1]) / d, my - h * (c2[0] - c1[0]) / d)
    p2 = (mx - h * (c2[1] - c1[1]) / d, my + h * (c2[0] - c1[0]) / d)
    g['reflect'] = [
        ('stroke',
         f'M{f(p1[0])} {f(p1[1])} A{f(r1)} {f(r1)} 0 1 0 {f(p2[0])} {f(p2[1])} '
         f'A{f(r2)} {f(r2)} 0 0 1 {f(p1[0])} {f(p1[1])} Z', 'ink'),
        ('fill', circle(17.25, 6.75, DOT), 'dot'),
    ]
    # Ledgerly: an invoice — page, line items, the total as the family dot.
    g['ledgerly'] = [
        ('stroke', rrect(4.5, 2.5, 15, 19, 3), 'ink'),
        ('stroke', line(8.5, 8, 15.5, 8), 'ink'),
        ('stroke', line(8.5, 12, 15.5, 12), 'ink'),
        ('stroke', line(8.5, 16.5, 11.5, 16.5), 'ink'),
        ('fill', circle(15.5, 16.5, DOT), 'dot'),
    ]
    # DoseWise: a capsule split at its waist; the tablet is the family dot.
    ax, ay = 6.5, 15
    bx, by = 15, 6.5
    r = 4
    mx, my = (ax + bx) / 2, (ay + by) / 2
    k = r / math.sqrt(2)
    g['dosewise'] = [
        ('stroke', capsule(ax, ay, bx, by, r), 'ink'),
        ('stroke', line(mx - k, my - k, mx + k, my + k), 'ink'),
        ('fill', circle(18.5, 18.5, DOT), 'dot'),
    ]
    # Warden: a shield that sieves — two filter bars narrowing to the dot.
    g['warden'] = [
        ('stroke',
         'M12 2.75 L19.25 5.5 L19.25 11.25 C19.25 15.9 16.2 19.55 12 21.25 '
         'C7.8 19.55 4.75 15.9 4.75 11.25 L4.75 5.5 Z', 'ink'),
        ('stroke', line(8.75, 9.5, 15.25, 9.5), 'ink'),
        ('stroke', line(10.25, 13, 13.75, 13), 'ink'),
        ('fill', circle(12, 16.75, 1.75), 'dot'),
    ]
    return g


GLYPHS = glyphs()


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as fh:
        fh.write(text)


# ---------------------------------------------------------------- Dart -----
def dart():
    out = ['// Brand geometry. The SVG masters and Android drawables under brand/',
           '// are exported from exactly these paths; change them together or the',
           '// painted icons and the launcher icons will disagree.',
           '',
           "import 'package:flutter/foundation.dart';",
           '',
           '/// One drawn element of a brand shape, in 24-unit grid space.',
           '@immutable',
           'final class BrandShape {',
           '  const BrandShape(this.path, {this.stroke = false, this.dot = false});',
           '',
           '  /// Absolute SVG path data using only M, L, C, A and Z.',
           '  final String path;',
           '',
           '  /// Stroked at [brandStroke] with round caps and joins; else filled.',
           '  final bool stroke;',
           '',
           '  /// The family dot: takes the dot color where a variant has one.',
           '  final bool dot;',
           '}',
           '',
           '/// Stroke weight shared by every app glyph, in grid units.',
           f'const double brandStroke = {f(STROKE)};',
           '',
           '/// Glyph grid extent on the 108-unit adaptive icon canvas.',
           f'const double brandGlyphExtent = {f(GLYPH)};',
           '']

    def shapes(name, items):
        out.append(f'const List<BrandShape> {name} = [')
        for kind, d, role in items:
            flags = []
            if kind == 'stroke':
                flags.append('stroke: true')
            if role == 'dot':
                flags.append('dot: true')
            fl = (', ' + ', '.join(flags)) if flags else ''
            out.append(f"  BrandShape('{d}'{fl}),")
        out.append('];')
        out.append('')

    shapes('suiteMarkShapes', MARK)
    for key, items in GLYPHS.items():
        shapes(f'{key}Glyph', items)
    write(os.path.join(ROOT, 'core_ui/lib/src/brand/brand_geometry.dart'),
          '\n'.join(out))


# ----------------------------------------------------------------- SVG -----
def svg_shapes(items, ink, dot, sw):
    parts = []
    for kind, d, role in items:
        c = dot if role == 'dot' else ink
        if kind == 'stroke':
            parts.append(f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{f(sw)}" '
                         f'stroke-linecap="round" stroke-linejoin="round"/>')
        else:
            parts.append(f'<path d="{d}" fill="{c}"/>')
    return parts


def svgs():
    for name, ink, dot in (('offlyne-mark-mono', '#0E1116', '#0E1116'),
                           ('offlyne-mark-mono-white', '#FFFFFF', '#FFFFFF'),
                           ('offlyne-mark-accent', '#0E1116', '#0F62D6'),
                           ('offlyne-mark-accent-dark', '#FFFFFF', '#6AA6FF')):
        body = '\n  '.join(svg_shapes(MARK, ink, dot, STROKE))
        write(os.path.join(ROOT, f'brand/mark/{name}.svg'),
              f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
              f'width="24" height="24">\n  {body}\n</svg>\n')
    for key, (title, light, _dark) in ACCENTS.items():
        # Master: full 108-unit adaptive canvas, glyph at 2x centred.
        body = '\n    '.join(svg_shapes(GLYPHS[key], '#FFFFFF', '#FFFFFF', STROKE))
        write(os.path.join(ROOT, f'brand/icons/{key}/{key}-icon.svg'),
              f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108" '
              f'width="1080" height="1080">\n'
              f'  <title>{title}</title>\n'
              f'  <rect width="108" height="108" fill="#{light}"/>\n'
              f'  <g transform="translate({f(OFF)} {f(OFF)}) scale({f(SCALE)})">\n    {body}\n  </g>\n'
              f'</svg>\n')
        gbody = '\n  '.join(svg_shapes(GLYPHS[key], '#0E1116', '#0E1116', STROKE))
        write(os.path.join(ROOT, f'brand/icons/{key}/{key}-glyph.svg'),
              f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" '
              f'width="24" height="24">\n  {gbody}\n</svg>\n')


# ------------------------------------------------------------- Android -----
NS = 'xmlns:android="http://schemas.android.com/apk/res/android"'


def vector(items, color):
    paths = []
    for kind, d, _role in items:
        if kind == 'stroke':
            paths.append(
                f'        <path\n            android:pathData="{d}"\n'
                f'            android:strokeColor="{color}"\n'
                f'            android:strokeWidth="{f(STROKE)}"\n'
                f'            android:strokeLineCap="round"\n'
                f'            android:strokeLineJoin="round" />')
        else:
            paths.append(
                f'        <path\n            android:pathData="{d}"\n'
                f'            android:fillColor="{color}" />')
    return (f'<?xml version="1.0" encoding="utf-8"?>\n'
            f'<vector {NS}\n    android:width="108dp"\n    android:height="108dp"\n'
            f'    android:viewportWidth="108"\n    android:viewportHeight="108">\n'
            f'    <group\n        android:scaleX="{f(SCALE)}"\n        android:scaleY="{f(SCALE)}"\n'
            f'        android:translateX="{f(OFF)}"\n        android:translateY="{f(OFF)}">\n'
            + '\n'.join(paths) + '\n    </group>\n</vector>\n')


def android():
    for key, (_title, light, _dark) in ACCENTS.items():
        base = os.path.join(ROOT, f'brand/icons/{key}/res')
        write(f'{base}/drawable/ic_suite_foreground.xml', vector(GLYPHS[key], '#FFFFFFFF'))
        write(f'{base}/drawable/ic_suite_monochrome.xml', vector(GLYPHS[key], '#FFFFFFFF'))
        write(f'{base}/drawable/ic_suite_background.xml',
              f'<?xml version="1.0" encoding="utf-8"?>\n'
              f'<vector {NS}\n    android:width="108dp"\n    android:height="108dp"\n'
              f'    android:viewportWidth="108"\n    android:viewportHeight="108">\n'
              f'    <path\n        android:pathData="M0 0 L108 0 L108 108 L0 108 Z"\n'
              f'        android:fillColor="#FF{light}" />\n</vector>\n')
        adaptive = (f'<?xml version="1.0" encoding="utf-8"?>\n'
                    f'<adaptive-icon {NS}>\n'
                    f'    <background android:drawable="@drawable/ic_suite_background" />\n'
                    f'    <foreground android:drawable="@drawable/ic_suite_foreground" />\n'
                    f'    <monochrome android:drawable="@drawable/ic_suite_monochrome" />\n'
                    f'</adaptive-icon>\n')
        write(f'{base}/mipmap-anydpi-v26/ic_launcher.xml', adaptive)
        write(f'{base}/mipmap-anydpi-v26/ic_launcher_round.xml', adaptive)


dart()
svgs()
android()
print('ok')
