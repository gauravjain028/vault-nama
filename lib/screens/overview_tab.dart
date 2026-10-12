import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/asset.dart';
import '../data/cash_flow.dart';
import '../data/summary.dart';
import '../reminders/due_dates.dart';
import '../ui/theme.dart';
import '../util/money.dart';

/// The dashboard: total value, where it sits, cover, and what's due.
class OverviewTab extends StatelessWidget {
  const OverviewTab({
    super.key,
    required this.assets,
    required this.onOpenAsset,
    required this.onSeeAllReminders,
    required this.onAdd,
  });

  final List<Asset> assets;
  final void Function(Asset asset) onOpenAsset;
  final VoidCallback onSeeAllReminders;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) return _Welcome(onAdd: onAdd);
    final summary = AssetSummary(assets);
    final today = DateTime.now();
    final upcoming = dueEvents(
      assets,
      today: today,
      until: today.add(const Duration(days: 60)),
    );
    final premiums = premiumsByMonth(assets, today: today);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        _NetWorthCard(summary: summary, count: assets.length),
        if (summary.byType.isNotEmpty) ...[
          const SizedBox(height: 12),
          _AllocationCard(summary: summary),
        ],
        if (summary.lifeCoverPaise > 0 || summary.healthCoverPaise > 0) ...[
          const SizedBox(height: 12),
          _CoverRow(summary: summary),
        ],
        const SizedBox(height: 12),
        _UpcomingCard(
          events: upcoming.take(3).toList(),
          total: upcoming.length,
          onOpenAsset: onOpenAsset,
          onSeeAll: onSeeAllReminders,
        ),
        if (premiums.any((p) => p > 0)) ...[
          const SizedBox(height: 12),
          _PremiumsCard(premiums: premiums, start: today),
        ],
      ],
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Your assets, in one private place',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your policies, deposits, gold and property. Everything stays '
              'encrypted on this phone.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add your first asset'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.summary, required this.count});

  final AssetSummary summary;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final words = amountInWords(summary.netWorthPaise);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, Colors.black, 0.35)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total value',
            style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatPaise(summary.netWorthPaise),
              key: const Key('net-worth'),
              style: TextStyle(
                color: scheme.onPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [?words, '$count ${count == 1 ? 'asset' : 'assets'}'].join(' · '),
            style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}

/// Donut of value by category with a legend that names every slice with its
/// value and share, so colour is never the only cue.
class _AllocationCard extends StatefulWidget {
  const _AllocationCard({required this.summary});

  final AssetSummary summary;

  @override
  State<_AllocationCard> createState() => _AllocationCardState();
}

