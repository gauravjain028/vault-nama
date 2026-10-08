import 'package:flutter/material.dart';

import 'app.dart';
import 'data/asset_repository.dart';
import 'reminders/reminders.dart';
import 'security/biometrics.dart';
import 'security/database_key.dart';
import 'security/key_value_store.dart';
import 'security/pin_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = SecureKeyValueStore();
  runApp(
    VaultNamaApp(
      pinService: PinService(store),
      biometrics: Biometrics(),
      reminders: LocalNotificationReminders(),
      openRepository: () async => AssetRepository(
        await openEncryptedDatabase(await loadOrCreateDatabaseKey(store)),
      ),
    ),
  );
}
