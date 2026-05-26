import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/overview/data/datasources/overview_local_datasource.dart';
import 'package:colmeia/features/overview/data/models/overview_model.dart';
import 'package:colmeia/features/overview/data/overview_batch_loader.dart';
import 'package:colmeia/features/overview/data/repositories/overview_repository_impl.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockOverviewLocalDataSource extends Mock
    implements OverviewLocalDataSource {}

class _MockAgentQueryTargetResolver extends Mock
    implements AgentQueryTargetResolver {}

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockOverviewLocalDataSource local;
  late _MockAgentQueryTargetResolver batchTargetResolver;
  late _MockAgentQueriesRepository batchAgentQueriesRepository;

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
    registerFallbackValue(
      OverviewModel(
        periodStart: DateTime(2026),
        periodEnd: DateTime(2026),
        kpis: const OverviewPaymentKpis(
          totalSalesCount: 0,
          totalAmount: 0,
          averageTicket: 0,
          paymentMethodCount: 0,
        ),
        paymentMethods: const <OverviewPaymentMethodBreakdown>[],
        agentRankings: const [],
        userRankings: const [],
      ),
    );
  });

  setUp(() {
    local = _MockOverviewLocalDataSource();
    batchTargetResolver = _MockAgentQueryTargetResolver();
    batchAgentQueriesRepository = _MockAgentQueriesRepository();
    when(
      () => local.saveOverview(
        userId: any(named: 'userId'),
        overview: any(named: 'overview'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => local.readOverview(userId: any(named: 'userId')),
    ).thenAnswer((_) async => null);
  });

  OverviewRepositoryImpl makeRepository() {
    return OverviewRepositoryImpl(
      localDataSource: local,
      batchLoader: OverviewBatchLoader(
        targetResolver: batchTargetResolver,
        planBuilder: const AgentQueryPlanBuilder(),
        agentQueriesRepository: batchAgentQueriesRepository,
      ),
      now: () => fixedNow,
    );
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
