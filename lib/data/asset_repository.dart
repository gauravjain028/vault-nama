import 'package:path/path.dart' as p;
import 'package:sqflite_sqlcipher/sqflite.dart' as cipher;

import 'asset.dart';

const schemaVersion = 2;

Future<void> createSchema(cipher.Database db, int version) async {
  await db.execute('''
    CREATE TABLE assets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL,
      name TEXT NOT NULL,
      value_paise INTEGER NOT NULL DEFAULT 0,
      details TEXT NOT NULL DEFAULT '{}',
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    )
  ''');
  await db.execute('CREATE INDEX assets_type ON assets(type)');
}

/// Version 2 merged the gold and silver types into one metal type.
Future<void> upgradeSchema(
  cipher.Database db,
  int oldVersion,
  int newVersion,
) async {
  if (oldVersion < 2) {
    final rows = await db.query('assets', where: "type IN ('gold', 'silver')");
    for (final row in rows) {
      // fromRow converts the legacy type; write it back in the new form.
      await db.update(
        'assets',
        Asset.fromRow(row).toRow(),
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }
}

/// Opens the SQLCipher-encrypted database on the device.
Future<cipher.Database> openEncryptedDatabase(String key) async {
  final path = p.join(await cipher.getDatabasesPath(), 'vault_nama.db');
  return cipher.openDatabase(
    path,
    password: key,
    version: schemaVersion,
    onCreate: createSchema,
    onUpgrade: upgradeSchema,
  );
}

class AssetRepository {
  AssetRepository(this._db);

  final cipher.Database _db;

  Future<List<Asset>> all() async {
    final rows = await _db.query('assets', orderBy: 'type, name');
    return rows.map(Asset.fromRow).toList();
  }

  Future<int> insert(Asset asset) => _db.insert('assets', asset.toRow());

  Future<void> update(Asset asset) => _db.update(
    'assets',
    asset.toRow(),
    where: 'id = ?',
    whereArgs: [asset.id],
  );

  Future<void> delete(int id) =>
      _db.delete('assets', where: 'id = ?', whereArgs: [id]);

  /// Replaces every asset with [assets], all or nothing.
  Future<void> replaceAll(List<Asset> assets) => _db.transaction((txn) async {
    await txn.delete('assets');
    for (final asset in assets) {
      await txn.insert('assets', asset.toRow());
    }
  });

  Future<void> close() => _db.close();
}
