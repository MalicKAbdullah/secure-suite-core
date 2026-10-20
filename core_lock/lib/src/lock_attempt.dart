/// Outcome of a secret check against the app lock (password, recovery key).
sealed class LockAttempt {
  const LockAttempt();
}

final class LockAttemptSuccess extends LockAttempt {
  const LockAttemptSuccess();
}

final class LockAttemptRejected extends LockAttempt {
  const LockAttemptRejected({this.cooldown});

  /// Non-null when this failure started a cooldown.
  final Duration? cooldown;
}

/// Too many recent failures: nothing was checked.
final class LockAttemptCoolingDown extends LockAttempt {
  const LockAttemptCoolingDown(this.remaining);

  final Duration remaining;
}

/// How the current unlocked session was opened.
enum UnlockMethod { password, biometric, recoveryKey }

/// Escalating cooldown shared by password and recovery-key attempts: the
/// first [freeAttempts] failures are free, then 30 s doubling per failure,
/// capped at 15 minutes.
abstract final class LockCooldown {
  static const int freeAttempts = 5;
  static const Duration base = Duration(seconds: 30);
  static const Duration max = Duration(minutes: 15);

  static Duration after(int failedAttempts) {
    if (failedAttempts < freeAttempts) return Duration.zero;
    var seconds = base.inSeconds;
    for (var i = freeAttempts; i < failedAttempts; i++) {
      seconds *= 2;
      if (seconds >= max.inSeconds) return max;
    }
    return Duration(seconds: seconds);
  }
}

/// User-facing text for a failed [LockAttempt]; [wrong] names what was
/// rejected, e.g. "Incorrect password."
String lockAttemptError(LockAttempt attempt, {required String wrong}) =>
    switch (attempt) {
      LockAttemptSuccess() => '',
      LockAttemptRejected(cooldown: final Duration cooldown) =>
        '$wrong Too many attempts — try again in ${_wait(cooldown)}.',
      LockAttemptRejected() => wrong,
      LockAttemptCoolingDown(:final remaining) =>
        'Too many attempts — try again in ${_wait(remaining)}.',
    };

String _wait(Duration d) {
  final seconds = d.inSeconds + (d.inMilliseconds % 1000 > 0 ? 1 : 0);
  if (seconds < 60) return '$seconds s';
  final minutes = (seconds / 60).ceil();
  return minutes == 1 ? '1 minute' : '$minutes minutes';
}
