import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_produto_venda_page_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_top_products_per_agent_section.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:result_dart/result_dart.dart';

class _MockLoadResumo extends Mock implements LoadResumoProdutoVendaPageUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      ResumoProdutoVendaFilter(
        dataVendaInicio: DateTime(2026),
        dataVendaFim: DateTime(2026, 1, 31),
      ),
    );
  });

  Overview minimalOverview() {
    return Overview(
      periodStart: DateTime(2026),
      periodEnd: DateTime(2026, 1, 31),
      kpis: const OverviewPaymentKpis(
        totalSalesCount: 0,
        totalAmount: 0,
        averageTicket: 0,
        paymentMethodCount: 0,
      ),
      paymentMethods: const [],
      agentRankings: const [],
      userRankings: const [],
    );
  }

  testWidgets('shows message when no agents have a client token', (
    tester,
  ) async {
    final mock = _MockLoadResumo();

    await tester.pumpWidget(
      _TestApp(
        mock: mock,
        child: Builder(
          builder: (context) {
            return OverviewTopProductsPerAgentSection(
              userId: 'u1',
              overview: minimalOverview(),
              filter: OverviewFilter.initial(),
              availableAgents: const <OverviewAgentOption>[
                OverviewAgentOption(
                  agentId: 'a1',
                  name: 'Agent One',
                  missingLocalClientToken: true,
                ),
              ],
              l10n: AppLocalizations.of(context),
            );
          },
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text(
        'No agents available for this chart. Save a client token on the '
        'agent or adjust the filter.',
      ),
      findsOneWidget,
    );
    verifyNever(() => mock.call(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          filter: any(named: 'filter'),
        ));
  });

  testWidgets('loads once per agent and caches when switching tabs back', (
    tester,
  ) async {
    final mock = _MockLoadResumo();
    when(
      () => mock.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
      ),
    ).thenAnswer(
      (_) async => const Success<ResumoProdutoVendaPageResult, AppFailure>(
        ResumoProdutoVendaPageResult(
          items: <ResumoProdutoVendaRow>[
            ResumoProdutoVendaRow(
              codEmpresa: 1,
              codFilial: 1,
              codProduto: 10,
              nomeProduto: 'Prod',
              qtdVendas: 5,
              qtdItensVendido: 5,
              valorTotalCustoMedio: 1,
              custoReposicao: 2,
              pontoEquilibrio: 0,
              valorTotalItem: 10,
              percentualLucro: 20,
            ),
          ],
          totalCount: 1,
        ),
      ),
    );

    await tester.pumpWidget(
      _TestApp(
        mock: mock,
        child: Builder(
          builder: (context) {
            return OverviewTopProductsPerAgentSection(
              userId: 'u1',
              overview: minimalOverview(),
              filter: OverviewFilter.initial(),
              availableAgents: const <OverviewAgentOption>[
                OverviewAgentOption(agentId: 'a1', name: 'Zed'),
                OverviewAgentOption(agentId: 'a2', name: 'Amy'),
              ],
              l10n: AppLocalizations.of(context),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Zed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Amy'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    verify(
      () => mock.call(
        userId: 'u1',
        agentId: 'a2',
        filter: any(named: 'filter'),
      ),
    ).called(1);
    verify(
      () => mock.call(
        userId: 'u1',
        agentId: 'a1',
        filter: any(named: 'filter'),
      ),
    ).called(1);
    verifyNoMoreInteractions(mock);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp({required this.mock, required this.child});

  final LoadResumoProdutoVendaPageUseCase mock;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Provider<LoadResumoProdutoVendaPageUseCase>.value(
      value: mock,
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }
}
