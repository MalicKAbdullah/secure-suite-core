/// Abstraction over the platform **biometric** prompt (fingerprint / face) so
/// lock logic is testable without platform channels.
///
/// Biometric-only by design: the Secure Suite lock never falls back to the
/// device PIN/pattern. The in-app password (see [IPasswordHasher]) is the only
/// fallback, so unlocking never depends on the phone's own screen lock.
abstract interface class IDeviceAuth {
  /// Whether the device has usable enrolled biometrics right now.
  Future<bool> canAuthenticate();

  /// Shows the biometric prompt. Returns true when it succeeds.
  Future<bool> authenticate({required String reason});
}

/// Default used outside main() — e.g. tests that don't override the provider.
/// Reports no capability and never authenticates.
final class UnavailableDeviceAuth implements IDeviceAuth {
  const UnavailableDeviceAuth();

  @override
  Future<bool> canAuthenticate() async => false;

  @override
  Future<bool> authenticate({required String reason}) async => false;
}
