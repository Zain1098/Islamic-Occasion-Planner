import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class BackupEncryption {
  static const format = 'noor-encrypted-backup';
  static const _iterations = 150000;

  final _cipher = AesGcm.with256bits();
  final _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _iterations,
    bits: 256,
  );

  Future<String> encrypt(String plainText, String pin) async {
    _validatePin(pin);
    final salt = _randomBytes(16);
    final nonce = _randomBytes(12);
    final key = await _keyFor(pin, salt);
    final box = await _cipher.encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: nonce,
    );
    return jsonEncode({
      'format': format,
      'version': 1,
      'kdf': 'PBKDF2-HMAC-SHA256',
      'iterations': _iterations,
      'salt': base64Encode(salt),
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  Future<String> decrypt(String encryptedJson, String pin) async {
    _validatePin(pin);
    final decoded = jsonDecode(encryptedJson);
    if (decoded is! Map<String, dynamic> ||
        decoded['format'] != format ||
        decoded['version'] != 1) {
      throw const FormatException(
        'This is not a supported encrypted Noor backup.',
      );
    }
    try {
      final salt = base64Decode(decoded['salt'] as String);
      final nonce = base64Decode(decoded['nonce'] as String);
      final ciphertext = base64Decode(decoded['ciphertext'] as String);
      final mac = Mac(base64Decode(decoded['mac'] as String));
      final key = await _keyFor(pin, salt);
      final bytes = await _cipher.decrypt(
        SecretBox(ciphertext, nonce: nonce, mac: mac),
        secretKey: key,
      );
      return utf8.decode(bytes);
    } on SecretBoxAuthenticationError {
      throw const FormatException(
        'PIN is incorrect or this backup was changed.',
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Encrypted backup data is invalid.');
    }
  }

  Future<SecretKey> _keyFor(String pin, List<int> salt) =>
      _kdf.deriveKey(secretKey: SecretKey(utf8.encode(pin)), nonce: salt);

  List<int> _randomBytes(int length) => Uint8List.fromList(
    List<int>.generate(length, (_) => Random.secure().nextInt(256)),
  );

  void _validatePin(String pin) {
    if (pin.length < 6)
      throw const FormatException('Use a PIN of at least 6 characters.');
  }
}
