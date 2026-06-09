import 'dart:async';

import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/refresh/auto_refresh_snapshot.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_grupo_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_marca_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_screen_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/marca_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_screen_data.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_hub_page.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_produto_tendencia_page.dart';
import 'package:colmeia/features/sales/presentation/routes/sales_routes.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:result_dart/result_dart.dart';

class _MockAuthController extends Mock implements AuthController {}

class _MockSalesPreferences extends Mock implements SalesPreferences {}

class _MockAgentClientTokenReader extends Mock
    implements AgentClientTokenReader {}

class _MockLoadAvailableAgentsForSales extends Mock
    implements LoadAvailableAgentsForSales {}

class _MockLoadProdutoVendidoTendenciaDeVendaScreenUseCase extends Mock
    implements LoadProdutoVendidoTendenciaDeVendaScreenUseCase {}

class _MockLoadProdutoVendidoTendenciaDeVendaUseCase extends Mock
    implements LoadProdutoVendidoTendenciaDeVendaUseCase {}

class _MockLoadGrupoProdutoOptionsUseCase extends Mock
    implements LoadGrupoProdutoOptionsUseCase {}

class _MockLoadMarcaProdutoOptionsUseCase extends Mock
    implements LoadMarcaProdutoOptionsUseCase {}

late SalesPreferences _pumpSalesPreferences;
late LoadAvailableAgentsForSales _pumpLoadAvailableAgentsForSales;
late AgentClientTokenReader _pumpTokenReader;
late LoadProdutoVendidoTendenciaDeVendaScreenUseCase
_pumpLoadTrendScreenUseCase;
late LoadProdutoVendidoTendenciaDeVendaUseCase _pumpLoadTrendPageUseCase;
late LoadGrupoProdutoOptionsUseCase _pumpLoadGrupoProdutoOptionsUseCase;
late LoadMarcaProdutoOptionsUseCase _pumpLoadMarcaProdutoOptionsUseCase;

