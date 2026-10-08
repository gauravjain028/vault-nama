import '../data/asset.dart';

/// A dated event worth reminding about: a premium, a renewal or a maturity.
class DueEvent {
  const DueEvent(this.asset, this.label, this.date);

  final Asset asset;

  /// What happens on [date], e.g. "Premium due".
  final String label;
  final DateTime date;

  @override
  String toString() => '${asset.name}: $label on $date';
}

const _monthsPerFrequency = {
  'Monthly': 1,
  'Quarterly': 3,
  'Half-yearly': 6,
  'Yearly': 12,
};

/// Every occurrence of each asset's events from [today] up to and including
/// [until], sorted by date. Premiums and renewals repeat; maturities don't.
List<DueEvent> dueEvents(
  List<Asset> assets, {
  required DateTime today,
  required DateTime until,
}) {
  final from = _dateOnly(today);
  final events = <DueEvent>[];

  void add(Asset asset, String label, Object? stored, {int? everyMonths}) {
    final start = stored is String ? DateTime.tryParse(stored) : null;
    if (start == null) return;
    if (everyMonths == null) {
      if (!start.isBefore(from) && !start.isAfter(until)) {
        events.add(DueEvent(asset, label, start));
      }
      return;
    }
    var n = 0;
    var date = start;
    // Skip past occurrences, then collect the ones in range.
    while (date.isBefore(from)) {
      date = addMonths(start, ++n * everyMonths);
    }
    while (!date.isAfter(until)) {
      events.add(DueEvent(asset, label, date));
      date = addMonths(start, ++n * everyMonths);
    }
  }

  for (final asset in assets) {
    final d = asset.details;
    final premiumEvery = _monthsPerFrequency[d['premiumFrequency']];
    switch (asset.type) {
      case AssetType.lifeInsurance:
        add(
          asset,
          'Premium due',
          d['nextPremiumDue'],
          everyMonths: premiumEvery,
        );
        add(asset, 'Policy matures', d['maturityDate']);
      case AssetType.termInsurance:
        add(
          asset,
          'Premium due',
          d['nextPremiumDue'],
          everyMonths: premiumEvery,
        );
        add(asset, 'Cover ends', d['policyEndDate']);
      case AssetType.healthInsurance:
        add(asset, 'Renewal due', d['renewalDate'], everyMonths: 12);
      case AssetType.fixedDeposit:
        add(asset, 'FD matures', d['maturityDate']);
      case AssetType.gold:
      case AssetType.silver:
      case AssetType.bankAccount:
      case AssetType.realEstate:
      case AssetType.other:
        break;
    }
  }

  // No premium is due on or after the day the policy ends.
  events.removeWhere((e) {
    if (e.label != 'Premium due') return false;
    final end =
        e.asset.details[e.asset.type == AssetType.termInsurance
            ? 'policyEndDate'
            : 'maturityDate'];
    final endDate = end is String ? DateTime.tryParse(end) : null;
    return endDate != null && !e.date.isBefore(endDate);
  });

  events.sort((a, b) => a.date.compareTo(b.date));
  return events;
}

/// Adds calendar months, clamping the day to the end of shorter months
/// (31 Jan + 1 month = 28/29 Feb).
DateTime addMonths(DateTime date, int months) {
  final monthIndex = date.month - 1 + months;
  final year = date.year + monthIndex ~/ 12;
  final month = monthIndex % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, date.day > lastDay ? lastDay : date.day);
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
