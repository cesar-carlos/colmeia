import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_dia_semana_usuario_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_usuario_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/overview/data/datasources/overview_local_datasource.dart';
import 'package:colmeia/features/overview/data/models/overview_model.dart';
import 'package:colmeia/features/overview/data/overview_batch_loader.dart';
import 'package:colmeia/features/overview/data/repositories/overview_repository_impl.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/overview_failure_ui_key.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockOverviewLocalDataSource extends Mock
    implements OverviewLocalDataSource {}

class _MockResumoAcrossAgentsRepository extends Mock
    implements ResumoParcelaFormaPagamentoAcrossAgentsRepository {}

class _MockLoadResumoParcelasMensalAcrossAgents extends Mock
    implements LoadResumoParcelasMensalAcrossAgentsUseCase {}

class _MockLoadResumoParcelasDiaSemanaAcrossAgents extends Mock
    implements LoadResumoParcelasDiaSemanaAcrossAgentsUseCase {}

class _MockLoadResumoParcelasDiaSemanaUsuarioAcrossAgents extends Mock
    implements LoadResumoParcelasDiaSemanaUsuarioAcrossAgentsUseCase {}

class _MockLoadResumoTotalDiarioVendasAcrossAgents extends Mock
    implements LoadResumoTotalDiarioVendasAcrossAgentsUseCase {}

class _MockLoadResumoProdutoVendaLucratividadeMensal extends Mock
    implements LoadResumoProdutoVendaLucratividadeMensalUseCase {}

class _MockLoadResumoProdutoVendaLucratividade extends Mock
    implements LoadResumoProdutoVendaLucratividadeUseCase {}

