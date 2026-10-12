import 'package:flutter/material.dart';

/// Backup, lock and a plain statement of how data is kept.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key, required this.onBackup, required this.onLock});

  final VoidCallback onBackup;
  final VoidCallback onLock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.import_export),
                title: const Text('Backup and restore'),
                subtitle: const Text('Save an encrypted copy, or restore one'),
                trailing: const Icon(Icons.chevron_right),
                onTap: onBackup,
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Lock now'),
                onTap: onLock,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Your data stays here',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Vault Nama works fully offline. Your records are encrypted on '
                  'this phone and never sent anywhere. The app locks whenever you '
                  'leave it, and screenshots are blocked.',
                  style: muted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
