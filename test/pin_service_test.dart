import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault_nama/security/database_key.dart';
import 'package:vault_nama/security/pin_service.dart';

import 'fakes.dart';

void main() {
  test('pbkdf2 matches the RFC 7914 HMAC-SHA256 test vector', () {
    final key = pbkdf2(utf8.encode('passwd'), utf8.encode('salt'), 1, 64);
    expect(
      hex.encode(key),
      '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc'
      '49ca9cccf179b645991664b39d77ef317c71b845b1e30bd509112041d3a19783',
    );
  });

  test('stores a hash, not the PIN, and verifies it', () async {
    final store = MemoryKeyValueStore();
    final pins = PinService(store, iterations: 10);

    expect(await pins.hasPin(), isFalse);
    await pins.setPin('2468');

    expect(await pins.hasPin(), isTrue);
    expect(store.values.values, isNot(contains('2468')));
    expect(await pins.verifyPin('2468'), isTrue);
    expect(await pins.verifyPin('1357'), isFalse);
  });

  test('rejects PINs that are too short or not numeric', () {
    expect(PinService.isValidPin('123'), isFalse);
    expect(PinService.isValidPin('12a4'), isFalse);
    expect(PinService.isValidPin('123456789'), isFalse);
    expect(PinService.isValidPin('1234'), isTrue);
  });

  test('database key is created once and reused', () async {
    final store = MemoryKeyValueStore();
    final first = await loadOrCreateDatabaseKey(store);
    expect(base64Decode(first), hasLength(32));
    expect(await loadOrCreateDatabaseKey(store), first);
  });
}
