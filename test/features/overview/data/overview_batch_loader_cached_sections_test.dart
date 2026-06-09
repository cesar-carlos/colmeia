import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_dia_semana_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_dia_semana_usuario_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_mensal_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_lucratividade_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_total_diario_vendas_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/overview/data/overview_batch_loader.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockTargetResolver extends Mock implements AgentQueryTargetResolver {}

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

class _MockLoadDaily extends Mock implements LoadResumoTotalDiarioVendasUseCase {}

class _MockLoadMonthly extends Mock implements LoadResumoParcelasMensalUseCase {}

class _MockLoadWeekday extends Mock
    implements LoadResumoParcelasDiaSemanaUseCase {}

class _MockLoadLucratividade extends Mock
    implements LoadResumoProdutoVendaLucratividadeUseCase {}

void main() {
  late _MockTargetResolver targetResolver;
  late _MockAgentQueriesRepository agentQueriesRepository;
  late _MockLoadDaily loadDaily;
  late _MockLoadMonthly loadMonthly;
  late _MockLoadWeekday loadWeekday;
  late _MockLoadLucratividade loadLucratividade;

  const target = AgentQueryTarget(
    agentId: 'agent-1',
    displayName: 'Agent 1',
    connectionStatus: AgentConnectionStatus.online,
    clientToken: 'token',
    hubConnectedFromApprovedCatalogRow: true,
  );

  setUpAll(() {
    registerFallbackValue(AgentQueryExecutionStrategy.mergeAll);
    registerFallbackValue(AgentQueryLoadPolicy.defaultLoad);
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
    registerFallbackValue(
      ResumoParcelasDiaSemanaFilter(
        dataVendaInicio: DateTime(2026),
        dataVendaFim: DateTime(2026, 1, 31),
      ),
    );
    registerFallbackValue(
      ResumoProdutoVendaLucratividadeFilter(
        dataVendaInicio: DateTime(2026),
        dataVendaFim: DateTime(2026, 1, 31),
      ),
    );
  });

  setUp(() {
    targetResolver = _MockTargetResolver();
    agentQueriesRepository = _MockAgentQueriesRepository();
    loadDaily = _MockLoadDaily();
    loadMonthly = _MockLoadMonthly();
    loadWeekday = _MockLoadWeekday();
    loadLucratividade = _MockLoadLucratividade();

    when(
      () => targetResolver.resolve(
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
        cancelScope: any(named: 'cancelScope'),
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
        cancelScope: any(named: 'cancelScope'),
        cachePolicy: any(named: 'cachePolicy'),
      ),
    ).thenAnswer(
      (_) async => const Success<List<ResumoParcelasMensalRow>, AppFailure>(
        <ResumoParcelasMensalRow>[],
      ),
    );
    when(
      () => loadWeekday.call(
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
        cancelScope: any(named: 'cancelScope'),
        cachePolicy: any(named: 'cachePolicy'),
      ),
    ).thenAnswer(
      (_) async => const Success<List<ResumoParcelasDiaSemanaRow>, AppFailure>(
        <ResumoParcelasDiaSemanaRow>[],
      ),
    );
    when(
      () => loadLucratividade.call(
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
        cancelScope: any(named: 'cancelScope'),
        cachePolicy: any(named: 'cachePolicy'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<List<ResumoProdutoVendaLucratividadeRow>, AppFailure>(
            <ResumoProdutoVendaLucratividadeRow>[],
          ),
    );
  });

  OverviewBatchLoader loaderWithCachedSections() {
    return OverviewBatchLoader(
      targetResolver: targetResolver,
      planBuilder: const AgentQueryPlanBuilder(),
      agentQueriesRepository: agentQueriesRepository,
      loadDaily: loadDaily,
      loadMonthly: loadMonthly,
      loadWeekday: loadWeekday,
      loadLucratividade: loadLucratividade,
    );
  }

  Future<void> runDefaultLoad({
    required OverviewBatchLoader loader,
    bool mergeSqlBatchesPerTarget = false,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
  }) async {
    final periodStart = DateTime(2026, 4);
    final periodEnd = DateTime(2026, 4, 15);
    final mensalFilter = ResumoParcelasMensalFilter(
      dataVendaInicio: DateTime(2025, 4),
      dataVendaFim: periodEnd,
    );
    final dailyFilter = ResumoTotalDiarioVendasFilter(
      dataVendaInicio: periodStart,
      dataVendaFim: periodEnd,
    );

    await loader.load(
      userId: 'user-1',
      filter: filter,
      periodStart: periodStart,
      periodEnd: periodEnd,
      last12Range: (
        dataVendaInicio: DateTime(2025, 4),
        dataVendaFim: periodEnd,
      ),
      mensalFilter: mensalFilter,
      weekdayFilter: ResumoParcelasDiaSemanaFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
      dailyTotalFilter: dailyFilter,
      executionStrategy: AgentQueryExecutionStrategy.mergeAll,
      cachePolicy: cachePolicy,
      mergeSqlBatchesPerTarget: mergeSqlBatchesPerTarget,
    );
  }

  test('section batch includes daily and monthly SQL without cached use cases',
      () async {
    when(() => agentQueriesRepository.executeSqlBatch(any())).thenAnswer((
      invocation,
    ) async {
      final request =
          invocation.positionalArguments.single as AgentSqlExecuteBatchRequest;
      if (request.commands.length == 2) {
        return Success<AgentSqlBatchExecutionResult, AppFailure>(
          _batchResult(
            commandCount: 2,
            rowsByIndex: <int, List<Map<String, dynamic>>>{
              0: <Map<String, dynamic>>[_mainRow()],
              1: <Map<String, dynamic>>[_userRankingRow()],
            },
          ),
        );
      }
      return Success<AgentSqlBatchExecutionResult, AppFailure>(
        _batchResult(commandCount: request.commands.length),
      );
    });

    final loader = OverviewBatchLoader(
      targetResolver: targetResolver,
      planBuilder: const AgentQueryPlanBuilder(),
      agentQueriesRepository: agentQueriesRepository,
    );

    await runDefaultLoad(loader: loader);

    final batchRequests = verify(
      () => agentQueriesRepository.executeSqlBatch(captureAny()),
    ).captured.cast<AgentSqlExecuteBatchRequest>();
    expect(batchRequests.length, greaterThanOrEqualTo(2));
    final sectionRequest = batchRequests.firstWhere(
      (request) => request.commands.length >= 5,
    );
    final sqlBodies = sectionRequest.commands
        .map((command) => command.sql)
        .join('\n');
    expect(sqlBodies.contains(ResumoTotalDiarioVendasSql.query), isTrue);
    expect(
      sqlBodies.contains(
        ResumoParcelasMensalSql.query(),
      ),
      isTrue,
    );
  });

  test(
    'section batch omits cached daily monthly weekday lucratividade SQL',
    () async {
      when(() => agentQueriesRepository.executeSqlBatch(any())).thenAnswer((
        invocation,
      ) async {
        final request =
            invocation.positionalArguments.single as AgentSqlExecuteBatchRequest;
        if (request.commands.length == 2) {
          return Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(
              commandCount: 2,
              rowsByIndex: <int, List<Map<String, dynamic>>>{
                0: <Map<String, dynamic>>[_mainRow()],
                1: <Map<String, dynamic>>[_userRankingRow()],
              },
            ),
          );
        }
        return Success<AgentSqlBatchExecutionResult, AppFailure>(
          _batchResult(commandCount: request.commands.length),
        );
      });

      await runDefaultLoad(loader: loaderWithCachedSections());

      final batchRequests = verify(
        () => agentQueriesRepository.executeSqlBatch(captureAny()),
      ).captured.cast<AgentSqlExecuteBatchRequest>();
      expect(batchRequests.length, 2);
      final sectionRequest = batchRequests.last;
      expect(sectionRequest.commands.length, 1);
      expect(
        sectionRequest.commands.single.sql,
        ResumoParcelasDiaSemanaUsuarioSql.query(),
      );
      verify(() => loadDaily.call(
            userId: 'user-1',
            agentId: 'agent-1',
            filter: any(named: 'filter'),
            clientToken: 'token',
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            hubPresenceOnlineAgentIdsSnapshot: any(
              named: 'hubPresenceOnlineAgentIdsSnapshot',
            ),
            hubConnectedFromApprovedCatalogRow: true,
            cancelScope: any(named: 'cancelScope'),
            cachePolicy: any(named: 'cachePolicy'),
          )).called(1);
      verify(() => loadWeekday.call(
            userId: 'user-1',
            agentId: 'agent-1',
            filter: any(named: 'filter'),
            clientToken: 'token',
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            hubPresenceOnlineAgentIdsSnapshot: any(
              named: 'hubPresenceOnlineAgentIdsSnapshot',
            ),
            hubConnectedFromApprovedCatalogRow: true,
            cancelScope: any(named: 'cancelScope'),
            cachePolicy: any(named: 'cachePolicy'),
          )).called(1);
    },
  );

  test(
    'mergeSqlBatchesPerTarget omits cached sections and loads them via use cases',
    () async {
      when(() => agentQueriesRepository.executeSqlBatch(any())).thenAnswer((
        invocation,
      ) async {
        final request =
            invocation.positionalArguments.single as AgentSqlExecuteBatchRequest;
        return Success<AgentSqlBatchExecutionResult, AppFailure>(
          _batchResult(
            commandCount: request.commands.length,
            rowsByIndex: request.commands.length >= 2
                ? <int, List<Map<String, dynamic>>>{
                    0: <Map<String, dynamic>>[_mainRow()],
                    1: <Map<String, dynamic>>[_userRankingRow()],
                  }
                : const <int, List<Map<String, dynamic>>>{},
          ),
        );
      });

      await runDefaultLoad(
        loader: loaderWithCachedSections(),
        mergeSqlBatchesPerTarget: true,
      );

      final batchRequests = verify(
        () => agentQueriesRepository.executeSqlBatch(captureAny()),
      ).captured.cast<AgentSqlExecuteBatchRequest>();
      expect(batchRequests.length, 1);
      expect(batchRequests.single.commands.length, 3);
      final mergedSqlBodies = batchRequests.single.commands
          .map((command) => command.sql)
          .join('\n');
      expect(
        mergedSqlBodies.contains(ResumoParcelasDiaSemanaUsuarioSql.query()),
        isTrue,
      );
      expect(mergedSqlBodies.contains(ResumoTotalDiarioVendasSql.query), isFalse);
      expect(
        mergedSqlBodies.contains(ResumoParcelasMensalSql.query()),
        isFalse,
      );
      expect(
        mergedSqlBodies.contains(ResumoParcelasDiaSemanaSql.query()),
        isFalse,
      );
      expect(
        mergedSqlBodies.contains(ResumoProdutoVendaLucratividadeSql.query),
        isFalse,
      );
      verify(() => loadDaily.call(
            userId: 'user-1',
            agentId: 'agent-1',
            filter: any(named: 'filter'),
            clientToken: 'token',
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            hubPresenceOnlineAgentIdsSnapshot: any(
              named: 'hubPresenceOnlineAgentIdsSnapshot',
            ),
            hubConnectedFromApprovedCatalogRow: true,
            cancelScope: any(named: 'cancelScope'),
            cachePolicy: any(named: 'cachePolicy'),
          )).called(1);
      verify(() => loadMonthly.call(
            userId: 'user-1',
            agentId: 'agent-1',
            filter: any(named: 'filter'),
            clientToken: 'token',
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            hubPresenceOnlineAgentIdsSnapshot: any(
              named: 'hubPresenceOnlineAgentIdsSnapshot',
            ),
            hubConnectedFromApprovedCatalogRow: true,
            cancelScope: any(named: 'cancelScope'),
            cachePolicy: any(named: 'cachePolicy'),
          )).called(1);
      verify(() => loadWeekday.call(
            userId: 'user-1',
            agentId: 'agent-1',
            filter: any(named: 'filter'),
            clientToken: 'token',
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            hubPresenceOnlineAgentIdsSnapshot: any(
              named: 'hubPresenceOnlineAgentIdsSnapshot',
            ),
            hubConnectedFromApprovedCatalogRow: true,
            cancelScope: any(named: 'cancelScope'),
            cachePolicy: any(named: 'cachePolicy'),
          )).called(1);
      verify(() => loadLucratividade.call(
            userId: 'user-1',
            agentId: 'agent-1',
            filter: any(named: 'filter'),
            clientToken: 'token',
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            hubPresenceOnlineAgentIdsSnapshot: any(
              named: 'hubPresenceOnlineAgentIdsSnapshot',
            ),
            hubConnectedFromApprovedCatalogRow: true,
            cancelScope: any(named: 'cancelScope'),
            cachePolicy: any(named: 'cachePolicy'),
          )).called(1);
    },
  );

  test(
    'phasedBatchPerTarget with merge yields main batch before section batch',
    () async {
      when(() => agentQueriesRepository.executeSqlBatch(any())).thenAnswer((
        invocation,
      ) async {
        final request =
            invocation.positionalArguments.single as AgentSqlExecuteBatchRequest;
        if (request.commands.length == 2) {
          return Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(
              commandCount: 2,
              rowsByIndex: <int, List<Map<String, dynamic>>>{
                0: <Map<String, dynamic>>[_mainRow()],
                1: <Map<String, dynamic>>[_userRankingRow()],
              },
            ),
          );
        }
        return Success<AgentSqlBatchExecutionResult, AppFailure>(
          _batchResult(commandCount: request.commands.length),
        );
      });

      final loader = loaderWithCachedSections();
      final periodStart = DateTime(2026, 4);
      final periodEnd = DateTime(2026, 4, 15);
      final snapshots = await loader
          .loadProgressively(
            userId: 'user-1',
            filter: const DashboardFilter(),
            periodStart: periodStart,
            periodEnd: periodEnd,
            last12Range: (
              dataVendaInicio: DateTime(2025, 4),
              dataVendaFim: periodEnd,
            ),
            mensalFilter: ResumoParcelasMensalFilter(
              dataVendaInicio: DateTime(2025, 4),
              dataVendaFim: periodEnd,
            ),
            weekdayFilter: ResumoParcelasDiaSemanaFilter(
              dataVendaInicio: periodStart,
              dataVendaFim: periodEnd,
            ),
            dailyTotalFilter: ResumoTotalDiarioVendasFilter(
              dataVendaInicio: periodStart,
              dataVendaFim: periodEnd,
            ),
            executionStrategy: AgentQueryExecutionStrategy.mergeAll,
            mergeSqlBatchesPerTarget: true,
            phasedBatchPerTarget: true,
          )
          .toList();

      expect(snapshots.length, 2);
      expect(snapshots.first.getOrThrow().isFinal, isFalse);
      expect(snapshots.last.getOrThrow().isFinal, isTrue);

      final batchRequests = verify(
        () => agentQueriesRepository.executeSqlBatch(captureAny()),
      ).captured.cast<AgentSqlExecuteBatchRequest>();
      expect(batchRequests.length, 2);
      expect(batchRequests.first.commands.length, 2);
      expect(batchRequests.last.commands.length, 1);
      expect(
        batchRequests.last.commands.single.sql,
        ResumoParcelasDiaSemanaUsuarioSql.query(),
      );
    },
  );

  test(
    'forceRefresh includes daily monthly weekday lucratividade in section batch',
    () async {
      when(() => agentQueriesRepository.executeSqlBatch(any())).thenAnswer((
        invocation,
      ) async {
        final request =
            invocation.positionalArguments.single as AgentSqlExecuteBatchRequest;
        if (request.commands.length == 2) {
          return Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(
              commandCount: 2,
              rowsByIndex: <int, List<Map<String, dynamic>>>{
                0: <Map<String, dynamic>>[_mainRow()],
                1: <Map<String, dynamic>>[_userRankingRow()],
              },
            ),
          );
        }
        return Success<AgentSqlBatchExecutionResult, AppFailure>(
          _batchResult(commandCount: request.commands.length),
        );
      });

      await runDefaultLoad(
        loader: loaderWithCachedSections(),
        cachePolicy: AgentQueryLoadPolicy.forceRefresh,
      );

      final batchRequests = verify(
        () => agentQueriesRepository.executeSqlBatch(captureAny()),
      ).captured.cast<AgentSqlExecuteBatchRequest>();
      final sectionRequest = batchRequests.last;
      final sqlBodies = sectionRequest.commands
          .map((command) => command.sql)
          .join('\n');
      expect(sqlBodies.contains(ResumoTotalDiarioVendasSql.query), isTrue);
      expect(
        sqlBodies.contains(ResumoParcelasMensalSql.query()),
        isTrue,
      );
      expect(
        sqlBodies.contains(ResumoParcelasDiaSemanaSql.query()),
        isTrue,
      );
      expect(
        sqlBodies.contains(ResumoProdutoVendaLucratividadeSql.query),
        isTrue,
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
          cancelScope: any(named: 'cancelScope'),
          cachePolicy: any(named: 'cachePolicy'),
        ),
      );
    },
  );

  test('forceRefresh sets skipTransportCache on batch requests', () async {
    when(() => agentQueriesRepository.executeSqlBatch(any())).thenAnswer((
      invocation,
    ) async {
      final request =
          invocation.positionalArguments.single as AgentSqlExecuteBatchRequest;
      if (request.commands.length == 2) {
        return Success<AgentSqlBatchExecutionResult, AppFailure>(
          _batchResult(
            commandCount: 2,
            rowsByIndex: <int, List<Map<String, dynamic>>>{
              0: <Map<String, dynamic>>[_mainRow()],
              1: <Map<String, dynamic>>[_userRankingRow()],
            },
          ),
        );
      }
      return Success<AgentSqlBatchExecutionResult, AppFailure>(
        _batchResult(commandCount: request.commands.length),
      );
    });

    final loader = OverviewBatchLoader(
      targetResolver: targetResolver,
      planBuilder: const AgentQueryPlanBuilder(),
      agentQueriesRepository: agentQueriesRepository,
    );

    await runDefaultLoad(
      loader: loader,
      cachePolicy: AgentQueryLoadPolicy.forceRefresh,
    );

    final batchRequests = verify(
      () => agentQueriesRepository.executeSqlBatch(captureAny()),
    ).captured.cast<AgentSqlExecuteBatchRequest>();
    expect(batchRequests, isNotEmpty);
    expect(batchRequests.every((request) => request.skipTransportCache), isTrue);
  });
}

