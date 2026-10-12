// Renders the main screens with sample data to PNGs for review.
// Run: flutter test tool/screenshots_test.dart --update-goldens
// Output: tool/screenshots/*.png (not part of CI).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vault_nama/backup/backup_codec.dart';
import 'package:vault_nama/backup/backup_screen.dart';
import 'package:vault_nama/data/asset.dart';
import 'package:vault_nama/data/asset_repository.dart';
import 'package:vault_nama/screens/asset_form_screen.dart';
import 'package:vault_nama/screens/home_shell.dart';
import 'package:vault_nama/security/auto_lock.dart';
import 'package:vault_nama/ui/theme.dart';

import '../test/fakes.dart';

Future<void> _loadFonts() async {
  final dir =
      '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter'}'
      '/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String f) async =>
      ByteData.sublistView(await File('$dir/$f').readAsBytes());
  final roboto = FontLoader('Roboto')
    ..addFont(read('Roboto-Regular.ttf'))
    ..addFont(read('Roboto-Medium.ttf'))
    ..addFont(read('Roboto-Bold.ttf'));
  await roboto.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(read('MaterialIcons-Regular.otf'));
  await icons.load();
}

String _inDays(int days) =>
    DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: days)));

List<Asset> _sample() => [
  Asset(
    type: AssetType.lifeInsurance,
    name: 'LIC Jeevan Anand',
    valuePaise: 42000000,
    details: {
      'insurer': 'LIC',
      'policyNumber': '873451209',
      'sumAssured': 1000000000,
      'premium': 2450000,
      'premiumFrequency': 'Half-yearly',
      'nextPremiumDue': _inDays(5),
      'maturityDate': '2041-03-28',
    },
  ),
  Asset(
    type: AssetType.termInsurance,
    name: 'HDFC Click 2 Protect',
    details: {
      'insurer': 'HDFC Life',
      'policyNumber': 'TP99812',
      'coverAmount': 15000000000,
      'premium': 1850000,
      'premiumFrequency': 'Yearly',
      'nextPremiumDue': _inDays(48),
    },
  ),
  Asset(
    type: AssetType.healthInsurance,
    name: 'Star Family Health',
    details: {
      'insurer': 'Star Health',
      'coverAmount': 1000000000,
      'premium': 3200000,
      'renewalDate': _inDays(130),
    },
  ),
  Asset(
    type: AssetType.metal,
    name: 'Wedding jewellery',
    valuePaise: 185000000,
    details: {'metal': 'Gold', 'weightGrams': 240.0, 'purity': '22K'},
  ),
  Asset(
    type: AssetType.metal,
    name: 'Silver coins',
    valuePaise: 9500000,
    details: {'metal': 'Silver', 'weightGrams': 1000.0, 'form': 'Coins / bars'},
  ),
  Asset(
    type: AssetType.fixedDeposit,
    name: 'SBI tax saver FD',
    valuePaise: 150000000,
    details: {
      'bank': 'SBI',
      'interestRate': 7.1,
      'maturityDate': _inDays(21),
      'maturityAmount': 162000000,
    },
  ),
  Asset(
    type: AssetType.bankAccount,
    name: 'HDFC savings',
    valuePaise: 34500000,
    details: {'bank': 'HDFC Bank', 'accountType': 'Savings'},
  ),
  Asset(
    type: AssetType.realEstate,
    name: 'Flat in Pune',
    valuePaise: 8500000000,
    details: {'propertyType': 'Flat', 'area': '1150 sq ft'},
  ),
];

void main() {
  late AssetRepository repository;

  setUpAll(_loadFonts);

  setUp(() async {
    sqfliteFfiInit();
    repository = AssetRepository(
      await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: schemaVersion,
          onCreate: createSchema,
          singleInstance: false,
        ),
      ),
    );
    await repository.replaceAll(_sample());
  });

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget home, {
    Brightness brightness = Brightness.light,
    Future<void> Function()? before,
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // flutter_test draws shadows as solid outlines unless told otherwise;
    // it is restored below before the test ends.
    debugDisableShadows = false;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(brightness),
        home: home,
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
    await before?.call();
    try {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('screenshots/$name.png'),
      );
    } finally {
      debugDisableShadows = true;
    }
  }

  Widget shell() => HomeShell(
    repository: repository,
    reminders: FakeReminders(),
    backupTools: BackupTools(
      codec: BackupCodec(iterations: 10),
      files: FakeBackupFiles(),
      autoLock: AutoLock(),
    ),
    onLock: () {},
  );

  Future<void> tab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('overview', (t) => shoot(t, '1-overview', shell()));
  testWidgets(
    'overview scrolled',
    (t) => shoot(
      t,
      '2-overview-premiums',
      shell(),
      before: () async {
        await t.drag(find.byType(ListView).first, const Offset(0, -1400));
        await t.pumpAndSettle();
      },
    ),
  );
  testWidgets(
    'assets',
    (t) => shoot(t, '3-assets', shell(), before: () => tab(t, 'Assets')),
  );
  testWidgets(
    'reminders',
    (t) => shoot(t, '4-reminders', shell(), before: () => tab(t, 'Reminders')),
  );
  testWidgets(
    'add sheet',
    (t) => shoot(
      t,
      '5-add',
      shell(),
      before: () async {
        await t.tap(find.text('Add asset'));
        await t.pumpAndSettle();
      },
    ),
  );
  testWidgets('metal form', (t) async {
    final metal = (await t.runAsync(repository.all))!
        .firstWhere((a) => a.type == AssetType.metal);
    await shoot(
      t,
      '6-metal-form',
      AssetFormScreen(
        repository: repository,
        type: AssetType.metal,
        existing: metal,
      ),
    );
  });
  testWidgets(
    'overview dark',
    (t) => shoot(t, '7-overview-dark', shell(), brightness: Brightness.dark),
  );
}
