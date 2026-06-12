import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/agent_query_failure_diagnostic.dart';

const int overviewTechnicalSummaryMaxChars = 4096;

/// Compact one-line technical summary for partial-failure list rows.
String overviewAgentQueryFailureTechnicalSummary(AppFailure failure) {
  final buffer = StringBuffer()
    ..write(failure.runtimeType)
    ..write(': ')
    ..write(failure.message);
  if (failure is RpcFailure) {
    buffer
      ..write(' | rpcCode=')
      ..write(failure.rpcCode)
      ..write(' | reason=')
      ..write(truncateAgentQueryDiagnosticField(failure.reason))
      ..write(' | correlationId=')
      ..write(truncateAgentQueryDiagnosticField(failure.correlationId));
  }
  var out = buffer.toString();
  if (out.length > overviewTechnicalSummaryMaxChars) {
    out = '${out.substring(0, overviewTechnicalSummaryMaxChars)}…(truncated)';
  }
  return out;
}
