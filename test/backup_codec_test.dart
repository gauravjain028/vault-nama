import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vault_nama/backup/backup_codec.dart';
import 'package:vault_nama/data/asset.dart';

void main() {
  final codec = BackupCodec(iterations: 10);
  final assets = [
    Asset(
      id: 4,
      type: AssetType.fixedDeposit,
      name: 'SBI FD',
      valuePaise: 15000000,
      details: {'rate': 7.1, 'maturityDate': '2028-03-31'},
      createdAt: DateTime(2026, 1, 2),
      updatedAt: DateTime(2026, 3, 4),
    ),
    Asset(type: AssetType.gold, name: 'Coins', details: {'weightGrams': 20.0}),
  ];

  test('round-trips assets with the right password', () async {
    final file = await codec.encode(assets, 'correct horse');
    final restored = await codec.decode(file, 'correct horse');
    expect(restored, hasLength(2));
    expect(restored.first.toRow(), assets.first.toRow());
    expect(restored.last.details['weightGrams'], 20.0);
  });

  test('the file does not contain the data in readable form', () async {
    final file = utf8.decode(await codec.encode(assets, 'correct horse'));
    expect(file, isNot(contains('SBI')));
    expect(file, isNot(contains('maturityDate')));
    expect(jsonDecode(file)['format'], BackupCodec.format);
  });

  test('rejects a wrong password', () async {
    final file = await codec.encode(assets, 'correct horse');
    expect(
      () => codec.decode(file, 'wrong horse'),
      throwsA(
        isA<BackupException>().having(
          (e) => e.message,
          'message',
          'Wrong backup password',
        ),
      ),
    );
  });

  test('rejects a tampered file', () async {
    final envelope = jsonDecode(
      utf8.decode(await codec.encode(assets, 'correct horse')),
    ) as Map;
    final cipher = base64Decode(envelope['ciphertext'] as String);
    cipher[0] ^= 1;
    envelope['ciphertext'] = base64Encode(cipher);
    expect(
      () => codec.decode(utf8.encode(jsonEncode(envelope)), 'correct horse'),
      throwsA(isA<BackupException>()),
    );
  });

  test('rejects files that are not backups', () async {
    expect(
      () => codec.decode(utf8.encode('hello'), 'correct horse'),
      throwsA(
        isA<BackupException>().having(
          (e) => e.message,
          'message',
          'This is not a Vault Nama backup file',
        ),
      ),
    );
  });

  test('refuses a short backup password', () async {
    expect(
      () => codec.encode(assets, 'short'),
      throwsA(isA<BackupException>()),
    );
  });
}
