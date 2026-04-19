import 'dart:io';

import 'package:colmeia/core/value_objects/value_object_validation_exception.dart';
import 'package:dio/dio.dart';

sealed class AppFailure implements Exception {
  const AppFailure({
    required this.message,
    this.userMessage,
    this.cause,
    this.stackTrace,
    this.context = const <String, Object?>{},
    this.isTransient = false,
  });

  final String message;
  final String? userMessage;
  final Object? cause;
  final StackTrace? stackTrace;
  final Map<String, Object?> context;
  final bool isTransient;

  String get displayMessage => userMessage ?? message;

  @override
  String toString() => displayMessage;
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure({
    required super.message,
    super.userMessage,
    super.cause,
    super.stackTrace,
    super.context,
  });
}

final class SessionFailure extends AppFailure {
  const SessionFailure({
    required super.message,
    super.userMessage,
    super.cause,
    super.stackTrace,
    super.context,
  }) : super(isTransient: false);
}

/// HTTP 403 or equivalent: authenticated but not allowed to perform the action.
final class AuthorizationFailure extends AppFailure {
  const AuthorizationFailure({
    required super.message,
    super.userMessage,
    super.cause,
    super.stackTrace,
    super.context,
  }) : super(isTransient: false);
}

/// Stable context fields for HTTP 403 authorization failures.
abstract final class AuthorizationFailureContext {
  static const String accountBlockedField = 'accountBlocked';
}

bool isBlockedAccountFailure(AppFailure failure) =>
    failure is AuthorizationFailure &&
    failure.context[AuthorizationFailureContext.accountBlockedField] == true;

/// True when an API response body indicates a blocked client account.
///
/// Used for HTTP 403 on client-scoped reads where a generic 403 often means
/// "no relationship" / not linked and must not be confused with a block.
bool isBlockedAccountApiPayload(Object? responseData) {
  return _isBlockedAccountResponse(responseData);
}

/// Returns true when the response indicates the caller should not use cached
/// snapshots (session expired or forbidden).
bool isDioUnauthorizedOrForbidden(DioException error) {
  final code = error.response?.statusCode;
  return code == 401 || code == 403;
}

/// Wire-level API error `code` values mapped by [mapToAppFailure] for HTTP 409.
abstract final class ApiConflictErrorCode {
  static const String agentDocumentConflict = 'AGENT_DOCUMENT_CONFLICT';

  /// Agent profile CAS mismatch — `expectedProfileVersion` did not match
  /// the current server `profileVersion`, OR the same `Idempotency-Key`
  /// was reused with a different body. UI should reload the agent and
  /// ask the user to retry on top of the fresh data.
  static const String agentProfileCasMismatch = 'AGENT_PROFILE_CAS_MISMATCH';
}

/// Context keys for conflict and API error mapping.
abstract final class ApiErrorContext {
  static const String apiErrorCode = 'apiErrorCode';
}

final class StorageFailure extends AppFailure {
  const StorageFailure({
    required super.message,
    super.userMessage,
    super.cause,
    super.stackTrace,
    super.context,
  });
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({
    required super.message,
    super.userMessage,
    super.cause,
    super.stackTrace,
    super.context,
    super.isTransient = true,
    this.retryAfter,
  });

  /// Hint extracted from the `Retry-After` HTTP header (or its socket
  /// equivalents `error.data.retry_after_ms` / `reset_at`) propagated by
  /// the hub when a request is rate-limited. Callers SHOULD surface this
  /// as a wait period to the user before allowing manual retry.
  ///
  /// `null` when the response did not carry a hint.
  final Duration? retryAfter;
}

final class RpcFailure extends AppFailure {
  const RpcFailure({
    required super.message,
    required super.userMessage,
    required this.rpcCode,
    required this.retryable,
    this.reason,
    this.category,
    this.technicalMessage,
    this.correlationId,
    this.timestamp,
    super.cause,
    super.stackTrace,
    super.context,
  }) : super(isTransient: retryable);

  final int? rpcCode;
  final bool retryable;
  final String? reason;
  final String? category;
  final String? technicalMessage;
  final String? correlationId;
  final DateTime? timestamp;
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure({
    required super.message,
    super.userMessage,
    super.cause,
    super.stackTrace,
    super.context,
  });
}

