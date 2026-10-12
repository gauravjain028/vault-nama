import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vault_nama/data/asset.dart';
import 'package:vault_nama/data/asset_repository.dart';

Map<String, Object?> _legacyRow(String type, Map<String, Object?> details) => {
  'type': type,
  'name': 'Old $type',
  'value_paise': 100,
  'details': jsonEncode(details),
  'created_at': 0,
  'updated_at': 0,
};

void main() {
  test('old gold and silver rows read as metals', () {
    final gold = Asset.fromRow({'id': 1, ..._legacyRow('gold', {})});
    expect(gold.type, AssetType.metal);
    expect(gold.details['metal'], 'Gold');

    final silver = Asset.fromRow({
      'id': 2,
      ..._legacyRow('silver', {'weightGrams': 50.0}),
    });
    expect(silver.type, AssetType.metal);
    expect(silver.details, {'weightGrams': 50.0, 'metal': 'Silver'});
  });

  test('upgrading a version 1 database rewrites gold and silver', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await createSchema(db, 1);
    await db.insert('assets', _legacyRow('gold', {'purity': '22K'}));
    await db.insert('assets', _legacyRow('fixedDeposit', {}));

    await upgradeSchema(db, 1, 2);

    final rows = await db.query('assets', orderBy: 'id');
    expect(rows.map((r) => r['type']), ['metal', 'fixedDeposit']);
    expect(jsonDecode(rows.first['details'] as String), {
      'purity': '22K',
      'metal': 'Gold',
    });
    await db.close();
  });
}
