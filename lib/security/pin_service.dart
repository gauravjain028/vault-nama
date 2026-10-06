import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'key_value_store.dart';

/// Stores a salted PBKDF2 hash of the user's PIN and verifies attempts.
/// The PIN itself is never stored.
class PinService {
  PinService(this._store, {this.iterations = 100000});

  static const minLength = 4;
  static const maxLength = 8;
  static const _hashKey = 'pin_hash';
  static const _saltKey = 'pin_salt';

  final KeyValueStore _store;
  final int iterations;

  Future<bool> hasPin() async => await _store.read(_hashKey) != null;

  static bool isValidPin(String pin) =>
      pin.length >= minLength &&
      pin.length <= maxLength &&
      RegExp(r'^\d+$').hasMatch(pin);

  Future<void> setPin(String pin) async {
    if (!isValidPin(pin)) {
      throw ArgumentError('PIN must be $minLength-$maxLength digits');
    }
    final salt = randomBytes(16);
    final hash = await _hash(pin, salt);
    await _store.write(_saltKey, base64Encode(salt));
    await _store.write(_hashKey, base64Encode(hash));
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await _store.read(_hashKey);
    final storedSalt = await _store.read(_saltKey);
    if (storedHash == null || storedSalt == null) return false;
    final hash = await _hash(pin, base64Decode(storedSalt));
    return _constantTimeEquals(hash, base64Decode(storedHash));
  }

  /// Hashing is deliberately slow, so it runs off the UI thread.
  Future<Uint8List> _hash(String pin, List<int> salt) {
    final rounds = iterations;
    return Isolate.run(() => pbkdf2(utf8.encode(pin), salt, rounds, 32));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

Uint8List randomBytes(int length) {
  final random = Random.secure();
  return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
}

/// PBKDF2 with HMAC-SHA256 (RFC 8018).
Uint8List pbkdf2(
  List<int> password,
  List<int> salt,
  int iterations,
  int keyLength,
) {
  final hmac = Hmac(sha256, password);
  final output = BytesBuilder();
  var block = 1;
  while (output.length < keyLength) {
    final blockIndex = ByteData(4)..setUint32(0, block);
    var u = hmac.convert([...salt, ...blockIndex.buffer.asUint8List()]).bytes;
    final t = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    output.add(t);
    block++;
  }
  return Uint8List.fromList(output.toBytes().sublist(0, keyLength));
}
