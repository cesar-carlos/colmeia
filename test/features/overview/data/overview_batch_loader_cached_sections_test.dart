import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_parcelas_mensal_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_total_diario_vendas_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
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

void main() {
  late _MockTargetResolver targetResolver;
  late _MockAgentQueriesRepository agentQueriesRepository;

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
  });

  setUp(() {
    targetResolver = _MockTargetResolver();
    agentQueriesRepository = _MockAgentQueriesRepository();

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
  });

  test('section batch includes daily and monthly SQL', () async {
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
      filter: const DashboardFilter(),
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
    );

    final batchRequests = verify(
      () => agentQueriesRepository.executeSqlBatch(captureAny()),
    ).captured.cast<AgentSqlExecuteBatchRequest>();
    expect(batchRequests.length, greaterThanOrEqualTo(2));
    final sectionRequest = batchRequests.firstWhere(
      (request) => request.commands.length == 5,
    );
    final sqlBodies = sectionRequest.commands
        .map((command) => command.sql)
        .join('\n');
    expect(sqlBodies.contains(ResumoTotalDiarioVendasSql.query), isTrue);
    expect(
      sqlBodies.contains(
        ResumoParcelasMensalSql.query(
          codEmpresa: mensalFilter.codEmpresa,
          codFilial: mensalFilter.codFilial,
          codVendedor: mensalFilter.codVendedor,
        ),
      ),
      isTrue,
    );
  });

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

    final periodStart = DateTime(2026, 4);
    final periodEnd = DateTime(2026, 4, 15);

    await loader.load(
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
