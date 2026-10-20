# Offlyne mark, wordmark and lockups

All text in these SVGs is converted to outlines (Mona Sans Display SemiBold
for the wordmark, Mona Sans for the endorsement), so they render without the
font installed.

| File | Content |
|---|---|
| `offlyne-mark-mono.svg` | Mark, ink `#0E1116`, for light surfaces |
| `offlyne-mark-mono-white.svg` | Mark, white, for dark surfaces and photos |
| `offlyne-mark-accent.svg` | Ink ring, accent dot (cobalt shown; swap per app) |
| `offlyne-mark-accent-dark.svg` | White ring, dark-theme accent dot |
| `offlyne-wordmark.svg`, `-white.svg` | Wordmark, mono |
| `offlyne-wordmark-accent.svg` | Wordmark with the accent y |
| `offlyne-lockup.svg`, `-white.svg`, `-accent.svg` | Mark + wordmark |
| `offlyne-endorsement.svg`, `-white.svg` | "by Offlyne" lockup |
| `png/offlyne-endorsement*.png` | Endorsement at 200x80dp, 4x, for native splash branding |

## Minimum sizes

| Element | Minimum | Below that |
|---|---|---|
| Mark | 16px / 16dp | The break in the ring closes and the dot merges with it. Use no mark. |
| Wordmark | 14px font size (about 10px cap height) | Set "Offlyne" as plain text in the UI font. |
| Endorsement | 11px text, mark at 16px | Drop the mark, keep "by Offlyne" as text. |

Clear space: half the mark's height on every side of the mark and of any
lockup containing it; the cap height of the "O" around a wordmark on its own.
See `docs/BRAND.md`.
