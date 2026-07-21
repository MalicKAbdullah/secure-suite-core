import 'package:core_lock/src/device_auth.dart';
import 'package:local_auth/local_auth.dart';

/// Production [IDeviceAuth] backed by the local_auth plugin. Construct only in
/// main(); everything else depends on the interface.
final class LocalAuthDeviceAuth implements IDeviceAuth {
  LocalAuthDeviceAuth([LocalAuthentication? auth])
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> canAuthenticate() async {
    try {
      // Biometric-only: usable only when biometrics are actually enrolled.
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        // biometricOnly: the app's own password is the fallback, never the
        // device PIN/pattern.
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
