import 'package:colmeia/core/errors/app_failure.dart';

final _agentIdPattern = RegExp(
  r'\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b',
  caseSensitive: false,
);

/// When hub/bridge errors mention a different agent id than the store row,
/// returns that referenced id so UI can clarify bridge vs branch identifiers.
String? overviewFailureReferencedAgentId({
  required String detailAgentId,
  required AppFailure failure,
}) {
  final normalizedDetail = detailAgentId.trim().toLowerCase();
  if (normalizedDetail.isEmpty) {
    return null;
  }

  final haystack = StringBuffer()
    ..write(failure.message)
    ..write(' ')
    ..write(failure.userMessage);
  if (failure is RpcFailure) {
    haystack
      ..write(' ')
      ..write(failure.reason ?? '')
      ..write(' ')
      ..write(failure.technicalMessage ?? '')
      ..write(' ')
      ..write(failure.correlationId ?? '');
  }

  for (final match in _agentIdPattern.allMatches(haystack.toString())) {
    final candidate = match.group(0)!.toLowerCase();
    if (candidate != normalizedDetail) {
      return match.group(0);
    }
  }
  return null;
}
