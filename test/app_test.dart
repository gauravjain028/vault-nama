import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vault_nama/app.dart';
import 'package:vault_nama/data/asset_repository.dart';
import 'package:vault_nama/security/pin_service.dart';

import 'fakes.dart';

void main() {
  late MemoryKeyValueStore store;
  late FakeReminders reminders;

  Future<AssetRepository> openRepository() async {
    sqfliteFfiInit();
    return AssetRepository(
      await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: schemaVersion,
          onCreate: createSchema,
        ),
      ),
    );
  }

  Widget app() => VaultNamaApp(
    pinService: PinService(store, iterations: 10),
    biometrics: FakeBiometrics(),
    reminders: reminders,
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

  Future<void> setUpPin(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await enterPin(tester, '2468', 'Next');
    await enterPin(tester, '2468', 'Set PIN');
  }

  setUp(() {
    store = MemoryKeyValueStore();
    reminders = FakeReminders();
  });

  testWidgets('first launch sets a PIN, then locks and unlocks', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Choose a PIN'), findsOneWidget);

    await enterPin(tester, '2468', 'Next');
    expect(find.text('Confirm your PIN'), findsOneWidget);
    await enterPin(tester, '2468', 'Set PIN');
    expect(find.textContaining('No assets yet'), findsOneWidget);

    await tester.tap(find.byTooltip('Lock'));
    await tester.pumpAndSettle();
    expect(find.text('Vault Nama is locked'), findsOneWidget);

    await enterPin(tester, '0000', 'Unlock');
    expect(find.text('Wrong PIN'), findsOneWidget);

    await enterPin(tester, '2468', 'Unlock');
    expect(find.textContaining('No assets yet'), findsOneWidget);
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
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await setUpPin(tester);

    await tester.tap(find.text('Add asset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fixed deposit'));
    await tester.pumpAndSettle();
    expect(find.text('Add Fixed deposit'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('asset-name')), 'SBI FD');
    await tester.enterText(find.byKey(const Key('asset-value')), '1,50,000');
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

    expect(find.text('SBI FD'), findsOneWidget);
    // In the list, the net-worth headline and the category bar.
    expect(find.text('₹1,50,000.00'), findsNWidgets(3));
    expect(
      tester.widget<Text>(find.byKey(const Key('net-worth'))).data,
      '₹1,50,000.00',
    );
    expect(reminders.lastScheduled?.single.name, 'SBI FD');
    expect(find.text('SBI · 7.1%'), findsOneWidget);

    await tester.tap(find.text('SBI FD'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Fixed deposit'), findsOneWidget);
    expect(find.text('7.1'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('asset-name')), 'SBI FD 2');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('SBI FD 2'), findsOneWidget);

    await tester.tap(find.text('SBI FD 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await settle(tester);
    expect(find.textContaining('No assets yet'), findsOneWidget);
  });

  testWidgets('locking closes an open form', (tester) async {
    await setUpPin(tester);
    await tester.tap(find.text('Add asset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gold'));
    await tester.pumpAndSettle();
    expect(find.text('Add Gold'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    // Frames only render once the app is back in the foreground.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Vault Nama is locked'), findsOneWidget);
    expect(find.text('Add Gold'), findsNothing);
  });
}
