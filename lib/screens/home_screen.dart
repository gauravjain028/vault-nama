import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/asset.dart';
import '../data/asset_repository.dart';
import '../util/money.dart';
import 'asset_form_screen.dart';

/// Lists saved assets grouped by type, with add and edit.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repository, required this.onLock});

  final AssetRepository repository;
  final VoidCallback onLock;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Asset>> _assets = widget.repository.all();

  void _reload() {
    setState(() {
      _assets = widget.repository.all();
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

  Future<void> _addAsset() async {
    final type = await showModalBottomSheet<AssetType>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final type in AssetType.values)
              ListTile(
                leading: Icon(iconFor(type)),
                title: Text(type.label),
                onTap: () => Navigator.pop(context, type),
              ),
          ],
        ),
      ),
    );
    if (type != null) await _openForm(type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault Nama'),
        actions: [
          IconButton(
            tooltip: 'Lock',
            icon: const Icon(Icons.lock_outline),
            onPressed: widget.onLock,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAsset,
        icon: const Icon(Icons.add),
        label: const Text('Add asset'),
      ),
      body: FutureBuilder<List<Asset>>(
        future: _assets,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final assets = snapshot.data!;
          if (assets.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No assets yet.\nTap "Add asset" to record a policy, '
                  'deposit, gold or property.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final byType = <AssetType, List<Asset>>{};
          for (final asset in assets) {
            byType.putIfAbsent(asset.type, () => []).add(asset);
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              for (final type in AssetType.values)
                if (byType[type] case final group?) ...[
                  _SectionHeader(type: type),
                  for (final asset in group)
                    ListTile(
                      leading: Icon(iconFor(type)),
                      title: Text(asset.name),
                      subtitle: subtitleFor(asset) == null
                          ? null
                          : Text(subtitleFor(asset)!),
                      trailing: asset.valuePaise == 0
                          ? null
                          : Text(formatPaise(asset.valuePaise)),
                      onTap: () => _openForm(type, asset),
                    ),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.type});

  final AssetType type;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        type.label,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

IconData iconFor(AssetType type) => switch (type) {
  AssetType.lifeInsurance => Icons.shield_outlined,
  AssetType.healthInsurance => Icons.local_hospital_outlined,
  AssetType.termInsurance => Icons.verified_user_outlined,
  AssetType.gold => Icons.workspace_premium_outlined,
  AssetType.silver => Icons.circle_outlined,
  AssetType.fixedDeposit => Icons.savings_outlined,
  AssetType.bankAccount => Icons.account_balance_outlined,
  AssetType.realEstate => Icons.home_work_outlined,
  AssetType.other => Icons.category_outlined,
};

/// One short line under the asset's name: the most useful identifying
/// detail for its type.
String? subtitleFor(Asset asset) {
  final d = asset.details;
  final parts = switch (asset.type) {
    AssetType.lifeInsurance ||
    AssetType.healthInsurance ||
    AssetType.termInsurance => [d['insurer'], d['policyNumber']],
    AssetType.gold || AssetType.silver => [
      d['weightGrams'] == null ? null : '${d['weightGrams']} g',
      d['purity'],
      d['form'],
    ],
    AssetType.fixedDeposit => [
      d['bank'],
      d['interestRate'] == null ? null : '${d['interestRate']}%',
      _matures(d['maturityDate']),
    ],
    AssetType.bankAccount => [d['bank'], d['accountType']],
    AssetType.realEstate => [d['propertyType'], d['area']],
    AssetType.other => [d['notes']],
  };
  final text = parts.whereType<Object>().map((p) => '$p').join(' · ');
  return text.isEmpty ? null : text;
}

String? _matures(Object? stored) {
  final date = stored is String ? DateTime.tryParse(stored) : null;
  return date == null
      ? null
      : 'matures ${DateFormat('d MMM yyyy').format(date)}';
}
