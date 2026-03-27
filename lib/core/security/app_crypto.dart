import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

abstract final class AppCrypto {
  static String hashSha256(String value) {
    return _encodeDigest(
      crypto.sha256.convert(utf8.encode(value)),
    );
  }

  static String hashSha256WithSalt({
    required String value,
    required String salt,
  }) {
    return hashSha256('$value:$salt');
  }

  static String signHmacSha256({
    required String value,
    required String secret,
  }) {
    final hmac = crypto.Hmac(
      crypto.sha256,
      utf8.encode(secret),
    );

    return _encodeDigest(
      hmac.convert(utf8.encode(value)),
    );
  }

  static bool secureEquals(String left, String right) {
    final leftBytes = utf8.encode(left);
    final rightBytes = utf8.encode(right);
    final maxLength = leftBytes.length > rightBytes.length
        ? leftBytes.length
        : rightBytes.length;
    var difference = leftBytes.length ^ rightBytes.length;

    for (var index = 0; index < maxLength; index++) {
      final leftByte = index < leftBytes.length ? leftBytes[index] : 0;
      final rightByte = index < rightBytes.length ? rightBytes[index] : 0;
      difference |= leftByte ^ rightByte;
    }

    return difference == 0;
  }

  static String _encodeDigest(crypto.Digest digest) => digest.toString();
}
