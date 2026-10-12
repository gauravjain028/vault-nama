import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vault_nama/app.dart';
import 'package:vault_nama/backup/backup_codec.dart';
import 'package:vault_nama/backup/backup_screen.dart';
import 'package:vault_nama/data/asset.dart';
import 'package:vault_nama/security/auto_lock.dart';
import 'package:vault_nama/data/asset_repository.dart';
import 'package:vault_nama/security/pin_service.dart';

import 'fakes.dart';

void main() {
  late MemoryKeyValueStore store;
  late FakeReminders reminders;
  late FakeBackupFiles backupFiles;
  late AssetRepository repository;

  var seed = <Asset>[];

  Future<AssetRepository> openRepository() async {
    sqfliteFfiInit();
    repository = AssetRepository(
      await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: schemaVersion,
          onCreate: createSchema,
        ),
      ),
    );
    await repository.replaceAll(seed);
    return repository;
  }

  Widget app() => VaultNamaApp(
    pinService: PinService(store, iterations: 10),
    biometrics: FakeBiometrics(),
    reminders: reminders,
    backupTools: BackupTools(
      codec: BackupCodec(iterations: 10),
      files: backupFiles,
      autoLock: AutoLock(),
    ),
    openRepository: openRepository,
  );

  Future<void> enterPin(WidgetTester tester, String pin, String button) async {
    await tester.enterText(find.byKey(const Key('pin-field')), pin);
    await tester.tap(find.text(button));
    // PIN hashing and the database do real async work, and the busy spinner
    // never settles, so pump until the work finishes.
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    await tester.pumpAndSettle();
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  void phoneSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  const welcome = 'Your assets, in one private place';

  Future<void> setUpPin(WidgetTester tester) async {
    phoneSize(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await enterPin(tester, '2468', 'Next');
    await enterPin(tester, '2468', 'Set PIN');
  }

  setUp(() {
    store = MemoryKeyValueStore();
    reminders = FakeReminders();
    backupFiles = FakeBackupFiles();
    seed = [];
  });

  testWidgets('first launch sets a PIN, then locks and unlocks', (
    tester,
  ) async {
    phoneSize(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Choose a PIN'), findsOneWidget);

    await enterPin(tester, '2468', 'Next');
    expect(find.text('Confirm your PIN'), findsOneWidget);
    await enterPin(tester, '2468', 'Set PIN');
    expect(find.text(welcome), findsOneWidget);

    await tester.tap(find.byTooltip('Lock'));
    await tester.pumpAndSettle();
    expect(find.text('Vault Nama is locked'), findsOneWidget);

    await enterPin(tester, '0000', 'Unlock');
    expect(find.text('Wrong PIN'), findsOneWidget);

    await enterPin(tester, '2468', 'Unlock');
    expect(find.text(welcome), findsOneWidget);
  });

  testWidgets('mismatched confirmation starts PIN setup again', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await enterPin(tester, '2468', 'Next');
    await enterPin(tester, '1357', 'Set PIN');
    expect(find.text('Choose a PIN'), findsOneWidget);
    expect(find.textContaining("PINs didn't match"), findsOneWidget);
  });

  testWidgets('adds, edits and deletes a fixed deposit', (tester) async {
    await setUpPin(tester);

    await tester.tap(find.text('Add your first asset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fixed deposit'));
    await tester.pumpAndSettle();
    expect(find.text('Add asset'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('asset-name')), 'SBI FD');
    await tester.enterText(find.byKey(const Key('asset-value')), '1,50,000');
    await tester.pump();
    expect(find.text('1.5 lakh'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('field-bank')),
        matching: find.byType(TextFormField),
      ),
      'SBI',
    );
    await tester.enterText(
      find.descendant(
        of: find.byKey(const Key('field-interestRate')),
        matching: find.byType(TextFormField),
      ),
      '7.1',
    );
    await tester.tap(find.text('Save'));
    await settle(tester);

    // Back on the overview.
    expect(
      tester.widget<Text>(find.byKey(const Key('net-worth'))).data,
      '₹1,50,000',
    );
    expect(find.text('Where your money is'), findsOneWidget);
    expect(reminders.lastScheduled?.single.name, 'SBI FD');

    await openTab(tester, 'Assets');
    expect(find.text('SBI FD'), findsOneWidget);
    expect(find.text('SBI · 7.1%'), findsOneWidget);

    await tester.tap(find.text('SBI FD'));
    await tester.pumpAndSettle();
    expect(find.text('Edit asset'), findsOneWidget);
    expect(find.text('7.1'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('asset-name')), 'SBI FD 2');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('SBI FD 2'), findsOneWidget);

    // Search narrows the list.
    await tester.enterText(find.byKey(const Key('asset-search')), 'hdfc');
    await tester.pump();
    expect(find.text('Nothing matches your search.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('asset-search')), 'sbi');
    await tester.pump();
    expect(find.text('SBI FD 2'), findsOneWidget);

    await tester.tap(find.text('SBI FD 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(find.textContaining('No assets yet'), findsOneWidget);
  });

  testWidgets('any metal can be added with a suggestion', (tester) async {
    await setUpPin(tester);
    await tester.tap(find.text('Add asset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gold, silver & metals'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('asset-name')), 'Coin');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Platinum'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await settle(tester);

    await openTab(tester, 'Assets');
    expect(find.text('Platinum'), findsOneWidget);
  });

  testWidgets('locking closes an open form', (tester) async {
    await setUpPin(tester);
    await tester.tap(find.text('Add asset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gold, silver & metals'));
    await tester.pumpAndSettle();
    expect(find.text('Add asset'), findsWidgets);
    expect(find.text('Save'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    // Frames only render once the app is back in the foreground.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Vault Nama is locked'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('saves a backup and restores it', (tester) async {
    seed = [Asset(type: AssetType.metal, name: 'Coins', valuePaise: 2500000)];
    await setUpPin(tester);
    await openTab(tester, 'Assets');
    expect(find.text('Coins'), findsOneWidget);

    await openTab(tester, 'Settings');
    await tester.tap(find.text('Backup and restore'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save a backup'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('backup-password')), 'short');
    await tester.enterText(
      find.byKey(const Key('backup-password-again')),
      'short',
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('At least 8 characters'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('backup-password')),
      'gold-and-fds',
    );
    await tester.enterText(
      find.byKey(const Key('backup-password-again')),
      'gold-and-fds',
    );
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(backupFiles.saved, isNotNull);
    expect(backupFiles.savedName, endsWith('.vnbackup'));
    expect(find.text('Backup saved with 1 asset'), findsOneWidget);

    // Lose the data, then restore it.
    await tester.runAsync(() => repository.replaceAll([]));

    await tester.tap(find.text('Restore from a backup'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('backup-password')), 'wrong');
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(find.text('Wrong backup password'), findsOneWidget);

    await tester.tap(find.text('Restore from a backup'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('backup-password')),
      'gold-and-fds',
    );
    await tester.tap(find.text('OK'));
    await settle(tester);
    expect(find.text('Restore 1 asset?'), findsOneWidget);
    await tester.tap(find.text('Replace'));
    await settle(tester);

    await tester.pageBack();
    await settle(tester);
    await openTab(tester, 'Assets');
    expect(find.text('Coins'), findsOneWidget);
  });

  testWidgets('choosing a backup file does not lock the app', (tester) async {
    await setUpPin(tester);
    await openTab(tester, 'Settings');
    await tester.tap(find.text('Backup and restore'));
    await tester.pumpAndSettle();

    backupFiles.whilePicking = () {
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
    };
    await tester.tap(find.text('Restore from a backup'));
    await tester.pumpAndSettle();

    // Nothing was saved, so the picker returns no file and nothing happens.
    expect(find.text('Vault Nama is locked'), findsNothing);
    expect(find.text('Backup and restore'), findsOneWidget);
  });
}
