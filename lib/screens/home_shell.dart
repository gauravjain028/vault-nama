import 'package:flutter/material.dart';

import '../backup/backup_screen.dart';
import '../data/asset.dart';
import '../data/asset_repository.dart';
import '../reminders/reminders.dart';
import 'add_asset_sheet.dart';
import 'asset_form_screen.dart';
import 'assets_tab.dart';
import 'overview_tab.dart';
import 'reminders_tab.dart';
import 'settings_tab.dart';

/// The unlocked app: Overview, Assets, Reminders and Settings tabs over one
/// loaded copy of the assets.
class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.repository,
    required this.reminders,
    required this.backupTools,
    required this.onLock,
  });

  final AssetRepository repository;
  final Reminders reminders;
  final BackupTools backupTools;
  final VoidCallback onLock;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _titles = ['Overview', 'Assets', 'Reminders', 'Settings'];

  int _tab = 0;
  late Future<List<Asset>> _assets = _load();

  /// Loads assets and brings scheduled reminders in line with them.
  Future<List<Asset>> _load() async {
    final assets = await widget.repository.all();
    widget.reminders.reschedule(assets);
    return assets;
  }

  void _reload() {
    setState(() {
      _assets = _load();
    });
  }

  Future<void> _openForm(AssetType type, [Asset? existing]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AssetFormScreen(
          repository: widget.repository,
          type: type,
          existing: existing,
        ),
      ),
    );
    if (changed == true) _reload();
  }

  Future<void> _add() async {
    final type = await pickAssetType(context);
    if (type != null) await _openForm(type);
  }

  Future<void> _openBackup() async {
    final restored = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BackupScreen(
          repository: widget.repository,
          tools: widget.backupTools,
        ),
      ),
    );
    if (restored == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'Vault Nama' : _titles[_tab]),
        actions: [
          IconButton(
            tooltip: 'Lock',
            icon: const Icon(Icons.lock_outline),
            onPressed: widget.onLock,
          ),
        ],
      ),
      floatingActionButton: _tab <= 1
          ? FloatingActionButton.extended(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: const Text('Add asset'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.wallet_outlined),
            selectedIcon: Icon(Icons.wallet),
            label: 'Assets',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Reminders',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      body: FutureBuilder<List<Asset>>(
        future: _assets,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final assets = snapshot.data!;
          void open(Asset a) => _openForm(a.type, a);
          return switch (_tab) {
            0 => OverviewTab(
              assets: assets,
              onOpenAsset: open,
              onSeeAllReminders: () => setState(() => _tab = 2),
              onAdd: _add,
            ),
            1 => AssetsTab(assets: assets, onOpen: open),
            2 => RemindersTab(assets: assets, onOpen: open),
            _ => SettingsTab(onBackup: _openBackup, onLock: widget.onLock),
          };
        },
      ),
    );
  }
}