class _MockAgentQueryTargetResolver extends Mock
    implements AgentQueryTargetResolver {}

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockOverviewLocalDataSource local;
  late _MockResumoAcrossAgentsRepository resumoAcrossAgentsRepository;
  late _MockLoadResumoParcelasMensalAcrossAgents
  loadResumoParcelasMensalAcrossAgents;
  late _MockLoadResumoParcelasDiaSemanaAcrossAgents
  loadResumoParcelasDiaSemanaAcrossAgents;
  late _MockLoadResumoParcelasDiaSemanaUsuarioAcrossAgents
  loadResumoParcelasDiaSemanaUsuarioAcrossAgents;
  late _MockLoadResumoTotalDiarioVendasAcrossAgents
  loadResumoTotalDiarioVendasAcrossAgents;
  late _MockLoadResumoProdutoVendaLucratividadeMensal
  loadResumoProdutoVendaLucratividadeMensal;
  late _MockLoadResumoProdutoVendaLucratividade
  loadResumoProdutoVendaLucratividade;
  late _MockAgentQueryTargetResolver batchTargetResolver;
  late _MockAgentQueriesRepository batchAgentQueriesRepository;

  final fixedNow = DateTime(2026, 4, 8);

  setUpAll(() {
    registerFallbackValue(
      ResumoParcelaFormaPagamentoFilter(
        dataVendaInicio: DateTime(2026, 3, 10),
        dataVendaFim: DateTime(2026, 4, 8),
      ),
    );
    registerFallbackValue(AgentQueryExecutionStrategy.mergeAll);
    registerFallbackValue(
      const AgentSqlExecuteBatchRequest(
        agentId: 'agent-fallback',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
      ),
    );
    registerFallbackValue(
      ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime(2025, 5),
        dataVendaFim: DateTime(2026, 4, 30),
      ),
    );
    registerFallbackValue(
      ResumoParcelasDiaSemanaFilter(
        dataVendaInicio: DateTime(2026, 3, 10),
        dataVendaFim: DateTime(2026, 4, 8),
      ),
    );
    registerFallbackValue(
      ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 3, 10),
        dataVendaFim: DateTime(2026, 4, 8),
      ),
    );
    registerFallbackValue(<String>{'agent-fallback'});
    registerFallbackValue(
      ResumoProdutoVendaLucratividadeMensalFilter(
        dataVendaInicio: DateTime(2025, 5),
        dataVendaFim: DateTime(2026, 4, 30),
      ),
    );
    registerFallbackValue(
      ResumoProdutoVendaLucratividadeFilter(
        dataVendaInicio: DateTime(2026, 3, 10),
        dataVendaFim: DateTime(2026, 4, 8),
      ),
    );
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
    resumoAcrossAgentsRepository = _MockResumoAcrossAgentsRepository();
    loadResumoParcelasMensalAcrossAgents =
        _MockLoadResumoParcelasMensalAcrossAgents();
    loadResumoParcelasDiaSemanaAcrossAgents =
        _MockLoadResumoParcelasDiaSemanaAcrossAgents();
    loadResumoParcelasDiaSemanaUsuarioAcrossAgents =
        _MockLoadResumoParcelasDiaSemanaUsuarioAcrossAgents();
    loadResumoTotalDiarioVendasAcrossAgents =
        _MockLoadResumoTotalDiarioVendasAcrossAgents();
    loadResumoProdutoVendaLucratividadeMensal =
        _MockLoadResumoProdutoVendaLucratividadeMensal();
    when(
      () => loadResumoProdutoVendaLucratividadeMensal(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<
            List<ResumoProdutoVendaLucratividadeMensalRow>,
            AppFailure
          >(<ResumoProdutoVendaLucratividadeMensalRow>[]),
    );
    loadResumoProdutoVendaLucratividade =
        _MockLoadResumoProdutoVendaLucratividade();
    batchTargetResolver = _MockAgentQueryTargetResolver();
    batchAgentQueriesRepository = _MockAgentQueriesRepository();
    when(
      () => loadResumoProdutoVendaLucratividade(
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
      ),
    ).thenAnswer(
      (_) async =>
          const Success<List<ResumoProdutoVendaLucratividadeRow>, AppFailure>(
            <ResumoProdutoVendaLucratividadeRow>[],
          ),
    );
    when(
      () => loadResumoParcelasMensalAcrossAgents(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        selectedAgentIds: any(named: 'selectedAgentIds'),
        strategy: any(named: 'strategy'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        raceMaxSources: any(named: 'raceMaxSources'),
      ),
    ).thenAnswer(
      (_) async =>
          Success<
            AgentQueryExecutionReport<ResumoParcelasMensalRow>,
            AppFailure
          >(_emptyMensalReport()),
    );
    when(
      () => loadResumoParcelasDiaSemanaAcrossAgents(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        selectedAgentIds: any(named: 'selectedAgentIds'),
        strategy: any(named: 'strategy'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        raceMaxSources: any(named: 'raceMaxSources'),
      ),
    ).thenAnswer(
      (_) async =>
          Success<
            AgentQueryExecutionReport<ResumoParcelasDiaSemanaRow>,
            AppFailure
          >(_emptyWeekdayReport()),
    );
    when(
      () => loadResumoParcelasDiaSemanaUsuarioAcrossAgents(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        selectedAgentIds: any(named: 'selectedAgentIds'),
        strategy: any(named: 'strategy'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        raceMaxSources: any(named: 'raceMaxSources'),
      ),
    ).thenAnswer(
      (_) async =>
          Success<
            AgentQueryExecutionReport<ResumoParcelasDiaSemanaUsuarioRow>,
            AppFailure
          >(_emptyWeekdayUsuarioReport()),
    );
    when(
      () => loadResumoTotalDiarioVendasAcrossAgents(
        userId: any(named: 'userId'),
        filter: any(named: 'filter'),
        selectedAgentIds: any(named: 'selectedAgentIds'),
        strategy: any(named: 'strategy'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        raceMaxSources: any(named: 'raceMaxSources'),
      ),
    ).thenAnswer(
      (_) async =>
          Success<
            AgentQueryExecutionReport<ResumoTotalDiarioVendasRow>,
            AppFailure
          >(_emptyDailyReport()),
    );

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

  OverviewRepositoryImpl makeRepository({
    bool useBatchOverviewLoading = false,
  }) {
    return OverviewRepositoryImpl(
      localDataSource: local,
      resumoAcrossAgentsRepository: resumoAcrossAgentsRepository,
      loadResumoParcelasMensalAcrossAgents:
          loadResumoParcelasMensalAcrossAgents,
      loadResumoParcelasDiaSemanaAcrossAgents:
          loadResumoParcelasDiaSemanaAcrossAgents,
      loadResumoParcelasDiaSemanaUsuarioAcrossAgents:
          loadResumoParcelasDiaSemanaUsuarioAcrossAgents,
      loadResumoTotalDiarioVendasAcrossAgents:
          loadResumoTotalDiarioVendasAcrossAgents,
      loadResumoProdutoVendaLucratividadeMensal:
          loadResumoProdutoVendaLucratividadeMensal,
      loadResumoProdutoVendaLucratividade: loadResumoProdutoVendaLucratividade,
      batchLoader: OverviewBatchLoader(
        targetResolver: batchTargetResolver,
        planBuilder: const AgentQueryPlanBuilder(),
        agentQueriesRepository: batchAgentQueriesRepository,
      ),
      useBatchOverviewLoading: useBatchOverviewLoading,
      now: () => fixedNow,
    );
  }

  group('OverviewRepositoryImpl', () {
    test('batch load resolves targets once and emits final snapshot', () async {
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
          AgentSqlBatchExecutionResult(
            totalCommands: 7,
            successfulCommands: 7,
            failedCommands: 0,
            items: List<AgentSqlBatchExecutionItem>.generate(
              7,
              (index) => AgentSqlBatchExecutionItem(
                index: index,
                ok: true,
                rows: const <Map<String, dynamic>>[],
                rowCount: 0,
              ),
            ),
          ),
        ),
      );

      final repository = makeRepository(useBatchOverviewLoading: true);
      final snapshots = await repository
          .loadOverviewProgressively(
            userId: 'user-1',
            filter: const OverviewFilter(
              selectedAgentIds: <String>{'agent-1'},
            ),
          )
          .toList();

      check(snapshots.length).equals(1);
      final snapshot = snapshots.single.getOrThrow();
      check(snapshot.isFinal).isTrue();
      check(snapshot.pendingSections).isEmpty();
      check(snapshot.completedSections.length).equals(10);

      verify(
        () => batchTargetResolver.resolve(
          userId: 'user-1',
          selectedAgentIds: const <String>{'agent-1'},
        ),
      ).called(1);
      final capturedRequest =
          verify(
                () => batchAgentQueriesRepository.executeSqlBatch(captureAny()),
              ).captured.single
              as AgentSqlExecuteBatchRequest;
      check(capturedRequest.agentId).equals('agent-1');
      check(capturedRequest.clientToken).equals('token-1');
      check(capturedRequest.commands.length).equals(7);
      check(capturedRequest.useRelay).isFalse();
    });

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
        ).thenAnswer(
          (_) async => Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(
              commandCount: 7,
              rowsByIndex: <int, List<Map<String, dynamic>>>{
                0: <Map<String, dynamic>>[_mainBatchRow()],
              },
              failedIndexes: const <int>{1},
            ),
          ),
        );

        final repository = makeRepository(useBatchOverviewLoading: true);
        final result = await repository.loadOverview(
          userId: 'user-1',
          filter: const OverviewFilter(
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
            _batchResult(commandCount: 7, failedIndexes: const <int>{0}),
          ),
        );

        final repository = makeRepository(useBatchOverviewLoading: true);
        final snapshots = await repository
            .loadOverviewProgressively(
              userId: 'user-1',
              filter: const OverviewFilter(
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
        ).thenAnswer(
          (_) async => Success<AgentSqlBatchExecutionResult, AppFailure>(
            _batchResult(
              commandCount: 6,
              rowsByIndex: <int, List<Map<String, dynamic>>>{
                0: <Map<String, dynamic>>[_mainBatchRow()],
              },
            ),
          ),
        );

        final repository = makeRepository(useBatchOverviewLoading: true);
        final result = await repository.loadOverview(
          userId: 'user-1',
          filter: const OverviewFilter(
            selectedAgentIds: <String>{'agent-1', 'agent-2'},
          ),
        );

        check(result.isSuccess()).isTrue();
        final captured = verify(
          () => batchAgentQueriesRepository.executeSqlBatch(captureAny()),
        ).captured;
        check(captured.length).equals(2);
        for (final raw in captured) {
          final request = raw as AgentSqlExecuteBatchRequest;
          check(request.commands.length).equals(6);
        }
      },
    );

    test('returns ValidationFailure when no approved agents exist', () async {
      _stubLoad(
        resumoAcrossAgentsRepository,
        const Failure<
          AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
          AppFailure
        >(
          ValidationFailure(
            message: 'No approved agents available for agent query',
            context: <String, Object?>{
              'reason': 'no_approved_agents',
            },
          ),
        ),
      );

      final repository = makeRepository();
      final result = await repository.loadOverview(userId: 'user-1');

      check(result.isError()).isTrue();
      final failure = result.exceptionOrNull()!;
      check(failure).isA<ValidationFailure>();
      check(
        failure.context[OverviewFailureUiKey.field],
      ).equals(OverviewFailureUiKey.noApprovedAgents);
    });

    test(
      'aggregates rows into correct KPIs and persists sorted source ids',
      () async {
        _stubLoad(
          resumoAcrossAgentsRepository,
          Success<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            _report(
              consideredApprovedAgentCount: 1,
              plannedTargets: <AgentQueryTarget>[
                _target('agent-42', name: 'Agente 42'),
              ],
              participants:
                  <
                    AgentQueryExecutionParticipant<
                      ResumoParcelaFormaPagamentoRow
                    >
                  >[
                    _successParticipant(
                      agentId: 'agent-42',
                      displayName: 'Agente 42',
                      rows: <ResumoParcelaFormaPagamentoRow>[
                        _row(
                          userName: 'Caixa 01',
                          code: 'PIX',
                          description: 'Pix',
                          salesCount: 10,
                          amount: 900,
                        ),
                        _row(
                          userName: 'Caixa 01',
                          code: 'CRED',
                          description: 'Credito',
                          salesCount: 5,
                          amount: 600,
                        ),
                        _row(
                          userName: 'Caixa 02',
                          code: 'PIX',
                          description: 'Pix',
                          salesCount: 8,
                          amount: 480,
                        ),
                      ],
                    ),
                  ],
            ),
          ),
        );

        final repository = makeRepository();
        final result = await repository.loadOverview(userId: 'user-1');

        check(result.isSuccess()).isTrue();
        final overview = result.getOrThrow();

        check(overview.kpis.totalSalesCount).equals(23);
        check(overview.kpis.totalAmount).equals(1980);
        check(overview.kpis.paymentMethodCount).equals(2);
        check(overview.paymentMethods.first.code).equals('PIX');
        check(overview.paymentMethods.first.totalSalesCount).equals(18);
        check(overview.paymentMethods.first.totalAmount).equals(1380);
        check(overview.paymentMethods.last.code).equals('CRED');
        check(overview.paymentMethods.last.totalAmount).equals(600);
        check(overview.agentRankings.length).equals(1);
        check(overview.agentRankings.first.agentId).equals('agent-42');
        check(overview.agentRankings.first.totalSalesCount).equals(23);
        check(overview.agentRankings.first.totalAmount).equals(1980);
        check(overview.userRankings.first.userName).equals('Caixa 01');
        check(overview.userRankings.first.totalAmount).equals(1500);

        verify(
          () => loadResumoParcelasMensalAcrossAgents(
            userId: 'user-1',
            filter: any(named: 'filter'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
            strategy: any(named: 'strategy'),
            bridgeTimeoutMs: 300000,
            raceMaxSources: any(named: 'raceMaxSources'),
          ),
        ).called(1);

        final captured =
            verify(
                  () => local.saveOverview(
                    userId: 'user-1',
                    overview: captureAny(named: 'overview'),
                  ),
                ).captured.single
                as OverviewModel;
        check(captured.sourceAgentIds).isNotNull();
        check(captured.sourceAgentIds!.length).equals(1);
        check(captured.sourceAgentIds!.single).equals('agent-42');
      },
    );

    test(
      'progressive stream emits summary before slower chart sections',
      () async {
        final dailyCompleter =
            Completer<
              ResultDart<
                AgentQueryExecutionReport<ResumoTotalDiarioVendasRow>,
                AppFailure
              >
            >();
        when(
          () => loadResumoTotalDiarioVendasAcrossAgents(
            userId: any(named: 'userId'),
            filter: any(named: 'filter'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
            strategy: any(named: 'strategy'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            raceMaxSources: any(named: 'raceMaxSources'),
          ),
        ).thenAnswer((_) => dailyCompleter.future);
        _stubLoad(
          resumoAcrossAgentsRepository,
          Success<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            _report(
              consideredApprovedAgentCount: 1,
              plannedTargets: <AgentQueryTarget>[
                _target('agent-42', name: 'Agente 42'),
              ],
              participants:
                  <
                    AgentQueryExecutionParticipant<
                      ResumoParcelaFormaPagamentoRow
                    >
                  >[
                    _successParticipant(
                      agentId: 'agent-42',
                      displayName: 'Agente 42',
                      rows: <ResumoParcelaFormaPagamentoRow>[
                        _row(
                          userName: 'Caixa 01',
                          code: 'PIX',
                          description: 'Pix',
                          salesCount: 10,
                          amount: 900,
                        ),
                      ],
                    ),
                  ],
            ),
          ),
        );

        final repository = makeRepository();
        final iterator = StreamIterator<AppResult<OverviewProgressiveSnapshot>>(
          repository.loadOverviewProgressively(userId: 'user-1'),
        );

        check(await iterator.moveNext()).isTrue();
        final first = iterator.current.getOrNull()!;
        check(first.isFinal).isFalse();
        check(
          first.completedSections.contains(OverviewProgressiveSection.summary),
        ).isTrue();
        check(
          first.completedSections.contains(
            OverviewProgressiveSection.dailySales,
          ),
        ).isFalse();
        check(first.overview.kpis.totalSalesCount).equals(10);

        dailyCompleter.complete(
          Success<
            AgentQueryExecutionReport<ResumoTotalDiarioVendasRow>,
            AppFailure
          >(_dailyReport()),
        );

        OverviewProgressiveSnapshot? last;
        while (await iterator.moveNext()) {
          last = iterator.current.getOrNull();
        }

        check(last).isNotNull();
        check(last!.isFinal).isTrue();
        check(
          last.completedSections.contains(
            OverviewProgressiveSection.dailySales,
          ),
        ).isTrue();
        check(last.overview.dailySalesTrend).isNotEmpty();
      },
    );

    test(
      'uses singleSource when exactly one agent is selected',
      () async {
        _stubLoad(
          resumoAcrossAgentsRepository,
          Success<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            _report(
              strategy: AgentQueryExecutionStrategy.singleSource,
              consideredApprovedAgentCount: 1,
              plannedTargets: <AgentQueryTarget>[
                _target('agent-42', name: 'Agente 42'),
              ],
              participants:
                  <
                    AgentQueryExecutionParticipant<
                      ResumoParcelaFormaPagamentoRow
                    >
                  >[
                    _successParticipant(
                      agentId: 'agent-42',
                      displayName: 'Agente 42',
                      rows: const <ResumoParcelaFormaPagamentoRow>[],
                    ),
                  ],
            ),
          ),
        );

        final repository = makeRepository();
        await repository.loadOverview(
          userId: 'user-1',
          filter: const OverviewFilter(
            selectedAgentIds: <String>{'agent-42'},
          ),
        );

        final captured = verify(
          () => resumoAcrossAgentsRepository.load(
            userId: 'user-1',
            filter: captureAny(named: 'filter'),
            selectedAgentIds: captureAny(named: 'selectedAgentIds'),
            strategy: captureAny(named: 'strategy'),
          ),
        ).captured;

        final selectedAgentIds = captured[2] as Set<String>;
        check(selectedAgentIds.length).equals(1);
        check(selectedAgentIds.contains('agent-42')).isTrue();
        check(captured[1]).equals(AgentQueryExecutionStrategy.singleSource);
      },
    );

    test(
      'maps weekday chart rows and forwards selected agent and period',
      () async {
        when(
          () => loadResumoParcelasDiaSemanaAcrossAgents(
            userId: any(named: 'userId'),
            filter: any(named: 'filter'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
            strategy: any(named: 'strategy'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            raceMaxSources: any(named: 'raceMaxSources'),
          ),
        ).thenAnswer(
          (_) async =>
              Success<
                AgentQueryExecutionReport<ResumoParcelasDiaSemanaRow>,
                AppFailure
              >(
                _weekdayReport(
                  rows: const <ResumoParcelasDiaSemanaRow>[
                    ResumoParcelasDiaSemanaRow(
                      codEmpresa: 1,
                      codFilial: 1,
                      diaSemanaNumero: 2,
                      diaSemana: 'Segunda-feira',
                      qtdVendas: 3,
                      valorParcela: 120,
                    ),
                    ResumoParcelasDiaSemanaRow(
                      codEmpresa: 1,
                      codFilial: 1,
                      diaSemanaNumero: 4,
                      diaSemana: 'Quarta-feira',
                      qtdVendas: 5,
                      valorParcela: 240,
                    ),
                  ],
                ),
              ),
        );
        _stubLoad(
          resumoAcrossAgentsRepository,
          Success<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            _report(
              strategy: AgentQueryExecutionStrategy.singleSource,
              consideredApprovedAgentCount: 1,
              plannedTargets: <AgentQueryTarget>[
                _target('agent-42', name: 'Agente 42'),
              ],
              participants:
                  <
                    AgentQueryExecutionParticipant<
                      ResumoParcelaFormaPagamentoRow
                    >
                  >[
                    _successParticipant(
                      agentId: 'agent-42',
                      displayName: 'Agente 42',
                      rows: <ResumoParcelaFormaPagamentoRow>[
                        _row(
                          userName: 'Caixa',
                          code: 'PIX',
                          description: 'Pix',
                          salesCount: 2,
                          amount: 50,
                        ),
                      ],
                    ),
                  ],
            ),
          ),
        );

        final repository = makeRepository();
        final result = await repository.loadOverview(
          userId: 'user-1',
          filter: const OverviewFilter(
            selectedAgentIds: <String>{'agent-42'},
            yearMonth: OverviewYearMonth(year: 2026, month: 3),
          ),
        );

        check(result.isSuccess()).isTrue();
        final overview = result.getOrThrow();
        check(overview.weekdaySalesTrend).length.equals(7);
        final monday = overview.weekdaySalesTrend.firstWhere(
          (point) => point.weekdayNumber == 2,
        );
        final wednesday = overview.weekdaySalesTrend.firstWhere(
          (point) => point.weekdayNumber == 4,
        );
        check(monday.salesCount).equals(3);
        check(monday.salesAmount).equals(120);
        check(wednesday.salesCount).equals(5);
        check(wednesday.salesAmount).equals(240);
        check(
          overview.weekdaySalesTrend
              .firstWhere(
                (point) => point.weekdayNumber == 1,
              )
              .salesCount,
        ).equals(0);

        final captured = verify(
          () => loadResumoParcelasDiaSemanaAcrossAgents(
            userId: 'user-1',
            filter: captureAny(named: 'filter'),
            selectedAgentIds: captureAny(named: 'selectedAgentIds'),
            strategy: captureAny(named: 'strategy'),
            bridgeTimeoutMs: 300000,
            raceMaxSources: any(named: 'raceMaxSources'),
          ),
        ).captured;

        final filter = captured[0] as ResumoParcelasDiaSemanaFilter;
        final strategy = captured[1] as AgentQueryExecutionStrategy;
        final selectedAgentIds = captured[2] as Set<String>;
        check(filter.dataVendaInicio).equals(DateTime(2026, 3));
        check(filter.dataVendaFim.year).equals(2026);
        check(filter.dataVendaFim.month).equals(3);
        check(filter.dataVendaFim.day).equals(31);
        check(selectedAgentIds).deepEquals(<String>{'agent-42'});
        check(strategy).equals(AgentQueryExecutionStrategy.singleSource);

        verify(
          () => loadResumoParcelasDiaSemanaUsuarioAcrossAgents(
            userId: 'user-1',
            filter: any(named: 'filter'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
            strategy: any(named: 'strategy'),
            bridgeTimeoutMs: 300000,
            raceMaxSources: any(named: 'raceMaxSources'),
          ),
        ).called(1);
      },
    );

    test(
      'falls back to cache on transient error during default load',
      () async {
        _stubLoad(
          resumoAcrossAgentsRepository,
          const Failure<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            NetworkFailure(
              message: 'Connection error',
              userMessage: 'Sem conexao com o servidor.',
            ),
          ),
        );
        when(
          () => local.readOverview(userId: any(named: 'userId')),
        ).thenAnswer((_) async => _cachedModel());

        final repository = makeRepository();
        final result = await repository.loadOverview(userId: 'user-1');

        check(result.isSuccess()).isTrue();
        check(result.getOrThrow().kpis.totalSalesCount).equals(50);
      },
    );

    test('falls back to legacy cache with weekday defaults', () async {
      _stubLoad(
        resumoAcrossAgentsRepository,
        const Failure<
          AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
          AppFailure
        >(
          NetworkFailure(
            message: 'Connection error',
            userMessage: 'Sem conexao com o servidor.',
          ),
        ),
      );
      when(
        () => local.readOverview(userId: any(named: 'userId')),
      ).thenAnswer(
        (_) async => OverviewModel.fromJson(<String, dynamic>{
          'periodStart': '2026-03-10T00:00:00.000',
          'periodEnd': '2026-04-08T00:00:00.000',
          'cachedAt': '2026-04-08T10:00:00.000',
          'sourceAgentIds': <String>['agent-42'],
          'kpis': <String, Object?>{
            'totalSalesCount': 50,
            'totalAmount': 4500,
            'averageTicket': 90,
            'paymentMethodCount': 2,
          },
          'paymentMethods': const <Map<String, Object?>>[],
          'agentRankings': const <Map<String, Object?>>[],
          'userRankings': const <Map<String, Object?>>[],
        }),
      );

      final repository = makeRepository();
      final result = await repository.loadOverview(userId: 'user-1');

      check(result.isSuccess()).isTrue();
      final overview = result.getOrThrow();
      check(overview.weekdaySalesTrend).isEmpty();
      check(overview.weekdaySalesTrendLoadFailed).isFalse();
    });

    test(
      'uses failure source agent ids to validate cache fallback signature',
      () async {
        _stubLoad(
          resumoAcrossAgentsRepository,
          const Failure<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            NetworkFailure(
              message: 'Connection error',
              userMessage: 'Sem conexao com o servidor.',
              context: <String, Object?>{
                'sourceAgentIds': <String>['agent-42'],
              },
            ),
          ),
        );
        when(
          () => local.readOverview(userId: any(named: 'userId')),
        ).thenAnswer((_) async => _cachedModel());

        final repository = makeRepository();
        final result = await repository.loadOverview(userId: 'user-1');

        check(result.isSuccess()).isTrue();
        check(result.getOrThrow().isStaleCache).isTrue();
      },
    );

    test(
      'does not use cache when failure source agent ids do not match signature',
      () async {
        _stubLoad(
          resumoAcrossAgentsRepository,
          const Failure<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            NetworkFailure(
              message: 'Connection error',
              userMessage: 'Sem conexao com o servidor.',
              context: <String, Object?>{
                'sourceAgentIds': <String>['agent-x'],
              },
            ),
          ),
        );
        when(
          () => local.readOverview(userId: any(named: 'userId')),
        ).thenAnswer((_) async => _cachedModel());

        final repository = makeRepository();
        final result = await repository.loadOverview(userId: 'user-1');

        check(result.isError()).isTrue();
      },
    );

    test('does not fall back to cache during force refresh', () async {
      _stubLoad(
        resumoAcrossAgentsRepository,
        const Failure<
          AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
          AppFailure
        >(
          NetworkFailure(
            message: 'Connection error',
            userMessage: 'Sem conexao com o servidor.',
          ),
        ),
      );

      final repository = makeRepository();
      final result = await repository.loadOverview(
        userId: 'user-1',
        policy: OverviewLoadPolicy.forceRefresh,
      );

      check(result.isError()).isTrue();
      verifyNever(() => local.readOverview(userId: any(named: 'userId')));
    });

    test(
      'succeeds with partial data when some agent resumo queries fail',
      () async {
        _stubLoad(
          resumoAcrossAgentsRepository,
          Success<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            _report(
              consideredApprovedAgentCount: 2,
              plannedTargets: <AgentQueryTarget>[
                _target('agent-bad', name: 'Agente ruim'),
                _target('agent-good', name: 'Agente bom'),
              ],
              participants:
                  <
                    AgentQueryExecutionParticipant<
                      ResumoParcelaFormaPagamentoRow
                    >
                  >[
                    _failureParticipant(
                      agentId: 'agent-bad',
                      displayName: 'Agente ruim',
                      failure: const RpcFailure(
                        message: 'SQL validation failed',
                        userMessage: 'The query is invalid.',
                        rpcCode: -32101,
                        retryable: false,
                      ),
                    ),
                    _successParticipant(
                      agentId: 'agent-good',
                      displayName: 'Agente bom',
                      rows: <ResumoParcelaFormaPagamentoRow>[
                        _row(
                          userName: 'Caixa',
                          code: 'PIX',
                          description: 'Pix',
                          salesCount: 1,
                          amount: 100,
                        ),
                      ],
                    ),
                  ],
            ),
          ),
        );

        final repository = makeRepository();
        final result = await repository.loadOverview(userId: 'user-1');

        check(result.isSuccess()).isTrue();
        final overview = result.getOrThrow();
        check(overview.agentIdsExcludedFromQueryFailure.length).equals(1);
        check(overview.agentIdsExcludedFromQueryFailure.single).equals(
          'agent-bad',
        );
        check(overview.agentNamesExcludedFromQueryFailure.length).equals(1);
        check(overview.agentNamesExcludedFromQueryFailure.single).equals(
          'Agente ruim',
        );
        check(overview.kpis.totalSalesCount).equals(1);
        check(overview.hasPartialAgentQueryFailure).isTrue();
      },
    );

    test(
      'returns guided empty overview when all approved agents lack local token',
      () async {
        _stubLoad(
          resumoAcrossAgentsRepository,
          Success<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            _report(
              consideredApprovedAgentCount: 2,
              missingClientTokenTargets: <AgentQueryTarget>[
                _target('agent-a', name: 'Loja Centro', clientToken: null),
                _target('agent-b', name: 'Loja Norte', clientToken: null),
              ],
            ),
          ),
        );

        final repository = makeRepository();
        final result = await repository.loadOverview(userId: 'user-1');

        check(result.isSuccess()).isTrue();
        final overview = result.getOrThrow();
        check(overview.requiresClientTokenSetup).isTrue();
        check(overview.mainResumoHadPlannedTargets).isFalse();
        check(overview.hasRows).isFalse();
        check(overview.agentNamesMissingClientToken.length).equals(2);
        check(overview.agentNamesMissingClientToken.first).equals(
          'Loja Centro',
        );
        check(overview.agentNamesMissingClientToken.last).equals('Loja Norte');
      },
    );

    test(
      'does not fall back to missing-token cache when runnable agents '
      'return empty SQL but others lack token',
      () async {
        when(
          () => local.readOverview(userId: any(named: 'userId')),
        ).thenAnswer((_) async => _cachedModel());
        _stubLoad(
          resumoAcrossAgentsRepository,
          Success<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            _report(
              consideredApprovedAgentCount: 2,
              plannedTargets: <AgentQueryTarget>[
                _target('agent-online', name: 'Online Loja'),
              ],
              missingClientTokenTargets: <AgentQueryTarget>[
                _target('agent-miss', name: 'Sem token', clientToken: null),
              ],
              participants:
                  <
                    AgentQueryExecutionParticipant<
                      ResumoParcelaFormaPagamentoRow
                    >
                  >[
                    _successParticipant(
                      agentId: 'agent-online',
                      displayName: 'Online Loja',
                      rows: const <ResumoParcelaFormaPagamentoRow>[],
                    ),
                  ],
            ),
          ),
        );

        final repository = makeRepository();
        final result = await repository.loadOverview(userId: 'user-1');

        check(result.isSuccess()).isTrue();
        final overview = result.getOrThrow();
        check(overview.isStaleCache).isFalse();
        check(overview.requiresClientTokenSetup).isFalse();
        check(overview.mainResumoHadPlannedTargets).isTrue();
        check(overview.kpis.totalSalesCount).equals(0);
        check(overview.agentNamesMissingClientToken.single).equals('Sem token');
        verifyNever(
          () => local.readOverview(userId: any(named: 'userId')),
        );
        verify(
          () => local.saveOverview(
            userId: any(named: 'userId'),
            overview: any(named: 'overview'),
          ),
        ).called(1);
      },
    );

    test(
      'falls back to cache when all approved agents lack local token',
      () async {
        _stubLoad(
          resumoAcrossAgentsRepository,
          Success<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            _report(
              consideredApprovedAgentCount: 1,
              missingClientTokenTargets: <AgentQueryTarget>[
                _target(
                  'agent-42',
                  name: 'Agente cacheado',
                  clientToken: null,
                ),
              ],
            ),
          ),
        );
        when(
          () => local.readOverview(userId: any(named: 'userId')),
        ).thenAnswer((_) async => _cachedModel());

        final repository = makeRepository();
        final result = await repository.loadOverview(userId: 'user-1');

        check(result.isSuccess()).isTrue();
        final overview = result.getOrThrow();
        check(overview.isStaleCache).isTrue();
        check(overview.kpis.totalSalesCount).equals(50);
        check(overview.agentNamesMissingClientToken.length).equals(1);
        check(overview.agentNamesMissingClientToken.single).equals(
          'Agente cacheado',
        );
        check(overview.monthlyParcelTrendLoadFailed).isFalse();
        check(overview.monthlyParcelTrend).isNotEmpty();
      },
    );

    test(
      'missing-token cache fallback keeps fresh resumo report diagnostic '
      'metadata from participants',
      () async {
        when(
          () => local.readOverview(userId: any(named: 'userId')),
        ).thenAnswer((_) async => _cachedModel());
        _stubLoad(
          resumoAcrossAgentsRepository,
          Success<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            _report(
              consideredApprovedAgentCount: 1,
              missingClientTokenTargets: <AgentQueryTarget>[
                _target(
                  'agent-42',
                  name: 'Agente cacheado',
                  clientToken: null,
                ),
              ],
              participants:
                  <
                    AgentQueryExecutionParticipant<
                      ResumoParcelaFormaPagamentoRow
                    >
                  >[
                    _failureParticipant(
                      agentId: 'agent-42',
                      displayName: 'Agente cacheado',
                      failure: const ValidationFailure(
                        message: 'rpc rejected',
                        userMessage: 'Consulta indisponível para este agente.',
                      ),
                    ),
                  ],
            ),
          ),
        );

        final repository = makeRepository();
        final result = await repository.loadOverview(userId: 'user-1');

        check(result.isSuccess()).isTrue();
        final overview = result.getOrThrow();
        check(overview.isStaleCache).isTrue();
        check(overview.kpis.totalSalesCount).equals(50);
        check(overview.partialQueryFailureDetails).isNotEmpty();
        check(overview.partialQueryFailureDetails.single.agentId).equals(
          'agent-42',
        );
        check(overview.agentIdsExcludedFromQueryFailure.single).equals(
          'agent-42',
        );
      },
    );

    test(
      'when every lucratividade-by-agent query fails, overview still records '
      'per-agent diagnostics and chart load-failed state',
      () async {
        when(
          () => loadResumoProdutoVendaLucratividade(
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
          ),
        ).thenAnswer(
          (_) async =>
              const Failure<
                List<ResumoProdutoVendaLucratividadeRow>,
                AppFailure
              >(
                RpcFailure(
                  message: 'bridge error',
                  userMessage: 'Não foi possível carregar lucratividade.',
                  rpcCode: -1,
                  retryable: false,
                ),
              ),
        );

        _stubLoad(
          resumoAcrossAgentsRepository,
          Success<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            _report(
              consideredApprovedAgentCount: 1,
              plannedTargets: <AgentQueryTarget>[
                _target('agent-42', name: 'Loja Centro'),
              ],
              participants:
                  <
                    AgentQueryExecutionParticipant<
                      ResumoParcelaFormaPagamentoRow
                    >
                  >[
                    _successParticipant(
                      agentId: 'agent-42',
                      displayName: 'Loja Centro',
                      rows: <ResumoParcelaFormaPagamentoRow>[
                        _row(
                          userName: 'Caixa',
                          code: 'PIX',
                          description: 'Pix',
                          salesCount: 1,
                          amount: 100,
                        ),
                      ],
                    ),
                  ],
            ),
          ),
        );

        final repository = makeRepository();
        final result = await repository.loadOverview(userId: 'user-1');

        check(result.isSuccess()).isTrue();
        final overview = result.getOrThrow();
        check(overview.lucratividadeTrendLoadFailed).isTrue();
        check(overview.lucratividadeTrendLoadFailureMessage).equals(
          'Não foi possível carregar lucratividade.',
        );
        check(overview.hasLucratividadePartialFailure).isTrue();
        check(overview.partialQueryFailureDetails).isNotEmpty();
        check(
          overview.partialQueryFailureDetails.any(
            (d) =>
                d.source == OverviewAgentQueryFailureSource.lucratividadePeriod,
          ),
        ).isTrue();
      },
    );

    test(
      'falls back to cache on force refresh without local client token',
      () async {
        _stubLoad(
          resumoAcrossAgentsRepository,
          Success<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            _report(
              consideredApprovedAgentCount: 1,
              missingClientTokenTargets: <AgentQueryTarget>[
                _target(
                  'agent-42',
                  name: 'Agente cacheado',
                  clientToken: null,
                ),
              ],
            ),
          ),
        );
        when(
          () => local.readOverview(userId: any(named: 'userId')),
        ).thenAnswer((_) async => _cachedModel());

        final repository = makeRepository();
        final result = await repository.loadOverview(
          userId: 'user-1',
          policy: OverviewLoadPolicy.forceRefresh,
        );

        check(result.isSuccess()).isTrue();
        final overview = result.getOrThrow();
        check(overview.isStaleCache).isTrue();
        check(overview.kpis.totalSalesCount).equals(50);
        check(overview.agentNamesMissingClientToken.single).equals(
          'Agente cacheado',
        );
        check(overview.monthlyParcelTrendLoadFailed).isFalse();
        check(overview.monthlyParcelTrend).isNotEmpty();
      },
    );

    test(
      'falls back to cache and propagates monthly query failure flag',
      () async {
        when(
          () => loadResumoParcelasMensalAcrossAgents(
            userId: any(named: 'userId'),
            filter: any(named: 'filter'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
            strategy: any(named: 'strategy'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            raceMaxSources: any(named: 'raceMaxSources'),
          ),
        ).thenAnswer(
          (_) async =>
              const Failure<
                AgentQueryExecutionReport<ResumoParcelasMensalRow>,
                AppFailure
              >(
                RpcFailure(
                  message: 'agent sql timeout',
                  userMessage: 'Timeout.',
                  rpcCode: -1,
                  retryable: false,
                ),
              ),
        );
        _stubLoad(
          resumoAcrossAgentsRepository,
          Success<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            _report(
              consideredApprovedAgentCount: 1,
              missingClientTokenTargets: <AgentQueryTarget>[
                _target(
                  'agent-42',
                  name: 'Agente cacheado',
                  clientToken: null,
                ),
              ],
            ),
          ),
        );
        when(
          () => local.readOverview(userId: any(named: 'userId')),
        ).thenAnswer((_) async => _cachedModel());

        final repository = makeRepository();
        final result = await repository.loadOverview(userId: 'user-1');

        check(result.isSuccess()).isTrue();
        final overview = result.getOrThrow();
        check(overview.monthlyParcelTrendLoadFailed).isTrue();
        check(overview.monthlyParcelTrend).isEmpty();
      },
    );

    test(
      'degrades weekday chart independently when weekday query fails',
      () async {
        when(
          () => loadResumoParcelasDiaSemanaAcrossAgents(
            userId: any(named: 'userId'),
            filter: any(named: 'filter'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
            strategy: any(named: 'strategy'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            raceMaxSources: any(named: 'raceMaxSources'),
          ),
        ).thenAnswer(
          (_) async =>
              const Failure<
                AgentQueryExecutionReport<ResumoParcelasDiaSemanaRow>,
                AppFailure
              >(
                RpcFailure(
                  message: 'weekday sql timeout',
                  userMessage: 'Timeout.',
                  rpcCode: -1,
                  retryable: false,
                ),
              ),
        );
        _stubLoad(
          resumoAcrossAgentsRepository,
          Success<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            _report(
              consideredApprovedAgentCount: 1,
              plannedTargets: <AgentQueryTarget>[
                _target('agent-42', name: 'Agente 42'),
              ],
              participants:
                  <
                    AgentQueryExecutionParticipant<
                      ResumoParcelaFormaPagamentoRow
                    >
                  >[
                    _successParticipant(
                      agentId: 'agent-42',
                      displayName: 'Agente 42',
                      rows: <ResumoParcelaFormaPagamentoRow>[
                        _row(
                          userName: 'Caixa',
                          code: 'PIX',
                          description: 'Pix',
                          salesCount: 1,
                          amount: 100,
                        ),
                      ],
                    ),
                  ],
            ),
          ),
        );

        final repository = makeRepository();
        final result = await repository.loadOverview(userId: 'user-1');

        check(result.isSuccess()).isTrue();
        final overview = result.getOrThrow();
        check(overview.kpis.totalSalesCount).equals(1);
        check(overview.weekdaySalesTrend).isEmpty();
        check(overview.weekdaySalesTrendLoadFailed).isTrue();
        check(overview.monthlyParcelTrendLoadFailed).isFalse();
      },
    );

    test(
      'falls back to cache and propagates weekday query failure flag',
      () async {
        when(
          () => loadResumoParcelasDiaSemanaAcrossAgents(
            userId: any(named: 'userId'),
            filter: any(named: 'filter'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
            strategy: any(named: 'strategy'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            raceMaxSources: any(named: 'raceMaxSources'),
          ),
        ).thenAnswer(
          (_) async =>
              const Failure<
                AgentQueryExecutionReport<ResumoParcelasDiaSemanaRow>,
                AppFailure
              >(
                RpcFailure(
                  message: 'weekday sql timeout',
                  userMessage: 'Timeout.',
                  rpcCode: -1,
                  retryable: false,
                ),
              ),
        );
        _stubLoad(
          resumoAcrossAgentsRepository,
          Success<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            _report(
              consideredApprovedAgentCount: 1,
              missingClientTokenTargets: <AgentQueryTarget>[
                _target(
                  'agent-42',
                  name: 'Agente cacheado',
                  clientToken: null,
                ),
              ],
            ),
          ),
        );
        when(
          () => local.readOverview(userId: any(named: 'userId')),
        ).thenAnswer((_) async => _cachedModel());

        final repository = makeRepository();
        final result = await repository.loadOverview(userId: 'user-1');

        check(result.isSuccess()).isTrue();
        final overview = result.getOrThrow();
        check(overview.weekdaySalesTrendLoadFailed).isTrue();
        check(overview.weekdaySalesTrend).isEmpty();
        check(overview.monthlyParcelTrendLoadFailed).isFalse();
      },
    );

    test(
      'returns empty overview when selected ids match no approved agent',
      () async {
        _stubLoad(
          resumoAcrossAgentsRepository,
          Success<
            AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
            AppFailure
          >(
            _report(),
          ),
        );

        final repository = makeRepository();
        final result = await repository.loadOverview(
          userId: 'user-1',
          filter: const OverviewFilter(
            selectedAgentIds: <String>{'unknown-agent'},
          ),
        );

        check(result.isSuccess()).isTrue();
        final overview = result.getOrThrow();
        check(overview.approvedAgentCount).equals(0);
        check(overview.hasRows).isFalse();
        verifyNever(
          () => local.saveOverview(
            userId: any(named: 'userId'),
            overview: any(named: 'overview'),
          ),
        );
        verifyNever(
          () => loadResumoParcelasDiaSemanaUsuarioAcrossAgents(
            userId: any(named: 'userId'),
            filter: any(named: 'filter'),
            selectedAgentIds: any(named: 'selectedAgentIds'),
            strategy: any(named: 'strategy'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            raceMaxSources: any(named: 'raceMaxSources'),
          ),
        );
      },
    );
  });
}

void _stubLoad(
  ResumoParcelaFormaPagamentoAcrossAgentsRepository repository,
  ResultDart<
    AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>,
    AppFailure
  >
  result,
) {
  when(
    () => repository.load(
      userId: any(named: 'userId'),
      filter: any(named: 'filter'),
      selectedAgentIds: any(named: 'selectedAgentIds'),
      strategy: any(named: 'strategy'),
    ),
  ).thenAnswer((_) async => result);
}

AgentQueryExecutionReport<ResumoParcelasMensalRow> _emptyMensalReport() {
  return const AgentQueryExecutionReport<ResumoParcelasMensalRow>(
    queryKey: AgentQueryKey.resumoParcelasMensal,
    strategy: AgentQueryExecutionStrategy.mergeAll,
    consideredApprovedAgentCount: 0,
    plannedTargets: <AgentQueryTarget>[],
    missingClientTokenTargets: <AgentQueryTarget>[],
    participants: <AgentQueryExecutionParticipant<ResumoParcelasMensalRow>>[],
    totalElapsedMs: 0,
  );
}

AgentQueryExecutionReport<ResumoParcelasDiaSemanaRow> _emptyWeekdayReport() {
  return const AgentQueryExecutionReport<ResumoParcelasDiaSemanaRow>(
    queryKey: AgentQueryKey.resumoParcelasDiaSemana,
    strategy: AgentQueryExecutionStrategy.mergeAll,
    consideredApprovedAgentCount: 0,
    plannedTargets: <AgentQueryTarget>[],
    missingClientTokenTargets: <AgentQueryTarget>[],
    participants:
        <AgentQueryExecutionParticipant<ResumoParcelasDiaSemanaRow>>[],
    totalElapsedMs: 0,
  );
}

AgentQueryExecutionReport<ResumoParcelasDiaSemanaUsuarioRow>
_emptyWeekdayUsuarioReport() {
  return const AgentQueryExecutionReport<ResumoParcelasDiaSemanaUsuarioRow>(
    queryKey: AgentQueryKey.resumoParcelasDiaSemanaUsuario,
    strategy: AgentQueryExecutionStrategy.mergeAll,
    consideredApprovedAgentCount: 0,
    plannedTargets: <AgentQueryTarget>[],
    missingClientTokenTargets: <AgentQueryTarget>[],
    participants:
        <AgentQueryExecutionParticipant<ResumoParcelasDiaSemanaUsuarioRow>>[],
    totalElapsedMs: 0,
  );
}

AgentQueryExecutionReport<ResumoTotalDiarioVendasRow> _emptyDailyReport() {
  return const AgentQueryExecutionReport<ResumoTotalDiarioVendasRow>(
    queryKey: AgentQueryKey.resumoTotalDiarioVendas,
    strategy: AgentQueryExecutionStrategy.mergeAll,
    consideredApprovedAgentCount: 0,
    plannedTargets: <AgentQueryTarget>[],
    missingClientTokenTargets: <AgentQueryTarget>[],
    participants:
        <AgentQueryExecutionParticipant<ResumoTotalDiarioVendasRow>>[],
    totalElapsedMs: 0,
  );
}

AgentQueryExecutionReport<ResumoTotalDiarioVendasRow> _dailyReport() {
  return AgentQueryExecutionReport<ResumoTotalDiarioVendasRow>(
    queryKey: AgentQueryKey.resumoTotalDiarioVendas,
    strategy: AgentQueryExecutionStrategy.mergeAll,
    consideredApprovedAgentCount: 1,
    plannedTargets: <AgentQueryTarget>[
      _target('agent-42', name: 'Agente 42'),
    ],
    missingClientTokenTargets: const <AgentQueryTarget>[],
    participants: <AgentQueryExecutionParticipant<ResumoTotalDiarioVendasRow>>[
      AgentQueryExecutionParticipant<ResumoTotalDiarioVendasRow>(
        agentId: 'agent-42',
        displayName: 'Agente 42',
        rows: <ResumoTotalDiarioVendasRow>[
          ResumoTotalDiarioVendasRow(
            codEmpresa: 1,
            codFilial: 1,
            dataVenda: DateTime(2026, 3, 15),
            qtdVendas: 2,
            valorTotalDiarioVenda: 200,
          ),
        ],
        elapsedMs: 5,
      ),
    ],
    totalElapsedMs: 10,
  );
}

AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow> _report({
  AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
  int consideredApprovedAgentCount = 0,
  List<AgentQueryTarget> plannedTargets = const <AgentQueryTarget>[],
  List<AgentQueryTarget> missingClientTokenTargets = const <AgentQueryTarget>[],
  List<AgentQueryExecutionParticipant<ResumoParcelaFormaPagamentoRow>>
      participants =
      const <AgentQueryExecutionParticipant<ResumoParcelaFormaPagamentoRow>>[],
}) {
  return AgentQueryExecutionReport<ResumoParcelaFormaPagamentoRow>(
    queryKey: AgentQueryKey.resumoParcelaFormaPagamento,
    strategy: strategy,
    consideredApprovedAgentCount: consideredApprovedAgentCount,
    plannedTargets: plannedTargets,
    missingClientTokenTargets: missingClientTokenTargets,
    participants: participants,
    totalElapsedMs: 10,
  );
}

AgentQueryExecutionReport<ResumoParcelasDiaSemanaRow> _weekdayReport({
  AgentQueryExecutionStrategy strategy = AgentQueryExecutionStrategy.mergeAll,
  int consideredApprovedAgentCount = 1,
  List<AgentQueryTarget> plannedTargets = const <AgentQueryTarget>[],
  List<AgentQueryExecutionParticipant<ResumoParcelasDiaSemanaRow>>
      participants =
      const <AgentQueryExecutionParticipant<ResumoParcelasDiaSemanaRow>>[],
  List<ResumoParcelasDiaSemanaRow> rows = const <ResumoParcelasDiaSemanaRow>[],
}) {
  return AgentQueryExecutionReport<ResumoParcelasDiaSemanaRow>(
    queryKey: AgentQueryKey.resumoParcelasDiaSemana,
    strategy: strategy,
    consideredApprovedAgentCount: consideredApprovedAgentCount,
    plannedTargets: plannedTargets,
    missingClientTokenTargets: const <AgentQueryTarget>[],
    participants: participants.isNotEmpty
        ? participants
        : <AgentQueryExecutionParticipant<ResumoParcelasDiaSemanaRow>>[
            AgentQueryExecutionParticipant<ResumoParcelasDiaSemanaRow>(
              agentId: 'agent-42',
              displayName: 'Agente 42',
              rows: rows,
              elapsedMs: 5,
            ),
          ],
    totalElapsedMs: 10,
  );
}

AgentQueryTarget _target(
  String agentId, {
  required String name,
  String? clientToken = 'client-token',
}) {
  return AgentQueryTarget(
    agentId: agentId,
    displayName: name,
    connectionStatus: AgentConnectionStatus.online,
    clientToken: clientToken,
  );
}

AgentQueryExecutionParticipant<ResumoParcelaFormaPagamentoRow>
_successParticipant({
  required String agentId,
  required String displayName,
  required List<ResumoParcelaFormaPagamentoRow> rows,
}) {
  return AgentQueryExecutionParticipant<ResumoParcelaFormaPagamentoRow>(
    agentId: agentId,
    displayName: displayName,
    rows: rows,
    elapsedMs: 5,
  );
}

AgentQueryExecutionParticipant<ResumoParcelaFormaPagamentoRow>
_failureParticipant({
  required String agentId,
  required String displayName,
  required AppFailure failure,
}) {
  return AgentQueryExecutionParticipant<ResumoParcelaFormaPagamentoRow>(
    agentId: agentId,
    displayName: displayName,
    rows: const <ResumoParcelaFormaPagamentoRow>[],
    failure: failure,
    elapsedMs: 5,
  );
}

ResumoParcelaFormaPagamentoRow _row({
  required String userName,
  required String code,
  required String description,
  required int salesCount,
  required double amount,
}) {
  return ResumoParcelaFormaPagamentoRow(
    codEmpresa: 1,
    codFilial: 1,
    nomeUsuario: userName,
    anoDataVenda: 2026,
    mesDataVenda: 4,
    anoMesDataVenda: '2026/04',
    codFormaPagamento: code,
    descricaoFormaPagamento: description,
    qtdVendas: salesCount,
    valorParcela: amount,
  );
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

OverviewModel _cachedModel() {
  return OverviewModel(
    periodStart: DateTime(2026, 3, 10),
    periodEnd: DateTime(2026, 4, 8),
    cachedAt: DateTime(2026, 4, 8, 10),
    sourceAgentIds: const <String>['agent-42'],
    kpis: const OverviewPaymentKpis(
      totalSalesCount: 50,
      totalAmount: 4500,
      averageTicket: 90,
      paymentMethodCount: 2,
    ),
    paymentMethods: const <OverviewPaymentMethodBreakdown>[
      OverviewPaymentMethodBreakdown(
        code: 'PIX',
        label: 'Pix',
        totalSalesCount: 30,
        totalAmount: 2700,
        averageTicket: 90,
        sharePercent: 60,
      ),
      OverviewPaymentMethodBreakdown(
        code: 'CRED',
        label: 'Credito',
        totalSalesCount: 20,
        totalAmount: 1800,
        averageTicket: 90,
        sharePercent: 40,
      ),
    ],
    agentRankings: const [],
    userRankings: const [],
    weekdaySalesTrend: const <OverviewWeekdaySalesTrendPoint>[
      OverviewWeekdaySalesTrendPoint(
        weekdayNumber: 1,
        salesCount: 9,
        salesAmount: 810,
      ),
    ],
  );
}
