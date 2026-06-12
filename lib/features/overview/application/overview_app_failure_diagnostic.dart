import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/agent_query_failure_diagnostic.dart';

/// Overview load banner: friendly line first, then wire diagnostic block.
String overviewAppFailureDiagnosticBody(
  AppFailure failure, {
  String? localizedUserMessage,
}) {
  final friendly = localizedUserMessage?.trim();
  final technical = agentQueryFailureDiagnosticBody(failure);
  if (friendly == null || friendly.isEmpty) {
    return technical;
  }
  return <String>[
    'userFacingMessage: $friendly',
    ...technical.split('\n'),
  ].join('\n');
}
