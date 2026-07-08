# Security Policy

## Our promise

Every app in Secure Suite is **offline-only and local-first**:

- No network calls, no accounts, no telemetry, no analytics. There is no server.
- All user data is encrypted at rest with **AES-256-GCM**; every write uses a fresh
  random 12-byte nonce and the authentication tag is verified on every read.
- Encryption keys are either random 256-bit keys held in the platform keystore
  (Android Keystore / iOS Keychain via `flutter_secure_storage`) or derived from a
  user secret with **Argon2id** (OWASP-recommended parameters: 64 MiB memory,
  3 iterations, parallelism 4).
- Password-manager (Vaultly) and journal (Reflect) keys exist only in memory while
  unlocked and are zeroed on lock. Screenshots are blocked in Vaultly (FLAG_SECURE).
- Backups are encrypted with a key derived from a **separate backup passphrase** —
  a backup file alone reveals nothing.
- Data leaves the device only when the user explicitly shares or exports it.

All cryptography is centralized in one audited package: [`packages/core_crypto`](packages/core_crypto/).
No crypto logic exists anywhere else in the codebase.

## Reporting a vulnerability

Please **do not open a public issue** for security problems.

Email **abdullah.malik@doctornow.io** with a description and reproduction steps.
You should receive a response within 72 hours. Coordinated disclosure is
appreciated; you will be credited in the fix release notes unless you prefer
otherwise.

## Scope notes

- Release builds must be signed with the maintainer's release keystore; debug-signed
  builds are for development only.
- The threat model is device-at-rest protection and backup-file confidentiality.
  A compromised OS / rooted device with a live unlocked session is out of scope.
