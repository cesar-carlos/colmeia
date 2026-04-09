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
  });
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
  });
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
    final resolvedUserMessage = _resolveDioUserMessage(
      error,
      fallbackUserMessage: fallbackUserMessage,
    );
    return NetworkFailure(
      message: fallbackMessage ?? 'Network request failed',
      userMessage: resolvedUserMessage,
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
