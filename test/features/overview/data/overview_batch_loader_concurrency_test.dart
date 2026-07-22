import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/cache/agent_query_facts_store.dart';
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
import 'package:colmeia/features/overview/data/overview_cached_facts_warmth_checker.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockTargetResolver extends Mock implements AgentQueryTargetResolver {}

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

class _MockLoadDaily extends Mock
    implements LoadResumoTotalDiarioVendasUseCase {}

class _MockLoadMonthly extends Mock
    implements LoadResumoParcelasMensalUseCase {}

class _MockLoadWeekday extends Mock
    implements LoadResumoParcelasDiaSemanaUseCase {}

class _MockLoadLucratividade extends Mock
    implements LoadResumoProdutoVendaLucratividadeUseCase {}

class _MockFactsStore extends Mock implements AgentQueryFactsStore {}

void main() {
  late _MockTargetResolver targetResolver;
  late _MockAgentQueriesRepository agentQueriesRepository;
  late _MockLoadDaily loadDaily;
  late _MockLoadMonthly loadMonthly;
  late _MockLoadWeekday loadWeekday;
  late _MockLoadLucratividade loadLucratividade;
  late _MockFactsStore factsStore;
  late OverviewCachedFactsWarmthChecker warmthChecker;

  const target = AgentQueryTarget(
    agentId: 'agent-1',
    displayName: 'Agent 1',
    connectionStatus: AgentConnectionStatus.online,
    clientToken: 'token',
    hubConnectedFromApprovedCatalogRow: true,
  );

  setUpAll(() {
    registerFallbackValue(<String>{'agent-fallback'});
    registerFallbackValue(
      const AgentSqlExecuteBatchRequest(
        agentId: 'agent-fallback',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
      ),
    );
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
    factsStore = _MockFactsStore();
    warmthChecker = OverviewCachedFactsWarmthChecker(
      factsStore: factsStore,
      clock: () => DateTime(2026, 4, 15),
    );

    when(
      () => factsStore.readPayload(
        storageKey: any(named: 'storageKey'),
        expectedSchemaVersion: any(named: 'expectedSchemaVersion'),
      ),
    ).thenAnswer((_) async => <int>[1]);

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

  test(
    'section SQL batch completes before cached use cases start',
    () async {
      final timeline = <String>[];
      when(() => agentQueriesRepository.executeSqlBatch(any())).thenAnswer((
        invocation,
      ) async {
        final request =
            invocation.positionalArguments.single
                as AgentSqlExecuteBatchRequest;
        if (request.commands.length == 2) {
          timeline.add('mainBatchStart');
          await Future<void>.delayed(const Duration(milliseconds: 20));
          timeline.add('mainBatchEnd');
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
        timeline.add('sectionBatchStart');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        timeline.add('sectionBatchEnd');
        return Success<AgentSqlBatchExecutionResult, AppFailure>(
          _batchResult(commandCount: request.commands.length),
        );
      });
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
      ).thenAnswer((_) async {
        timeline.add('cachedDailyStart');
        await Future<void>.delayed(const Duration(milliseconds: 5));
        timeline.add('cachedDailyEnd');
        return const Success<List<ResumoTotalDiarioVendasRow>, AppFailure>(
          <ResumoTotalDiarioVendasRow>[],
        );
      });

      final loader = OverviewBatchLoader(
        targetResolver: targetResolver,
        planBuilder: const AgentQueryPlanBuilder(),
        agentQueriesRepository: agentQueriesRepository,
        loadDaily: loadDaily,
        loadMonthly: loadMonthly,
        loadWeekday: loadWeekday,
        loadLucratividade: loadLucratividade,
        factsWarmthChecker: warmthChecker,
      );

      await loader.load(
        userId: 'user-1',
        filter: const DashboardFilter(),
        periodStart: DateTime(2026, 4),
        periodEnd: DateTime(2026, 4, 15),
        mensalFilter: ResumoParcelasMensalFilter(
          dataVendaInicio: DateTime(2025, 4),
          dataVendaFim: DateTime(2026, 4, 15),
        ),
        weekdayFilter: ResumoParcelasDiaSemanaFilter(
          dataVendaInicio: DateTime(2026, 4),
          dataVendaFim: DateTime(2026, 4, 15),
        ),
        dailyTotalFilter: ResumoTotalDiarioVendasFilter(
          dataVendaInicio: DateTime(2026, 4),
          dataVendaFim: DateTime(2026, 4, 15),
        ),
        executionStrategy: AgentQueryExecutionStrategy.mergeAll,
      );

      final sectionBatchEnd = timeline.indexOf('sectionBatchEnd');
      final cachedDailyStart = timeline.indexOf('cachedDailyStart');
      expect(sectionBatchEnd, greaterThanOrEqualTo(0));
      expect(cachedDailyStart, greaterThan(sectionBatchEnd));
    },
  );

  test(
    'cold cache uses single merged batch without cached use cases',
    () async {
      when(
        () => factsStore.readPayload(
          storageKey: any(named: 'storageKey'),
          expectedSchemaVersion: any(named: 'expectedSchemaVersion'),
        ),
      ).thenAnswer((_) async => null);
      when(() => agentQueriesRepository.executeSqlBatch(any())).thenAnswer((
        invocation,
      ) async {
        final request =
            invocation.positionalArguments.single
                as AgentSqlExecuteBatchRequest;
        return Success<AgentSqlBatchExecutionResult, AppFailure>(
          _batchResult(commandCount: request.commands.length),
        );
      });

      final loader = OverviewBatchLoader(
        targetResolver: targetResolver,
        planBuilder: const AgentQueryPlanBuilder(),
        agentQueriesRepository: agentQueriesRepository,
        loadDaily: loadDaily,
        loadMonthly: loadMonthly,
        factsWarmthChecker: warmthChecker,
      );

      await loader.load(
        userId: 'user-1',
        filter: const DashboardFilter(),
        periodStart: DateTime(2026, 4),
        periodEnd: DateTime(2026, 4, 15),
        mensalFilter: ResumoParcelasMensalFilter(
          dataVendaInicio: DateTime(2025, 4),
          dataVendaFim: DateTime(2026, 4, 15),
        ),
        weekdayFilter: ResumoParcelasDiaSemanaFilter(
          dataVendaInicio: DateTime(2026, 4),
          dataVendaFim: DateTime(2026, 4, 15),
        ),
        dailyTotalFilter: ResumoTotalDiarioVendasFilter(
          dataVendaInicio: DateTime(2026, 4),
          dataVendaFim: DateTime(2026, 4, 15),
        ),
        executionStrategy: AgentQueryExecutionStrategy.mergeAll,
      );

      verify(() => agentQueriesRepository.executeSqlBatch(any())).called(1);
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
