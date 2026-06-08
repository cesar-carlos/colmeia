import 'package:checks/checks.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/config/env_keys.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_fact_kind.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/overview/data/overview_batch_loader.dart';
import 'package:colmeia/features/overview/data/repositories/overview_repository_impl.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueryTargetResolver extends Mock
    implements AgentQueryTargetResolver {}

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

class _MockFactsStore extends Mock implements AgentQueryFactsStore {}

void main() {
  late _MockAgentQueryTargetResolver batchTargetResolver;
  late _MockAgentQueriesRepository batchAgentQueriesRepository;
  final fixedNow = DateTime(2026, 4, 8);

  setUpAll(() {
    registerFallbackValue(AgentQueryFactKind.dailySales);
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
  });

  OverviewRepositoryImpl makeRepository({AgentQueryFactsStore? factsStore}) {
    return OverviewRepositoryImpl(
      batchLoader: OverviewBatchLoader(
        targetResolver: batchTargetResolver,
        planBuilder: const AgentQueryPlanBuilder(),
        agentQueriesRepository: batchAgentQueriesRepository,
        maxParallelReadOnlyBatchItems:
            AppEnvironment.agentSqlOverviewBatchMaxParallelReadOnlyItems,
      ),
      factsStore: factsStore,
      now: () => fixedNow,
    );
  }

  void stubSuccessfulBatches({Set<int> sectionFailedIndexes = const <int>{}}) {
    when(
      () => batchAgentQueriesRepository.executeSqlBatch(any()),
    ).thenAnswer((invocation) async {
      final request =
          invocation.positionalArguments.single
              as AgentSqlExecuteBatchRequest;
      return Success<AgentSqlBatchExecutionResult, AppFailure>(
        _batchResult(
          commandCount: request.commands.length,
          rowsByIndex: request.commands.length >= 2
              ? <int, List<Map<String, dynamic>>>{
                  0: <Map<String, dynamic>>[_mainBatchRow()],
                  1: <Map<String, dynamic>>[_userRankingBatchRow()],
                }
              : const <int, List<Map<String, dynamic>>>{},
          failedIndexes: request.commands.length == 2
              ? const <int>{}
              : _overviewSectionFailedIndexesInBatch(
                  request,
                  sectionFailedIndexes,
                ),
        ),
      );
    });
  }

  group('OverviewRepositoryImpl', () {
    test(
      'batch load resolves targets once and emits phased snapshots with merge flag',
      () async {
        dotenv.loadFromString(
          envString:
              '${EnvKeys.agentSqlOverviewMergeSqlBatchesPerTarget}=true',
        );
        addTearDown(() {
          dotenv.loadFromString(
            envString:
                '${EnvKeys.agentSqlOverviewMergeSqlBatchesPerTarget}=false',
          );
        });

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
              rowsByIndex: request.commands.length >= 2
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
        check(finalSnapshot.completedSections.length).equals(9);

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
        check(capturedRequests[1].commands.length).equals(5);
        check(capturedRequests[0].useRelay).isTrue();
        check(
          capturedRequests[0].options?.maxParallelReadOnlyBatchItems,
        ).equals(4);
      },
    );

    test(
      'batch load emits phased snapshots when merge flag is disabled',
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
        check(finalSnapshot.completedSections.length).equals(9);

        final capturedRequests = verify(
          () => batchAgentQueriesRepository.executeSqlBatch(captureAny()),
        ).captured.cast<AgentSqlExecuteBatchRequest>().toList(growable: false);
        check(capturedRequests.length).equals(2);
        check(capturedRequests[0].commands.length).equals(2);
        check(capturedRequests[1].commands.length).equals(5);
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
          final monthlyIndex = request.commands.length >= 7 ? 2 : 0;
          return Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(
              commandCount: request.commands.length,
              rowsByIndex: <int, List<Map<String, dynamic>>>{
                0: <Map<String, dynamic>>[_mainBatchRow()],
                1: <Map<String, dynamic>>[_userRankingBatchRow()],
              },
              failedIndexes: <int>{monthlyIndex},
            ),
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
        ).thenAnswer((invocation) async {
          final request =
              invocation.positionalArguments.single
                  as AgentSqlExecuteBatchRequest;
          return Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(
              commandCount: request.commands.length,
              failedIndexes: const <int>{0},
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
        check(captured.length).equals(2);
        final requests = captured.cast<AgentSqlExecuteBatchRequest>().toList(
          growable: false,
        );
        for (final request in requests) {
          check(request.commands.length).equals(7);
        }
      },
    );

    test(
      'forceRefresh invalidates daily and monthly facts before load',
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
          () => factsStore.removeMatchingFactKind(
            userId: any(named: 'userId'),
            factKind: any(named: 'factKind'),
          ),
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
          () => factsStore.removeMatchingFactKind(
            userId: 'user-1',
            factKind: AgentQueryFactKind.dailySales,
          ),
        ).called(1);
        verify(
          () => factsStore.removeMatchingFactKind(
            userId: 'user-1',
            factKind: AgentQueryFactKind.monthlyParcels,
          ),
        ).called(1);
        verifyNever(() => factsStore.removeMatching(any()));
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
      'section batch daily item failure marks daily trend load failed',
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
        stubSuccessfulBatches(sectionFailedIndexes: const <int>{2});

        final repository = makeRepository();
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
      'partial section daily failure surfaces detail and keeps successful agent data',
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
          final dailyIndex = _overviewDailyCommandIndexInBatch(request);
          final failedIndexes = request.agentId == 'agent-2'
              ? <int>{dailyIndex}
              : const <int>{};
          final rowsByIndex = <int, List<Map<String, dynamic>>>{
            0: <Map<String, dynamic>>[_mainBatchRow()],
            1: <Map<String, dynamic>>[_userRankingBatchRow()],
            if (request.agentId == 'agent-1')
              dailyIndex: <Map<String, dynamic>>[
                <String, dynamic>{
                  'CodEmpresa': 1,
                  'CodFilial': 1,
                  'DataVenda': '2026-04-07',
                  'QtdVendas': 3,
                  'ValorTotalDiarioVenda': 300.0,
                },
              ],
          };
          return Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(
              commandCount: request.commands.length,
              rowsByIndex: rowsByIndex,
              failedIndexes: failedIndexes,
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

const int _overviewMainBatchCommandCount = 2;

Set<int> _overviewSectionFailedIndexesInBatch(
  AgentSqlExecuteBatchRequest request,
  Set<int> sectionFailedIndexes,
) {
  if (request.commands.length < _overviewMainBatchCommandCount + 5) {
    return sectionFailedIndexes;
  }
  return sectionFailedIndexes
      .map((index) => index + _overviewMainBatchCommandCount)
      .toSet();
}

int _overviewDailyCommandIndexInBatch(AgentSqlExecuteBatchRequest request) {
  if (request.commands.length >= _overviewMainBatchCommandCount + 5) {
    return _overviewMainBatchCommandCount + 2;
  }
  return 2;
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
