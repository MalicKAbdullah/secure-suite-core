import 'package:safe_device/safe_device.dart';

final class RootDetectionService {
  const RootDetectionService();

  Future<DeviceIntegrityStatus> checkDeviceIntegrity() async {
    final isRooted = await SafeDevice.isJailBroken;
    final isRealDevice = await SafeDevice.isRealDevice;

    return DeviceIntegrityStatus(
      isRootedOrJailbroken: isRooted,
      isDeveloperMode: !isRealDevice,
    );
  }
}

final class DeviceIntegrityStatus {
  const DeviceIntegrityStatus({
    required this.isRootedOrJailbroken,
    required this.isDeveloperMode,
  });

  final bool isRootedOrJailbroken;
  final bool isDeveloperMode;

  bool get isCompromised => isRootedOrJailbroken;
}
