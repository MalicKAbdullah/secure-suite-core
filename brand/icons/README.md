# Offlyne app icons

One construction for all seven apps (see `docs/BRAND.md`): flat accent tile,
white 2-unit-stroke glyph on the shared 24-unit grid, one family dot per glyph.

## Folder → app

| Icon folder | App directory (`apps/…`) | Tile color |
|---|---|---|
| `budgetly/` | `budgetly` | `#0F62D6` |
| `vaultly/`  | `vaultkey` | `#7341E6` |
| `openlock/` | `openlock` | `#007E9C` |
| `reflect/`  | `reflect`  | `#C81E5B` |
| `ledgerly/` | `ledgerly` | `#4A4FE0` |
| `dosewise/` | `dose_wise` | `#08805F` |
| `warden/`   | `warden`   | `#457A0C` |

## What each folder holds

| File | Use |
|---|---|
| `res/drawable/ic_suite_foreground.xml` | Adaptive icon foreground (vector, 108dp canvas) |
| `res/drawable/ic_suite_background.xml` | Adaptive icon background (flat accent) |
| `res/drawable/ic_suite_monochrome.xml` | Android 13+ themed icon layer |
| `res/mipmap-anydpi-v26/ic_launcher.xml`, `ic_launcher_round.xml` | Adaptive icon wiring the three layers |
| `png/icon-1024.png` | Full-bleed 1024px master: iOS icon and pre-API-26 Android mipmaps |
| `png/icon-foreground-1024.png` | Glyph on transparent, 108-unit canvas: flutter_launcher_icons foreground, Android 12 splash icon |
| `png/icon-monochrome-1024.png` | Glyph on transparent for `adaptive_icon_monochrome` |
| `png/splash-tile.png` | Rounded tile, 384px (96dp at 4x): the pre-Android-12 and iOS splash image |
| `png/play-store-512.png` | Google Play listing icon (full bleed; Play applies the mask) |
| `<app>-icon.svg` | Vector master of the full icon |
| `<app>-glyph.svg` | Glyph alone on the 24-unit grid (in-app use, docs) |

## Installing in an app

Paths below are relative to the app directory, e.g.
`/Users/abdullah/Desktop/Abdullah/secure_suite/apps/vaultkey`.

1. Copy the PNG masters:
   - `png/icon-1024.png` → `assets/icon/icon.png`
   - `png/icon-foreground-1024.png` → `assets/icon/icon_foreground.png`
   - `png/icon-monochrome-1024.png` → `assets/icon/icon_monochrome.png`
2. In `pubspec.yaml`, set the `flutter_launcher_icons` block to:
   ```yaml
   flutter_launcher_icons:
     android: true
     ios: true            # false for openlock and warden (Android-only)
     image_path: assets/icon/icon.png
     adaptive_icon_background: "#7341E6"   # the tile color from the table
     adaptive_icon_foreground: assets/icon/icon_foreground.png
     adaptive_icon_monochrome: assets/icon/icon_monochrome.png
     remove_alpha_ios: true
   ```
   and run `dart run flutter_launcher_icons`. This writes the legacy
   `mipmap-*dpi/ic_launcher.png` files and the iOS icon set.
3. **After** step 2 (the tool rewrites `mipmap-anydpi-v26`), copy the vectors so
   API 26+ renders crisp vector layers instead of PNGs:
   - `res/drawable/ic_suite_*.xml` → `android/app/src/main/res/drawable/`
   - `res/mipmap-anydpi-v26/ic_launcher.xml` and `ic_launcher_round.xml` →
     `android/app/src/main/res/mipmap-anydpi-v26/`
4. In `android/app/src/main/AndroidManifest.xml`, on `<application>`, keep
   `android:icon="@mipmap/ic_launcher"` and add
   `android:roundIcon="@mipmap/ic_launcher_round"`.
5. Delete the now-unreferenced `android/app/src/main/res/drawable-*dpi/ic_launcher_foreground.png`
   files and the `ic_launcher_background` entry in `res/values/colors.xml`.
6. Upload `png/play-store-512.png` as the Play listing icon.

The `<monochrome>` layer needs `compileSdk` 33 or higher; older launchers
ignore it.

## Native splash

Each app's `flutter_native_splash` block uses the glyph and the endorsement:

```yaml
flutter_native_splash:
  color: "#F6F7F9"
  color_dark: "#0A0C10"
  image: assets/brand/splash-tile.png
  branding: assets/brand/offlyne-endorsement.png
  branding_dark: assets/brand/offlyne-endorsement-white.png
  android_12:
    image: assets/icon/icon_foreground.png
    icon_background_color: "#7341E6"        # the tile color
    icon_background_color_dark: "#7341E6"
    color: "#F6F7F9"
    color_dark: "#0A0C10"
    branding: assets/brand/offlyne-endorsement.png
    branding_dark: assets/brand/offlyne-endorsement-white.png
```

Copy `png/splash-tile.png`, `brand/mark/png/offlyne-endorsement.png` and
`offlyne-endorsement-white.png` to `assets/brand/`. On Android 12+ the system
draws the glyph on an accent circle; earlier Android and iOS show the rounded
tile. The endorsement PNGs are 800x320px (200x80dp at 4x), the size of Android
12's splash branding slot.

## Regenerating

The geometry lives in `core_ui/lib/src/brand/brand_geometry.dart`. The PNGs
are rendered from it by:

```sh
cd core_ui && GALLERY=1 flutter test test/brand/brand_render_test.dart
```
