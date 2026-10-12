import 'dart:convert';

/// The kinds of assets the app tracks.
enum AssetType {
  lifeInsurance('LIC / life insurance'),
  healthInsurance('Health insurance'),
  termInsurance('Term insurance'),
  metal('Gold, silver & metals'),
  fixedDeposit('Fixed deposit'),
  bankAccount('Bank account'),
  realEstate('Real estate'),
  other('Other');

  const AssetType(this.label);
  final String label;
}

/// One asset record. Type-specific fields (policy number, FD rate, grams of
/// gold, ...) live in [details] so new fields don't need a schema change.
class Asset {
  Asset({
    this.id,
    required this.type,
    required this.name,
    this.valuePaise = 0,
    Map<String, Object?>? details,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : details = details ?? {},
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final int? id;
  final AssetType type;
  final String name;

  /// Current value in paise, kept as an integer to avoid rounding errors.
  final int valuePaise;
  final Map<String, Object?> details;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toRow() => {
    if (id != null) 'id': id,
    'type': type.name,
    'name': name,
    'value_paise': valuePaise,
    'details': jsonEncode(details),
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory Asset.fromRow(Map<String, Object?> row) {
    var typeName = row['type'] as String;
    final details = (jsonDecode(row['details'] as String) as Map)
        .cast<String, Object?>();
    // Gold and silver used to be separate types; now they are one "metal"
    // type with the metal named in its details. Older databases and backups
    // still say "gold" or "silver".
    if (_legacyMetals[typeName] case final metal?) {
      typeName = AssetType.metal.name;
      details['metal'] ??= metal;
    }
    return Asset(
      id: row['id'] as int?,
      type: AssetType.values.asNameMap()[typeName] ?? AssetType.other,
      name: row['name'] as String,
      valuePaise: row['value_paise'] as int,
      details: details,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }

  static const _legacyMetals = {'gold': 'Gold', 'silver': 'Silver'};
}
