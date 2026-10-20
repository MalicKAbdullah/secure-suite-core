# Migrating an app to the Offlyne design system

Most apps compile unchanged: every existing token and widget name still exists.
The list below covers what changes visually and what to update.

## 1. Required: pick your accent

The legacy accent names now point at suite accents. Switch to the app's own
accent explicitly:

| App | Before | After |
|---|---|---|
| Budgetly | `AppColors.emeraldAccent` | `AppAccents.budgetly` |
| Vaultly | `AppColors.emeraldAccent` | `AppAccents.vaultly` |
| OpenLock | custom `AppAccent(...)` | `AppAccents.openlock` |
| Reflect | `AppColors.violetAccent` | `AppAccents.reflect` |
| Ledgerly | `AppColors.indigoAccent` | `AppAccents.ledgerly` |
| DoseWise | `AppColors.tealAccent` | `AppAccents.dosewise` |
| Warden | `AppColors.indigoAccent` | `AppAccents.warden` |

```dart
theme: AppTheme.build(Brightness.light, accent: AppAccents.budgetly),
darkTheme: AppTheme.build(Brightness.dark, accent: AppAccents.budgetly),
```

## 2. Breaking or visible changes

- **Font.** Inter is replaced by Mona Sans, Mona Sans Display and Mona Sans Mono. `AppTextStyles.fontFamily` is now `packages/core_theme/MonaSans`, and the Inter files are gone. Code that hard-codes `'packages/core_theme/Inter'` must use `AppTextStyles.fontFamily`.
- **`AppTextStyles.code`** is set in Mona Sans Mono and drops the `slashedZero` feature, because the mono already distinguishes zero.
- **Sizes.** `h1` grows from 30 to 32, `h3` from 18 to 19 and `hero`-class numbers from 52 to 56. `displayHuge` changes from 52/w800 to 56/w600. Number styles move to the display face at weight 500. Check tight layouts.
- **`AppSpacing.borderRadius`** changes from 12 to 14 and **`borderRadiusLg`** from 20 to 22.
- **`VaultTextField`** no longer draws its label above the field. The label floats inside a filled field, so remove any extra spacing you added above it. The constructor is unchanged.
- **`VaultEmptyState`** renders through `AppEmptyState`: `message` becomes the headline (h2) and the icon sits in a hairline ring. Keep messages short. For a supporting sentence, use `AppEmptyState(title:, message:)`.
- **`VaultButton`** is a pill. `secondary` is now a neutral hairline outline in ink rather than accent-coloured, and `destructive` uses `onError` text. New optional parameters: `icon`, `compact`.
- **`SettingsTile`** renders as an `AppListRow` with an `IconBadge`. Put groups of tiles in a `RowGroup` instead of a `Card` + `Column` + `Divider`s. New optional parameter: `iconColor`.
- **`SectionHeader`** uses a larger title (18/600), and its action is an accent text with a chevron. New optional parameters: `subtitle`, `trailing`.
- **`VaultCard`** has a hairline edge, radius 22 and padding 20 (was 16). New optional parameters: `color`, `radius`.
- **`StatTile`** takes its label and caption colours from `SuiteColors`. New optional parameter: `dotColor`.
- **`ChipTheme`.** Selected chips invert to ink (`selectedColor = textPrimary`). Read `chipTheme.secondaryLabelStyle` for selected-label text, or use `AppChip`.
- **`ColorScheme.inverseSurface`** is now the ink colour (dark in light mode). Snackbars and tooltips use it.
- **Shadows.** Every component theme has elevation 0, including the FAB, dialogs, menus and sheets. Remove any `elevation:` overrides an app relied on.
- **`LockScreen`** has a new layout and the optional `appMark` parameter. Pass `SuiteAppIcon(app: SuiteApp.<app>, size: 56)`. `core_lock` now depends on `core_ui`.
- **`AppColors.gray*`** ramp values shift to the cool graphite ramp. Every name is kept.

## 3. Recommended swaps

| Instead of | Use |
|---|---|
| `Text(formatAmount(x), style: AppTextStyles.number)` | `MoneyText(x, currency: 'Rs')` (`tone: MoneyTone.signed` for ± amounts) |
| hand-rolled balance cards | `HeroMetricCard` + `MoneyText(style: AppTextStyles.hero)` |
| `Card(child: Column([... ListTile, Divider ...]))` | `RowGroup(children: [AppListRow(...)])` |
| `TextField(decoration: InputDecoration(...))` | `AppTextField(...)` (`monospace: true` for secrets) |
| custom search boxes | `AppSearchField` |
| `SegmentedButton` for period pickers | `AppSegmentedControl` |
| `FilterChip` rows | `AppChip` |
| `LinearProgressIndicator` for budgets | `AppProgressBar(value:, marker:)` |
| `CircularProgressIndicator` placeholders in lists | `SkeletonRow` |
| `Theme.of(context).brightness == ... ? AppColors.x : AppColors.y` | `SuiteColors.of(context).x` |

## 4. Brand

Install the launcher icons, monochrome layer and splash for each app from
`brand/icons/<app>/` by following `brand/icons/README.md`. Add
`SuiteEndorsement()` to the About screen.
