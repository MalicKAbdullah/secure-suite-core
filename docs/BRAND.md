# Offlyne brand

Offlyne is the family behind Budgetly, Vaultly, OpenLock, Reflect, Ledgerly,
DoseWise and Warden. The name means offline, by design: every app keeps its
data on the device. The y is deliberate.

## Architecture: endorsed brands

Each app is the brand the user meets: its own name, icon and accent. Offlyne
endorses it, quietly, in fixed places. Think Google apps or Microsoft 365: the
app leads, the family signs.

| Layer | Carries | Where |
|---|---|---|
| App | Name, glyph, accent | Launcher, app bar, store listing, every screen |
| Family | Shared construction: tile shape, grid, stroke, family dot, type, neutrals | Everywhere, implicitly |
| Endorsement | "by Offlyne" lockup | Splash, lock screen, About, store description |

The app name is never replaced by or merged with the family name ("Offlyne
Budgetly" is wrong; "Budgetly, by Offlyne" is right).

## The mark

A heavy O on a 24-unit grid, centred at (12, 12): outer radius 10.5, inner
radius 6, so the ring is 4.5 units thick. The ring is broken at 45° up and to
the right, where a signal would leave; the break spans 62°. The family dot,
radius 2.25 (diameter 4.5, the ring's own thickness), sits on the ring's
centre line in the break. Nothing leaves the circle; the dot seals it.

- **Mono:** ring and dot in one color: ink `#0E1116` on light, white on dark.
  This is the default and the Android themed-icon form.
- **Accent:** ring in ink (or white), dot in the current app's accent.
  Inside an app, only that app's accent. Outside any app, Budgetly cobalt.

The symbol never spells the name, so it survives a rename.

Files: `brand/mark/`. Widget: `SuiteMark`.

## Wordmark

"Offlyne" in Mona Sans Display SemiBold, tracked −0.02 em. The letters before
and including the y get 0.025 em of extra room, so the y sits slightly apart
and reads as chosen. In the accent wordmark the y takes the app accent; in the
mono wordmark it does not. Never set the wordmark in another face or weight,
never bold or italic the y on its own.

Widget: `SuiteWordmark`. Lockup (mark + wordmark): `SuiteLockup`. The mark in
the lockup is 1.1x the font size, set 0.4x the font size from the word,
centred on the cap height.

## Endorsement lockup

The mark followed by "by Offlyne": "by" in Mona Sans Regular, "Offlyne" in
SemiBold, one color (secondary text, `#5B6472` light / `#9AA3B2` dark). The
mark is 1.15x the text size (16px minimum), set 0.4x its own size from the
text. Widget: `SuiteEndorsement`.

| Surface | Placement | Size |
|---|---|---|
| Native splash | Bottom branding slot (`flutter_native_splash` `branding`) | 15dp text, from `brand/mark/png/` |
| Lock screen | Bottom centre, below the unlock controls, above the safe area | `labelMedium` (12dp) |
| About screen | Under the app name and version, before licences | `labelMedium` or 14dp |
| Store listing | Last line of the short description: "Budgetly, by Offlyne." | Text only |

One endorsement per screen. Never in app bars, navigation, lists, dialogs or
notifications.

## Clear space and minimum sizes

- Clear space around the mark and any lockup: half the mark's height on every
  side. Around a wordmark on its own: the cap height of its "O".
- Mark: 16px minimum. Wordmark: 14px font size minimum. Endorsement: 11px text
  minimum; below the mark's minimum, drop the mark and keep the text.

## Accents

One accent per app, shared neutrals and semantic colors for the rest
(`docs/DESIGN.md`). The light value fills the launcher tile; the dark value is
the accent on dark surfaces.

| App | Accent | Light | Dark |
|---|---|---|---|
| Budgetly | Cobalt | `#0F62D6` | `#6AA6FF` |
| Vaultly | Violet | `#7341E6` | `#B197FF` |
| OpenLock | Cyan | `#007E9C` | `#3FD0EE` |
| Reflect | Berry | `#C81E5B` | `#FF6B9A` |
| Ledgerly | Indigo | `#4A4FE0` | `#9298FF` |
| DoseWise | Jade | `#08805F` | `#3EDDA6` |
| Warden | Lime | `#457A0C` | `#A6E33C` |

Neutrals for brand surfaces: ink `#0E1116`, paper `#F6F7F9`, night `#0A0C10`.

## App icon construction

Every icon is built the same way; only the glyph and the tile color change.

- **Canvas:** Android adaptive icon, 108 units. Visible tile 72 units, safe
  zone 66 units.
- **Tile:** flat accent fill, no gradient, no shadow, no texture. Where a
  rounded tile is drawn by the app (in-app, splash on older systems) its
  corner radius is 0.3x the tile size, matching the mark's proportions.
- **Glyph grid:** 24 units, scaled to 44 of the 108 units and centred, which
  leaves a 14-unit keyline inside the visible tile on every side.
- **Stroke:** 2 grid units, round caps, round joins. Glyphs are strokes;
  the only fill is the family dot.
- **Family dot:** every glyph has exactly one dot, radius 2 grid units
  (Vaultly 1.5, Warden 1.75, where the dot sits inside a tighter form). It is
  the meaningful point of the glyph: the budget headroom, the key's bow, the
  keyhole, the rising star, the invoice total, the tablet, what passes the
  filter.
- **Color:** white glyph on the accent tile. Themed (Android 13+): the
  monochrome layer is the same glyph, and the system tints it.

| App | Glyph |
|---|---|
| Budgetly | Three budget bars; the dot marks the headroom above the shortest |
| Vaultly | A key on the diagonal; the dot in its bow |
| OpenLock | Shackle and body; the dot is the keyhole |
| Reflect | A crescent; the dot rises in its bite |
| Ledgerly | An invoice page with line items; the dot is the total |
| DoseWise | A capsule split at its waist; the dot is a tablet |
| Warden | A shield with two narrowing filter bars; the dot is what gets through |

In-app variants (`SuiteAppIcon` `style`): `color` (launcher), `ink` (ink
tile, white glyph, dot in the app's dark accent, for "more from Offlyne"
rows), `mono` (tinted tile, single-color glyph).

Assets and install steps: `brand/icons/README.md`.

## Don'ts

- No gradients, glows, shadows, bevels, glass or outlines on the mark, tile or
  glyph.
- Don't recolor the ring in an accent, or the dot in a second accent.
- Don't rotate, stretch, or move the break away from 45°.
- Don't add a second dot to a glyph, or a glyph without one.
- Don't change stroke weight or corner radius per app.
- Don't place the mark on busy imagery; use the white mono mark on a flat dark
  field instead.
- Don't use orange, terracotta or warm cream anywhere in the brand.
- Don't put "Offlyne" before the app name, or use the endorsement more than
  once per screen.