/// Returns [failure] with [extra] merged into [AppFailure.context].
///
/// Later keys in [extra] overwrite earlier context entries.
AppFailure appFailureWithMergedContext(
  AppFailure failure,
  Map<String, Object?> extra,
) {
  final mergedContext = <String, Object?>{
    ...failure.context,
    ...extra,
  };

  return switch (failure) {
    ValidationFailure() => ValidationFailure(
      message: failure.message,
      userMessage: failure.userMessage,
      cause: failure.cause,
      stackTrace: failure.stackTrace,
      context: mergedContext,
    ),
    SessionFailure() => SessionFailure(
      message: failure.message,
      userMessage: failure.userMessage,
      cause: failure.cause,
      stackTrace: failure.stackTrace,
      context: mergedContext,
    ),
    AuthorizationFailure() => AuthorizationFailure(
      message: failure.message,
      userMessage: failure.userMessage,
      cause: failure.cause,
      stackTrace: failure.stackTrace,
      context: mergedContext,
    ),
    StorageFailure() => StorageFailure(
      message: failure.message,
      userMessage: failure.userMessage,
      cause: failure.cause,
      stackTrace: failure.stackTrace,
      context: mergedContext,
    ),
    NetworkFailure() => NetworkFailure(
      message: failure.message,
      userMessage: failure.userMessage,
      cause: failure.cause,
      stackTrace: failure.stackTrace,
      context: mergedContext,
      isTransient: failure.isTransient,
    ),
    RpcFailure() => RpcFailure(
      message: failure.message,
      userMessage: failure.userMessage ?? failure.message,
      rpcCode: failure.rpcCode,
      retryable: failure.retryable,
      reason: failure.reason,
      category: failure.category,
      technicalMessage: failure.technicalMessage,
      correlationId: failure.correlationId,
      timestamp: failure.timestamp,
      cause: failure.cause,
      stackTrace: failure.stackTrace,
      context: mergedContext,
    ),
    UnknownFailure() => UnknownFailure(
      message: failure.message,
      userMessage: failure.userMessage,
      cause: failure.cause,
      stackTrace: failure.stackTrace,
      context: mergedContext,
    ),
  };
}

/// Maps low-level failures to [AppFailure].
///
/// [DioException] with HTTP 401 becomes [SessionFailure] and 403 becomes
/// [AuthorizationFailure]; both are non-transient and must not trigger cache
/// fallbacks for authenticated resources. For rare flows where 403 means
/// something other than "authenticated but forbidden" (for example a public
/// endpoint), handle that case before calling this function or adjust the
/// mapped [AppFailure] afterward.
AppFailure mapToAppFailure(
  Object error, {
  StackTrace? stackTrace,
  String? fallbackMessage,
  String? fallbackUserMessage,
  Map<String, Object?> context = const <String, Object?>{},
}) {
  if (error is AppFailure) {
    return error;
  }

  if (error is ValueObjectValidationException) {
    return ValidationFailure(
      message: error.toString(),
      userMessage: error.messages.join(', '),
      cause: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    final resolvedUserMessage = _resolveDioUserMessage(
      error,
      fallbackUserMessage: fallbackUserMessage,
    );
    final retryAfter = _extractRetryAfterFromDio(error);
    if (statusCode == 401) {
      return SessionFailure(
        message: fallbackMessage ?? 'Unauthorized request',
        userMessage: resolvedUserMessage,
        cause: error,
        stackTrace: stackTrace,
        context: <String, Object?>{
          ...context,
          'httpStatusCode': statusCode,
        },
      );
    }
    if (statusCode == 403) {
      if (_isBlockedAccountResponse(responseData)) {
        return AuthorizationFailure(
          message: fallbackMessage ?? 'Forbidden request',
          userMessage: _resolveBlockedAccountUserMessage(
            fallbackUserMessage: fallbackUserMessage,
          ),
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            ...context,
            'httpStatusCode': statusCode,
            AuthorizationFailureContext.accountBlockedField: true,
          },
        );
      }
      return AuthorizationFailure(
        message: fallbackMessage ?? 'Forbidden request',
        userMessage: resolvedUserMessage,
        cause: error,
        stackTrace: stackTrace,
        context: <String, Object?>{
          ...context,
          'httpStatusCode': statusCode,
        },
      );
    }
    if (statusCode == 409) {
      final apiCode = _extractApiErrorCode(responseData);
      if (apiCode == ApiConflictErrorCode.agentDocumentConflict) {
        return ValidationFailure(
          message: 'Agent document conflict',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            ...context,
            'httpStatusCode': statusCode,
            ApiErrorContext.apiErrorCode:
                ApiConflictErrorCode.agentDocumentConflict,
          },
        );
      }
      if (apiCode == ApiConflictErrorCode.agentProfileCasMismatch) {
        return ValidationFailure(
          message: 'Agent profile CAS mismatch',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            ...context,
            'httpStatusCode': statusCode,
            ApiErrorContext.apiErrorCode:
                ApiConflictErrorCode.agentProfileCasMismatch,
          },
        );
      }
      return NetworkFailure(
        message: fallbackMessage ?? 'Conflict request',
        userMessage: resolvedUserMessage,
        cause: error,
        stackTrace: stackTrace,
        retryAfter: retryAfter,
        context: <String, Object?>{
          ...context,
          'httpStatusCode': statusCode,
        },
      );
    }
    return NetworkFailure(
      message: fallbackMessage ?? 'Network request failed',
      userMessage: resolvedUserMessage,
      retryAfter: retryAfter,
      cause: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  return UnknownFailure(
    message: fallbackMessage ?? 'Unexpected application failure',
    userMessage:
        fallbackUserMessage ?? 'Ocorreu um erro inesperado. Tente novamente.',
    cause: error,
    stackTrace: stackTrace,
    context: context,
  );
}