class _AllocationCardState extends State<_AllocationCard> {
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ranked = widget.summary.ranked;
    final total = widget.summary.netWorthPaise;
    final touched = _touched == null || _touched! >= ranked.length
        ? null
        : ranked[_touched!];
    return SectionCard(
      title: 'Where your money is',
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 62,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) => setState(() {
                        _touched = event.isInterestedForInteractions
                            ? response?.touchedSection?.touchedSectionIndex
                            : null;
                        if (_touched == -1) _touched = null;
                      }),
                    ),
                    sections: [
                      for (final (i, entry) in ranked.indexed)
                        PieChartSectionData(
                          value: entry.value.toDouble(),
                          color: categoryColor(entry.key, theme.brightness),
                          radius: i == _touched ? 34 : 28,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      touched == null ? 'Total' : _shortLabel(touched.key),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      formatCompact(touched?.value ?? total),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (touched != null)
                      Text(
                        _percent(touched.value, total),
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final (i, entry) in ranked.indexed)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _touched = _touched == i ? null : i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: categoryColor(entry.key, theme.brightness),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.key.label,
                        style: i == _touched
                            ? const TextStyle(fontWeight: FontWeight.w600)
                            : null,
                      ),
                    ),
                    Text(formatPaise(entry.value)),
                    SizedBox(
                      width: 48,
                      child: Text(
                        _percent(entry.value, total),
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _percent(int part, int total) {
    final p = part * 100 / total;
    return p > 0 && p < 1 ? '<1%' : '${p.round()}%';
  }

  static String _shortLabel(AssetType type) => switch (type) {
    AssetType.metal => 'Metals',
    AssetType.lifeInsurance => 'Life insurance',
    _ => type.label,
  };
}

class _CoverRow extends StatelessWidget {
  const _CoverRow({required this.summary});

  final AssetSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (summary.lifeCoverPaise > 0)
          Expanded(
            child: _StatTile(
              icon: Icons.shield_outlined,
              label: 'Life cover',
              value: summary.lifeCoverPaise,
            ),
          ),
        if (summary.lifeCoverPaise > 0 && summary.healthCoverPaise > 0)
          const SizedBox(width: 12),
        if (summary.healthCoverPaise > 0)
          Expanded(
            child: _StatTile(
              icon: Icons.health_and_safety_outlined,
              label: 'Health cover',
              value: summary.healthCoverPaise,
            ),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            formatCompact(value),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.events,
    required this.total,
    required this.onOpenAsset,
    required this.onSeeAll,
  });

  final List<DueEvent> events;
  final int total;
  final void Function(Asset) onOpenAsset;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Coming up',
      trailing: TextButton(onPressed: onSeeAll, child: const Text('See all')),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: events.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Nothing due in the next 60 days.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              children: [
                for (final e in events)
                  DueEventTile(event: e, onTap: () => onOpenAsset(e.asset)),
              ],
            ),
    );
  }
}

/// A premium, renewal or maturity with a date badge.
class DueEventTile extends StatelessWidget {
  const DueEventTile({super.key, required this.event, required this.onTap});

  final DueEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = daysUntil(event.date);
    final soon = days <= 7;
    final amount =
        event.asset.details[switch (event.label) {
          'FD matures' => 'maturityAmount',
          'Premium due' || 'Renewal due' => 'premium',
          _ => '',
        }];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        width: 48,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: soon
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('MMM').format(event.date).toUpperCase(),
              style: theme.textTheme.labelSmall,
            ),
            Text(
              '${event.date.day}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      title: Text(
        event.asset.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('${event.label} · ${_relative(days)}'),
      trailing: amount is int ? Text(formatCompact(amount)) : null,
    );
  }

  static String _relative(int days) => switch (days) {
    0 => 'today',
    1 => 'tomorrow',
    _ => 'in $days days',
  };
}

int daysUntil(DateTime date) {
  final now = DateTime.now();
  return DateTime(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
}

/// Bars of premiums payable per month for the next 12 months, one hue.
class _PremiumsCard extends StatelessWidget {
  const _PremiumsCard({required this.premiums, required this.start});

  final List<int> premiums;
  final DateTime start;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = premiums.fold(0, (a, b) => a + b);
    final peak = premiums.reduce((a, b) => a > b ? a : b);
    final month = DateFormat('MMM');
    final monthYear = DateFormat('MMMM yyyy');
    DateTime monthAt(int i) => DateTime(start.year, start.month + i);
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return SectionCard(
      title: 'Premiums, next 12 months',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatPaise(total),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text('in total', style: muted),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: peak * 1.15,
                alignment: BarChartAlignment.spaceBetween,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: peak / 2,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: peak / 2,
                      // Gridline values only, not the padded top of the axis.
                      getTitlesWidget: (value, meta) =>
                          value == 0 || value == meta.max
                          ? const SizedBox.shrink()
                          : Text(formatCompact(value.round()), style: muted),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          month.format(monthAt(value.toInt()))[0],
                          style: muted,
                        ),
                      ),
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => scheme.inverseSurface,
                    getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                      '${monthYear.format(monthAt(group.x))}\n',
                      TextStyle(color: scheme.onInverseSurface, fontSize: 12),
                      children: [
                        TextSpan(
                          text: formatPaise(rod.toY.round()),
                          style: TextStyle(
                            color: scheme.onInverseSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                barGroups: [
                  for (final (i, paise) in premiums.indexed)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: paise.toDouble(),
                          width: 14,
                          color: scheme.primary,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
