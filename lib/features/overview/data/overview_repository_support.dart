import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row_v2.dart';
import 'package:colmeia/features/overview/data/overview_batch_load_result.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_policy.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/overview_failure_ui_key.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:result_dart/result_dart.dart';

const String overviewSourceAgentIdsContextField = 'sourceAgentIds';

const Set<OverviewProgressiveSection> overviewAllProgressiveSections =
    <OverviewProgressiveSection>{
      OverviewProgressiveSection.summary,
      OverviewProgressiveSection.dailySales,
      OverviewProgressiveSection.monthlyParcels,
      OverviewProgressiveSection.paymentMix,
      OverviewProgressiveSection.weekdaySales,
      OverviewProgressiveSection.weekdayUserSales,
      OverviewProgressiveSection.agentRanking,
      OverviewProgressiveSection.userRanking,
      OverviewProgressiveSection.lucratividadePeriod,
    };

class OverviewPeriod {
  const OverviewPeriod({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}

OverviewPeriod buildOverviewPeriod(
  DashboardFilter filter, {
  required DateTime Function() now,
}) {
  final rr = filter.referenceRange;
  if (rr != null) {
    final start = DateTime(
      rr.startInclusive.year,
      rr.startInclusive.month,
      rr.startInclusive.day,
    );
    final end = DateTime(
      rr.endInclusive.year,
      rr.endInclusive.month,
      rr.endInclusive.day + 1,
    ).subtract(const Duration(microseconds: 1));
    return OverviewPeriod(start: start, end: end);
  }

  final yearMonth = filter.yearMonth;
  final DateTime start;
  final DateTime end;

  if (yearMonth != null) {
    start = yearMonth.start;
    end = yearMonth.end;
  } else {
    final clock = now();
    end = DateTime(clock.year, clock.month, clock.day);
    start = end.subtract(const Duration(days: 29));
  }

  return OverviewPeriod(start: start, end: end);
}

AgentQueryExecutionStrategy resolveOverviewExecutionStrategy(
  DashboardFilter filter,
) {
  final selectedAgentIds = filter.selectedAgentIds;
  if (selectedAgentIds != null && selectedAgentIds.length == 1) {
    return AgentQueryExecutionStrategy.singleSource;
  }
  return AgentQueryExecutionStrategy.mergeAll;
}

Map<String, String> resolveAgentDisplayNames(
  AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRowV2> report,
) {
  return <String, String>{
    for (final target in report.plannedTargets)
      target.agentId: target.displayName,
    for (final target in report.missingClientTokenTargets)
      target.agentId: target.displayName,
  };
}

List<String> resolveSourceAgentIds(
  AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRowV2> report,
) {
  final ids = <String>{
    for (final target in report.plannedTargets) target.agentId,
    for (final target in report.missingClientTokenTargets) target.agentId,
  }.toList(growable: false)..sort();
  return ids;
}

List<String>? normalizeSelectedAgentIds(Set<String>? selectedAgentIds) {
  if (selectedAgentIds == null) {
    return null;
  }
  final ids =
      selectedAgentIds
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false)
        ..sort();
  return ids;
}

List<String>? resolveFailureSourceAgentIds(
  AppFailure failure, {
  required Set<String>? fallbackSelectedAgentIds,
}) {
  final rawSourceAgentIds = failure.context[overviewSourceAgentIdsContextField];
  if (rawSourceAgentIds is Iterable<Object?>) {
    final ids =
        rawSourceAgentIds
            .map((id) => id?.toString().trim() ?? '')
            .where((id) => id.isNotEmpty)
            .toList(growable: false)
          ..sort();
    return ids;
  }
  return normalizeSelectedAgentIds(fallbackSelectedAgentIds);
}

AppFailure mapOverviewFailure(
  AppFailure failure, {
  required String userId,
}) {
  if (failure is ValidationFailure &&
      failure.context['reason'] == 'no_approved_agents') {
    return ValidationFailure(
      message: 'No approved agents available for overview',
      userMessage: failure.userMessage,
      cause: failure.cause ?? failure,
      stackTrace: failure.stackTrace,
      context: <String, Object?>{
        ...failure.context,
        'operation': 'loadOverview',
        'userId': userId,
        OverviewFailureUiKey.field: OverviewFailureUiKey.noApprovedAgents,
      },
    );
  }
  return failure;
}

Future<AppResult<Overview>> recoverOverviewOrFail({
  required AppFailure failure,
  required String userId,
  required OverviewLoadPolicy policy,
  Object? error,
  StackTrace? stackTrace,
}) async {
  logOverviewTerminalFailure(
    failure: failure,
    userId: userId,
    policy: policy,
    error: error ?? failure.cause ?? failure,
    stackTrace: stackTrace ?? failure.stackTrace,
  );
  return Failure<Overview, AppFailure>(failure);
}

void logOverviewTerminalFailure({
  required AppFailure failure,
  required String userId,
  required OverviewLoadPolicy policy,
  required Object error,
  required StackTrace? stackTrace,
}) {
  final context = <String, Object?>{
    'operation': 'loadOverview',
    'userId': userId,
    'policy': policy.name,
    'failureType': failure.runtimeType.toString(),
  };

  if (isNoApprovedAgentsOverviewFailure(failure)) {
    AppLogger.info(
      'Overview unavailable: no approved agents',
      context: context,
    );
    return;
  }

  if (failure is ValidationFailure ||
      failure is SessionFailure ||
      failure is AuthorizationFailure) {
    AppLogger.warning(
      'Unable to load overview',
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
    return;
  }

  AppLogger.error(
    'Unable to load overview',
    context: context,
    error: error,
    stackTrace: stackTrace,
  );
}

bool isNoApprovedAgentsOverviewFailure(AppFailure failure) {
  return failure is ValidationFailure &&
      failure.context[OverviewFailureUiKey.field] ==
          OverviewFailureUiKey.noApprovedAgents;
}

void logOverviewLoadTelemetry({
  required String userId,
  required OverviewLoadPolicy policy,
  required OverviewBatchLoadResult loaded,
  required AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRowV2> report,
  required Overview overview,
  required List<OverviewBatchTargetResult> batchResults,
  required OverviewPeriod period,
}) {
  var monthlySectionFailures = 0;
  var dailySectionFailures = 0;
  var weekdaySectionFailures = 0;
  var weekdayUserSectionFailures = 0;
  var lucratividadeSectionFailures = 0;
  for (final result in batchResults) {
    if (result.monthlyFailure != null) {
      monthlySectionFailures++;
    }
    if (result.dailyFailure != null) {
      dailySectionFailures++;
    }
    if (result.weekdayFailure != null) {
      weekdaySectionFailures++;
    }
    if (result.weekdayUserFailure != null) {
      weekdayUserSectionFailures++;
    }
    if (result.lucratividadeFailure != null) {
      lucratividadeSectionFailures++;
    }
  }

  AppLogger.info(
    'Overview loaded from agent query batch',
    context: <String, Object?>{
      'operation': 'loadOverview',
      'userId': userId,
      'policy': policy.name,
      'isFinal': loaded.isFinal,
      'consideredApprovedAgentCount': report.consideredApprovedAgentCount,
      'plannedTargetCount': loaded.plan.plannedTargets.length,
      'sqlEligibleConsideredTargetCount':
          loaded.resolution.sqlEligibleConsideredTargetCount,
      'periodStart': period.start.toIso8601String(),
      'periodEnd': period.end.toIso8601String(),
      'paymentMethods': overview.paymentMethods.length,
      'partialQueryFailures': overview.agentIdsExcludedFromQueryFailure.length,
      'agentsMissingClientToken': overview.agentIdsMissingClientToken.length,
      'batchElapsedMs': loaded.totalElapsedMs,
      'monthlySectionFailures': monthlySectionFailures,
      'dailySectionFailures': dailySectionFailures,
      'weekdaySectionFailures': weekdaySectionFailures,
      'weekdayUserSectionFailures': weekdayUserSectionFailures,
      'lucratividadeSectionFailures': lucratividadeSectionFailures,
    },
  );
}

OverviewProgressiveSnapshot overviewProgressiveSnapshotFor({
  required Overview overview,
  required Set<OverviewProgressiveSection> completedSections,
  required bool isFinal,
}) {
  final completed = Set<OverviewProgressiveSection>.unmodifiable(
    completedSections,
  );
  return OverviewProgressiveSnapshot(
    overview: overview,
    completedSections: completed,
    pendingSections: Set<OverviewProgressiveSection>.unmodifiable(
      overviewAllProgressiveSections.difference(completed),
    ),
    isFinal: isFinal,
  );
}

AppResult<OverviewProgressiveSnapshot> asOverviewProgressiveResult(
  AppResult<Overview> result,
) {
  return result.fold(
    (overview) => Success<OverviewProgressiveSnapshot, AppFailure>(
      overviewProgressiveSnapshotFor(
        overview: overview,
        completedSections: overviewAllProgressiveSections,
        isFinal: true,
      ),
    ),
    Failure<OverviewProgressiveSnapshot, AppFailure>.new,
  );
}
