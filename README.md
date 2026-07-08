# Secure Suite — Core

Shared foundation for **Secure Suite**, a family of privacy-first, **offline-only**
Flutter apps. No servers, no accounts, no telemetry — every app stores its data
encrypted on the device and nowhere else.

This repository holds the five shared packages the apps are built on. Each app
lives in its own repository and depends on these packages via a Git dependency.

## The apps

| App | What it is | Repo |
| --- | --- | --- |
| 💊 **DoseWise** | Medication schedule & adherence tracker | [dosewise](https://github.com/MalicKAbdullah/dosewise) |
| 📄 **Ledgerly** | Freelance invoices, payments & expenses | [ledgerly](https://github.com/MalicKAbdullah/ledgerly) |
| 📓 **Reflect** | Encrypted journal with photos & mood analytics | [reflect](https://github.com/MalicKAbdullah/reflect) |
| 🔐 **Vaultly** | Password manager with TOTP & autofill | [vaultly](https://github.com/MalicKAbdullah/vaultly) |

## Packages

| Package | Responsibility |
| --- | --- |
| `core_crypto` | AES-256-GCM encryption + Argon2id key derivation (OWASP parameters). The **only** place cryptography lives. Pure Dart, fully unit-tested. |
| `core_storage` | `ISecureStorage` over the platform keystore (Android Keystore / iOS Keychain). |
| `core_security` | App-lifecycle security (lock/blur on background) and root/jailbreak detection. |
| `core_theme` | Design system: bundled Inter typography, color tokens, spacing, Material 3 light/dark themes with per-app accents. |
| `core_ui` | Shared widgets — buttons, cards, text fields, empty states, loading overlay. |

## Security model

- Data keys are either random 256-bit keys held in the platform keystore, or
  derived from a user secret (PIN / master password) with **Argon2id**
  (64 MiB memory, 3 iterations, parallelism 4).
- All app data is serialized to JSON and encrypted with **AES-256-GCM** — a fresh
  random nonce per write, authentication tag verified on every read.
- Keys derived from a user secret exist only in memory while unlocked and are
  zeroed on lock.
- Encrypted backups are protected by a **separate** passphrase, so a backup file
  alone reveals nothing.

See [SECURITY.md](SECURITY.md) for the full policy and responsible-disclosure
process.

## Using the packages

```yaml
dependencies:
  core_crypto:
    git:
      url: https://github.com/MalicKAbdullah/secure-suite-core.git
      path: core_crypto
      ref: main
```

## Develop

```sh
cd core_crypto      # or any package
flutter pub get
dart analyze
flutter test        # core_crypto uses `dart test`
```

## License

[MIT](LICENSE) © 2026 Abdullah Malik
