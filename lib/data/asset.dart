import 'dart:convert';

/// The kinds of assets the app tracks.
enum AssetType {
  lifeInsurance('LIC / life insurance'),
  healthInsurance('Health insurance'),
  termInsurance('Term insurance'),
  gold('Gold'),
  silver('Silver'),
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

  factory Asset.fromRow(Map<String, Object?> row) => Asset(
    id: row['id'] as int,
    type: AssetType.values.asNameMap()[row['type']] ?? AssetType.other,
    name: row['name'] as String,
    valuePaise: row['value_paise'] as int,
    details: (jsonDecode(row['details'] as String) as Map)
        .cast<String, Object?>(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
  );
}
