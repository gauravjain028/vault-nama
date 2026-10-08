import 'package:vault_nama/data/asset.dart';
import 'package:vault_nama/reminders/reminders.dart';
import 'package:vault_nama/security/biometrics.dart';
import 'package:vault_nama/security/key_value_store.dart';

class MemoryKeyValueStore implements KeyValueStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

class FakeBiometrics implements Biometrics {
  FakeBiometrics({this.available = false, this.succeeds = false});

  final bool available;
  final bool succeeds;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate() async => succeeds;
}

class FakeReminders implements Reminders {
  List<Asset>? lastScheduled;

  @override
  Future<void> reschedule(List<Asset> assets) async => lastScheduled = assets;
}
