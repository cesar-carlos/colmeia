import 'dart:convert';

DateTime deriveTokenExpiry({
  required String accessToken,
  Duration fallbackTtl = const Duration(hours: 8),
}) {
  final fallback = DateTime.now().add(fallbackTtl);
  final tokenParts = accessToken.split('.');
  if (tokenParts.length < 2) {
    return fallback;
  }

  try {
    final normalized = base64Url.normalize(tokenParts[1]);
    final payload = utf8.decode(base64Url.decode(normalized));
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) {
      return fallback;
    }

    final expirySeconds = decoded['exp'];
    if (expirySeconds is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        expirySeconds * 1000,
        isUtc: true,
      ).toLocal();
    }
    if (expirySeconds is String) {
      final parsed = int.tryParse(expirySeconds);
      if (parsed != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          parsed * 1000,
          isUtc: true,
        ).toLocal();
      }
    }
  } on FormatException {
    return fallback;
  }

  return fallback;
}
