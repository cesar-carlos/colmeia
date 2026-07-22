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
