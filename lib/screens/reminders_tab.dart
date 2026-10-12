import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/asset.dart';
import '../reminders/due_dates.dart';
import 'overview_tab.dart';

/// Everything due in the next 12 months, grouped by month.
class RemindersTab extends StatelessWidget {
  const RemindersTab({super.key, required this.assets, required this.onOpen});

  final List<Asset> assets;
  final void Function(Asset asset) onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final events = dueEvents(
      assets,
      today: today,
      until: DateTime(today.year + 1, today.month, today.day),
    );
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No premiums, renewals or maturities in the next 12 months.\n'
            'Add due dates to your policies and deposits to see them here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final byMonth = <DateTime, List<DueEvent>>{};
    for (final e in events) {
      byMonth.putIfAbsent(DateTime(e.date.year, e.date.month), () => []).add(e);
    }
    final heading = DateFormat('MMMM yyyy');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            "You'll get a notification a week before and on the day.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final MapEntry(key: month, value: monthEvents)
            in byMonth.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Text(
              heading.format(month),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final e in monthEvents)
                    DueEventTile(event: e, onTap: () => onOpen(e.asset)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