AgentSqlBatchExecutionResult _batchResult({
  required int commandCount,
  Map<int, List<Map<String, dynamic>>> rowsByIndex =
      const <int, List<Map<String, dynamic>>>{},
}) {
  return AgentSqlBatchExecutionResult(
    totalCommands: commandCount,
    successfulCommands: commandCount,
    failedCommands: 0,
    items: List<AgentSqlBatchExecutionItem>.generate(
      commandCount,
      (index) => AgentSqlBatchExecutionItem(
        index: index,
        ok: true,
        rows: rowsByIndex[index] ?? const <Map<String, dynamic>>[],
        rowCount: rowsByIndex[index]?.length ?? 0,
      ),
    ),
  );
}

Map<String, dynamic> _mainRow() {
  return <String, dynamic>{
    'CodEmpresa': 1,
    'CodFilial': 1,
    'NomeUsuario': 'Caixa',
    'AnoDataVenda': 2026,
    'MesDataVenda': 4,
    'AnoMesDataVenda': '2026/04',
    'CodFormaPagamento': 'PIX',
    'DescricaoFormaPagamento': 'Pix',
    'QtdVendas': 2,
    'ValorParcela': 100.0,
  };
}

Map<String, dynamic> _userRankingRow() {
  return <String, dynamic>{
    'CodEmpresa': 1,
    'CodFilial': 1,
    'NomeUsuario': 'Caixa',
    'QtdVendas': 3,
    'ValorParcela': 90.0,
  };
}