String _resolveDioUserMessage(
  DioException error, {
  String? fallbackUserMessage,
}) {
  final responseData = error.response?.data;
  final apiMessage = _extractApiErrorMessage(responseData);
  if (apiMessage != null) {
    return apiMessage;
  }

  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout =>
      'A comunicacao com o servidor demorou mais do que o esperado.',
    DioExceptionType.connectionError =>
      'Nao foi possivel conectar ao servidor. '
          'Verifique sua internet e tente novamente.',
    DioExceptionType.badCertificate =>
      'Nao foi possivel validar a seguranca da conexao com o servidor.',
    DioExceptionType.cancel => 'A solicitacao foi cancelada.',
    _ =>
      fallbackUserMessage ??
          'Nao foi possivel concluir a comunicacao com o servidor.',
  };
}

String _resolveBlockedAccountUserMessage({String? fallbackUserMessage}) {
  return fallbackUserMessage ??
      'Sua conta esta bloqueada. Entre em contato com o administrador.';
}

String? _extractApiErrorCode(Object? responseData) {
  if (responseData is! Map<String, dynamic>) {
    return null;
  }
  return _readFirstNonEmptyString(
    responseData,
    const <String>['code', 'errorCode', 'failure_code'],
  );
}

/// Resolves the `Retry-After` hint for a [DioException].
///
/// Inspects, in order:
///
/// 1. The `Retry-After` HTTP header (RFC 7231 — either delta-seconds or
///    HTTP-date).
/// 2. JSON-RPC `error.data.retry_after_ms` propagated by the hub for the
///    `-32013` rate-limit family (e.g. `client_token.getPolicy`).
/// 3. JSON-RPC `error.data.reset_at` (HTTP-date or epoch seconds).
///
/// Returns `null` when the response did not carry a hint.
Duration? _extractRetryAfterFromDio(DioException error) {
  final headerValue = _firstHeaderValue(
    error.response?.headers.map,
    'retry-after',
  );
  final headerHint = _parseRetryAfterHeader(headerValue);
  if (headerHint != null) {
    return headerHint;
  }
  final responseData = error.response?.data;
  if (responseData is Map) {
    final errorBody = responseData['error'];
    if (errorBody is Map) {
      final data = errorBody['data'];
      if (data is Map) {
        final ms = data['retry_after_ms'] ?? data['retryAfterMs'];
        final fromMs = _parseDurationFromMillis(ms);
        if (fromMs != null) {
          return fromMs;
        }
        final resetAt = data['reset_at'] ?? data['resetAt'];
        final fromReset = _parseRetryAfterHeader(resetAt?.toString());
        if (fromReset != null) {
          return fromReset;
        }
      }
    }
  }
  return null;
}

String? _firstHeaderValue(
  Map<String, List<String>>? headers,
  String name,
) {
  if (headers == null) {
    return null;
  }
  final lower = name.toLowerCase();
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == lower) {
      for (final value in entry.value) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          return trimmed;
        }
      }
    }
  }
  return null;
}

