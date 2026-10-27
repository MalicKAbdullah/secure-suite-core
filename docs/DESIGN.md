# Offlyne design system

The shared visual language of every Offlyne app (Budgetly, Vaultly, OpenLock,
Reflect, Ledgerly, DoseWise, Warden). Tokens live in `core_theme`, components
in `core_ui`, brand assets in `brand/` (rules in [BRAND.md](BRAND.md)).

## Philosophy

1. **The number is the interface.** Dashboards lead with one large figure, then its change, its trend, and the figures that explain it.
2. **Flat and exact.** No shadows, no glass, no gradients on surfaces. Depth comes from one step of surface tone and a hairline edge.
3. **One accent, used sparingly.** Each app has a single identity colour for actions, focus and the hero trend. Everything else is cool neutral.
4. **Airy, not sparse.** A 4 pt grid, 20 pt gutters and large type allow many facts per screen without visual noise.
5. **Semantics are shared.** Positive, negative and warning mean the same thing in every app, independent of the accent.

## What the reference products do

| Source | Principle taken |
|---|---|
| Copilot Money ([design analysis](https://blakecrosley.com/ko/guides/design/copilot-money); [9to5Mac review](https://9to5mac.com/2024/10/31/copilot-money-review-ipad-cash-flow-tags/)) | Summary-first home: spend, net, top categories and recent transactions on one screen. Very large, tightly tracked display figures (line-height ≈ 1.0). Fixed semantic money colours: income green, spend red. |
| Linear ([How we redesigned the Linear UI](https://linear.app/now/how-we-redesigned-the-linear-ui), [design refresh](https://linear.app/now/behind-the-latest-design-refresh)) | Themes generated from a few inputs (base, accent, contrast). Higher contrast in both modes. Fewer borders and less chrome to cut noise. Neutrals stay crisp without turning muddy. |
| Material 3 Expressive ([Wear OS guidance](https://developer.android.com/design/ui/wear/guides/get-started)) | Physics-like settle for direct manipulation, with calmer motion everywhere else. |
| Mona Sans ([GitHub announcement](https://github.blog/news-insights/company-news/introducing-mona-sans-and-hubot-sans/)) | An open (OFL) grotesque superfamily with text, display and mono cuts. `tnum` was verified in the font files' GSUB tables. |
| Revolut, Monzo, Apple HIG (product study) | Pill-shaped primary buttons, grouped list rows with inset separators, currency and minor units set smaller than the whole amount, segmented controls on a recessed track. |

## Colour

### Neutral shell (cool graphite)

| Token | Light | Dark |
|---|---|---|
| background | `#F6F7F9` | `#0A0C10` |
| surface (cards) | `#FFFFFF` | `#12151A` |
| surfaceAlt (fields, tracks) | `#EEF0F3` | `#1B1F26` |
| border | `#E2E5EA` | `#262B34` |
| hairline (dividers, card edge) | `#E8EBEF` | `#1F232B` |
| textPrimary | `#0E1116` | `#EDEFF3` |
| textSecondary | `#5B6371` (5.6:1) | `#9BA3B1` (7.7:1) |
| textTertiary | `#7F8794` | `#687080` |

### Semantics (shared by every app)

| Role | Light | Dark | Container L / D |
|---|---|---|---|
| positive / success | `#0E9F55` | `#3DD68C` | `#E6F6EC` / `#0F231A` |
| negative / error | `#DC3B42` | `#FF6B70` | `#FDECEC` / `#2A1416` |
| warning | `#B58100` | `#F2C14E` | `#FBF3DC` / `#261F0E` |
| info | `#1F6FEB` | `#6CB0FF` | `#E8F0FE` / `#111D30` |

Money uses `MoneyTone.signed`: positive green, negative red. A negative amount
always uses a true minus sign (U+2212).

### Per-app accents (`AppAccents.*`)

The hues are spread around the cool half of the colour wheel, and none is
orange or terracotta. White text on the light accent passes AA (≥ 4.5:1).

| App | Accent | Light | Dark |
|---|---|---|---|
| Budgetly | Cobalt | `#0F62D6` | `#6AA6FF` |
| Vaultly | Violet | `#7341E6` | `#B197FF` |
| OpenLock | Cyan | `#007E9C` | `#3FD0EE` |
| Reflect | Berry | `#C81E5B` | `#FF6B9A` |
| Ledgerly | Indigo | `#4A4FE0` | `#9298FF` |
| DoseWise | Jade | `#08805F` | `#3EDDA6` |
| Warden | Lime | `#457A0C` | `#A6E33C` |

`AppTheme.build(brightness, accent: AppAccents.budgetly)` builds a theme.
`AppTheme.seeded(brightness, seed)` builds one from any colour.
`SuiteColors.of(context)` returns every token above, plus `chart`, a
categorical series that starts at the accent.

## Type

The **Mona Sans** superfamily (OFL) is bundled in `core_theme/fonts`, so no
font is ever fetched at runtime.

- **Mona Sans Display** (`AppTextStyles.displayFamily`) sets hero figures, display text and h1/h2. Its display cut is drawn for 40–90 px, where a text cut looks loose.
- **Mona Sans** (`fontFamily`) sets body text, labels and rows.
- **Mona Sans Mono** (`monoFamily`) sets passwords, codes and keys, so `0/O` and `1/l/I` are never ambiguous.

The default figures are proportional, so every numeric style enables `tnum`.

| Style | Face | Size / weight / tracking |
|---|---|---|
| heroXL | Display | 64 / 500 / −2.4 |
| hero | Display | 56 / 500 / −2.0 |
| displayHuge · display | Display | 56 · 40 / 600 |
| h1 · h2 | Display | 32 · 24 / 600 |
| h3 · h4 | Text | 19 · 16 / 600 |
| body · bodyMedium · bodySmall | Text | 16 · 15 · 13 / 400 |
| label · labelStrong · button | Text | 14 · 14 · 15 / 500–600 |
| caption · overline | Text | 12 · 11 / 500–600 |
| numberLarge · numberMedium | Display, tnum | 34 · 24 / 500 |
| number · numberSmall | Text, tnum | 17 · 13 / 600–500 |
| code · codeLarge | Mono | 15 · 22 / 500 |

## Space, shape, elevation

- **Grid:** 2, 4, 8, 12, 16, 20, 24, 32, 48, 64. The page gutter is 20 and card padding is 20.
- **Radii:** 6 (xs), 10 (sm), 14 (md: fields, banners), 22 (lg: cards), 28 (xl: hero card, sheets, dialogs), pill (buttons, chips, search, segmented). Inner radius = outer radius − padding.
- **Elevation:** none. Cards are `surface` plus a 1 px `hairline`. Sheets and dialogs sit on a scrim with no shadow.
- **Targets:** buttons are 54 px (40 compact), fields 58, list rows ≥ 66 (dense 52), and every target ≥ 48.

## Motion (`AppMotion`)

| Token | ms | Use |
|---|---|---|
| instant | 90 | press, toggle, colour |
| fast | 160 | chip, field focus, selection |
| base | 240 | content in, segmented thumb (`settle` curve) |
| slow | 420 | lock-screen entrance, progress fill, chart draw |
| shimmer | 1400 | skeleton period |

The curves are `standard` (easeOutCubic), `emphasized` (easeOutQuart), `exit`
(easeInCubic) and `settle` (a slight overshoot, used only for direct
manipulation). When the platform asks for reduced motion, skeletons and the
biometric pulse stop.

## Components (`core_ui`)

| Need | Widget |
|---|---|
| Home hero | `HeroMetricCard` (label, big value, `DeltaBadge`, sparkline, footer `StatTile`s) |
| 2-up metric | `MetricCard` (label, value, delta/caption, optional `AppProgressBar` or chart) |
| Money | `MoneyText` (tabular, true minus, small currency and minor units, shrink-to-fit), `formatMoney` |
| Any figure | `ValueText`, `StatTile` |
| Change | `DeltaBadge` with `DeltaPolarity.upIsGood / upIsBad / neutral` |
| Charts | `Sparkline`, `MiniBarChart`, `DonutChart` + `ChartLegendRow`, `SegmentedBar`, `AppProgressBar` (overflow and pace marker) |
| Lists | `AppListRow`, `IconBadge`, `RowGroup` (grouped card, inset separators), `SettingsTile`, `SectionHeader` |
| Inputs | `AppTextField` (`filled` / `underline` / `outlined`, floating label inside, clear, reveal, mono), `AppSelectField` (a field that opens a sheet of rows; replaces Material dropdowns), `AppSearchField`, `AppSegmentedControl`, `AppChip` |
| Actions | `VaultButton` (primary / secondary / destructive, `icon`, `compact`), `BottomActionBar` |
| States | `AppEmptyState` (typographic: figure or icon ring, headline, sentence, action), `Skeleton`, `SkeletonRow`, `AppBanner`, `LoadingOverlay` |
| Brand | `SuiteMark`, `SuiteWordmark`, `SuiteLockup`, `SuiteEndorsement`, `SuiteAppIcon` (see BRAND.md) |

Material controls (switch, slider, checkbox, chips, navigation bar, tabs,
sheets, dialogs, snackbars, menus, date and time pickers, search bar) are
themed to match, so plain Material widgets also look right.

### Home screen recipe

From the top:

1. A date eyebrow and a greeting in `h2`.
2. `HeroMetricCard` with `AppTextStyles.hero`.
3. Two `MetricCard`s side by side.
4. A chart card.
5. `SectionHeader` and a `RowGroup` of the latest rows.
6. A breakdown card (`DonutChart` and legend).

Leave 12 px between cards and 24 px before each section header. A dashboard
uses exactly one hero card.

### Lock screen

Every lock in the suite has one structure, built by `core_lock`'s
`LockLayout`; only the app tile, name and accent differ. There is no clock,
date, greeting or background graphic: the screen is the app's flat
`background`.

One centred column (380 max width) sits a little below the middle of the
screen (alignment y = 0.2, a 3:2 split of the free space), in thumb reach:

1. the app tile (`SuiteAppIcon`), drawn at 64;
2. the app name in `h2`, 20 below;
3. one short line in `bodyMedium` secondary, 4 below ("Unlock to continue");
4. the unlock controls, 32 below, stacked 12 apart.

The "by Offlyne" endorsement sits at the bottom. With the keyboard up it steps
aside, the tile shrinks to 48 and the gaps tighten, so the field and its
button stay above the keyboard on a 360 × 640 phone.

Controls, from the top:

- **Fingerprint on:** "Use fingerprint" as the primary pill
  (`LockFingerprintButton`; the system prompt also starts once on appear), an
  "or" hairline (`LockDivider`), the password field, and an outlined Unlock
  button.
- **Fingerprint off:** the password field, focused, and a primary Unlock
  button.
- A quiet "Forgot password?" link (`LockTextLink`). It swaps the controls for
  the recovery form in the same column (line: "Reset your password"): a short
  explanation, recovery key, new password, confirm, "Reset and unlock", and
  "Back to unlock".

A wrong password shakes the field (`LockShake`, still under reduced motion)
and shows the error under it. A cooldown shows "Too many attempts. Try again
in 0:28." counting down each second (`formatLockCountdown`) and disables
Unlock. While Argon2 runs, Unlock shows a spinner.

`LockScreen` and `AppLockGate` take `appMark: SuiteAppIcon(app: SuiteApp.<app>,
size: 64)`. Apps with their own unlock (a master password, a PIN keypad) build
the same screen with `LockLayout` and these parts; a PIN keypad goes where the
password field is, below the fingerprint button.

## Native splash

Each app uses `flutter_native_splash` with the shared neutral background, the
app tile and the endorsement. The asset paths and the full block are in
[brand/icons/README.md](../brand/icons/README.md#native-splash).

```yaml
flutter_native_splash:
  color: "#F6F7F9"
  color_dark: "#0A0C10"
  image: assets/brand/splash-tile.png
  branding: assets/brand/offlyne-endorsement.png
  branding_dark: assets/brand/offlyne-endorsement-white.png
  android_12:
    image: assets/icon/icon_foreground.png
    icon_background_color: "<accent light>"   # table above
    icon_background_color_dark: "<accent light>"
    color: "#F6F7F9"
    color_dark: "#0A0C10"
    branding: assets/brand/offlyne-endorsement.png
    branding_dark: assets/brand/offlyne-endorsement-white.png
```

The tile colour is the app's light accent in both modes, which keeps the icon
identical to the launcher icon.

## Notifications

Every notification carries the app's identity on Android:

- **Small icon**: `ic_stat_notify`, the app glyph white on transparent, from
  the brand kit ([install steps](../brand/icons/README.md#notification-icon)).
- **Colour**: the app's light accent, which tints the icon and app name.

```dart
LocalNotify(smallIcon: 'ic_stat_notify', accentColor: AppAccents.budgetly.light)
```

Channel names are short sentence-case nouns ("Budget alerts", "Dose
reminders"). A channel description is one sentence fragment, without a full
stop, that says when the notification arrives.

## Previews

The previews render with the real fonts and are not CI goldens, because pixels
differ per platform:

- `cd core_ui && GALLERY=<dir> flutter test test/gallery`: home dashboard, components, accent variants.
- `cd core_lock && GALLERY=<dir> flutter test test/lock_screen_test.dart`: lock screens.
- `cd core_ui && GALLERY=1 flutter test test/brand`: brand contact sheet and launcher PNGs.
