import 'package:intl/intl.dart';

import '../data/asset.dart';

final _day = DateFormat('d MMM yyyy');

/// One short line under the asset's name: the most useful identifying
/// details for its type.
String? subtitleFor(Asset asset) {
  final d = asset.details;
  final parts = switch (asset.type) {
    AssetType.lifeInsurance ||
    AssetType.healthInsurance ||
    AssetType.termInsurance => [d['insurer'], d['policyNumber']],
    AssetType.metal => [
      d['metal'],
      d['weightGrams'] == null ? null : '${_number(d['weightGrams'])} g',
      d['purity'],
      d['form'],
    ],
    AssetType.fixedDeposit => [
      d['bank'],
      d['interestRate'] == null ? null : '${_number(d['interestRate'])}%',
      _date('matures', d['maturityDate']),
    ],
    AssetType.bankAccount => [d['bank'], d['accountType']],
    AssetType.realEstate => [d['propertyType'], d['area']],
    AssetType.other => [d['notes']],
  };
  final text = parts
      .whereType<Object>()
      .map((p) => '$p')
      .where((p) => p.isNotEmpty)
      .join(' · ');
  return text.isEmpty ? null : text;
}

String _number(Object? n) =>
    n is num && n == n.truncate() ? '${n.truncate()}' : '$n';

String? _date(String prefix, Object? stored) {
  final date = stored is String ? DateTime.tryParse(stored) : null;
  return date == null ? null : '$prefix ${_day.format(date)}';
}

/// Searchable text for an asset: its name, type and every detail.
String searchText(Asset asset) => [
  asset.name,
  asset.type.label,
  ...asset.details.values.map((v) => '$v'),
].join(' ').toLowerCase();
