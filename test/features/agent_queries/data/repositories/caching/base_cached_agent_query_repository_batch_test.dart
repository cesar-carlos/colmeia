import 'package:checks/checks.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_total_diario_vendas_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/caching_resumo_total_diario_vendas_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_diario_vendas_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

import '../../facts/memory_agent_query_facts_store.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

class _CountingDelegate implements ResumoTotalDiarioVendasRepository {
  int loadCount = 0;

  @override
  Future<AppResult<List<ResumoTotalDiarioVendasRow>>> load({
    required String userId,
    required String agentId,
    required ResumoTotalDiarioVendasFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    loadCount++;
    return Success<List<ResumoTotalDiarioVendasRow>, AppFailure>(
      <ResumoTotalDiarioVendasRow>[
        ResumoTotalDiarioVendasRow(
          codEmpresa: 1,
          codFilial: 1,
          dataVenda: filter.dataVendaInicio,
          qtdVendas: filter.dataVendaInicio.day,
          valorTotalDiarioVenda: filter.dataVendaInicio.day.toDouble(),
        ),
      ],
    );
  }
}

void main() {
  const strategy = ResumoTotalDiarioVendasCacheStrategy();
  final clock = DateTime(2026, 6, 3);

  late _MockAgentQueriesRepository agentQueries;
  late _CountingDelegate delegate;
  late CachingResumoTotalDiarioVendasRepositoryImpl cachingRepo;

  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteBatchRequest(
        agentId: 'fallback',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
      ),
    );
  });

  setUp(() {
    agentQueries = _MockAgentQueriesRepository();
    delegate = _CountingDelegate();
    cachingRepo = CachingResumoTotalDiarioVendasRepositoryImpl(
      delegate: delegate,
      factsStore: memoryAgentQueryFactsStore(),
      agentQueriesRepository: agentQueries,
      clock: () => clock,
      useExecuteBatchForBuckets: true,
    );
  });

  test(
    'forceRefresh loads open buckets via one executeSqlBatch per chunk',
    () async {
      when(() => agentQueries.executeSqlBatch(any())).thenAnswer((
        invocation,
      ) async {
        final request =
            invocation.positionalArguments.single as AgentSqlExecuteBatchRequest;
        check(request.commands.length).equals(3);
        check(
          request.options?.maxParallelReadOnlyBatchItems,
        ).equals(AppEnvironment.agentSqlOverviewBatchMaxParallelReadOnlyItems);
        return Success<AgentSqlBatchExecutionResult, AppFailure>(
          AgentSqlBatchExecutionResult(
            totalCommands: request.commands.length,
            successfulCommands: request.commands.length,
            failedCommands: 0,
            items: List<AgentSqlBatchExecutionItem>.generate(
              request.commands.length,
              (index) => AgentSqlBatchExecutionItem(
                index: index,
                ok: true,
                rows: <Map<String, dynamic>>[
                  <String, dynamic>{
                    'codEmpresa': 1,
                    'codFilial': 1,
                    'dataVenda': request.commands[index].namedParams['dataVendaInicio'],
                    'qtdVendas': index + 1,
                    'valorTotalDiarioVenda': (index + 1).toDouble(),
                  },
                ],
                rowCount: 1,
              ),
            ),
          ),
        );
      });

      final filter = ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 3, 23, 59, 59, 999, 999),
      );

      final result = await cachingRepo.load(
        userId: 'u1',
        agentId: 'a1',
        filter: filter,
        cachePolicy: AgentQueryLoadPolicy.forceRefresh,
      );

      expect(
        result.getOrNull()?.map((row) => row.qtdVendas).toList(),
        <int>[1, 2, 3],
      );
      verify(() => agentQueries.executeSqlBatch(any())).called(1);
      check(delegate.loadCount).equals(0);
    },
  );

  test('useExecuteBatchForBuckets false falls back to delegate per bucket', () async {
    cachingRepo = CachingResumoTotalDiarioVendasRepositoryImpl(
      delegate: delegate,
      factsStore: memoryAgentQueryFactsStore(),
      agentQueriesRepository: agentQueries,
      clock: () => clock,
      useExecuteBatchForBuckets: false,
    );

    final filter = ResumoTotalDiarioVendasFilter(
      dataVendaInicio: DateTime(2026, 6),
      dataVendaFim: DateTime(2026, 6, 3, 23, 59, 59, 999, 999),
    );

    await cachingRepo.load(
      userId: 'u1',
      agentId: 'a1',
      filter: filter,
      cachePolicy: AgentQueryLoadPolicy.forceRefresh,
    );

    verifyNever(() => agentQueries.executeSqlBatch(any()));
    check(delegate.loadCount).equals(3);
  });

  test('batch item failure fails load at first failed bucket in plan order', () async {
    when(() => agentQueries.executeSqlBatch(any())).thenAnswer((
      invocation,
    ) async {
      final request =
          invocation.positionalArguments.single as AgentSqlExecuteBatchRequest;
      return Success<AgentSqlBatchExecutionResult, AppFailure>(
        AgentSqlBatchExecutionResult(
          totalCommands: request.commands.length,
          successfulCommands: 1,
          failedCommands: 1,
          items: <AgentSqlBatchExecutionItem>[
            const AgentSqlBatchExecutionItem(
              index: 0,
              ok: true,
              rows: <Map<String, dynamic>>[
                <String, dynamic>{
                  'codEmpresa': 1,
                  'codFilial': 1,
                  'dataVenda': '2026-06-01',
                  'qtdVendas': 1,
                  'valorTotalDiarioVenda': 1.0,
                },
              ],
              rowCount: 1,
            ),
            const AgentSqlBatchExecutionItem(
              index: 1,
              ok: false,
              rows: <Map<String, dynamic>>[],
              rowCount: 0,
              error: 'bucket-2026-06-02',
            ),
            const AgentSqlBatchExecutionItem(
              index: 2,
              ok: true,
              rows: <Map<String, dynamic>>[
                <String, dynamic>{
                  'codEmpresa': 1,
                  'codFilial': 1,
                  'dataVenda': '2026-06-03',
                  'qtdVendas': 3,
                  'valorTotalDiarioVenda': 3.0,
                },
              ],
              rowCount: 1,
            ),
          ],
        ),
      );
    });

    final filter = ResumoTotalDiarioVendasFilter(
      dataVendaInicio: DateTime(2026, 6),
      dataVendaFim: DateTime(2026, 6, 3, 23, 59, 59, 999, 999),
    );

    final result = await cachingRepo.load(
      userId: 'u1',
      agentId: 'a1',
      filter: filter,
      cachePolicy: AgentQueryLoadPolicy.forceRefresh,
    );

    check(result.isError()).isTrue();
    expect(
      result.exceptionOrNull()?.message,
      contains('bucket-2026-06-02'),
    );
  });

  test('persists closed buckets from successful batch items', () async {
    when(() => agentQueries.executeSqlBatch(any())).thenAnswer((
      invocation,
    ) async {
      final request =
          invocation.positionalArguments.single as AgentSqlExecuteBatchRequest;
      return Success<AgentSqlBatchExecutionResult, AppFailure>(
        AgentSqlBatchExecutionResult(
          totalCommands: request.commands.length,
          successfulCommands: request.commands.length,
          failedCommands: 0,
          items: List<AgentSqlBatchExecutionItem>.generate(
            request.commands.length,
            (index) => AgentSqlBatchExecutionItem(
              index: index,
              ok: true,
              rows: <Map<String, dynamic>>[
                <String, dynamic>{
                  'codEmpresa': 1,
                  'codFilial': 1,
                  'dataVenda': request.commands[index].namedParams['dataVendaInicio'],
                  'qtdVendas': 7,
                  'valorTotalDiarioVenda': 7.0,
                },
              ],
              rowCount: 1,
            ),
          ),
        ),
      );
    });

    final filter = ResumoTotalDiarioVendasFilter(
      dataVendaInicio: DateTime(2026, 6),
      dataVendaFim: DateTime(2026, 6, 1, 23, 59, 59, 999, 999),
    );

    await cachingRepo.load(
      userId: 'u1',
      agentId: 'a1',
      filter: filter,
      cachePolicy: AgentQueryLoadPolicy.forceRefresh,
    );

    final storageKey = strategy.storageKey(
      userId: 'u1',
      agentId: 'a1',
      bucketId: '2026-06-01',
      rangeFilter: filter,
    );
    final cached = await cachingRepo.factsStore.readPayload(
      storageKey: storageKey,
      expectedSchemaVersion: strategy.schemaVersion,
    );
    check(cached).isNotNull();
    check(strategy.decodePayload(cached!).single.qtdVendas).equals(7);
  });
}
