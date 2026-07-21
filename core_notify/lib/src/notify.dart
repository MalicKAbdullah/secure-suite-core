import 'package:core_notify/src/notify_models.dart';

/// On-device notification surface. Apps depend on this interface; production
/// uses [LocalNotify], tests use a fake or [NoopNotify].
abstract interface class INotify {
  /// Sets up timezones, registers [channels] (Android channels + iOS
  /// categories), and wires the tap/action callback. [onSelect] fires when a
  /// notification (or its action) is tapped while the app is running or
  /// backgrounded; a cold-start tap is read once via [launchSelection].
  Future<void> initialize({
    required List<NotifyChannel> channels,
    required void Function(NotifySelection selection) onSelect,
  });

  /// Requests OS permission to post notifications (Android 13+, iOS). Returns
  /// whether it is granted.
  Future<bool> requestPermission();

  /// Whether notifications are currently permitted.
  Future<bool> isPermitted();

  /// Shows [request] immediately.
  Future<void> show(NotifyRequest request);

  /// Schedules [request] for [when] (local time), optionally repeating.
  Future<void> scheduleAt(
    NotifyRequest request,
    DateTime when, {
    NotifyRepeat repeat = NotifyRepeat.none,
  });

  Future<void> cancel(int id);
  Future<void> cancelAll();

  /// The selection that cold-launched the app via a notification tap, or null.
  /// Call once after [initialize] during startup.
  Future<NotifySelection?> launchSelection();
}

/// No-op implementation for tests and unsupported platforms.
final class NoopNotify implements INotify {
  const NoopNotify();

  @override
  Future<void> initialize({
    required List<NotifyChannel> channels,
    required void Function(NotifySelection selection) onSelect,
  }) async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<bool> isPermitted() async => false;

  @override
  Future<void> show(NotifyRequest request) async {}

  @override
  Future<void> scheduleAt(
    NotifyRequest request,
    DateTime when, {
    NotifyRepeat repeat = NotifyRepeat.none,
  }) async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<NotifySelection?> launchSelection() async => null;
}
