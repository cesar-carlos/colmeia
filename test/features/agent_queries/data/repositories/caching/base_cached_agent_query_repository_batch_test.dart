import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_total_diario_vendas_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/caching_resumo_total_diario_vendas_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/cache/calendar_bucket_closure.dart';
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
  ResumoTotalDiarioVendasFilter? lastFilter;

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
    lastFilter = filter;
    final days = CalendarBucketClosure.daysInRange(
      start: filter.dataVendaInicio,
      end: filter.dataVendaFim,
    );
    return Success<List<ResumoTotalDiarioVendasRow>, AppFailure>(
      days
          .map(
            (day) => ResumoTotalDiarioVendasRow(
              codEmpresa: 1,
              codFilial: 1,
              dataVenda: day,
              qtdVendas: day.day,
              valorTotalDiarioVenda: day.day.toDouble(),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _FailingDelegate implements ResumoTotalDiarioVendasRepository {
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
    return const Failure<List<ResumoTotalDiarioVendasRow>, AppFailure>(
      UnknownFailure(message: 'range-coalesce-failed'),
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
    'forceRefresh multi-bucket uses one range delegate load (coalesce)',
    () async {
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
      verifyNever(() => agentQueries.executeSqlBatch(any()));
      check(delegate.loadCount).equals(1);
      check(delegate.lastFilter!.dataVendaInicio).equals(DateTime(2026, 6));
      check(
        DateTime(
          delegate.lastFilter!.dataVendaFim.year,
          delegate.lastFilter!.dataVendaFim.month,
          delegate.lastFilter!.dataVendaFim.day,
        ),
      ).equals(DateTime(2026, 6, 3));
    },
  );

  test(
    'multi-bucket coalesce runs even when executeBatch is disabled',
    () async {
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
      check(delegate.loadCount).equals(1);
    },
  );

  test('range coalesce failure fails the whole load', () async {
    cachingRepo = CachingResumoTotalDiarioVendasRepositoryImpl(
      delegate: _FailingDelegate(),
      factsStore: memoryAgentQueryFactsStore(),
      agentQueriesRepository: agentQueries,
      clock: () => clock,
      useExecuteBatchForBuckets: true,
    );

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
      contains('range-coalesce-failed'),
    );
  });

  test(
    'defaultLoad cold closed days coalesce to one range load and persist',
    () async {
      // All days closed relative to July clock.
      cachingRepo = CachingResumoTotalDiarioVendasRepositoryImpl(
        delegate: delegate,
        factsStore: memoryAgentQueryFactsStore(),
        agentQueriesRepository: agentQueries,
        clock: () => DateTime(2026, 7, 23),
        useExecuteBatchForBuckets: true,
      );

      final filter = ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 3, 23, 59, 59, 999, 999),
      );

      final result = await cachingRepo.load(
        userId: 'u1',
        agentId: 'a1',
        filter: filter,
      );

      expect(
        result.getOrNull()?.map((row) => row.qtdVendas).toList(),
        <int>[1, 2, 3],
      );
      verifyNever(() => agentQueries.executeSqlBatch(any()));
      check(delegate.loadCount).equals(1);

      for (final bucketId in <String>['2026-06-01', '2026-06-02', '2026-06-03']) {
        final storageKey = strategy.storageKey(
          userId: 'u1',
          agentId: 'a1',
          bucketId: bucketId,
          rangeFilter: filter,
        );
        final cached = await cachingRepo.factsStore.readPayload(
          storageKey: storageKey,
          expectedSchemaVersion: strategy.schemaVersion,
        );
        check(cached).isNotNull();
      }
    },
  );

  test(
    'defaultLoad partial cache hit still uses one range load for misses',
    () async {
      final factsStore = memoryAgentQueryFactsStore();
      cachingRepo = CachingResumoTotalDiarioVendasRepositoryImpl(
        delegate: delegate,
        factsStore: factsStore,
        agentQueriesRepository: agentQueries,
        clock: () => clock,
        useExecuteBatchForBuckets: true,
      );

      final filter = ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 3, 23, 59, 59, 999, 999),
      );

      await factsStore.writePayload(
        storageKey: strategy.storageKey(
          userId: 'u1',
          agentId: 'a1',
          bucketId: '2026-06-01',
          rangeFilter: filter,
        ),
        payload: strategy.encodePayload(<ResumoTotalDiarioVendasRow>[
          ResumoTotalDiarioVendasRow(
            codEmpresa: 1,
            codFilial: 1,
            dataVenda: DateTime(2026, 6),
            qtdVendas: 99,
            valorTotalDiarioVenda: 99,
          ),
        ]),
        schemaVersion: strategy.schemaVersion,
      );

      final result = await cachingRepo.load(
        userId: 'u1',
        agentId: 'a1',
        filter: filter,
      );

      // Closed hit keeps cached 99; open/miss days come from one range load.
      expect(
        result.getOrNull()?.map((row) => row.qtdVendas).toList(),
        <int>[99, 2, 3],
      );
      verifyNever(() => agentQueries.executeSqlBatch(any()));
      check(delegate.loadCount).equals(1);
    },
  );

  test('single-bucket forceRefresh persists via executeSqlBatch', () async {
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
                  'dataVenda':
                      request.commands[index].namedParams['dataVendaInicio'],
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

    verify(() => agentQueries.executeSqlBatch(any())).called(1);
    check(delegate.loadCount).equals(0);

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
