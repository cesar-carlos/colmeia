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
    return NetworkFailure(
      message: fallbackMessage ?? 'Network request failed',
      userMessage:
          fallbackUserMessage ??
          'Nao foi possivel concluir a comunicacao com o servidor.',
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
