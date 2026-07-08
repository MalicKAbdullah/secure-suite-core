<div align="center">

# 🛡️ Secure Suite — Core

### The private foundation behind four apps.

Shared encryption, secure storage, and design system for the **Secure Suite** — a family of privacy-first, **offline-only** apps.

![License](https://img.shields.io/badge/License-MIT-ff5c35?style=flat-square)
![Language](https://img.shields.io/badge/Dart-Flutter-027DFD?style=flat-square&logo=dart)
![Privacy](https://img.shields.io/badge/Privacy-Offline%20First-34D399?style=flat-square)
![Trackers](https://img.shields.io/badge/Trackers-0-34D399?style=flat-square)

</div>

> ### 🔒 Privacy is the product
> Every app built on this core stores your data **encrypted on your device and nowhere else**. No servers, no accounts, no telemetry — because the safest data is the data that never leaves your phone.

This repository holds the five shared packages the Secure Suite apps are built on. Each app lives in its own repository and depends on these packages.

## 📱 The apps

| App | What it is | Repository |
| --- | --- | --- |
| 💊 **DoseWise** | Medication schedule & adherence tracker | [dosewise](https://github.com/MalicKAbdullah/dosewise) |
| 📄 **Ledgerly** | Freelance invoices, payments & expenses | [ledgerly](https://github.com/MalicKAbdullah/ledgerly) |
| 📓 **Reflect** | Encrypted journal with photos & mood analytics | [reflect](https://github.com/MalicKAbdullah/reflect) |
| 🔒 **Latchly** | App lock — guard any app behind a PIN or fingerprint (Android) | [latchly](https://github.com/MalicKAbdullah/latchly) |
| 🔐 **Vaultly** | Password manager with 2FA & autofill | [vaultly](https://github.com/MalicKAbdullah/vaultly) |

## 📦 Packages

| Package | Responsibility |
| --- | --- |
| **`core_crypto`** | AES-256-GCM encryption + Argon2id key derivation. The **only** place cryptography lives. Pure Dart, fully unit-tested. |
| **`core_storage`** | `ISecureStorage` over the platform keystore (Android Keystore / iOS Keychain). |
| **`core_security`** | App-lifecycle security (lock/blur on background) and root/jailbreak detection. |
| **`core_theme`** | Design system — bundled Inter typography, color tokens, spacing, and Material 3 light/dark themes with per-app accents. |
| **`core_ui`** | Shared widgets — buttons, cards, text fields, empty states, loading overlay. |

## 🔒 Security model

- **Keys** are either random 256-bit keys held in the platform keystore, or derived from a user secret (PIN / master password) with **Argon2id** (OWASP parameters: 64 MiB memory, 3 iterations, parallelism 4).
- **Data** is serialized to JSON and encrypted with **AES-256-GCM** — a fresh random nonce per write, authentication tag verified on every read.
- **User-derived keys** exist only in memory while unlocked and are zeroed on lock.
- **Backups** are protected by a *separate* passphrase, so a backup file alone reveals nothing.

See [SECURITY.md](SECURITY.md) for the full policy and responsible-disclosure process, and [CONTRIBUTING.md](CONTRIBUTING.md) to get involved.

## 🔧 Using a package

```yaml
dependencies:
  core_crypto:
    git:
      url: https://github.com/MalicKAbdullah/secure-suite-core.git
      path: core_crypto
      ref: main   # or pin to a commit SHA for reproducible builds
```

## 🚀 Develop

```sh
git clone https://github.com/MalicKAbdullah/secure-suite-core.git
cd secure-suite-core/core_crypto   # or any package

flutter pub get
dart analyze
dart test          # core_crypto is pure Dart; UI packages use `flutter test`
```

## 📄 License

[MIT](LICENSE) © 2026 Abdullah Malik
