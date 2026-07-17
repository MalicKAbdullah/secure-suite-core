import 'package:core_backup/src/auto_backup_policy.dart';
import 'package:core_backup/src/auto_backup_service.dart';
import 'package:core_theme/core_theme.dart';
import 'package:flutter/material.dart';

/// Drop-in Settings block for scheduled encrypted backups, shared across apps
/// for a consistent look: interval, folder, (optional) passphrase, status line
/// and "Back up now". Self-contained — no state-management dependency; give it
/// a [service] and a [producer].
class AutoBackupSection extends StatefulWidget {
  const AutoBackupSection({
    super.key,
    required this.service,
    required this.producer,
    this.description =
        'When you open the app, an encrypted backup is quietly written to your '
            'folder when one is due. Pick a Google Drive folder to keep backups '
            'synced to your Drive.',
    this.minPassphraseLength = 8,
  });

  final AutoBackupService service;
  final BackupProducer producer;
  final String description;
  final int minPassphraseLength;

  @override
  State<AutoBackupSection> createState() => _AutoBackupSectionState();
}

class _AutoBackupSectionState extends State<AutoBackupSection> {
  AutoBackupConfig? _config;
  bool _working = false;

  AutoBackupService get _service => widget.service;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final config = await _service.loadConfig();
    if (mounted) setState(() => _config = config);
  }

  Future<void> _setInterval(BackupInterval interval) async {
    final config = _config;
    if (config == null) return;
    if (interval != BackupInterval.off) {
      if (_service.requiresPassphrase && !config.hasPassphrase) {
        final passphrase = await _askPassphrase();
        if (passphrase == null) return;
        await _service.setPassphrase(passphrase);
      }
      if (config.folderUri == null) {
        final picked = await _service.pickFolder();
        if (!picked) return;
      }
    }
    await _service.setInterval(interval);
    await _reload();
  }

  Future<void> _pickFolder() async {
    await _service.pickFolder();
    await _reload();
  }

  Future<void> _editPassphrase() async {
    final passphrase = await _askPassphrase();
    if (passphrase != null) {
      await _service.setPassphrase(passphrase);
      await _reload();
    }
  }

  Future<void> _backupNow() async {
    setState(() => _working = true);
    final result = await _service.backupNow(widget.producer);
    await _reload();
    if (!mounted) return;
    setState(() => _working = false);
    final message = switch (result) {
      BackupWritten(:final fileName) => 'Backed up as $fileName.',
      BackupFailed(:final message) => message,
      BackupSkipped() => 'Nothing to back up right now.',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _askPassphrase() => showDialog<String>(
        context: context,
        builder: (_) =>
            _PassphraseDialog(minLength: widget.minPassphraseLength),
      );

  String _relative(DateTime time, DateTime now) {
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final config = _config;
    if (config == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final enabled = config.interval != BackupInterval.off;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SegmentedButton<BackupInterval>(
            segments: [
              for (final interval in BackupInterval.values)
                ButtonSegment(value: interval, label: Text(interval.label)),
            ],
            selected: {config.interval},
            onSelectionChanged: (s) => _setInterval(s.first),
          ),
        ),
        if (enabled) ...[
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('Backup folder'),
            subtitle: Text(
              config.folderName ?? 'Not chosen yet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickFolder,
          ),
          if (_service.requiresPassphrase)
            ListTile(
              leading: const Icon(Icons.key_outlined),
              title: const Text('Backup passphrase'),
              subtitle: Text(config.hasPassphrase ? 'Set' : 'Not set'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _editPassphrase,
            ),
          ListTile(
            leading: Icon(
              config.lastError == null
                  ? Icons.cloud_done_outlined
                  : Icons.cloud_off_outlined,
              color: config.lastError == null
                  ? null
                  : AppColors.warning(brightness),
            ),
            title: Text(
              config.lastBackupAt == null
                  ? 'No backup yet'
                  : 'Last backup: '
                      '${_relative(config.lastBackupAt!, DateTime.now())}'
                      '${config.folderName == null ? '' : ' • ${config.folderName}'}',
            ),
            subtitle: config.lastError == null
                ? null
                : Text(
                    config.lastError!,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.warning(brightness)),
                  ),
            trailing: _working
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: config.isReady ? _backupNow : null,
                    child: const Text('Back up now'),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              widget.description,
              style: AppTextStyles.caption
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}

class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog({required this.minLength});

  final int minLength;

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  final _controller = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.length < widget.minLength) {
      setState(() => _error = 'Use at least ${widget.minLength} characters.');
      return;
    }
    if (_controller.text != _confirmController.text) {
      setState(() => _error = 'The passphrases do not match.');
      return;
    }
    Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Backup passphrase'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Backups are encrypted with this passphrase. You will need it to '
            'restore — keep it somewhere safe.',
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Passphrase'),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _confirmController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Confirm passphrase',
              errorText: _error,
            ),
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
