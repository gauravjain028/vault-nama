import 'package:flutter/material.dart';

import '../data/asset.dart';
import '../ui/asset_display.dart';
import '../ui/theme.dart';
import '../util/money.dart';

/// Every asset, searchable and filterable by category.
class AssetsTab extends StatefulWidget {
  const AssetsTab({super.key, required this.assets, required this.onOpen});

  final List<Asset> assets;
  final void Function(Asset asset) onOpen;

  @override
  State<AssetsTab> createState() => _AssetsTabState();
}

class _AssetsTabState extends State<AssetsTab> {
  AssetType? _filter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final present = {for (final a in widget.assets) a.type};
    final filter = present.contains(_filter) ? _filter : null;
    final query = _query.trim().toLowerCase();
    final shown = [
      for (final a in widget.assets)
        if ((filter == null || a.type == filter) &&
            (query.isEmpty || searchText(a).contains(query)))
          a,
    ];
    final byType = <AssetType, List<Asset>>{};
    for (final a in shown) {
      byType.putIfAbsent(a.type, () => []).add(a);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              key: const Key('asset-search'),
              decoration: const InputDecoration(
                hintText: 'Search name, bank, policy number…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
        if (present.length > 1)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _chip(
                    'All',
                    filter == null,
                    () => setState(() => _filter = null),
                  ),
                  for (final type in AssetType.values)
                    if (present.contains(type))
                      _chip(
                        type.label,
                        filter == type,
                        () => setState(
                          () => _filter = filter == type ? null : type,
                        ),
                        avatar: Icon(
                          iconFor(type),
                          size: 18,
                          color: categoryColor(type, theme.brightness),
                        ),
                      ),
                ],
              ),
            ),
          ),
        if (widget.assets.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No assets yet. Tap + to add one.')),
          )
        else if (shown.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('Nothing matches your search.')),
          ),
        for (final type in AssetType.values)
          if (byType[type] case final group?)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _Group(type: type, assets: group, onOpen: widget.onOpen),
              ),
            ),
        const SliverToBoxAdapter(child: SizedBox(height: 96)),
      ],
    );
  }

  Widget _chip(
    String label,
    bool selected,
    VoidCallback onTap, {
    Widget? avatar,
  }) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: FilterChip(
      label: Text(label),
      avatar: selected ? null : avatar,
      selected: selected,
      onSelected: (_) => onTap(),
    ),
  );
}

class _Group extends StatelessWidget {
  const _Group({
    required this.type,
    required this.assets,
    required this.onOpen,
  });

  final AssetType type;
  final List<Asset> assets;
  final void Function(Asset) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = assets.fold(0, (sum, a) => sum + a.valuePaise);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  type.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (total > 0)
                Text(
                  formatCompact(total),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (final (i, asset) in assets.indexed) ...[
                if (i > 0) const Divider(height: 1, indent: 72),
                ListTile(
                  leading: CategoryAvatar(type),
                  title: Text(
                    asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: subtitleFor(asset) == null
                      ? null
                      : Text(
                          subtitleFor(asset)!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                  trailing: asset.valuePaise == 0
                      ? const Icon(Icons.chevron_right)
                      : Text(
                          formatPaise(asset.valuePaise),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                  onTap: () => onOpen(asset),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
