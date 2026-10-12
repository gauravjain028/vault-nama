import 'package:flutter/material.dart';

import '../data/asset.dart';
import '../ui/theme.dart';

/// Grid of categories to pick from when adding an asset.
Future<AssetType?> pickAssetType(BuildContext context) =>
    showModalBottomSheet<AssetType>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What would you like to add?',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final type in AssetType.values)
                    _TypeTile(
                      type: type,
                      onTap: () => Navigator.pop(context, type),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.type, required this.onTap});

  final AssetType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CategoryAvatar(type, size: 44),
              const SizedBox(height: 8),
              Text(
                type.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
