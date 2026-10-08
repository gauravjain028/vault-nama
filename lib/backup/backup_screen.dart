import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/asset_repository.dart';
import '../security/auto_lock.dart';
import 'backup_codec.dart';
import 'backup_files.dart';

/// Everything the backup screen needs besides the database.
class BackupTools {
  BackupTools({
    required this.codec,
    required this.files,
    required this.autoLock,
  });

  final BackupCodec codec;
  final BackupFiles files;
  final AutoLock autoLock;
}

/// Export all assets to a password-protected file, or restore from one.
/// Pops `true` after a restore so the caller reloads.
class BackupScreen extends StatefulWidget {
  const BackupScreen({
    super.key,
    required this.repository,
    required this.tools,
  });

  final AssetRepository repository;
  final BackupTools tools;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;
  bool _restored = false;

  static String _count(int n) => n == 1 ? '1 asset' : '$n assets';

  void _show(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _export() async {
    final password = await _askPassword(confirm: true);
    if (password == null) return;
    setState(() => _busy = true);
    try {
      final assets = await widget.repository.all();
      final bytes = await widget.tools.codec.encode(assets, password);
      final name =
          'vault-nama-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.vnbackup';
      final saved = await widget.tools.autoLock.whileExternal(
        () => widget.tools.files.save(name, bytes),
      );
      if (saved && mounted) {
        _show('Backup saved with ${_count(assets.length)}');
      }
    } on BackupException catch (e) {
      if (mounted) _show(e.message);
    } catch (e) {
      if (mounted) _show('Could not save the backup');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final bytes = await widget.tools.autoLock.whileExternal(
      () => widget.tools.files.pick(),
    );
    if (bytes == null || !mounted) return;
    final password = await _askPassword(confirm: false);
    if (password == null) return;
    setState(() => _busy = true);
    try {
      final assets = await widget.tools.codec.decode(bytes, password);
      if (!mounted) return;
      setState(() => _busy = false);
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Restore ${_count(assets.length)}?'),
          content: const Text(
            'Everything currently in the app will be replaced by the backup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await widget.repository.replaceAll(assets);
      _restored = true;
      if (mounted) _show('Restored ${_count(assets.length)}');
    } on BackupException catch (e) {
      if (mounted) _show(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _askPassword({required bool confirm}) => showDialog<String>(
    context: context,
    builder: (_) => _PasswordDialog(confirm: confirm),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_restored);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Backup and restore')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Your data lives only on this phone. Save a backup so you can '
              'move to a new phone or recover after losing this one.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The backup is locked with a password you choose. Keep it safe: '
              'without it the backup cannot be opened, by you or anyone else.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.save_alt),
              label: const Text('Save a backup'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _restore,
              icon: const Icon(Icons.restore),
              label: const Text('Restore from a backup'),
            ),
            if (_busy) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.confirm});

  /// Ask twice, for a new backup.
  final bool confirm;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _password = TextEditingController();
  final _again = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _password.text;
    if (widget.confirm && password.length < BackupCodec.minPasswordLength) {
      setState(
        () => _error = 'At least ${BackupCodec.minPasswordLength} characters',
      );
      return;
    }
    if (widget.confirm && password != _again.text) {
      setState(() => _error = "Passwords don't match");
      return;
    }
    if (password.isEmpty) return;
    Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.confirm ? 'Choose a backup password' : 'Backup password',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('backup-password'),
            controller: _password,
            autofocus: true,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: widget.confirm ? null : _error,
            ),
            onSubmitted: widget.confirm ? null : (_) => _submit(),
          ),
          if (widget.confirm)
            TextField(
              key: const Key('backup-password-again'),
              controller: _again,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password again',
                errorText: _error,
              ),
              onSubmitted: (_) => _submit(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('OK')),
      ],
    );
  }
}
