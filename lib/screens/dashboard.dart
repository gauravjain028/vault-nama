import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/asset.dart';
import '../data/summary.dart';
import '../reminders/due_dates.dart';
import '../util/money.dart';

/// Net worth, value by category and insurance cover.
class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.summary});

  final AssetSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranked = summary.ranked;
    final largest = ranked.isEmpty ? 1 : ranked.first.value;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total value', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              formatPaise(summary.netWorthPaise),
              key: const Key('net-worth'),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (ranked.isNotEmpty) const SizedBox(height: 16),
            for (final entry in ranked)
              _CategoryBar(
                label: entry.key.label,
                paise: entry.value,
                fraction: entry.value / largest,
                share: summary.netWorthPaise == 0
                    ? 0
                    : entry.value / summary.netWorthPaise,
              ),
            if (summary.lifeCoverPaise > 0 || summary.healthCoverPaise > 0) ...[
              const Divider(height: 24),
              if (summary.lifeCoverPaise > 0)
                _CoverLine('Life cover', summary.lifeCoverPaise),
              if (summary.healthCoverPaise > 0)
                _CoverLine('Health cover', summary.healthCoverPaise),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.label,
    required this.paise,
    required this.fraction,
    required this.share,
  });

  final String label;
  final int paise;

  /// Bar length relative to the largest category.
  final double fraction;

  /// Share of the total value.
  final double share;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Semantics(
      label: '$label ${formatPaise(paise)}, ${(share * 100).round()} percent',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label)),
                Text(formatPaise(paise)),
                SizedBox(
                  width: 44,
                  child: Text(
                    '${(share * 100).round()}%',
                    textAlign: TextAlign.end,
                    style: muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fraction.clamp(0.02, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverLine extends StatelessWidget {
  const _CoverLine(this.label, this.paise);

  final String label;
  final int paise;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(formatPaise(paise)),
        ],
      ),
    );
  }
}

/// The next few premiums, renewals and maturities.
class ComingUpCard extends StatelessWidget {
  const ComingUpCard({super.key, required this.events, required this.onTap});

  final List<DueEvent> events;
  final void Function(Asset asset) onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = DateFormat('d MMM');
    final today = DateTime.now();
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Coming up in the next 60 days',
              style: theme.textTheme.labelLarge,
            ),
          ),
          for (final e in events)
            ListTile(
              dense: true,
              leading: const Icon(Icons.event_outlined),
              title: Text('${e.label}: ${e.asset.name}'),
              subtitle: Text(_daysAway(e.date, today)),
              trailing: Text(shown.format(e.date)),
              onTap: () => onTap(e.asset),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static String _daysAway(DateTime date, DateTime now) {
    final days = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    return switch (days) {
      0 => 'Today',
      1 => 'Tomorrow',
      _ => 'In $days days',
    };
  }
}