Duration? _parseRetryAfterHeader(String? raw) {
  if (raw == null) {
    return null;
  }
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final asInt = int.tryParse(trimmed);
  if (asInt != null) {
    if (asInt <= 0) {
      return Duration.zero;
    }
    return Duration(seconds: asInt);
  }
  final asDate = DateTime.tryParse(trimmed) ?? _tryParseHttpDate(trimmed);
  if (asDate != null) {
    final delta = asDate.toUtc().difference(DateTime.now().toUtc());
    if (delta.isNegative) {
      return Duration.zero;
    }
    return delta;
  }
  return null;
}

Duration? _parseDurationFromMillis(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is num) {
    final ms = raw.toInt();
    if (ms < 0) {
      return Duration.zero;
    }
    return Duration(milliseconds: ms);
  }
  if (raw is String) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null) {
      return null;
    }
    if (parsed < 0) {
      return Duration.zero;
    }
    return Duration(milliseconds: parsed);
  }
  return null;
}

DateTime? _tryParseHttpDate(String value) {
  try {
    return HttpDate.parse(value);
  } on Object {
    return null;
  }
}

String? _extractApiErrorMessage(Object? responseData) {
  if (responseData is String) {
    final trimmed = responseData.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  if (responseData is! Map<String, dynamic>) {
    return null;
  }

  final directMessage = _readFirstNonEmptyString(
    responseData,
    const <String>['userMessage', 'message', 'error', 'detail', 'title'],
  );
  final validationMessage = _extractValidationMessage(responseData);

  return validationMessage ?? directMessage;
}

bool _isBlockedAccountResponse(Object? responseData) {
  if (responseData is String) {
    return _looksLikeBlockedAccountText(responseData);
  }

  if (responseData is! Map<String, dynamic>) {
    return false;
  }

  final directMessage = _readFirstNonEmptyString(
    responseData,
    const <String>[
      'userMessage',
      'message',
      'error',
      'detail',
      'title',
      'failure_code',
      'reason',
      'type',
    ],
  );

  return directMessage != null && _looksLikeBlockedAccountText(directMessage);
}

bool _looksLikeBlockedAccountText(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    return false;
  }

  return normalized == 'account is blocked' ||
      normalized.contains('account_blocked') ||
      normalized.contains('user_blocked') ||
      normalized.contains('client_blocked') ||
      (normalized.contains('account') && normalized.contains('blocked')) ||
      (normalized.contains('conta') && normalized.contains('bloquead'));
}

String? _extractValidationMessage(Map<String, dynamic> json) {
  final rawErrors = json['errors'] ?? json['details'];
  if (rawErrors is List<dynamic>) {
    final messages = rawErrors
        .map(_stringifyValidationEntry)
        .whereType<String>()
        .map((message) => message.trim())
        .where((message) => message.isNotEmpty)
        .toList(growable: false);
    if (messages.isNotEmpty) {
      return messages.join('\n');
    }
  }

  if (rawErrors is Map<String, dynamic>) {
    final messages = <String>[];
    for (final entry in rawErrors.entries) {
      final field = entry.key.trim();
      final value = entry.value;
      if (value is List<dynamic>) {
        for (final item in value) {
          final message = item?.toString().trim();
          if (message != null && message.isNotEmpty) {
            messages.add(field.isEmpty ? message : '$field: $message');
          }
        }
      } else {
        final message = value?.toString().trim();
        if (message != null && message.isNotEmpty) {
          messages.add(field.isEmpty ? message : '$field: $message');
        }
      }
    }
    if (messages.isNotEmpty) {
      return messages.join('\n');
    }
  }

  return null;
}

String? _stringifyValidationEntry(Object? entry) {
  if (entry == null) {
    return null;
  }
  if (entry is String) {
    return entry;
  }
  if (entry is Map<String, dynamic>) {
    final field = _readFirstNonEmptyString(
      entry,
      const <String>['field', 'path', 'property'],
    );
    final message = _readFirstNonEmptyString(
      entry,
      const <String>['message', 'error', 'detail'],
    );
    if (message == null) {
      return null;
    }
    if (field == null || field.isEmpty) {
      return message;
    }
    return '$field: $message';
  }
  return entry.toString();
}

String? _readFirstNonEmptyString(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}
