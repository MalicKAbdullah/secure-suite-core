# Contributing to Secure Suite

Thanks for your interest! This monorepo hosts four privacy-first Flutter apps on a
shared foundation. Contributions are welcome — bug fixes, features, translations,
and docs.

## Ground rules (non-negotiable)

1. **Offline stays offline.** No PRs that add network calls, telemetry, analytics,
   or third-party SDKs that phone home. This is the product's identity.
2. **No crypto outside `core_crypto`.** If a change needs cryptography, it goes
   through the shared package.
3. **Quality gates are hard requirements** — CI enforces all of them:
   - `dart format` clean
   - `dart analyze --fatal-infos` → zero issues
   - `flutter test` → all green; new logic needs new tests
4. **Backward-compatible data.** Users have live encrypted data. Model changes must
   load older JSON (defaults for missing fields, or an explicit versioned migration
   with tests proving old fixtures still load).

## Project layout

```
apps/
  dose_wise/   # DoseWise — medication & adherence tracker (teal)
  ledgerly/    # Ledgerly — invoices, payments, expenses (indigo)
  reflect/     # Reflect — encrypted journal (violet)
  vaultkey/    # Vaultly — password manager (emerald; dir name is historical)
packages/
  core_crypto/   core_storage/   core_security/   core_theme/   core_ui/
```

Apps are feature-first (`lib/src/features/<feature>/{models,services,providers,screens,widgets}`),
Riverpod + go_router, files ≤ ~350 lines. Platform seams (file system, secure
storage, clock, notifications, biometrics) sit behind small interfaces with
in-memory fakes — tests never touch platform channels.

## Developing

```sh
cd apps/<app>
flutter pub get
flutter run

# before pushing
dart format .
dart analyze --fatal-infos
flutter test
```

## Pull requests

- One focused change per PR, with a clear description of the user-visible effect.
- Match the surrounding code style; UI work must look right in **both light and
  dark** themes and use `core_theme` tokens (no hardcoded colors/sizes).
- User-facing copy is plain, friendly consumer language — technical/crypto detail
  belongs in READMEs, not in the UI.
