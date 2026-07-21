/// Android channel importance / iOS interruption hint.
enum NotifyImportance { low, normal, high }

/// How a scheduled notification repeats.
enum NotifyRepeat { none, daily }

/// An action button on a notification.
///
/// Tapping an action always brings the app to the foreground and dismisses
/// the notification; the app applies the action through the `onSelect`
/// callback (or [INotify.launchSelection] on a cold start). This is the
/// reliable cross-OEM path — background-isolate broadcasts silently no-op on
/// many devices, leaving the notification stuck on screen.
class NotifyAction {
  const NotifyAction({required this.id, required this.title});

  final String id;
  final String title;
}

/// A notification channel (Android) / action category (iOS). One channel maps
/// to one iOS category, so its [actions] are declared once here and attached
/// to every notification posted on it.
class NotifyChannel {
  const NotifyChannel({
    required this.id,
    required this.name,
    this.description = '',
    this.importance = NotifyImportance.normal,
    this.actions = const <NotifyAction>[],
    this.timeSensitive = false,
  });

  final String id;
  final String name;
  final String description;
  final NotifyImportance importance;
  final List<NotifyAction> actions;

  /// iOS: post as a time-sensitive interruption (breaks through Focus).
  final bool timeSensitive;
}

/// A single notification to show now or schedule.
class NotifyRequest {
  const NotifyRequest({
    required this.id,
    required this.channelId,
    required this.title,
    required this.body,
    this.payload,
  });

  /// Stable integer id — reusing an id replaces the earlier notification.
  final int id;
  final String channelId;
  final String title;
  final String body;

  /// Opaque string handed back verbatim in [NotifySelection.payload] when the
  /// user taps the notification or one of its actions. Encode whatever the app
  /// needs to act on the tap (e.g. a JSON id).
  final String? payload;
}

/// What the user tapped: the body ([actionId] null) or a specific action.
class NotifySelection {
  const NotifySelection({this.actionId, this.payload});

  final String? actionId;
  final String? payload;
}
