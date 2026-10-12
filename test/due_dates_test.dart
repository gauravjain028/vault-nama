import 'package:flutter_test/flutter_test.dart';
import 'package:vault_nama/data/asset.dart';
import 'package:vault_nama/data/cash_flow.dart';
import 'package:vault_nama/data/summary.dart';
import 'package:vault_nama/reminders/due_dates.dart';
import 'package:vault_nama/reminders/reminders.dart';

Asset _asset(
  AssetType type,
  Map<String, Object?> details, {
  int valuePaise = 0,
  String name = 'A',
}) => Asset(type: type, name: name, valuePaise: valuePaise, details: details);

void main() {
  final today = DateTime(2026, 10, 8);

  test('addMonths clamps to the end of shorter months', () {
    expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    expect(addMonths(DateTime(2028, 1, 31), 1), DateTime(2028, 2, 29));
    expect(addMonths(DateTime(2026, 11, 15), 3), DateTime(2027, 2, 15));
    // Each step is from the original date, so the 31st comes back.
    expect(addMonths(DateTime(2026, 1, 31), 2), DateTime(2026, 3, 31));
  });

  test('quarterly premium rolls forward past today', () {
    final policy = _asset(AssetType.lifeInsurance, {
      'nextPremiumDue': '2026-01-15',
      'premiumFrequency': 'Quarterly',
    });
    final events = dueEvents(
      [policy],
      today: today,
      until: DateTime(2027, 6, 1),
    );
    expect(events.map((e) => e.date), [
      DateTime(2026, 10, 15),
      DateTime(2027, 1, 15),
      DateTime(2027, 4, 15),
    ]);
    expect(events.first.label, 'Premium due');
  });

  test('premiums stop after the policy matures', () {
    final policy = _asset(AssetType.lifeInsurance, {
      'nextPremiumDue': '2026-11-01',
      'premiumFrequency': 'Monthly',
      'maturityDate': '2027-01-01',
    });
    final events = dueEvents(
      [policy],
      today: today,
      until: DateTime(2027, 6, 1),
    );
    expect(events.map((e) => '${e.label} ${e.date.month}'), [
      'Premium due 11',
      'Premium due 12',
      'Policy matures 1',
    ]);
  });

  test('one-off and yearly events are found and sorted', () {
    final fd = _asset(AssetType.fixedDeposit, {
      'maturityDate': '2026-11-20',
    }, name: 'FD');
    final oldFd = _asset(AssetType.fixedDeposit, {
      'maturityDate': '2026-01-01',
    }, name: 'Old FD');
    final health = _asset(AssetType.healthInsurance, {
      'renewalDate': '2025-10-20',
    }, name: 'Health');
    final events = dueEvents(
      [fd, oldFd, health],
      today: today,
      until: today.add(const Duration(days: 60)),
    );
    expect(events.map((e) => '${e.asset.name}: ${e.label}'), [
      'Health: Renewal due',
      'FD: FD matures',
    ]);
    expect(events.first.date, DateTime(2026, 10, 20));
  });

  test('reminders fire a week before and on the day, never in the past', () {
    final fd = _asset(AssetType.fixedDeposit, {
      'maturityDate': '2026-10-12',
    }, name: 'SBI FD');
    final plans = reminderPlan(
      dueEvents([fd], today: today, until: DateTime(2027)),
      now: DateTime(2026, 10, 8, 10),
    );
    // The week-before reminder (5 Oct) has passed, so only the day remains.
    expect(plans, hasLength(1));
    expect(plans.single.at, DateTime(2026, 10, 12));
    expect(plans.single.title, 'FD matures today');
    expect(plans.single.body, 'SBI FD, 12 Oct 2026');
  });

  test('summary totals value by type and insurance cover', () {
    final summary = AssetSummary([
      _asset(AssetType.fixedDeposit, {}, valuePaise: 500),
      _asset(AssetType.fixedDeposit, {}, valuePaise: 300),
      _asset(AssetType.metal, {}, valuePaise: 1000),
      _asset(AssetType.lifeInsurance, {'sumAssured': 7000}),
      _asset(AssetType.termInsurance, {'coverAmount': 3000}),
      _asset(AssetType.healthInsurance, {'coverAmount': 2000}),
    ]);
    expect(summary.netWorthPaise, 1800);
    expect(summary.ranked.map((e) => (e.key, e.value)), [
      (AssetType.metal, 1000),
      (AssetType.fixedDeposit, 800),
    ]);
    expect(summary.lifeCoverPaise, 10000);
    expect(summary.healthCoverPaise, 2000);
  });

  test('premiums are totalled per month for the next year', () {
    final lic = _asset(AssetType.lifeInsurance, {
      'nextPremiumDue': '2026-11-10',
      'premiumFrequency': 'Half-yearly',
      'premium': 1200000,
    });
    final health = _asset(AssetType.healthInsurance, {
      'renewalDate': '2027-02-01',
      'premium': 2500000,
    });
    final months = premiumsByMonth([lic, health], today: today);
    expect(months, hasLength(12));
    expect(months[1], 1200000); // Nov 2026
    expect(months[4], 2500000); // Feb 2027
    expect(months[7], 1200000); // May 2027
    expect(months.fold(0, (a, b) => a + b), 4900000);
  });
}
