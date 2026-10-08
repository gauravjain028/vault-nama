import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../data/asset.dart';

/// Thrown when a backup can't be opened: wrong password, or not a backup.
class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Encrypts assets into a self-contained backup file and back.
///
/// The file is JSON holding a PBKDF2 salt, an AES-256-GCM nonce and the
/// ciphertext. Only the backup password can open it, so it is safe to keep
/// in Google Drive, email or on a computer.
class BackupCodec {
  BackupCodec({this.iterations = 200000});

  static const format = 'vault-nama-backup';
  static const version = 1;
  static const minPasswordLength = 8;

  /// Upper bound accepted when reading, so a crafted file can't hang the app.
  static const _maxIterations = 5000000;

  final int iterations;
  final _cipher = AesGcm.with256bits();

  Future<Uint8List> encode(
    List<Asset> assets,
    String password, {
    DateTime? now,
  }) async {
    if (password.length < minPasswordLength) {
      throw const BackupException(
        'Use a backup password of at least $minPasswordLength characters',
      );
    }
    final salt = SecretKeyData.random(length: 16).bytes;
    final key = await _deriveKey(password, salt, iterations);
    final payload = utf8.encode(
      jsonEncode({
        'exportedAt': (now ?? DateTime.now()).toIso8601String(),
        'assets': [for (final a in assets) a.toRow()],
      }),
    );
    final box = await _cipher.encrypt(payload, secretKey: key);
    return utf8.encode(
      jsonEncode({
        'format': format,
        'version': version,
        'kdf': 'pbkdf2-hmac-sha256',
        'iterations': iterations,
        'salt': base64Encode(salt),
        'nonce': base64Encode(box.nonce),
        'mac': base64Encode(box.mac.bytes),
        'ciphertext': base64Encode(box.cipherText),
      }),
    );
  }

  Future<List<Asset>> decode(List<int> file, String password) async {
    final Map<String, Object?> envelope;
    final List<int> salt, nonce, mac, cipherText;
    final int fileIterations;
    try {
      envelope = (jsonDecode(utf8.decode(file)) as Map).cast();
      if (envelope['format'] != format) throw const FormatException();
      fileIterations = envelope['iterations'] as int;
      salt = base64Decode(envelope['salt'] as String);
      nonce = base64Decode(envelope['nonce'] as String);
      mac = base64Decode(envelope['mac'] as String);
      cipherText = base64Decode(envelope['ciphertext'] as String);
    } catch (_) {
      throw const BackupException('This is not a Vault Nama backup file');
    }
    if ((envelope['version'] as int? ?? 0) > version) {
      throw const BackupException(
        'This backup was made by a newer version of the app',
      );
    }
    if (fileIterations < 1 || fileIterations > _maxIterations) {
      throw const BackupException('This backup file is damaged');
    }

    final key = await _deriveKey(password, salt, fileIterations);
    final List<int> payload;
    try {
      payload = await _cipher.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
      );
    } on SecretBoxAuthenticationError {
      throw const BackupException('Wrong backup password');
    }
    try {
      final data = jsonDecode(utf8.decode(payload)) as Map;
      return [
        for (final row in data['assets'] as List)
          Asset.fromRow((row as Map).cast()),
      ];
    } catch (_) {
      throw const BackupException('This backup file is damaged');
    }
  }

  static Future<SecretKey> _deriveKey(
    String password,
    List<int> salt,
    int iterations,
  ) => Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  ).deriveKeyFromPassword(password: password, nonce: salt);
}
