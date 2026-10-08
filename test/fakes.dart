import 'dart:typed_data';

import 'package:vault_nama/backup/backup_files.dart';
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

/// Keeps "saved" backups in memory; [pick] returns the last one saved.
class FakeBackupFiles implements BackupFiles {
  Uint8List? saved;
  String? savedName;

  /// Runs while the "dialog" is open, e.g. to send the app to background.
  void Function()? whilePicking;

  @override
  Future<bool> save(String fileName, Uint8List bytes) async {
    savedName = fileName;
    saved = bytes;
    return true;
  }

  @override
  Future<Uint8List?> pick() async {
    whilePicking?.call();
    return saved;
  }
}
