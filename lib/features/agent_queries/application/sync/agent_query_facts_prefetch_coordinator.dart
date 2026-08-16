import 'dart:async';

import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

/// In-app backfill of closed fact buckets while the process is alive.
///
/// Does not schedule OS background work. The overview repository schedules
/// [prefetchForPlannedTargets] after a successful final overview load so
/// closed buckets can warm while the user stays on the dashboard.
///
/// Callers should pass the same [RetryAfterGate] used by agent-query surfaces
/// so prefetch does not amplify hub pressure during cooldown.
final class AgentQueryFactsPrefetchCoordinator {
  AgentQueryFactsPrefetchCoordinator({
    required this._loadDaily,
    required this._loadMonthly,
    RetryAfterGate? retryAfterGate,
    int maxConcurrentAgents = 2,
  }) : _retryAfterGate = retryAfterGate ?? RetryAfterGate(),
       _maxConcurrentAgents = maxConcurrentAgents.clamp(1, 4);

  final LoadResumoTotalDiarioVendasUseCase _loadDaily;
  final LoadResumoParcelasMensalUseCase _loadMonthly;
  final RetryAfterGate _retryAfterGate;
  final int _maxConcurrentAgents;

  Future<void> prefetchForPlannedTargets({
    required String userId,
    required List<AgentQueryTarget> targets,
    required ResumoTotalDiarioVendasFilter dailyFilter,
    required ResumoParcelasMensalFilter monthlyFilter,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    int? bridgeTimeoutMs,
    AgentQueriesCancelScope? cancelScope,
    Set<String> skipAgentIds = const <String>{},
  }) async {
    if (!AppEnvironment.agentQueryFactsPrefetchEnabled) {
      return;
    }
    if (!_retryAfterGate.isOpen || targets.isEmpty) {
      return;
    }
    if (cancelScope?.isCancelled ?? false) {
      return;
    }

    final delayMs = AppEnvironment.agentQueryFactsPrefetchDelayMs;
    if (delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
      if (!_retryAfterGate.isOpen || (cancelScope?.isCancelled ?? false)) {
        return;
      }
    }

    var index = 0;
    Future<void> worker() async {
      while (index < targets.length) {
        if (!_retryAfterGate.isOpen || (cancelScope?.isCancelled ?? false)) {
          return;
        }
        final targetIndex = index++;
        if (targetIndex >= targets.length) {
          return;
        }
        final target = targets[targetIndex];
        if (skipAgentIds.contains(target.agentId)) {
          continue;
        }
        await prefetchForAgent(
          userId: userId,
          agentId: target.agentId,
          dailyFilter: dailyFilter,
          monthlyFilter: monthlyFilter,
          clientToken: target.clientToken,
          bridgeTimeoutMs: bridgeTimeoutMs,
          hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
          hubConnectedFromApprovedCatalogRow:
              target.hubConnectedFromApprovedCatalogRow,
          cancelScope: cancelScope,
        );
      }
    }

    final workers = List<Future<void>>.generate(
      _maxConcurrentAgents.clamp(1, targets.length),
      (_) => worker(),
    );
    await Future.wait(workers);
  }

  Future<void> prefetchForAgent({
    required String userId,
    required String agentId,
    required ResumoTotalDiarioVendasFilter dailyFilter,
    required ResumoParcelasMensalFilter monthlyFilter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) async {
    if (!AppEnvironment.agentQueryFactsPrefetchEnabled) {
      return;
    }
    if (!_retryAfterGate.isOpen || (cancelScope?.isCancelled ?? false)) {
      return;
    }

    final dailyResult = await _loadDaily.call(
      userId: userId,
      agentId: agentId,
      filter: dailyFilter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      cancelScope: cancelScope,
    );
    if (!_retryAfterGate.isOpen || (cancelScope?.isCancelled ?? false)) {
      return;
    }
    final monthlyResult = await _loadMonthly.call(
      userId: userId,
      agentId: agentId,
      filter: monthlyFilter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
      cancelScope: cancelScope,
    );

    if (dailyResult.getOrNull() == null || monthlyResult.getOrNull() == null) {
      AppLogger.debug(
        'Agent query facts prefetch had failures',
        context: <String, Object?>{
          'operation': 'prefetchForAgent',
          'agentId': agentId,
          'dailyFailed': dailyResult.getOrNull() == null,
          'monthlyFailed': monthlyResult.getOrNull() == null,
        },
      );
    }
  }
}
