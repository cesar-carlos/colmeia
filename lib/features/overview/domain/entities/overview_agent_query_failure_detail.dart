import 'package:colmeia/core/errors/app_failure.dart';

/// Which overview query produced this partial failure row.
enum OverviewAgentQueryFailureSource {
  paymentResumo,
  lucratividadePeriod,
  userResumo,
  monthlyTrend,
  weekdayTrend,
  weekdayUserTrend,
  dailyTrend,
  lucratividadeMensalTrend,
}

/// One agent-scoped failure captured during overview load for diagnostics UI.
class OverviewAgentQueryFailureDetail {
  const OverviewAgentQueryFailureDetail({
    required this.agentId,
    required this.displayName,
    required this.source,
    required this.userMessage,
    this.technicalSummary,
  });

  final String agentId;
  final String displayName;
  final OverviewAgentQueryFailureSource source;

  /// User-facing text (typically [AppFailure.displayMessage]).
  final String userMessage;

  /// Optional support-oriented line (failure type, RPC codes); no stack traces.
  final String? technicalSummary;
}

const int _overviewDiagnosticWireFieldMaxChars = 512;
const int _overviewDiagnosticTechnicalSummaryMaxChars = 4096;

String _truncateDiagnosticWireField(String? value) {
  if (value == null || value.isEmpty) {
    return '';
  }
  final t = value.trim();
  if (t.length <= _overviewDiagnosticWireFieldMaxChars) {
    return t;
  }
  return '${t.substring(0, _overviewDiagnosticWireFieldMaxChars)}…(${t.length} chars)';
}

/// Builds a short technical line for support (no stack traces).
String overviewAgentQueryFailureTechnicalSummary(AppFailure failure) {
  final buffer = StringBuffer()
    ..write(failure.runtimeType.toString())
    ..write(': ')
    ..write(failure.message);
  if (failure is RpcFailure) {
    buffer
      ..write(' | rpcCode=')
      ..write(failure.rpcCode)
      ..write(' | reason=')
      ..write(_truncateDiagnosticWireField(failure.reason))
      ..write(' | correlationId=')
      ..write(_truncateDiagnosticWireField(failure.correlationId));
  }
  var out = buffer.toString();
  if (out.length > _overviewDiagnosticTechnicalSummaryMaxChars) {
    out =
        '${out.substring(0, _overviewDiagnosticTechnicalSummaryMaxChars)}…(truncated)';
  }
  return out;
}

/// Multi-line diagnostic for a top-level overview load failure (no stack traces).
String overviewAppFailureDiagnosticBody(AppFailure failure) {
  return <String>[
    failure.runtimeType.toString(),
    failure.displayMessage,
    overviewAgentQueryFailureTechnicalSummary(failure),
  ].join('\n');
}

OverviewAgentQueryFailureDetail overviewLucratividadePartialFailureDetail({
  required String agentId,
  required String displayName,
  required AppFailure failure,
}) {
  return overviewPartialFailureDetailForSource(
    agentId: agentId,
    displayName: displayName,
    failure: failure,
    source: OverviewAgentQueryFailureSource.lucratividadePeriod,
  );
}

/// Shared constructor used by every per-section partial-failure detail so the
/// shape stays consistent across `lucratividade`, `monthly`, `weekday`, etc.
OverviewAgentQueryFailureDetail overviewPartialFailureDetailForSource({
  required String agentId,
  required String displayName,
  required AppFailure failure,
  required OverviewAgentQueryFailureSource source,
}) {
  return OverviewAgentQueryFailureDetail(
    agentId: agentId,
    displayName: displayName,
    source: source,
    userMessage: failure.displayMessage,
    technicalSummary: overviewAgentQueryFailureTechnicalSummary(failure),
  );
}
