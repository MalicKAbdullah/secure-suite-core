import 'dart:convert';
import 'dart:typed_data';

import 'package:core_backup/core_backup.dart';
import 'package:core_storage/core_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory secure storage.
final class _FakeStorage implements ISecureStorage {
  final Map<String, String> _m = {};
  @override
  Future<void> write({required String key, required String value}) async =>
      _m[key] = value;
  @override
  Future<String?> read({required String key}) async => _m[key];
  @override
  Future<void> delete({required String key}) async => _m.remove(key);
  @override
  Future<void> deleteAll() async => _m.clear();
  @override
  Future<Map<String, String>> readAll() async => Map.of(_m);
}

/// In-memory backup folder that records written files.
final class _FakeFolder implements IBackupFolder {
  final Map<String, Uint8List> files = {};
  bool failWrites = false;
  @override
  Future<BackupFolderSelection?> pickFolder() async =>
      const BackupFolderSelection(uri: 'fake://f', name: 'F');
  @override
  Future<void> writeFile({
    required String folderUri,
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (failWrites) throw Exception('unavailable');
    files[fileName] = bytes;
  }
}

void main() {
  late _FakeStorage storage;
  late _FakeFolder folder;
  late DateTime now;
  late AutoBackupService service;

  Future<Uint8List> produce(String? pass) async =>
      Uint8List.fromList(utf8.encode('data:$pass'));

  setUp(() {
    storage = _FakeStorage();
    folder = _FakeFolder();
    now = DateTime(2026, 7, 20, 9);
    service = AutoBackupService(
      storage: storage,
      folder: folder,
      keyPrefix: 'test',
      fileLabel: 'Test',
      fileExtension: 'tbackup',
      now: () => now,
    );
  });

  Future<void> configure() async {
    await service.setInterval(BackupInterval.daily);
    await service.pickFolder();
    await service.setPassphrase('secret-pass');
  }

  test('runIfDue skips when not configured', () async {
    expect(await service.runIfDue(produce), isA<BackupSkipped>());
    expect(folder.files, isEmpty);
  });

  test('runIfDue writes when due, then skips until the next interval', () async {
    await configure();
    final first = await service.runIfDue(produce);
    expect(first, isA<BackupWritten>());
    expect(folder.files.keys.single, 'Test-backup-2026-07-20.tbackup');
    expect(utf8.decode(folder.files.values.single), 'data:secret-pass');

    // Same day → not due again.
    expect(await service.runIfDue(produce), isA<BackupSkipped>());

    // Next day → due again.
    now = now.add(const Duration(days: 1));
    expect(await service.runIfDue(produce), isA<BackupWritten>());
  });

  test('backupNow always writes and clears prior error', () async {
    await configure();
    expect(await service.backupNow(produce), isA<BackupWritten>());
  });

  test('a folder failure is reported and recorded, never thrown', () async {
    await configure();
    folder.failWrites = true;
    final result = await service.backupNow(produce);
    expect(result, isA<BackupFailed>());
    expect((await service.loadConfig()).lastError, isNotNull);
  });
}