void main() {
  late _MockAuthController authController;
  late _MockSalesPreferences salesPreferences;
  late _MockAgentClientTokenReader tokenReader;
  late _MockLoadAvailableAgentsForSales loadAvailableAgentsForSales;
  late _MockLoadProdutoVendidoTendenciaDeVendaScreenUseCase
  loadTrendScreenUseCase;
  late _MockLoadProdutoVendidoTendenciaDeVendaUseCase loadTrendPageUseCase;
  late _MockLoadGrupoProdutoOptionsUseCase loadGrupoProdutoOptionsUseCase;
  late _MockLoadMarcaProdutoOptionsUseCase loadMarcaProdutoOptionsUseCase;

  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
    registerFallbackValue(
      ProdutoVendidoTendenciaDeVendaFilter(
        periodoAtualInicio: DateTime(2026),
        periodoAtualFim: DateTime(2026, 1, 31),
        periodoAnteriorInicio: DateTime(2025, 12),
        periodoAnteriorFim: DateTime(2025, 12, 31),
      ),
    );
    registerFallbackValue(<String>[]);
    registerFallbackValue(AutoRefreshSnapshot.disabled);
    registerFallbackValue(SalesAutoRefreshOptions.optionSet);
  });

  setUp(() async {
    await getIt.reset();

    authController = _MockAuthController();
    salesPreferences = _MockSalesPreferences();
    tokenReader = _MockAgentClientTokenReader();
    loadAvailableAgentsForSales = _MockLoadAvailableAgentsForSales();
    loadTrendScreenUseCase =
        _MockLoadProdutoVendidoTendenciaDeVendaScreenUseCase();
    loadTrendPageUseCase = _MockLoadProdutoVendidoTendenciaDeVendaUseCase();
    loadGrupoProdutoOptionsUseCase = _MockLoadGrupoProdutoOptionsUseCase();
    loadMarcaProdutoOptionsUseCase = _MockLoadMarcaProdutoOptionsUseCase();
    _pumpSalesPreferences = salesPreferences;
    _pumpLoadAvailableAgentsForSales = loadAvailableAgentsForSales;
    _pumpTokenReader = tokenReader;
    _pumpLoadTrendScreenUseCase = loadTrendScreenUseCase;
    _pumpLoadTrendPageUseCase = loadTrendPageUseCase;
    _pumpLoadGrupoProdutoOptionsUseCase = loadGrupoProdutoOptionsUseCase;
    _pumpLoadMarcaProdutoOptionsUseCase = loadMarcaProdutoOptionsUseCase;

    when(() => authController.session).thenReturn(
      AuthSession(
        userId: 'user-1',
        email: EmailAddress('user@example.com'),
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        expiresAt: DateTime(2099),
      ),
    );

    when(() => salesPreferences.selectedAgentId).thenReturn('agent-1');
    when(() => salesPreferences.restoreCardFilters(any())).thenReturn(
      <String, Object?>{},
    );
    when(() => salesPreferences.setSelectedAgentId(any())).thenAnswer(
      (_) async {},
    );
    when(
      () => salesPreferences.persistCardFilters(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => salesPreferences.restoreAutoRefreshSnapshot(
        cardId: any(named: 'cardId'),
        optionSet: any(named: 'optionSet'),
      ),
    ).thenReturn(AutoRefreshSnapshot.disabled);
    when(
      () => salesPreferences.persistAutoRefreshSnapshot(
        cardId: any(named: 'cardId'),
        snapshot: any(named: 'snapshot'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => tokenReader.readMany(
        userId: any(named: 'userId'),
        agentIds: any(named: 'agentIds'),
      ),
    ).thenAnswer((_) async => <String, String>{'agent-1': 'client-token'});

    when(
      () => loadAvailableAgentsForSales.call(any()),
    ).thenAnswer(
      (_) async => <DashboardAgentOption>[
        const DashboardAgentOption(
          agentId: 'agent-1',
          name: 'Agent One',
        ),
      ],
    );

    when(
      () => loadTrendScreenUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        pageFilter: any(named: 'pageFilter'),
        summaryFilter: any(named: 'summaryFilter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<ProdutoVendidoTendenciaDeVendaScreenData, AppFailure>(
            ProdutoVendidoTendenciaDeVendaScreenData(
              rows: <ProdutoVendidoTendenciaDeVendaRow>[],
              totalCount: 0,
              summaryRows: <ProdutoVendidoTendenciaDeVendaSummaryRow>[],
              topGainers: <ProdutoVendidoTendenciaDeVendaRow>[],
              topLosers: <ProdutoVendidoTendenciaDeVendaRow>[],
            ),
          ),
    );

    when(
      () => loadTrendPageUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<ProdutoVendidoTendenciaDeVendaPageResult, AppFailure>(
            ProdutoVendidoTendenciaDeVendaPageResult(
              items: <ProdutoVendidoTendenciaDeVendaRow>[],
              totalCount: 0,
            ),
          ),
    );

    when(
      () => loadGrupoProdutoOptionsUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        searchTerm: any(named: 'searchTerm'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async => const Success<List<GrupoProdutoOption>, AppFailure>(
        <GrupoProdutoOption>[],
      ),
    );

    when(
      () => loadMarcaProdutoOptionsUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        searchTerm: any(named: 'searchTerm'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async => const Success<List<MarcaProdutoOption>, AppFailure>(
        <MarcaProdutoOption>[],
      ),
    );

    getIt
      ..registerSingleton<SalesPreferences>(salesPreferences)
      ..registerSingleton<AgentClientTokenReader>(tokenReader)
      ..registerSingleton<LoadAvailableAgentsForSales>(
        loadAvailableAgentsForSales,
      )
      ..registerSingleton<SalesSessionService>(
        SalesSessionService(salesPreferences),
      )
      ..registerSingleton<ResolveSalesAgentClientTokenUseCase>(
        ResolveSalesAgentClientTokenUseCase(tokenReader),
      )
      ..registerSingleton<LoadProdutoVendidoTendenciaDeVendaScreenUseCase>(
        loadTrendScreenUseCase,
      )
      ..registerSingleton<LoadProdutoVendidoTendenciaDeVendaUseCase>(
        loadTrendPageUseCase,
      )
      ..registerSingleton<LoadGrupoProdutoOptionsUseCase>(
        loadGrupoProdutoOptionsUseCase,
      )
      ..registerSingleton<LoadMarcaProdutoOptionsUseCase>(
        loadMarcaProdutoOptionsUseCase,
      );
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('shows branch-required state when there is no selected branch', (
    tester,
  ) async {
    when(() => salesPreferences.selectedAgentId).thenReturn(null);
    when(
      () => loadAvailableAgentsForSales.call(any()),
    ).thenAnswer((_) async => const <DashboardAgentOption>[]);

    await _pumpTrendPage(tester, authController: authController);
    await tester.pumpAndSettle();

    expect(find.text('Branch selection required'), findsOneWidget);
  });

  testWidgets('shows loading indicators while trend requests are in flight', (
    tester,
  ) async {
    final screenCompleter =
        Completer<AppResult<ProdutoVendidoTendenciaDeVendaScreenData>>();

    when(
      () => loadTrendScreenUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        pageFilter: any(named: 'pageFilter'),
        summaryFilter: any(named: 'summaryFilter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer((_) => screenCompleter.future);

    await _pumpTrendPage(tester, authController: authController);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AppSkeleton), findsNWidgets(3));
    expect(find.text('Executive summary'), findsOneWidget);
    expect(find.text('Detailed rows'), findsOneWidget);

    screenCompleter.complete(
      const Success<ProdutoVendidoTendenciaDeVendaScreenData, AppFailure>(
        ProdutoVendidoTendenciaDeVendaScreenData(
          rows: <ProdutoVendidoTendenciaDeVendaRow>[],
          totalCount: 0,
          summaryRows: <ProdutoVendidoTendenciaDeVendaSummaryRow>[],
          topGainers: <ProdutoVendidoTendenciaDeVendaRow>[],
          topLosers: <ProdutoVendidoTendenciaDeVendaRow>[],
        ),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('shows inline error when detail loading fails', (tester) async {
    when(
      () => loadTrendScreenUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        pageFilter: any(named: 'pageFilter'),
        summaryFilter: any(named: 'summaryFilter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async =>
          const Failure<ProdutoVendidoTendenciaDeVendaScreenData, AppFailure>(
            UnknownFailure(
              message: 'trend_request_failed',
              userMessage: 'Test detail error',
            ),
          ),
    );

    await _pumpTrendPage(tester, authController: authController);
    await tester.pumpAndSettle();

    expect(find.text('Test detail error'), findsOneWidget);
  });

  testWidgets('shows quick period presets and guidance in filters sheet', (
    tester,
  ) async {
    await _pumpTrendPage(tester, authController: authController);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.filter_list_rounded));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).last, const Offset(0, -220));
    await tester.pumpAndSettle();

    expect(find.text('Suggested periods'), findsOneWidget);
    expect(
      find.text(
        'Pick a base window and the report will align the comparison for you.',
      ),
      findsOneWidget,
    );
    expect(find.text('Current month'), findsOneWidget);
    expect(find.text('Previous month'), findsOneWidget);
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('Last 30 days'), findsOneWidget);
    expect(find.text('Adjust previous period'), findsOneWidget);
    expect(find.text('Comparison rule'), findsOneWidget);
  });

  testWidgets(
    'disables filter apply when restored periods are inconsistent',
    (tester) async {
      when(() => salesPreferences.restoreCardFilters(any())).thenReturn(
        <String, Object?>{
          'periodo_atual_start_ms': DateTime(2026, 4).millisecondsSinceEpoch,
          'periodo_atual_end_ms': DateTime(
            2026,
            4,
            30,
          ).millisecondsSinceEpoch,
          'periodo_anterior_start_ms': DateTime(2026, 2).millisecondsSinceEpoch,
          'periodo_anterior_end_ms': DateTime(
            2026,
            3,
            31,
          ).millisecondsSinceEpoch,
        },
      );

      await _pumpTrendPage(tester, authController: authController);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.filter_list_rounded));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Scrollable).last, const Offset(0, -240));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(SalesProdutoTendenciaPage)),
      );
      expect(
        find.text(l10n.salesProdutoTendenciaFilterPeriodsEquivalentWindowError),
        findsWidgets,
      );

      final applyButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Apply filters'),
      );
      expect(applyButton.onPressed, isNull);
    },
  );

  testWidgets('shows active filter chips when extra filters are applied', (
    tester,
  ) async {
    when(() => salesPreferences.restoreCardFilters(any())).thenReturn(
      <String, Object?>{
        'search_term': 'smart fox',
        'classificacao': 'CRESCENDO',
      },
    );

    await _pumpTrendPage(tester, authController: authController);
    await tester.pumpAndSettle();

    expect(find.text('Search term: smart fox'), findsOneWidget);
    expect(find.text('Classification: Growing'), findsNWidgets(2));
    expect(find.text('2 additional filters'), findsOneWidget);
  });

  testWidgets('shows empty-state message when summary and details are empty', (
    tester,
  ) async {
    await _pumpTrendPage(tester, authController: authController);
    await tester.pumpAndSettle();

    expect(find.text('No trend data for the selected filters.'), findsWidgets);
  });

  testWidgets(
    'renders summary, top movers, and paginated details when loaded',
    (
      tester,
    ) async {
      when(
        () => loadTrendScreenUseCase.call(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          pageFilter: any(named: 'pageFilter'),
          summaryFilter: any(named: 'summaryFilter'),
          clientToken: any(named: 'clientToken'),
          cancelScope: any(named: 'cancelScope'),
        ),
      ).thenAnswer(
        (_) async =>
            Success<ProdutoVendidoTendenciaDeVendaScreenData, AppFailure>(
              ProdutoVendidoTendenciaDeVendaScreenData(
                rows: <ProdutoVendidoTendenciaDeVendaRow>[
                  _trendRow(
                    codProduto: 1,
                    nomeProduto: 'Product A',
                    diferenca: 30,
                    percentualTendencia: 25,
                    classificacao: 'CRESCENDO',
                  ),
                  _trendRow(
                    codProduto: 2,
                    nomeProduto: 'Product B',
                    diferenca: -12,
                    percentualTendencia: -10,
                    classificacao: 'CAINDO',
                  ),
                ],
                totalCount: 2,
                summaryRows: const <ProdutoVendidoTendenciaDeVendaSummaryRow>[
                  ProdutoVendidoTendenciaDeVendaSummaryRow(
                    classificacao: 'CRESCENDO',
                    quantidadeProdutos: 1,
                    impactoLiquido: 30,
                  ),
                  ProdutoVendidoTendenciaDeVendaSummaryRow(
                    classificacao: 'CAINDO',
                    quantidadeProdutos: 1,
                    impactoLiquido: -12,
                  ),
                ],
                topGainers: <ProdutoVendidoTendenciaDeVendaRow>[
                  _trendRow(
                    codProduto: 1,
                    nomeProduto: 'Product A',
                    diferenca: 30,
                    percentualTendencia: 25,
                    classificacao: 'CRESCENDO',
                  ),
                ],
                topLosers: <ProdutoVendidoTendenciaDeVendaRow>[
                  _trendRow(
                    codProduto: 2,
                    nomeProduto: 'Product B',
                    diferenca: -12,
                    percentualTendencia: -10,
                    classificacao: 'CAINDO',
                  ),
                ],
              ),
            ),
      );

      await _pumpTrendPage(tester, authController: authController);
      await tester.pumpAndSettle();

      expect(find.text('Executive summary'), findsOneWidget);
      expect(find.text('By classification'), findsOneWidget);
      expect(find.text('Top 15 gainers'), findsOneWidget);
      expect(find.text('Detailed rows'), findsOneWidget);
      expect(find.text('Product A'), findsWidgets);
      expect(find.text('Product B'), findsWidgets);
    },
  );

  testWidgets('exposes share actions when trend data is loaded', (
    tester,
  ) async {
    when(
      () => loadTrendScreenUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        pageFilter: any(named: 'pageFilter'),
        summaryFilter: any(named: 'summaryFilter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async =>
          Success<ProdutoVendidoTendenciaDeVendaScreenData, AppFailure>(
            ProdutoVendidoTendenciaDeVendaScreenData(
              rows: <ProdutoVendidoTendenciaDeVendaRow>[
                _trendRow(
                  codProduto: 1,
                  nomeProduto: 'Product A',
                  diferenca: 30,
                  percentualTendencia: 25,
                  classificacao: 'CRESCENDO',
                ),
              ],
              totalCount: 1,
              summaryRows: const <ProdutoVendidoTendenciaDeVendaSummaryRow>[
                ProdutoVendidoTendenciaDeVendaSummaryRow(
                  classificacao: 'CRESCENDO',
                  quantidadeProdutos: 1,
                  impactoLiquido: 30,
                ),
              ],
              topGainers: <ProdutoVendidoTendenciaDeVendaRow>[
                _trendRow(
                  codProduto: 1,
                  nomeProduto: 'Product A',
                  diferenca: 30,
                  percentualTendencia: 25,
                  classificacao: 'CRESCENDO',
                ),
              ],
              topLosers: const <ProdutoVendidoTendenciaDeVendaRow>[],
            ),
          ),
    );

    await _pumpTrendPage(tester, authController: authController);
    await tester.pumpAndSettle();

    expect(find.text('By classification'), findsOneWidget);
    expect(find.text('Top 15 gainers'), findsOneWidget);
    expect(find.text('Top 15 losers'), findsOneWidget);
  });

  test(
    'opens classificacao fullscreen chart route',
    () {
      // Needs GoRouter with chart fullscreen routes; _pumpTrendPage uses
      // MaterialApp home only, so fullscreen navigation is not testable here.
    },
    skip:
        'Fullscreen navigation requires GoRouter with chart fullscreen routes',
  );

  testWidgets('renders pt_BR page chrome and filter summary', (tester) async {
    await _pumpTrendPage(
      tester,
      authController: authController,
      locale: const Locale('pt', 'BR'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tendência de vendas'), findsOneWidget);
    expect(find.text('Sem filtros adicionais'), findsOneWidget);
    expect(find.text('Sales trend'), findsNothing);
    expect(find.text('No additional filters'), findsNothing);
  });

  testWidgets('renders pt_BR summary KPIs when trend data is loaded', (
    tester,
  ) async {
    when(
      () => loadTrendScreenUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        pageFilter: any(named: 'pageFilter'),
        summaryFilter: any(named: 'summaryFilter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async =>
          Success<ProdutoVendidoTendenciaDeVendaScreenData, AppFailure>(
            ProdutoVendidoTendenciaDeVendaScreenData(
              rows: <ProdutoVendidoTendenciaDeVendaRow>[
                _trendRow(
                  codProduto: 1,
                  nomeProduto: 'Product A',
                  diferenca: 30,
                  percentualTendencia: 25,
                  classificacao: 'CRESCENDO',
                ),
              ],
              totalCount: 1,
              summaryRows: const <ProdutoVendidoTendenciaDeVendaSummaryRow>[
                ProdutoVendidoTendenciaDeVendaSummaryRow(
                  classificacao: 'CRESCENDO',
                  quantidadeProdutos: 1,
                  impactoLiquido: 30,
                ),
              ],
              topGainers: <ProdutoVendidoTendenciaDeVendaRow>[
                _trendRow(
                  codProduto: 1,
                  nomeProduto: 'Product A',
                  diferenca: 30,
                  percentualTendencia: 25,
                  classificacao: 'CRESCENDO',
                ),
              ],
              topLosers: const <ProdutoVendidoTendenciaDeVendaRow>[],
            ),
          ),
    );

    await _pumpTrendPage(
      tester,
      authController: authController,
      locale: const Locale('pt', 'BR'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resumo executivo'), findsOneWidget);
    expect(find.text('Produtos crescendo'), findsOneWidget);
    expect(find.text('Executive summary'), findsNothing);
    expect(find.text('Growing products'), findsNothing);
  });

  testWidgets('supports pagination with totalCount', (tester) async {
    final capturedDetailFilters = <ProdutoVendidoTendenciaDeVendaFilter>[];

    when(
      () => loadTrendScreenUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        pageFilter: any(named: 'pageFilter'),
        summaryFilter: any(named: 'summaryFilter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async =>
          Success<ProdutoVendidoTendenciaDeVendaScreenData, AppFailure>(
            ProdutoVendidoTendenciaDeVendaScreenData(
              rows: <ProdutoVendidoTendenciaDeVendaRow>[
                _trendRow(
                  codProduto: 1,
                  nomeProduto: 'Product A',
                  diferenca: 30,
                  percentualTendencia: 25,
                  classificacao: 'CRESCENDO',
                ),
              ],
              totalCount: 25,
              summaryRows: const <ProdutoVendidoTendenciaDeVendaSummaryRow>[
                ProdutoVendidoTendenciaDeVendaSummaryRow(
                  classificacao: 'CRESCENDO',
                  quantidadeProdutos: 25,
                  impactoLiquido: 80,
                ),
              ],
              topGainers: <ProdutoVendidoTendenciaDeVendaRow>[
                _trendRow(
                  codProduto: 1,
                  nomeProduto: 'Product A',
                  diferenca: 30,
                  percentualTendencia: 25,
                  classificacao: 'CRESCENDO',
                ),
              ],
              topLosers: const <ProdutoVendidoTendenciaDeVendaRow>[],
            ),
          ),
    );

    when(
      () => loadTrendPageUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer((invocation) async {
      final filter =
          invocation.namedArguments[#filter]
              as ProdutoVendidoTendenciaDeVendaFilter;
      capturedDetailFilters.add(filter);

      return Success<ProdutoVendidoTendenciaDeVendaPageResult, AppFailure>(
        ProdutoVendidoTendenciaDeVendaPageResult(
          items: <ProdutoVendidoTendenciaDeVendaRow>[
            _trendRow(
              codProduto: filter.page,
              nomeProduto: filter.page == 1 ? 'Product A' : 'Product B',
              diferenca: 30,
              percentualTendencia: 25,
              classificacao: 'CRESCENDO',
            ),
          ],
          totalCount: 2,
        ),
      );
    });

    await _pumpTrendPage(tester, authController: authController);
    await tester.pumpAndSettle();

    final nextPageButton = find.byIcon(Icons.chevron_right_rounded);
    await tester.scrollUntilVisible(
      nextPageButton,
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('25 rows'), findsOneWidget);
    expect(find.text('Product A'), findsOneWidget);
    expect(find.text('2'), findsWidgets);

    await tester.tap(nextPageButton);
    await tester.pumpAndSettle();

    expect(capturedDetailFilters.any((filter) => filter.page == 2), isTrue);
    expect(find.text('Product B'), findsOneWidget);
  });

  testWidgets('navigates from sales hub card to trend page route', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoute.sales.path,
      routes: buildSalesRoutes(),
    );

    await tester.pumpWidget(
      Provider<AuthController>.value(
        value: authController,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SalesHubPage), findsOneWidget);
    await tester.tap(find.text('Sales trend'));
    await tester.pumpAndSettle();

    expect(find.byType(SalesProdutoTendenciaPage), findsOneWidget);
  });
}

Future<void> _pumpTrendPage(
  WidgetTester tester, {
  required AuthController authController,
  Locale? locale,
}) async {
  await tester.pumpWidget(
    Provider<AuthController>.value(
      value: authController,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SalesProdutoTendenciaPage(
            sessionService: SalesSessionService(_pumpSalesPreferences),
            loadSalesAvailableAgentsUseCase: _pumpLoadAvailableAgentsForSales,
            resolveSalesAgentClientTokenUseCase:
                ResolveSalesAgentClientTokenUseCase(_pumpTokenReader),
            loadTrendScreenUseCase: _pumpLoadTrendScreenUseCase,
            loadTrendPageUseCase: _pumpLoadTrendPageUseCase,
            loadGrupoProdutoOptionsUseCase:
                _pumpLoadGrupoProdutoOptionsUseCase,
            loadMarcaProdutoOptionsUseCase:
                _pumpLoadMarcaProdutoOptionsUseCase,
          ),
        ),
      ),
    ),
  );
}

ProdutoVendidoTendenciaDeVendaRow _trendRow({
  required int codProduto,
  required String nomeProduto,
  required double diferenca,
  required double percentualTendencia,
  required String classificacao,
}) {
  return ProdutoVendidoTendenciaDeVendaRow(
    codEmpresa: 1,
    codFilial: 1,
    codProduto: codProduto,
    nomeProduto: nomeProduto,
    codUnidadeMedida: 'UN',
    qtdAnterior: 100,
    qtdAtual: 130,
    diferenca: diferenca,
    percentualTendencia: percentualTendencia,
    classificacao: classificacao,
    codGrupoProduto: 10,
    nomeGrupoProduto: 'Group',
    codMarca: 20,
    nomeMarca: 'Brand',
  );
}
