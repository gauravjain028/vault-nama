import 'asset.dart';

/// Totals for the dashboard.
class AssetSummary {
  AssetSummary(List<Asset> assets) {
    for (final asset in assets) {
      if (asset.valuePaise > 0) {
        byType.update(
          asset.type,
          (total) => total + asset.valuePaise,
          ifAbsent: () => asset.valuePaise,
        );
        netWorthPaise += asset.valuePaise;
      }
      final d = asset.details;
      switch (asset.type) {
        case AssetType.lifeInsurance:
          lifeCoverPaise += _paise(d['sumAssured']);
        case AssetType.termInsurance:
          lifeCoverPaise += _paise(d['coverAmount']);
        case AssetType.healthInsurance:
          healthCoverPaise += _paise(d['coverAmount']);
        default:
          break;
      }
    }
  }

  int netWorthPaise = 0;

  /// Value per type, only for types with a value; largest first when read
  /// through [ranked].
  final byType = <AssetType, int>{};

  /// Sum assured on life policies plus term cover.
  int lifeCoverPaise = 0;
  int healthCoverPaise = 0;

  List<MapEntry<AssetType, int>> get ranked =>
      byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

  static int _paise(Object? stored) => stored is int ? stored : 0;
}
