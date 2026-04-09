import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_produto_vendido_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_produto_vendido_forma_pagamento_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcela_produto_vendido_forma_pagamento_repository.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/dashboards/data/datasources/dashboard_local_datasource.dart';
import 'package:colmeia/features/dashboards/data/models/dashboard_overview_model.dart';
import 'package:colmeia/features/dashboards/data/repositories/dashboard_repository_impl.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_kpis.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_method_breakdown.dart';
import 'package:colmeia/features/dashboards/domain/repositories/dashboard_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockDashboardLocalDataSource extends Mock
    implements DashboardLocalDataSource {}

class _MockClientAgentsRepository extends Mock
    implements ClientAgentsRepository {}

class _MockResumoRepository extends Mock
    implements ResumoParcelaProdutoVendidoFormaPagamentoRepository {}

void main() {
  late _MockDashboardLocalDataSource local;
  late _MockClientAgentsRepository agents;
  late _MockResumoRepository resumo;

  final fixedNow = DateTime(2026, 4, 8);

  setUpAll(() {
    registerFallbackValue(const PaginatedQuery(pageSize: 1));
    registerFallbackValue(
      ResumoParcelaProdutoVendidoFormaPagamentoFilter(
        dataVendaInicio: DateTime(2026, 3, 10),
        dataVendaFim: DateTime(2026, 4, 8),
      ),
    );
    registerFallbackValue(
      DashboardOverviewModel(
        periodStart: DateTime(2026),
        periodEnd: DateTime(2026),
        kpis: const DashboardPaymentKpis(
          totalSalesCount: 0,
          totalAmount: 0,
          averageTicket: 0,
          paymentMethodCount: 0,
        ),
        paymentMethods: const <DashboardPaymentMethodBreakdown>[],
        filialRankings: const [],
        userRankings: const [],
      ),
    );
  });

  setUp(() {
    local = _MockDashboardLocalDataSource();
    agents = _MockClientAgentsRepository();
    resumo = _MockResumoRepository();

    when(
      () => local.saveOverview(
        userId: any(named: 'userId'),
        overview: any(named: 'overview'),
      ),
    ).thenAnswer((_) async {});
  });

  DashboardRepositoryImpl makeRepository() {
    return DashboardRepositoryImpl(
      localDataSource: local,
      clientAgentsRepository: agents,
      resumoRepository: resumo,
      now: () => fixedNow,
    );
  }

  group('DashboardRepositoryImpl', () {
    test('returns ValidationFailure when no approved agents exist', () async {
      when(
        () => agents.loadApprovedAgents(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          search: any(named: 'search'),
          status: any(named: 'status'),
        ),
      ).thenAnswer(
        (_) async => const Success<PaginatedResult<ClientAgent>, AppFailure>(
          PaginatedResult<ClientAgent>(
            items: <ClientAgent>[],
            count: 0,
            total: 0,
            page: 1,
            pageSize: 1,
          ),
        ),
      );

      final repository = makeRepository();
      final result = await repository.loadOverview(userId: 'user-1');

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()).isA<ValidationFailure>();
    });

    test(
      'aggregates rows into correct KPIs and sorted payment methods',
      () async {
        when(
          () => agents.loadApprovedAgents(
            userId: any(named: 'userId'),
            query: any(named: 'query'),
            search: any(named: 'search'),
            status: any(named: 'status'),
          ),
        ).thenAnswer(
          (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
            PaginatedResult<ClientAgent>(
              items: <ClientAgent>[_agent('agent-42')],
              count: 1,
              total: 1,
              page: 1,
              pageSize: 1,
            ),
          ),
        );

        when(
          () => resumo.load(
            agentId: any(named: 'agentId'),
            filter: any(named: 'filter'),
            clientToken: any(named: 'clientToken'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          ),
        ).thenAnswer(
          (_) async =>
              const Success<List<ResumoParcelaProdutoVendidoFormaPagamentoRow>,
                  AppFailure>(
            <ResumoParcelaProdutoVendidoFormaPagamentoRow>[
              ResumoParcelaProdutoVendidoFormaPagamentoRow(
                codEmpresa: 1,
                codFilial: 1,
                nomeUsuario: 'Caixa 01',
                codFormaPagamento: 'PIX',
                descricaoFormaPagamento: 'Pix',
                qtdVendas: 10,
                valorParcela: 900,
              ),
              ResumoParcelaProdutoVendidoFormaPagamentoRow(
                codEmpresa: 1,
                codFilial: 1,
                nomeUsuario: 'Caixa 01',
                codFormaPagamento: 'CRED',
                descricaoFormaPagamento: 'Credito',
                qtdVendas: 5,
                valorParcela: 600,
              ),
              ResumoParcelaProdutoVendidoFormaPagamentoRow(
                codEmpresa: 1,
                codFilial: 2,
                nomeUsuario: 'Caixa 02',
                codFormaPagamento: 'PIX',
                descricaoFormaPagamento: 'Pix',
                qtdVendas: 8,
                valorParcela: 480,
              ),
            ],
          ),
        );

        final repository = makeRepository();
        final result = await repository.loadOverview(userId: 'user-1');

        check(result.isSuccess()).isTrue();
        final overview = result.getOrThrow();

        final kpis = overview.kpis;
        check(kpis.totalSalesCount).equals(23);
        check(kpis.totalAmount).equals(1980);
        check(kpis.paymentMethodCount).equals(2);

        final methods = overview.paymentMethods;
        check(methods).length.equals(2);
        check(methods.first.code).equals('PIX');
        check(methods.first.totalSalesCount).equals(18);
        check(methods.first.totalAmount).equals(1380);
        check(methods.last.code).equals('CRED');
        check(methods.last.totalAmount).equals(600);

        final filiais = overview.filialRankings;
        check(filiais.first.codFilial).equals(1);
        check(filiais.first.totalAmount).equals(1500);

        final users = overview.userRankings;
        check(users.first.userName).equals('Caixa 01');
        check(users.first.totalAmount).equals(1500);
      },
    );

    test(
      'falls back to cache on transient error during default load',
      () async {
        when(
          () => agents.loadApprovedAgents(
            userId: any(named: 'userId'),
            query: any(named: 'query'),
            search: any(named: 'search'),
            status: any(named: 'status'),
          ),
        ).thenAnswer(
          (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
            PaginatedResult<ClientAgent>(
              items: <ClientAgent>[_agent('agent-42')],
              count: 1,
              total: 1,
              page: 1,
              pageSize: 1,
            ),
          ),
        );

        when(
          () => resumo.load(
            agentId: any(named: 'agentId'),
            filter: any(named: 'filter'),
            clientToken: any(named: 'clientToken'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          ),
        ).thenAnswer(
          (_) async =>
              const Failure<
                  List<ResumoParcelaProdutoVendidoFormaPagamentoRow>,
                  AppFailure>(
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
        final overview = result.getOrThrow();
        check(overview.kpis.totalSalesCount).equals(50);
      },
    );

    test(
      'does not fall back to cache during force refresh',
      () async {
        when(
          () => agents.loadApprovedAgents(
            userId: any(named: 'userId'),
            query: any(named: 'query'),
            search: any(named: 'search'),
            status: any(named: 'status'),
          ),
        ).thenAnswer(
          (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
            PaginatedResult<ClientAgent>(
              items: <ClientAgent>[_agent('agent-42')],
              count: 1,
              total: 1,
              page: 1,
              pageSize: 1,
            ),
          ),
        );

        when(
          () => resumo.load(
            agentId: any(named: 'agentId'),
            filter: any(named: 'filter'),
            clientToken: any(named: 'clientToken'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          ),
        ).thenAnswer(
          (_) async =>
              const Failure<
                  List<ResumoParcelaProdutoVendidoFormaPagamentoRow>,
                  AppFailure>(
            NetworkFailure(
              message: 'Connection error',
              userMessage: 'Sem conexao com o servidor.',
            ),
          ),
        );

        final repository = makeRepository();
        final result = await repository.loadOverview(
          userId: 'user-1',
          policy: DashboardLoadPolicy.forceRefresh,
        );

        check(result.isError()).isTrue();
        verifyNever(
          () => local.readOverview(userId: any(named: 'userId')),
        );
      },
    );

    test(
      'average ticket is computed correctly from aggregated rows',
      () async {
        when(
          () => agents.loadApprovedAgents(
            userId: any(named: 'userId'),
            query: any(named: 'query'),
            search: any(named: 'search'),
            status: any(named: 'status'),
          ),
        ).thenAnswer(
          (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
            PaginatedResult<ClientAgent>(
              items: <ClientAgent>[_agent('agent-1')],
              count: 1,
              total: 1,
              page: 1,
              pageSize: 1,
            ),
          ),
        );

        when(
          () => resumo.load(
            agentId: any(named: 'agentId'),
            filter: any(named: 'filter'),
            clientToken: any(named: 'clientToken'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          ),
        ).thenAnswer(
          (_) async =>
              const Success<List<ResumoParcelaProdutoVendidoFormaPagamentoRow>,
                  AppFailure>(
            <ResumoParcelaProdutoVendidoFormaPagamentoRow>[
              ResumoParcelaProdutoVendidoFormaPagamentoRow(
                codEmpresa: 1,
                codFilial: 1,
                nomeUsuario: 'Caixa',
                codFormaPagamento: 'PIX',
                descricaoFormaPagamento: 'Pix',
                qtdVendas: 4,
                valorParcela: 400,
              ),
            ],
          ),
        );

        final repository = makeRepository();
        final result = await repository.loadOverview(userId: 'user-1');

        final kpis = result.getOrThrow().kpis;
        check(kpis.averageTicket).equals(100);

        final methods = result.getOrThrow().paymentMethods;
        check(methods.single).has(
          (m) => m.averageTicket,
          'averageTicket',
        ).equals(100);
      },
    );

    test(
      'share percent sums to 100 for a single payment method',
      () async {
        when(
          () => agents.loadApprovedAgents(
            userId: any(named: 'userId'),
            query: any(named: 'query'),
            search: any(named: 'search'),
            status: any(named: 'status'),
          ),
        ).thenAnswer(
          (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
            PaginatedResult<ClientAgent>(
              items: <ClientAgent>[_agent('agent-1')],
              count: 1,
              total: 1,
              page: 1,
              pageSize: 1,
            ),
          ),
        );

        when(
          () => resumo.load(
            agentId: any(named: 'agentId'),
            filter: any(named: 'filter'),
            clientToken: any(named: 'clientToken'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          ),
        ).thenAnswer(
          (_) async =>
              const Success<List<ResumoParcelaProdutoVendidoFormaPagamentoRow>,
                  AppFailure>(
            <ResumoParcelaProdutoVendidoFormaPagamentoRow>[
              ResumoParcelaProdutoVendidoFormaPagamentoRow(
                codEmpresa: 1,
                codFilial: 1,
                nomeUsuario: 'Caixa',
                codFormaPagamento: 'DIN',
                descricaoFormaPagamento: 'Dinheiro',
                qtdVendas: 20,
                valorParcela: 2000,
              ),
            ],
          ),
        );

        final repository = makeRepository();
        final result = await repository.loadOverview(userId: 'user-1');

        final method = result.getOrThrow().paymentMethods.single;
        check(method.sharePercent).equals(100);
      },
    );
  });
}

ClientAgent _agent(String id) {
  return ClientAgent(
    agentId: id,
    name: 'Agente Teste',
    catalogStatus: AgentCatalogStatus.active,
    connectionStatus: AgentConnectionStatus.online,
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );
}

DashboardOverviewModel _cachedModel() {
  return DashboardOverviewModel(
    periodStart: DateTime(2026, 3, 9),
    periodEnd: DateTime(2026, 4, 7),
    kpis: const DashboardPaymentKpis(
      totalSalesCount: 50,
      totalAmount: 4500,
      averageTicket: 90,
      paymentMethodCount: 2,
    ),
    paymentMethods: const <DashboardPaymentMethodBreakdown>[
      DashboardPaymentMethodBreakdown(
        code: 'PIX',
        label: 'Pix',
        totalSalesCount: 30,
        totalAmount: 2700,
        averageTicket: 90,
        sharePercent: 60,
      ),
      DashboardPaymentMethodBreakdown(
        code: 'CRED',
        label: 'Credito',
        totalSalesCount: 20,
        totalAmount: 1800,
        averageTicket: 90,
        sharePercent: 40,
      ),
    ],
    filialRankings: const [],
    userRankings: const [],
  );
}
