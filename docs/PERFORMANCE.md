# Startup and unlock performance

How a Secure Suite app gets from tap to home screen, what each phase costs,
and the rules that keep it fast.

## The cold-start path

1. **Native splash → first frame.** Android shows `LaunchTheme`
   (`?android:colorBackground`, with a `values-night` variant, so no white
   flash in dark mode) until Flutter draws. Everything `main()` awaits before
   `runApp` extends this phase.
2. **First frame → biometric prompt.** `LockScreen` (core_lock) fires the
   prompt from its first post-frame callback; Vaultly's `UnlockScreen` fires
   it once its flags are read.
3. **Fingerprint → home with data.** core_lock apps build the router under the
   lock (`Offstage`), so the data load runs while the prompt is up. Vaultly
   derives nothing on the biometric path: the stored key is read, the vault
   file decrypted, the list shown.

## Where the time goes

### Secure storage round trips (the dominant cost)

flutter_secure_storage 9.2.4 on Android rebuilds `EncryptedSharedPreferences`
on **every** call (its "already initialised" check is commented out): a
Keystore master-key lookup plus two Tink keyset decrypts through the Keystore.
Calls also run one at a time on a single worker thread, so N reads cost N
initialisations in series. Estimated at 40–150 ms per call on a mid-range
Android phone (Keystore operations are IPC to the keystore daemon / TEE); no
device was available to measure, so confirm with the `*.startup` log lines
(`flutter run --profile`, then watch `developer.log` output).

| App | Before | Now |
| --- | --- | --- |
| Budgetly, before `runApp` | 5 serial reads | 1 `readAll` (`CachedSecureStorage`) |
| Budgetly, during unlock (data key, preferences) | 3+ serial reads, plus 1 per save | 0 (memory) |
| Ledgerly, before `runApp` | 2 serial reads | 1 `readAll` |
| Vaultly, before the prompt | verifier, cooldown, enabled, enabled again, then 2 `local_auth` probes — all serial | verifier, then cooldown + enabled + hardware probe started together |
| Vaultly, fingerprint → key | 2 serial reads (key, salt) | 1 (salt is fetched while the prompt is up) |

`CachedSecureStorage` (core_storage) is one `readAll` at launch with reads
served from memory and write-through updates. It is only for apps that are
the sole writer of their keys and hold no value that must stay out of memory
until a user gesture releases it. Vaultly does not use it: its
biometric-released vault key must not enter Dart memory before the prompt.

Threat model for the cache: values stay encrypted at rest (Keystore /
Keychain, unchanged). In memory they sit beside the decrypted dataset and the
data key, which the app already holds for the whole session, so an attacker
able to read process memory gains nothing new.

### Work awaited before the first frame

`main()` used to await notification setup (timezone lookup, plugin init,
channel creation) and the notification permission request before `runApp`.
`LocalNotify` now queues every call behind `initialize`, so apps start it
after `runApp` without blocking the first frame.

### Biometric prompt

`sensitiveTransaction: false` is passed to `local_auth`: unlocking an app is
not a payment-style confirmation, and with the default Android makes face
unlock wait for an extra "Confirm" tap after the face matched. Fingerprint is
unaffected.

### Crypto (measured, not a bottleneck on the biometric path)

`dart compile exe core_crypto/benchmark/startup_benchmark.dart`, Apple M-series,
mean of 3–5 runs after a warm-up. Rows are vault/transaction-shaped JSON
objects (~310 bytes each).

| Operation | Time |
| --- | --- |
| Argon2id derive (64 MiB, t=3, p=4), background isolate | 184–205 ms |
| decrypt + `jsonDecode`, 200 rows (62 KiB) | 4.7 ms |
| decrypt + `jsonDecode`, 1 000 rows (309 KiB) | 24 ms |
| decrypt + `jsonDecode`, 5 000 rows (1.5 MiB) | 120 ms |
| `jsonEncode` + encrypt + `toBytes`, 1 000 rows | 26 ms (was 37 ms) |
| `jsonEncode` + encrypt + `toBytes`, 5 000 rows | 130 ms (was 190 ms) |
| `EncryptedPayload.toBytes`, 5 000 rows | 0.2 ms (was 18.6 ms) |

Mid-range phone estimate: ×4–5 the M-series AOT figure (single-core
throughput and memory bandwidth of a Cortex-A76-class core). So a 1 000-row
vault decrypts and parses in roughly 100–120 ms, done while the prompt is
still up in the core_lock apps.

Argon2id runs only on the password path (setup, password unlock, backups),
never on the biometric path, and already off the UI isolate. Its parameters
(64 MiB, 3 passes, 4 lanes) are RFC 9106's second recommended option and
above OWASP's minimum (19 MiB, 2 passes, 1 lane); they stay. The estimated
~1 s on a mid-range phone is the cost of a password unlock, not of opening
the app.

### Fingerprint → home estimate

core_lock apps (Budgetly, Ledgerly): data is already loaded under the lock, so
home is one frame after the prompt closes (< 50 ms). Vaultly: one secure
storage read (40–150 ms) + vault decrypt and parse (≈ 30 ms for 300 entries on
a mid-range phone) + the route change ≈ 0.1–0.25 s.
