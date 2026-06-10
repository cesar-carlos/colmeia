import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:result_dart/result_dart.dart';

/// Outcome of a required-string validator: trimmed value on success,
/// pre-built `Failure` on error. Lets call sites `switch` on the result
/// without writing yet another guard clause.
typedef RequiredStringValidation<T extends Object> = ({
  String trimmed,
  AppResult<T>? failure,
});

/// Returns the trimmed value or, if blank, a `Failure` carrying a
/// [ValidationFailure] with [technicalMessage] (English, for logs) and
/// [userMessage] (translated, for UI).
///
/// Generic over `T` so callers can wire it into any
/// `Future<AppResult<T>>` return type without casting.
RequiredStringValidation<T> requireNonEmptyId<T extends Object>(
  String? rawValue, {
  required String technicalMessage,
  required String userMessage,
}) {
  final trimmed = rawValue?.trim() ?? '';
  if (trimmed.isEmpty) {
    return (
      trimmed: trimmed,
      failure: Failure<T, AppFailure>(
        ValidationFailure(
          message: technicalMessage,
          userMessage: userMessage,
        ),
      ),
    );
  }
  return (trimmed: trimmed, failure: null);
}

/// Convenience for the most common case: validating an `agentId`.
RequiredStringValidation<T> requireAgentId<T extends Object>(String? agentId) {
  return requireNonEmptyId<T>(
    agentId,
    technicalMessage: 'Agent id is empty',
    userMessage: 'Invalid agent identifier.',
  );
}

/// Convenience for validating a request/access-request id.
RequiredStringValidation<T> requireRequestId<T extends Object>(
  String? requestId,
) {
  return requireNonEmptyId<T>(
    requestId,
    technicalMessage: 'Request id is empty',
    userMessage: 'Invalid request identifier.',
  );
}

/// Convenience for validating a client access token (deep link / email
/// link payload).
RequiredStringValidation<T> requireClientAccessToken<T extends Object>(
  String? token,
) {
  return requireNonEmptyId<T>(
    token,
    technicalMessage: 'Client access token is empty',
    userMessage: 'Invalid access link.',
  );
}
