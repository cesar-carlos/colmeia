/// Matches the generic "agent RPC failed" copy in the app. Keep wording
/// transport-agnostic because the same bridge envelope is used by REST
/// and socket channels.
const String kBridgeRpcGenericUserMessageEn =
    'The agent RPC call could not be completed.';

class BridgeRpcErrorDetails {
  const BridgeRpcErrorDetails({
    required this.userMessage,
    required this.message,
    this.code,
    this.reason,
    this.category,
    this.retryable = false,
    this.technicalMessage,
    this.correlationId,
    this.timestamp,
    this.errorData,
  });

  final String userMessage;
  final String message;
  final String? code;
  final String? reason;
  final String? category;
  final bool retryable;
  final String? technicalMessage;
  final String? correlationId;
  final DateTime? timestamp;
  final Map<String, dynamic>? errorData;

  int? get codeAsInt {
    final raw = code;
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return int.tryParse(raw);
  }
}

final class BridgeRpcException implements Exception {
  BridgeRpcException(this.details);

  final BridgeRpcErrorDetails details;

  @override
  String toString() => details.userMessage;
}

/// Generic parser for the bridge envelope shared by REST and socket
/// transports. Consumers can reuse it for non-SQL RPC methods whose
/// inner `result` is just a plain JSON object.
abstract final class BridgeRpcResponse {
  static Map<String, Object?> parseSingleResultMap(Map<String, dynamic> json) {
    final response = json['response'];
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Bridge response missing "response" object');
    }

    if (response['success'] == false) {
      throw BridgeRpcException(_readRpcErrorDetails(response));
    }

    final item = response['item'];
    if (item is! Map<String, dynamic>) {
      throw const FormatException('Bridge response missing "item" object');
    }

    if (item['success'] == false) {
      throw BridgeRpcException(_readItemErrorDetails(item));
    }

    final itemError = item['error'];
    if (itemError is Map) {
      throw BridgeRpcException(_readItemErrorDetails(item));
    }

    final result = item['result'];
    if (result is! Map) {
      throw const FormatException('Bridge item missing "result" object');
    }

    return result.map(
      (key, value) => MapEntry<String, Object?>(key.toString(), value),
    );
  }

  static bool isMethodNotFound(BridgeRpcException error) {
    final code = error.details.code?.trim();
    final reason = error.details.reason?.trim().toLowerCase();
    return code == '-32601' || reason == 'method_not_found';
  }

  static BridgeRpcErrorDetails _readRpcErrorDetails(
    Map<String, dynamic> response,
  ) {
    final item = response['item'];
    if (item is Map<String, dynamic>) {
      return _readItemErrorDetails(item);
    }
    return const BridgeRpcErrorDetails(
      userMessage: kBridgeRpcGenericUserMessageEn,
      message: 'Agent RPC failed without item payload',
    );
  }

  static BridgeRpcErrorDetails _readItemErrorDetails(
    Map<String, dynamic> item,
  ) {
    final error = item['error'];
    if (error is! Map) {
      return const BridgeRpcErrorDetails(
        userMessage: kBridgeRpcGenericUserMessageEn,
        message: 'Agent RPC failed without error payload',
      );
    }
    final errorMap = Map<String, dynamic>.from(error);
    final data = errorMap['data'];
    final dataMap = data is Map ? Map<String, dynamic>.from(data) : null;
    final errorDataPayload = dataMap != null && dataMap.isNotEmpty
        ? Map<String, dynamic>.unmodifiable(
            Map<String, dynamic>.from(dataMap),
          )
        : null;
    final userMessage =
        _readNonEmptyString(
          dataMap,
          const <String>['user_message', 'userMessage'],
        ) ??
        _readNonEmptyString(errorMap, const <String>['message']) ??
        kBridgeRpcGenericUserMessageEn;
    final message =
        _readNonEmptyString(errorMap, const <String>['message']) ?? userMessage;

    return BridgeRpcErrorDetails(
      userMessage: userMessage,
      message: message,
      code: errorMap['code']?.toString(),
      reason: _readNonEmptyString(dataMap, const <String>['reason']),
      category: _readNonEmptyString(dataMap, const <String>['category']),
      retryable: _readBool(dataMap, const <String>['retryable']) ?? false,
      technicalMessage: _readNonEmptyString(
        dataMap,
        const <String>['technical_message', 'technicalMessage'],
      ),
      correlationId: _readNonEmptyString(
        dataMap,
        const <String>['correlation_id', 'correlationId'],
      ),
      timestamp: _readDateTime(
        _readNonEmptyString(dataMap, const <String>['timestamp']),
      ),
      errorData: errorDataPayload,
    );
  }

  static bool? _readBool(Map<String, dynamic>? json, List<String> keys) {
    if (json == null) {
      return null;
    }
    for (final key in keys) {
      final value = json[key];
      if (value is bool) {
        return value;
      }
    }
    return null;
  }

  static String? _readNonEmptyString(
    Map<String, dynamic>? json,
    List<String> keys,
  ) {
    if (json == null) {
      return null;
    }
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static DateTime? _readDateTime(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }
}
