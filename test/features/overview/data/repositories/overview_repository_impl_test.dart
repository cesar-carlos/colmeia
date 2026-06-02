import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_key_prefix.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/overview/data/overview_batch_loader.dart';
import 'package:colmeia/features/overview/data/repositories/overview_repository_impl.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueryTargetResolver extends Mock
    implements AgentQueryTargetResolver {}

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

class _MockLoadDaily extends Mock implements LoadResumoTotalDiarioVendasUseCase {}

class _MockLoadMonthly extends Mock implements LoadResumoParcelasMensalUseCase {}

class _MockFactsStore extends Mock implements AgentQueryFactsStore {}

void main() {
  late _MockAgentQueryTargetResolver batchTargetResolver;
  late _MockAgentQueriesRepository batchAgentQueriesRepository;
  late _MockLoadDaily loadDaily;
  late _MockLoadMonthly loadMonthly;

  final fixedNow = DateTime(2026, 4, 8);

  setUpAll(() {
    registerFallbackValue(AgentQueryExecutionStrategy.mergeAll);
    registerFallbackValue(
      const AgentSqlExecuteBatchRequest(
        agentId: 'agent-fallback',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
      ),
    );
    registerFallbackValue(<String>{'agent-fallback'});
    registerFallbackValue(AgentQueryLoadPolicy.defaultLoad);
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
  });

  setUp(() {
    batchTargetResolver = _MockAgentQueryTargetResolver();
    batchAgentQueriesRepository = _MockAgentQueriesRepository();
    loadDaily = _MockLoadDaily();
    loadMonthly = _MockLoadMonthly();

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
  });

  OverviewRepositoryImpl makeRepository({
    AgentQueryFactsStore? factsStore,
    bool useCachedDailyMonthly = false,
  }) {
    return OverviewRepositoryImpl(
      batchLoader: OverviewBatchLoader(
        targetResolver: batchTargetResolver,
        planBuilder: const AgentQueryPlanBuilder(),
        agentQueriesRepository: batchAgentQueriesRepository,
        loadDailySales: useCachedDailyMonthly ? loadDaily : null,
        loadMonthlyParcels: useCachedDailyMonthly ? loadMonthly : null,
      ),
      factsStore: factsStore,
      now: () => fixedNow,
    );
  }

  void stubSuccessfulBatches() {
    when(
      () => batchAgentQueriesRepository.executeSqlBatch(any()),
    ).thenAnswer((invocation) async {
      final request =
          invocation.positionalArguments.single
              as AgentSqlExecuteBatchRequest;
      return Success<AgentSqlBatchExecutionResult, AppFailure>(
        _batchResult(
          commandCount: request.commands.length,
          rowsByIndex: request.commands.length == 2
              ? <int, List<Map<String, dynamic>>>{
                  0: <Map<String, dynamic>>[_mainBatchRow()],
                  1: <Map<String, dynamic>>[_userRankingBatchRow()],
                }
              : const <int, List<Map<String, dynamic>>>{},
        ),
      );
    });
  }

  group('OverviewRepositoryImpl', () {
    test(
      'batch load resolves targets once and emits phased snapshots',
      () async {
        const target = AgentQueryTarget(
          agentId: 'agent-1',
          displayName: 'Agent 1',
          connectionStatus: AgentConnectionStatus.online,
          clientToken: 'token-1',
          hubConnectedFromApprovedCatalogRow: true,
        );
        when(
          () => batchTargetResolver.resolve(
            userId: any(named: 'userId'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
          ),
        ).thenAnswer(
          (_) async => const Success<AgentQueryTargetResolution, AppFailure>(
            AgentQueryTargetResolution(
              consideredApprovedTargets: <AgentQueryTarget>[target],
              missingClientTokenTargets: <AgentQueryTarget>[],
              consideredApprovedAgentCount: 1,
              selectedAgentIds: <String>{'agent-1'},
              hubPresenceOnlineAgentIdsSnapshot: <String>{'agent-1'},
            ),
          ),
        );
        when(
          () => batchAgentQueriesRepository.executeSqlBatch(any()),
        ).thenAnswer((invocation) async {
          final request =
              invocation.positionalArguments.single
                  as AgentSqlExecuteBatchRequest;
          return Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(
              commandCount: request.commands.length,
              rowsByIndex: request.commands.length == 2
                  ? <int, List<Map<String, dynamic>>>{
                      0: <Map<String, dynamic>>[_mainBatchRow()],
                      1: <Map<String, dynamic>>[_userRankingBatchRow()],
                    }
                  : const <int, List<Map<String, dynamic>>>{},
            ),
          );
        });

        final repository = makeRepository();
        final snapshots = await repository
            .loadOverviewProgressively(
              userId: 'user-1',
              filter: const DashboardFilter(
                selectedAgentIds: <String>{'agent-1'},
              ),
            )
            .toList();

        check(snapshots.length).equals(2);
        final summarySnapshot = snapshots.first.getOrThrow();
        check(summarySnapshot.isFinal).isFalse();
        check(summarySnapshot.completedSections.length).equals(4);
        final finalSnapshot = snapshots.last.getOrThrow();
        check(finalSnapshot.isFinal).isTrue();
        check(finalSnapshot.pendingSections).isEmpty();
        check(finalSnapshot.completedSections.length).equals(10);

        verify(
          () => batchTargetResolver.resolve(
            userId: 'user-1',
            selectedAgentIds: const <String>{'agent-1'},
          ),
        ).called(1);
        final capturedRequests = verify(
          () => batchAgentQueriesRepository.executeSqlBatch(captureAny()),
        ).captured.cast<AgentSqlExecuteBatchRequest>().toList(growable: false);
        check(capturedRequests.length).equals(2);
        check(capturedRequests[0].agentId).equals('agent-1');
        check(capturedRequests[0].clientToken).equals('token-1');
        check(capturedRequests[0].commands.length).equals(2);
        check(capturedRequests[0].useRelay).isTrue();
        check(
          capturedRequests[0].options?.maxParallelReadOnlyBatchItems,
        ).equals(4);
        check(capturedRequests[1].commands.length).equals(6);
        check(capturedRequests[1].useRelay).isTrue();
        check(
          capturedRequests[1].options?.maxParallelReadOnlyBatchItems,
        ).equals(4);
      },
    );

    test(
      'batch load marks only a secondary section when its item fails',
      () async {
        const target = AgentQueryTarget(
          agentId: 'agent-1',
          displayName: 'Agent 1',
          connectionStatus: AgentConnectionStatus.online,
          clientToken: 'token-1',
          hubConnectedFromApprovedCatalogRow: true,
        );
        when(
          () => batchTargetResolver.resolve(
            userId: any(named: 'userId'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
          ),
        ).thenAnswer(
          (_) async => const Success<AgentQueryTargetResolution, AppFailure>(
            AgentQueryTargetResolution(
              consideredApprovedTargets: <AgentQueryTarget>[target],
              missingClientTokenTargets: <AgentQueryTarget>[],
              consideredApprovedAgentCount: 1,
              selectedAgentIds: <String>{'agent-1'},
              hubPresenceOnlineAgentIdsSnapshot: <String>{'agent-1'},
            ),
          ),
        );
        when(
          () => batchAgentQueriesRepository.executeSqlBatch(any()),
        ).thenAnswer((invocation) async {
          final request =
              invocation.positionalArguments.single
                  as AgentSqlExecuteBatchRequest;
          if (request.commands.length == 2) {
            return Success<AgentSqlBatchExecutionResult, AppFailure>(
              _batchResult(
                commandCount: 2,
                rowsByIndex: <int, List<Map<String, dynamic>>>{
                  0: <Map<String, dynamic>>[_mainBatchRow()],
                  1: <Map<String, dynamic>>[_userRankingBatchRow()],
                },
              ),
            );
          }
          return Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(commandCount: 6, failedIndexes: const <int>{0}),
          );
        });

        final repository = makeRepository();
        final result = await repository.loadOverview(
          userId: 'user-1',
          filter: const DashboardFilter(
            selectedAgentIds: <String>{'agent-1'},
          ),
        );

        check(result.isSuccess()).isTrue();
        final overview = result.getOrThrow();
        check(overview.kpis.totalSalesCount).equals(1);
        check(overview.monthlyParcelTrendLoadFailed).isTrue();
        check(overview.weekdaySalesTrendLoadFailed).isFalse();
        check(overview.dailySalesTrendLoadFailed).isFalse();
      },
    );

    test(
      'batch load fails when the main resumo fails for every agent',
      () async {
        const target = AgentQueryTarget(
          agentId: 'agent-1',
          displayName: 'Agent 1',
          connectionStatus: AgentConnectionStatus.online,
          clientToken: 'token-1',
          hubConnectedFromApprovedCatalogRow: true,
        );
        when(
          () => batchTargetResolver.resolve(
            userId: any(named: 'userId'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
          ),
        ).thenAnswer(
          (_) async => const Success<AgentQueryTargetResolution, AppFailure>(
            AgentQueryTargetResolution(
              consideredApprovedTargets: <AgentQueryTarget>[target],
              missingClientTokenTargets: <AgentQueryTarget>[],
              consideredApprovedAgentCount: 1,
              selectedAgentIds: <String>{'agent-1'},
              hubPresenceOnlineAgentIdsSnapshot: <String>{'agent-1'},
            ),
          ),
        );
        when(
          () => batchAgentQueriesRepository.executeSqlBatch(any()),
        ).thenAnswer(
          (_) async => Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(commandCount: 2, failedIndexes: const <int>{0}),
          ),
        );

        final repository = makeRepository();
        final snapshots = await repository
            .loadOverviewProgressively(
              userId: 'user-1',
              filter: const DashboardFilter(
                selectedAgentIds: <String>{'agent-1'},
              ),
            )
            .toList();

        check(snapshots.length).equals(1);
        check(snapshots.single.isError()).isTrue();
        check(snapshots.single.exceptionOrNull()).isA<RpcFailure>();
      },
    );

    test(
      'batch load omits monthly lucratividade for multiple selected agents',
      () async {
        const first = AgentQueryTarget(
          agentId: 'agent-1',
          displayName: 'Agent 1',
          connectionStatus: AgentConnectionStatus.online,
          clientToken: 'token-1',
          hubConnectedFromApprovedCatalogRow: true,
        );
        const second = AgentQueryTarget(
          agentId: 'agent-2',
          displayName: 'Agent 2',
          connectionStatus: AgentConnectionStatus.online,
          clientToken: 'token-2',
          hubConnectedFromApprovedCatalogRow: true,
        );
        when(
          () => batchTargetResolver.resolve(
            userId: any(named: 'userId'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
          ),
        ).thenAnswer(
          (_) async => const Success<AgentQueryTargetResolution, AppFailure>(
            AgentQueryTargetResolution(
              consideredApprovedTargets: <AgentQueryTarget>[first, second],
              missingClientTokenTargets: <AgentQueryTarget>[],
              consideredApprovedAgentCount: 2,
              selectedAgentIds: <String>{'agent-1', 'agent-2'},
              hubPresenceOnlineAgentIdsSnapshot: <String>{'agent-1', 'agent-2'},
            ),
          ),
        );
        when(
          () => batchAgentQueriesRepository.executeSqlBatch(any()),
        ).thenAnswer((invocation) async {
          final request =
              invocation.positionalArguments.single
                  as AgentSqlExecuteBatchRequest;
          return Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(
              commandCount: request.commands.length,
              rowsByIndex: request.commands.length == 2
                  ? <int, List<Map<String, dynamic>>>{
                      0: <Map<String, dynamic>>[_mainBatchRow()],
                      1: <Map<String, dynamic>>[_userRankingBatchRow()],
                    }
                  : const <int, List<Map<String, dynamic>>>{},
            ),
          );
        });

        final repository = makeRepository();
        final result = await repository.loadOverview(
          userId: 'user-1',
          filter: const DashboardFilter(
            selectedAgentIds: <String>{'agent-1', 'agent-2'},
          ),
        );

        check(result.isSuccess()).isTrue();
        final captured = verify(
          () => batchAgentQueriesRepository.executeSqlBatch(captureAny()),
        ).captured;
        check(captured.length).equals(4);
        final requests = captured.cast<AgentSqlExecuteBatchRequest>().toList(
          growable: false,
        );
        for (final request in requests.take(2)) {
          check(request.commands.length).equals(2);
        }
        for (final request in requests.skip(2)) {
          check(request.commands.length).equals(5);
        }
      },
    );

    test(
      'forceRefresh invalidates all facts for the user before load',
      () async {
        const target = AgentQueryTarget(
          agentId: 'agent-1',
          displayName: 'Agent 1',
          connectionStatus: AgentConnectionStatus.online,
          clientToken: 'token-1',
          hubConnectedFromApprovedCatalogRow: true,
        );
        final factsStore = _MockFactsStore();
        when(
          () => batchTargetResolver.resolve(
            userId: any(named: 'userId'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
          ),
        ).thenAnswer(
          (_) async => const Success<AgentQueryTargetResolution, AppFailure>(
            AgentQueryTargetResolution(
              consideredApprovedTargets: <AgentQueryTarget>[target],
              missingClientTokenTargets: <AgentQueryTarget>[],
              consideredApprovedAgentCount: 1,
              selectedAgentIds: <String>{'agent-1'},
              hubPresenceOnlineAgentIdsSnapshot: <String>{'agent-1'},
            ),
          ),
        );
        when(
          () => factsStore.removeMatching(any()),
        ).thenAnswer((_) async {});
        stubSuccessfulBatches();

        final repository = makeRepository(factsStore: factsStore);
        await repository.loadOverview(
          userId: 'user-1',
          filter: const DashboardFilter(
            selectedAgentIds: <String>{'agent-1'},
          ),
          policy: OverviewLoadPolicy.forceRefresh,
        );

        verify(
          () => factsStore.removeMatching(
            AgentQueryFactsKeyPrefix.forUser('user-1'),
          ),
        ).called(1);
      },
    );

    test(
      'defaultLoad does not invalidate facts store',
      () async {
        const target = AgentQueryTarget(
          agentId: 'agent-1',
          displayName: 'Agent 1',
          connectionStatus: AgentConnectionStatus.online,
          clientToken: 'token-1',
          hubConnectedFromApprovedCatalogRow: true,
        );
        final factsStore = _MockFactsStore();
        when(
          () => batchTargetResolver.resolve(
            userId: any(named: 'userId'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
          ),
        ).thenAnswer(
          (_) async => const Success<AgentQueryTargetResolution, AppFailure>(
            AgentQueryTargetResolution(
              consideredApprovedTargets: <AgentQueryTarget>[target],
              missingClientTokenTargets: <AgentQueryTarget>[],
              consideredApprovedAgentCount: 1,
              selectedAgentIds: <String>{'agent-1'},
              hubPresenceOnlineAgentIdsSnapshot: <String>{'agent-1'},
            ),
          ),
        );
        stubSuccessfulBatches();

        final repository = makeRepository(factsStore: factsStore);
        await repository.loadOverview(
          userId: 'user-1',
          filter: const DashboardFilter(
            selectedAgentIds: <String>{'agent-1'},
          ),
        );

        verifyNever(() => factsStore.removeMatching(any()));
      },
    );

    test(
      'cached daily failures for every agent mark daily trend load failed',
      () async {
        const target = AgentQueryTarget(
          agentId: 'agent-1',
          displayName: 'Agent 1',
          connectionStatus: AgentConnectionStatus.online,
          clientToken: 'token-1',
          hubConnectedFromApprovedCatalogRow: true,
        );
        when(
          () => batchTargetResolver.resolve(
            userId: any(named: 'userId'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
          ),
        ).thenAnswer(
          (_) async => const Success<AgentQueryTargetResolution, AppFailure>(
            AgentQueryTargetResolution(
              consideredApprovedTargets: <AgentQueryTarget>[target],
              missingClientTokenTargets: <AgentQueryTarget>[],
              consideredApprovedAgentCount: 1,
              selectedAgentIds: <String>{'agent-1'},
              hubPresenceOnlineAgentIdsSnapshot: <String>{'agent-1'},
            ),
          ),
        );
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
          (_) async => const Failure<List<ResumoTotalDiarioVendasRow>, AppFailure>(
            RpcFailure(
              message: 'daily failed',
              userMessage: 'Daily trend unavailable.',
              rpcCode: -32001,
              retryable: false,
            ),
          ),
        );
        stubSuccessfulBatches();

        final repository = makeRepository(useCachedDailyMonthly: true);
        final result = await repository.loadOverview(
          userId: 'user-1',
          filter: const DashboardFilter(
            selectedAgentIds: <String>{'agent-1'},
          ),
        );

        final overview = result.getOrThrow();
        check(overview.dailySalesTrendLoadFailed).isTrue();
        check(overview.dailySalesTrend).isEmpty();
      },
    );

    test(
      'partial cached daily failure surfaces detail and keeps successful agent data',
      () async {
        const first = AgentQueryTarget(
          agentId: 'agent-1',
          displayName: 'Agent 1',
          connectionStatus: AgentConnectionStatus.online,
          clientToken: 'token-1',
          hubConnectedFromApprovedCatalogRow: true,
        );
        const second = AgentQueryTarget(
          agentId: 'agent-2',
          displayName: 'Agent 2',
          connectionStatus: AgentConnectionStatus.online,
          clientToken: 'token-2',
          hubConnectedFromApprovedCatalogRow: true,
        );
        when(
          () => batchTargetResolver.resolve(
            userId: any(named: 'userId'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
          ),
        ).thenAnswer(
          (_) async => const Success<AgentQueryTargetResolution, AppFailure>(
            AgentQueryTargetResolution(
              consideredApprovedTargets: <AgentQueryTarget>[first, second],
              missingClientTokenTargets: <AgentQueryTarget>[],
              consideredApprovedAgentCount: 2,
              selectedAgentIds: <String>{'agent-1', 'agent-2'},
              hubPresenceOnlineAgentIdsSnapshot: <String>{'agent-1', 'agent-2'},
            ),
          ),
        );
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
        ).thenAnswer((invocation) async {
          final agentId = invocation.namedArguments[#agentId] as String;
          if (agentId == 'agent-2') {
            return const Failure<List<ResumoTotalDiarioVendasRow>, AppFailure>(
              RpcFailure(
                message: 'daily failed',
                userMessage: 'Daily trend unavailable.',
                rpcCode: -32001,
                retryable: false,
              ),
            );
          }
          return Success<List<ResumoTotalDiarioVendasRow>, AppFailure>([
            ResumoTotalDiarioVendasRow(
              codEmpresa: 1,
              codFilial: 1,
              dataVenda: DateTime(2026, 4, 7),
              qtdVendas: 3,
              valorTotalDiarioVenda: 300,
            ),
          ]);
        });
        stubSuccessfulBatches();

        final repository = makeRepository(useCachedDailyMonthly: true);
        final result = await repository.loadOverview(
          userId: 'user-1',
          filter: const DashboardFilter(
            selectedAgentIds: <String>{'agent-1', 'agent-2'},
          ),
        );

        final overview = result.getOrThrow();
        check(overview.dailySalesTrendLoadFailed).isFalse();
        check(
          overview.partialQueryFailureDetails.any(
            (detail) =>
                detail.source == OverviewAgentQueryFailureSource.dailyTrend &&
                detail.agentId == 'agent-2',
          ),
        ).isTrue();
        check(overview.dailySalesTrend).isNotEmpty();
      },
    );
  });
}

AgentSqlBatchExecutionResult _batchResult({
  required int commandCount,
  Map<int, List<Map<String, dynamic>>> rowsByIndex =
      const <int, List<Map<String, dynamic>>>{},
  Set<int> failedIndexes = const <int>{},
}) {
  return AgentSqlBatchExecutionResult(
    totalCommands: commandCount,
    successfulCommands: commandCount - failedIndexes.length,
    failedCommands: failedIndexes.length,
    items: List<AgentSqlBatchExecutionItem>.generate(
      commandCount,
      (index) => AgentSqlBatchExecutionItem(
        index: index,
        ok: !failedIndexes.contains(index),
        rows: rowsByIndex[index] ?? const <Map<String, dynamic>>[],
        rowCount: rowsByIndex[index]?.length ?? 0,
        error: failedIndexes.contains(index) ? 'batch item failed' : null,
      ),
    ),
  );
}

Map<String, dynamic> _mainBatchRow() {
  return <String, dynamic>{
    'CodEmpresa': 1,
    'CodFilial': 1,
    'NomeUsuario': 'Caixa',
    'AnoDataVenda': 2026,
    'MesDataVenda': 4,
    'AnoMesDataVenda': '2026/04',
    'CodFormaPagamento': 'PIX',
    'DescricaoFormaPagamento': 'Pix',
    'QtdVendas': 1,
    'ValorParcela': 100.0,
  };
}

Map<String, dynamic> _userRankingBatchRow() {
  return <String, dynamic>{
    'CodEmpresa': 1,
    'CodFilial': 1,
    'NomeUsuario': 'Caixa',
    'QtdVendas': 1,
    'ValorParcela': 100.0,
  };
}
