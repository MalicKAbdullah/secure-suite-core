import 'package:core_notify/src/notify.dart';
import 'package:core_notify/src/notify_models.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// flutter_local_notifications-backed [INotify].
///
/// Never construct in tests — it talks to platform channels.
final class LocalNotify implements INotify {
  LocalNotify({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final Map<String, NotifyChannel> _channels = {};

  @override
  Future<void> initialize({
    required List<NotifyChannel> channels,
    required void Function(NotifySelection selection) onSelect,
  }) async {
    for (final c in channels) {
      _channels[c.id] = c;
    }

    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(
        tz.getLocation(await FlutterTimezone.getLocalTimezone()),
      );
    } catch (_) {
      // Keep the package default (UTC) if the lookup fails.
    }

    final settings = InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        notificationCategories: [
          for (final c in channels)
            if (c.actions.isNotEmpty)
              DarwinNotificationCategory(
                c.id,
                actions: [
                  for (final a in c.actions)
                    DarwinNotificationAction.plain(a.id, a.title),
                ],
              ),
        ],
      ),
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (r) =>
          onSelect(NotifySelection(actionId: r.actionId, payload: r.payload)),
    );

    // Create Android channels up front so importance is stable.
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      for (final c in channels) {
        await android.createNotificationChannel(
          AndroidNotificationChannel(
            c.id,
            c.name,
            description: c.description,
            importance: _androidImportance(c.importance),
          ),
        );
      }
    }
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  @override
  Future<bool> isPermitted() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  @override
  Future<void> show(NotifyRequest request) => _plugin.show(
        request.id,
        request.title,
        request.body,
        _details(request.channelId),
        payload: request.payload,
      );

  @override
  Future<void> scheduleAt(
    NotifyRequest request,
    DateTime when, {
    NotifyRepeat repeat = NotifyRepeat.none,
  }) {
    return _plugin.zonedSchedule(
      request.id,
      request.title,
      request.body,
      tz.TZDateTime.from(when, tz.local),
      _details(request.channelId),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents:
          repeat == NotifyRepeat.daily ? DateTimeComponents.time : null,
      payload: request.payload,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<NotifySelection?> launchSelection() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    final r = details.notificationResponse;
    if (r == null) return null;
    return NotifySelection(actionId: r.actionId, payload: r.payload);
  }

  NotificationDetails _details(String channelId) {
    final c = _channels[channelId];
    final actions = c?.actions ?? const <NotifyAction>[];
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        c?.name ?? channelId,
        channelDescription: c?.description,
        importance:
            _androidImportance(c?.importance ?? NotifyImportance.normal),
        priority:
            (c?.importance ?? NotifyImportance.normal) == NotifyImportance.high
                ? Priority.high
                : Priority.defaultPriority,
        actions: [
          for (final a in actions)
            // Opening the app is the reliable path; cancelNotification
            // defaults to true, so the alert clears on tap.
            AndroidNotificationAction(
              a.id,
              a.title,
              showsUserInterface: true,
            ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: actions.isNotEmpty ? channelId : null,
        interruptionLevel: (c?.timeSensitive ?? false)
            ? InterruptionLevel.timeSensitive
            : null,
      ),
    );
  }

  Importance _androidImportance(NotifyImportance i) => switch (i) {
        NotifyImportance.low => Importance.low,
        NotifyImportance.normal => Importance.defaultImportance,
        NotifyImportance.high => Importance.high,
      };
}
