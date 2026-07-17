import 'package:core_backup/src/auto_backup_policy.dart';
import 'package:core_backup/src/backup_folder.dart';
import 'package:core_storage/core_storage.dart';
import 'package:flutter/foundation.dart';

/// Produces the bytes to back up, encrypted however the app sees fit. Receives
/// the stored backup [passphrase] (null when the app opted out of one).
typedef BackupProducer = Future<Uint8List> Function(String? passphrase);

/// Current auto-backup configuration and status, as shown in Settings.
@immutable
final class AutoBackupConfig {
  const AutoBackupConfig({
    required this.interval,
    required this.folderUri,
    required this.folderName,
    required this.hasPassphrase,
    required this.requiresPassphrase,
    required this.lastBackupAt,
    required this.lastError,
  });

  final BackupInterval interval;
  final String? folderUri;
  final String? folderName;
  final bool hasPassphrase;
  final bool requiresPassphrase;
  final DateTime? lastBackupAt;
  final String? lastError;

  bool get isReady =>
      interval != BackupInterval.off &&
      folderUri != null &&
      (!requiresPassphrase || hasPassphrase);
}

sealed class AutoBackupRunResult {
  const AutoBackupRunResult();
}

final class BackupSkipped extends AutoBackupRunResult {
  const BackupSkipped();
}

final class BackupWritten extends AutoBackupRunResult {
  const BackupWritten({required this.fileName});

  final String fileName;
}

final class BackupFailed extends AutoBackupRunResult {
  const BackupFailed({required this.message});

  final String message;
}

/// Data-agnostic scheduled-backup engine, shared across Secure Suite apps.
///
/// The app supplies a [BackupProducer] that returns the bytes to write (already
/// encrypted as the app prefers); this service owns scheduling, the destination
/// folder, the stored passphrase, and status. Failures never throw out of
/// [runIfDue]/[backupNow] — they are recorded in [AutoBackupConfig.lastError].
///
/// Storage keys are namespaced by [keyPrefix] so sibling apps sharing the core
/// packages never collide.
final class AutoBackupService {
  AutoBackupService({
    required ISecureStorage storage,
    required IBackupFolder folder,
    required String keyPrefix,
    required String fileLabel,
    required String fileExtension,
    this.requiresPassphrase = true,
    DateTime Function()? now,
  })  : _storage = storage,
        _folder = folder,
        _keyPrefix = keyPrefix,
        _fileLabel = fileLabel,
        _fileExtension = fileExtension,
        _now = now ?? DateTime.now;

  final ISecureStorage _storage;
  final IBackupFolder _folder;
  final String _keyPrefix;
  final String _fileLabel;
  final String _fileExtension;
  final DateTime Function() _now;

  /// Whether a backup passphrase is required before backups can run.
  final bool requiresPassphrase;

  String get _kInterval => '${_keyPrefix}_backup_interval';
  String get _kFolderUri => '${_keyPrefix}_backup_folder_uri';
  String get _kFolderName => '${_keyPrefix}_backup_folder_name';
  String get _kPassphrase => '${_keyPrefix}_backup_passphrase';
  String get _kLastAt => '${_keyPrefix}_backup_last_at';
  String get _kLastError => '${_keyPrefix}_backup_last_error';

  Future<AutoBackupConfig> loadConfig() async {
    final lastAtRaw = await _storage.read(key: _kLastAt);
    return AutoBackupConfig(
      interval: BackupInterval.parse(await _storage.read(key: _kInterval)),
      folderUri: await _storage.read(key: _kFolderUri),
      folderName: await _storage.read(key: _kFolderName),
      hasPassphrase: await _storage.read(key: _kPassphrase) != null,
      requiresPassphrase: requiresPassphrase,
      lastBackupAt: lastAtRaw == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(int.parse(lastAtRaw)),
      lastError: await _storage.read(key: _kLastError),
    );
  }

  Future<void> setInterval(BackupInterval interval) =>
      _storage.write(key: _kInterval, value: interval.name);

  Future<void> setFolder(BackupFolderSelection folder) async {
    await _storage.write(key: _kFolderUri, value: folder.uri);
    await _storage.write(key: _kFolderName, value: folder.name);
  }

  Future<void> setPassphrase(String passphrase) =>
      _storage.write(key: _kPassphrase, value: passphrase);

  /// Opens the system folder picker and stores the selection. Returns false
  /// when the user cancels.
  Future<bool> pickFolder() async {
    final selection = await _folder.pickFolder();
    if (selection == null) return false;
    await setFolder(selection);
    return true;
  }

  /// Runs a backup if one is due per the schedule. Never throws.
  Future<AutoBackupRunResult> runIfDue(BackupProducer produce) async {
    final config = await loadConfig();
    if (!config.isReady) return const BackupSkipped();
    final due = AutoBackupPolicy.isDue(
      interval: config.interval,
      lastBackupAt: config.lastBackupAt,
      now: _now(),
    );
    if (!due) return const BackupSkipped();
    return _run(produce, config);
  }

  /// Runs a backup immediately (Settings → "Back up now"). Never throws.
  Future<AutoBackupRunResult> backupNow(BackupProducer produce) async {
    final config = await loadConfig();
    if (config.folderUri == null ||
        (requiresPassphrase && !config.hasPassphrase)) {
      return const BackupFailed(
        message: 'Choose a backup folder first.',
      );
    }
    return _run(produce, config);
  }

  Future<AutoBackupRunResult> _run(
    BackupProducer produce,
    AutoBackupConfig config,
  ) async {
    try {
      final passphrase = await _storage.read(key: _kPassphrase);
      if (requiresPassphrase && passphrase == null) {
        return const BackupFailed(message: 'Backup passphrase is not set.');
      }
      final now = _now();
      final bytes = await produce(passphrase);
      final fileName = fileNameFor(now);
      await _folder.writeFile(
        folderUri: config.folderUri!,
        fileName: fileName,
        bytes: bytes,
      );
      await _storage.write(
        key: _kLastAt,
        value: now.millisecondsSinceEpoch.toString(),
      );
      await _storage.delete(key: _kLastError);
      return BackupWritten(fileName: fileName);
    } catch (_) {
      const message = 'Could not write the backup. '
          'Check that the folder is still available.';
      await _storage.write(key: _kLastError, value: message);
      return const BackupFailed(message: message);
    }
  }

  String fileNameFor(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '$_fileLabel-backup-${date.year}-${two(date.month)}-${two(date.day)}'
        '.$_fileExtension';
  }
}
