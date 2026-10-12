import '../reminders/due_dates.dart';
import 'asset.dart';

/// Premiums payable in each of the next [months] calendar months, starting
/// with the month of [today]. Uses each policy's premium amount and how often
/// it is paid; health policies count their yearly premium at renewal.
List<int> premiumsByMonth(
  List<Asset> assets, {
  required DateTime today,
  int months = 12,
}) {
  final totals = List.filled(months, 0);
  final start = DateTime(today.year, today.month);
  final end = DateTime(today.year, today.month + months, 0);
  for (final e in dueEvents(assets, today: start, until: end)) {
    if (e.label != 'Premium due' && e.label != 'Renewal due') continue;
    final premium = e.asset.details['premium'];
    if (premium is! int) continue;
    final index = (e.date.year - start.year) * 12 + e.date.month - start.month;
    if (index >= 0 && index < months) totals[index] += premium;
  }
  return totals;
}
