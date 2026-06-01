import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_lucratividade_mensal_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/sales/application/load_sales_monthly_pnl_lines_use_case.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockLoadResumoProdutoVendaLucratividadeMensalUseCase extends Mock
    implements LoadResumoProdutoVendaLucratividadeMensalUseCase {}

void main() {
  late _MockLoadResumoProdutoVendaLucratividadeMensalUseCase dependency;
  late LoadSalesMonthlyPnlLinesUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      ResumoProdutoVendaLucratividadeMensalFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );
  });

  setUp(() {
    dependency = _MockLoadResumoProdutoVendaLucratividadeMensalUseCase();
    useCase = LoadSalesMonthlyPnlLinesUseCase(dependency);
  });

  test(
    'aggregates repeated months and fills missing months with zero',
    () async {
      when(
        () => dependency(
          userId: 'user-1',
          agentId: 'agent-1',
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
            const Success<
              List<ResumoProdutoVendaLucratividadeMensalRow>,
              AppFailure
            >(
              <ResumoProdutoVendaLucratividadeMensalRow>[
                ResumoProdutoVendaLucratividadeMensalRow(
                  codEmpresa: 1,
                  codFilial: 1,
                  ano: 2026,
                  mes: 1,
                  anoMes: '2026/01',
                  qtdVendas: 10,
                  qtdItensVendido: 10,
                  valorTotalCustoMedio: 0,
                  custoReposicao: 40,
                  pontoEquilibrio: 0,
                  valorTotalItem: 100,
                ),
                ResumoProdutoVendaLucratividadeMensalRow(
                  codEmpresa: 1,
                  codFilial: 2,
                  ano: 2026,
                  mes: 1,
                  anoMes: '2026/01',
                  qtdVendas: 8,
                  qtdItensVendido: 8,
                  valorTotalCustoMedio: 0,
                  custoReposicao: 30,
                  pontoEquilibrio: 0,
                  valorTotalItem: 70,
                ),
                ResumoProdutoVendaLucratividadeMensalRow(
                  codEmpresa: 1,
                  codFilial: 1,
                  ano: 2026,
                  mes: 3,
                  anoMes: '2026/03',
                  qtdVendas: 12,
                  qtdItensVendido: 12,
                  valorTotalCustoMedio: 0,
                  custoReposicao: 90,
                  pontoEquilibrio: 0,
                  valorTotalItem: 150,
                ),
              ],
            ),
      );

      final result = await useCase(
        userId: 'user-1',
        agentId: 'agent-1',
        anchor: const DashboardYearMonth(year: 2026, month: 3),
        clientToken: 'token-1',
      );

      verify(
        () => dependency(
          userId: 'user-1',
          agentId: 'agent-1',
          filter: any(named: 'filter'),
          clientToken: 'token-1',
          bridgeTimeoutMs: LoadSalesMonthlyPnlLinesUseCase.bridgeTimeoutMs,
          hubPresenceOnlineAgentIdsSnapshot: any(
            named: 'hubPresenceOnlineAgentIdsSnapshot',
          ),
          hubConnectedFromApprovedCatalogRow: any(
            named: 'hubConnectedFromApprovedCatalogRow',
          ),
        ),
      ).called(1);

      check(result.loadFailed).isFalse();
      check(result.points.length).equals(12);
      check(result.points.first.anoMes).equals('2025/04');
      check(result.points.last.anoMes).equals('2026/03');

      final jan = result.points.singleWhere(
        (point) => point.anoMes == '2026/01',
      );
      check(jan.venda).equals(170);
      check(jan.custoMercadoria).equals(70);
      check(jan.lucro).equals(100);

      final feb = result.points.singleWhere(
        (point) => point.anoMes == '2026/02',
      );
      check(feb.venda).equals(0);
      check(feb.custoMercadoria).equals(0);
      check(feb.lucro).equals(0);

      final mar = result.points.singleWhere(
        (point) => point.anoMes == '2026/03',
      );
      check(mar.venda).equals(150);
      check(mar.custoMercadoria).equals(90);
      check(mar.lucro).equals(60);
    },
  );

  test(
    'returns failure metadata and empty points when dependency fails',
    () async {
      when(
        () => dependency(
          userId: 'user-2',
          agentId: 'agent-2',
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
              List<ResumoProdutoVendaLucratividadeMensalRow>,
              AppFailure
            >(UnknownFailure(message: 'boom', userMessage: 'Falhou')),
      );

      final result = await useCase(
        userId: 'user-2',
        agentId: 'agent-2',
        anchor: const DashboardYearMonth(year: 2026, month: 3),
      );

      check(result.loadFailed).isTrue();
      check(result.loadFailure?.userMessage).equals('Falhou');
      check(result.points).isEmpty();
    },
  );
}
