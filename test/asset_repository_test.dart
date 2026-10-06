import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vault_nama/data/asset.dart';
import 'package:vault_nama/data/asset_repository.dart';

void main() {
  late AssetRepository repo;

  setUp(() async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onCreate: createSchema,
      ),
    );
    repo = AssetRepository(db);
  });

  tearDown(() => repo.close());

  test('saves, updates and deletes assets with their details', () async {
    final id = await repo.insert(
      Asset(
        type: AssetType.fixedDeposit,
        name: 'SBI FD',
        valuePaise: 50000000,
        details: {'rate': 7.1, 'maturity': '2028-03-31'},
      ),
    );

    var saved = (await repo.all()).single;
    expect(saved.id, id);
    expect(saved.type, AssetType.fixedDeposit);
    expect(saved.valuePaise, 50000000);
    expect(saved.details['rate'], 7.1);

    await repo.update(
      Asset(
        id: id,
        type: saved.type,
        name: 'SBI FD (renewed)',
        valuePaise: saved.valuePaise,
        details: saved.details,
        createdAt: saved.createdAt,
      ),
    );
    saved = (await repo.all()).single;
    expect(saved.name, 'SBI FD (renewed)');

    await repo.delete(id);
    expect(await repo.all(), isEmpty);
  });
}
