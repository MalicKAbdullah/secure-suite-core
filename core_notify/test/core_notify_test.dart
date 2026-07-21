import 'package:core_notify/core_notify.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoopNotify', () {
    const notify = NoopNotify();

    test('is safe to call and denies permission', () async {
      await notify.initialize(channels: const [], onSelect: (_) {});
      expect(await notify.requestPermission(), isFalse);
      expect(await notify.isPermitted(), isFalse);
      await notify.show(
        const NotifyRequest(id: 1, channelId: 'c', title: 't', body: 'b'),
      );
      await notify.scheduleAt(
        const NotifyRequest(id: 1, channelId: 'c', title: 't', body: 'b'),
        DateTime(2030),
        repeat: NotifyRepeat.daily,
      );
      await notify.cancel(1);
      await notify.cancelAll();
      expect(await notify.launchSelection(), isNull);
    });
  });

  test('channel carries its actions and importance', () {
    const channel = NotifyChannel(
      id: 'dose',
      name: 'Doses',
      importance: NotifyImportance.high,
      actions: [
        NotifyAction(id: 'take', title: 'Take'),
        NotifyAction(id: 'skip', title: 'Skip'),
      ],
    );
    expect(channel.actions.map((a) => a.id), ['take', 'skip']);
    expect(channel.importance, NotifyImportance.high);
  });
}
