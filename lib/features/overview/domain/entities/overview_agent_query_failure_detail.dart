import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/presentation/agent_query_failure_diagnostic.dart'
    show truncateAgentQueryDiagnosticField;
import 'package:colmeia/features/agent_queries/presentation/localization/agent_query_failure_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';

export 'package:colmeia/features/agent_queries/presentation/agent_query_failure_diagnostic.dart'
    show overviewAppFailureDiagnosticBody;

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
    required this.failure,
  });

  final String agentId;
  final String displayName;
  final OverviewAgentQueryFailureSource source;
  final AppFailure failure;

  String userMessageFor(AppLocalizations l10n) =>
      agentQueryFailureUserMessage(failure, l10n);

  /// Optional support-oriented line (failure type, RPC codes); no stack traces.
  String? get technicalSummary =>
      overviewAgentQueryFailureTechnicalSummary(failure);
}

const int _overviewTechnicalSummaryMaxChars = 4096;

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
  if (out.length > _overviewTechnicalSummaryMaxChars) {
    out = '${out.substring(0, _overviewTechnicalSummaryMaxChars)}…(truncated)';
  }
  return out;
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
    failure: failure,
  );
}
