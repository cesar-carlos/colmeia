import 'dart:convert';

import 'package:colmeia/core/cache/app_cache_store.dart' show AppCacheStore;

/// JSON envelope stored in [AppCacheStore] for fact payloads.
final class AgentQueryFactsEnvelope {
  const AgentQueryFactsEnvelope({
    required this.schemaVersion,
    required this.payloadBase64,
  });

  factory AgentQueryFactsEnvelope.fromJson(Map<String, dynamic> json) {
    return AgentQueryFactsEnvelope(
      schemaVersion: json['schemaVersion'] as int? ?? 0,
      payloadBase64: json['payloadBase64'] as String? ?? '',
    );
  }

  final int schemaVersion;
  final String payloadBase64;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': schemaVersion,
    'payloadBase64': payloadBase64,
  };

  static List<int> decodePayloadBase64(String base64) {
    return base64Decode(base64);
  }

  static String encodePayloadBase64(List<int> bytes) {
    return base64Encode(bytes);
  }
}
