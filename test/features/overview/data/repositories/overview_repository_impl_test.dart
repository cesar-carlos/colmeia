import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_parcelas_mensal_across_agents_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_forma_pagamento_across_agents_repository.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/overview/data/datasources/overview_local_datasource.dart';
import 'package:colmeia/features/overview/data/models/overview_model.dart';
import 'package:colmeia/features/overview/data/repositories/overview_repository_impl.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
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

void main() {
  late _MockOverviewLocalDataSource local;
  late _MockResumoAcrossAgentsRepository resumoAcrossAgentsRepository;
  late _MockLoadResumoParcelasMensalAcrossAgents
      loadResumoParcelasMensalAcrossAgents;

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
      ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime(2025, 5),
        dataVendaFim: DateTime(2026, 4, 30),
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
    resumoAcrossAgentsRepository = _MockResumoAcrossAgentsRepository();
    loadResumoParcelasMensalAcrossAgents =
        _MockLoadResumoParcelasMensalAcrossAgents();
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
      (_) async => Success<
        AgentQueryExecutionReport<ResumoParcelasMensalRow>,
        AppFailure
      >(_emptyMensalReport()),
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

  OverviewRepositoryImpl makeRepository() {
    return OverviewRepositoryImpl(
      localDataSource: local,
      resumoAcrossAgentsRepository: resumoAcrossAgentsRepository,
      loadResumoParcelasMensalAcrossAgents:
          loadResumoParcelasMensalAcrossAgents,
      now: () => fixedNow,
    );
  }

  group('OverviewRepositoryImpl', () {
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
        check(overview.hasRows).isFalse();
        check(overview.agentNamesMissingClientToken.length).equals(2);
        check(overview.agentNamesMissingClientToken.first).equals(
          'Loja Centro',
        );
        check(overview.agentNamesMissingClientToken.last).equals('Loja Norte');
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
          (_) async => const Failure<
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
  );
}
