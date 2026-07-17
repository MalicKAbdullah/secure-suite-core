import 'package:core_backup/core_backup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AutoBackupPolicy', () {
    test('off is never due', () {
      expect(
        AutoBackupPolicy.isDue(
          interval: BackupInterval.off,
          lastBackupAt: null,
          now: DateTime(2026, 7, 17),
        ),
        isFalse,
      );
    });

    test('never-backed-up is due immediately', () {
      expect(
        AutoBackupPolicy.isDue(
          interval: BackupInterval.daily,
          lastBackupAt: null,
          now: DateTime(2026, 7, 17),
        ),
        isTrue,
      );
    });

    test('daily is not due before 24h, due after', () {
      final last = DateTime(2026, 7, 17, 8);
      expect(
        AutoBackupPolicy.isDue(
          interval: BackupInterval.daily,
          lastBackupAt: last,
          now: last.add(const Duration(hours: 23)),
        ),
        isFalse,
      );
      expect(
        AutoBackupPolicy.isDue(
          interval: BackupInterval.daily,
          lastBackupAt: last,
          now: last.add(const Duration(hours: 25)),
        ),
        isTrue,
      );
    });

    test('monthly clamps to short months (Jan 31 -> Feb 28)', () {
      final due = AutoBackupPolicy.nextDue(
        interval: BackupInterval.monthly,
        lastBackupAt: DateTime(2026, 1, 31, 9, 30),
      );
      expect(due, DateTime(2026, 2, 28, 9, 30));
    });

    test('BackupInterval.parse falls back to off', () {
      expect(BackupInterval.parse('weekly'), BackupInterval.weekly);
      expect(BackupInterval.parse(null), BackupInterval.off);
      expect(BackupInterval.parse('garbage'), BackupInterval.off);
    });
  });
}
