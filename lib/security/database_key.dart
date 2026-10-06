import 'dart:convert';

import 'key_value_store.dart';
import 'pin_service.dart';

const _databaseKeyName = 'database_key';

/// Returns the random key that encrypts the database, creating it on first
/// launch. The key lives only in the platform keystore.
Future<String> loadOrCreateDatabaseKey(KeyValueStore store) async {
  final existing = await store.read(_databaseKeyName);
  if (existing != null) return existing;
  final key = base64Encode(randomBytes(32));
  await store.write(_databaseKeyName, key);
  return key;
}
