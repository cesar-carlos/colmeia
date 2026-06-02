import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/features/agent_queries/application/sync/agent_query_facts_prefetch_coordinator.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockLoadDaily extends Mock implements LoadResumoTotalDiarioVendasUseCase {}

class _MockLoadMonthly extends Mock implements LoadResumoParcelasMensalUseCase {}

void main() {
  late _MockLoadDaily loadDaily;
  late _MockLoadMonthly loadMonthly;
  late RetryAfterGate gate;

  setUpAll(() {
    registerFallbackValue(
      ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026),
        dataVendaFim: DateTime(2026, 1, 31),
      ),
    );
    registerFallbackValue(
      ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime(2026),
        dataVendaFim: DateTime(2026, 12, 31),
      ),
    );
    registerFallbackValue(AgentQueryLoadPolicy.defaultLoad);
  });

  final dailyFilter = ResumoTotalDiarioVendasFilter(
    dataVendaInicio: DateTime(2026),
    dataVendaFim: DateTime(2026, 1, 31),
  );
  final monthlyFilter = ResumoParcelasMensalFilter(
    dataVendaInicio: DateTime(2026),
    dataVendaFim: DateTime(2026, 12, 31),
  );

  setUp(() {
    loadDaily = _MockLoadDaily();
    loadMonthly = _MockLoadMonthly();
    gate = RetryAfterGate();
  });

  test('prefetchForPlannedTargets skips when retry gate is closed', () async {
    gate.arm(const Duration(minutes: 5));
    final coordinator = AgentQueryFactsPrefetchCoordinator(
      loadDaily: loadDaily,
      loadMonthly: loadMonthly,
      retryAfterGate: gate,
    );

    await coordinator.prefetchForPlannedTargets(
      userId: 'u1',
      targets: const [
        AgentQueryTarget(
          agentId: 'a1',
          displayName: 'A1',
          connectionStatus: AgentConnectionStatus.online,
        ),
      ],
      dailyFilter: dailyFilter,
      monthlyFilter: monthlyFilter,
    );

    verifyNever(
      () => loadDaily.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        hubPresenceOnlineAgentIdsSnapshot: any(
          named: 'hubPresenceOnlineAgentIdsSnapshot',
        ),
        hubConnectedFromApprovedCatalogRow: any(
          named: 'hubConnectedFromApprovedCatalogRow',
        ),
        cachePolicy: any(named: 'cachePolicy'),
      ),
    );
  });

  test('prefetchForPlannedTargets invokes loaders per target when enabled', () async {
    when(
      () => loadDaily.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        hubPresenceOnlineAgentIdsSnapshot: any(
          named: 'hubPresenceOnlineAgentIdsSnapshot',
        ),
        hubConnectedFromApprovedCatalogRow: any(
          named: 'hubConnectedFromApprovedCatalogRow',
        ),
        cachePolicy: any(named: 'cachePolicy'),
      ),
    ).thenAnswer(
      (_) async => const Success<List<ResumoTotalDiarioVendasRow>, AppFailure>(
        <ResumoTotalDiarioVendasRow>[],
      ),
    );
    when(
      () => loadMonthly.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        hubPresenceOnlineAgentIdsSnapshot: any(
          named: 'hubPresenceOnlineAgentIdsSnapshot',
        ),
        hubConnectedFromApprovedCatalogRow: any(
          named: 'hubConnectedFromApprovedCatalogRow',
        ),
        cachePolicy: any(named: 'cachePolicy'),
      ),
    ).thenAnswer(
      (_) async => const Success<List<ResumoParcelasMensalRow>, AppFailure>(
        <ResumoParcelasMensalRow>[],
      ),
    );

    final coordinator = AgentQueryFactsPrefetchCoordinator(
      loadDaily: loadDaily,
      loadMonthly: loadMonthly,
      retryAfterGate: gate,
    );

    await coordinator.prefetchForPlannedTargets(
      userId: 'u1',
      targets: const [
        AgentQueryTarget(
          agentId: 'a1',
          displayName: 'A1',
          connectionStatus: AgentConnectionStatus.online,
        ),
        AgentQueryTarget(
          agentId: 'a2',
          displayName: 'A2',
          connectionStatus: AgentConnectionStatus.online,
        ),
      ],
      dailyFilter: dailyFilter,
      monthlyFilter: monthlyFilter,
    );

    if (!AppEnvironment.agentQueryFactsPrefetchEnabled) {
      verifyNever(
        () => loadDaily.call(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          filter: any(named: 'filter'),
          clientToken: any(named: 'clientToken'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          hubPresenceOnlineAgentIdsSnapshot: any(
            named: 'hubPresenceOnlineAgentIdsSnapshot',
          ),
          hubConnectedFromApprovedCatalogRow: any(
            named: 'hubConnectedFromApprovedCatalogRow',
          ),
          cachePolicy: any(named: 'cachePolicy'),
        ),
      );
      return;
    }

    verify(
      () => loadDaily.call(
        userId: 'u1',
        agentId: 'a1',
        filter: dailyFilter,
        clientToken: any(named: 'clientToken'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        hubPresenceOnlineAgentIdsSnapshot: any(
          named: 'hubPresenceOnlineAgentIdsSnapshot',
        ),
        hubConnectedFromApprovedCatalogRow: any(
          named: 'hubConnectedFromApprovedCatalogRow',
        ),
        cachePolicy: any(named: 'cachePolicy'),
      ),
    ).called(1);
    verify(
      () => loadDaily.call(
        userId: 'u1',
        agentId: 'a2',
        filter: dailyFilter,
        clientToken: any(named: 'clientToken'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        hubPresenceOnlineAgentIdsSnapshot: any(
          named: 'hubPresenceOnlineAgentIdsSnapshot',
        ),
        hubConnectedFromApprovedCatalogRow: any(
          named: 'hubConnectedFromApprovedCatalogRow',
        ),
        cachePolicy: any(named: 'cachePolicy'),
      ),
    ).called(1);
  });
}
