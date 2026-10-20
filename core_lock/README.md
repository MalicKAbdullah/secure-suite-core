# core_lock

Shared app lock for Offlyne apps: fingerprint-primary unlock, an app-set
password fallback (never the device PIN), a recovery key for a forgotten
password, and auto-lock on background. Wrap the app with `AppLockGate`, put
`AppLockSettings` in Settings, and wire `confirmAppLockIdentity` to any
in-app reveal (e.g. `AutoBackupSection.onRevealGate`).

## Secrets and what is stored

| Secret | Stored as | Proves |
| --- | --- | --- |
| Password | Argon2id verifier `salt:hash` (`<key>_verifier`) | Unlock, turn the lock off, change the password |
| Recovery key | Argon2id verifier of its canonical form (`<key>_recovery`) | Set a new password while locked |
| Fingerprint | Nothing; the OS prompt answers yes or no | Unlock; change the password in a fingerprint session (prompted again) |

The password and the recovery key are never stored. A recovery key is 28
Crockford base32 characters from a secure RNG (140 bits), shown once with a
copy button and an "I've saved it" confirmation. Creating a new one replaces
the verifier, so the previous key stops working. Settings cannot show an
existing key, only replace it after a fingerprint or password check.

Existing locks without a recovery key get a one-time offer after the next
unlock; declining it leaves "Recovery key" in Settings.

## Threat model

Protects against someone holding the phone who does not know the password,
cannot pass the fingerprint prompt and does not have the recovery key.

- **Guessing.** Password and recovery-key attempts share one escalating
  cooldown: five free failures, then 30 s doubling per failure up to 15
  minutes, persisted across restarts. During a cooldown nothing is checked.
  Each check costs an Argon2id derivation.
- **An unlocked session left open.** Turning the lock off needs the password.
  Changing the password needs the current password, or a fresh fingerprint
  when the session was opened with one. A new recovery key and a backup
  passphrase reveal need a fresh fingerprint or the password.
- **Stored state read off the device.** Only Argon2id verifiers are in secure
  storage; the 140-bit recovery key cannot be brute-forced from its verifier.

Out of scope: a rooted device or compromised OS, and an attacker who can write
to the app's secure storage (they could replace the verifiers).

What the lock guards depends on the app. In apps whose data key is a random
key in the platform keystore, the lock gates the UI and the data key does not
depend on the password, so a password reset keeps all data. Apps whose data
key is derived from a user secret (a master password or PIN) cannot use a
verifier for recovery: they wrap the data key under the recovery key with
`core_crypto`'s `SecretWrapper` and show it with `RecoveryKeyView`.

Without the password, a working fingerprint and the recovery key, the lock
cannot be opened and the app's data cannot be recovered.
