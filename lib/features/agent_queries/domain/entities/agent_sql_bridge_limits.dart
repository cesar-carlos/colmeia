import 'dart:convert';

/// Hub contract limits for Agent SQL bridge requests.
///
/// Values match `plug_server` bridge validation so Colmeia fails locally
/// instead of receiving `invalid_params` from the hub.
abstract final class AgentSqlBridgeLimits {
  static const int namedParamsJsonMaxUtf8Bytes = 2 * 1024 * 1024;
  static const int pageSizeMax = 50000;
  static const int maxRowsMax = 1000000;
  static const int sqlTimeoutMsMax = 300000;
  static const int bridgeTimeoutMsMax = 360000;

  /// Returns a validation error when [namedParams] exceeds the UTF-8 JSON size
  /// cap, or `null` when within limits.
  static String? namedParamsUtf8JsonSizeError(
    Map<String, Object?> namedParams,
  ) {
    final byteLength = utf8.encode(jsonEncode(namedParams)).length;
    if (byteLength > namedParamsJsonMaxUtf8Bytes) {
      return 'namedParams JSON must be at most '
          '$namedParamsJsonMaxUtf8Bytes UTF-8 bytes (Agent SQL bridge limit)';
    }
    return null;
  }
}
