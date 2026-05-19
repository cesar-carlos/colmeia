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
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_summary_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/marca_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_available_agents_use_case.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_hub_page.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_produto_tendencia_page.dart';
import 'package:colmeia/features/sales/presentation/routes/sales_routes.dart';
import 'package:colmeia/l10n/app_localizations.dart';
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

class _MockLoadProdutoVendidoTendenciaDeVendaUseCase extends Mock
    implements LoadProdutoVendidoTendenciaDeVendaUseCase {}

class _MockLoadProdutoVendidoTendenciaDeVendaSummaryUseCase extends Mock
    implements LoadProdutoVendidoTendenciaDeVendaSummaryUseCase {}

class _MockLoadGrupoProdutoOptionsUseCase extends Mock
    implements LoadGrupoProdutoOptionsUseCase {}

class _MockLoadMarcaProdutoOptionsUseCase extends Mock
    implements LoadMarcaProdutoOptionsUseCase {}

late SalesPreferences _pumpSalesPreferences;
late LoadAvailableAgentsForSales _pumpLoadAvailableAgentsForSales;
late AgentClientTokenReader _pumpTokenReader;
late LoadProdutoVendidoTendenciaDeVendaUseCase _pumpLoadTrendUseCase;
late LoadProdutoVendidoTendenciaDeVendaSummaryUseCase
_pumpLoadTrendSummaryUseCase;
late LoadGrupoProdutoOptionsUseCase _pumpLoadGrupoOptionsUseCase;
late LoadMarcaProdutoOptionsUseCase _pumpLoadMarcaOptionsUseCase;

void main() {
  late _MockAuthController authController;
  late _MockSalesPreferences salesPreferences;
  late _MockAgentClientTokenReader tokenReader;
  late _MockLoadAvailableAgentsForSales loadAvailableAgentsForSales;
  late _MockLoadProdutoVendidoTendenciaDeVendaUseCase loadTrendUseCase;
  late _MockLoadProdutoVendidoTendenciaDeVendaSummaryUseCase
  loadTrendSummaryUseCase;
  late _MockLoadGrupoProdutoOptionsUseCase loadGrupoOptionsUseCase;
  late _MockLoadMarcaProdutoOptionsUseCase loadMarcaOptionsUseCase;

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
    loadTrendUseCase = _MockLoadProdutoVendidoTendenciaDeVendaUseCase();
    loadTrendSummaryUseCase =
        _MockLoadProdutoVendidoTendenciaDeVendaSummaryUseCase();
    loadGrupoOptionsUseCase = _MockLoadGrupoProdutoOptionsUseCase();
    loadMarcaOptionsUseCase = _MockLoadMarcaProdutoOptionsUseCase();
    _pumpSalesPreferences = salesPreferences;
    _pumpLoadAvailableAgentsForSales = loadAvailableAgentsForSales;
    _pumpTokenReader = tokenReader;
    _pumpLoadTrendUseCase = loadTrendUseCase;
    _pumpLoadTrendSummaryUseCase = loadTrendSummaryUseCase;
    _pumpLoadGrupoOptionsUseCase = loadGrupoOptionsUseCase;
    _pumpLoadMarcaOptionsUseCase = loadMarcaOptionsUseCase;

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
      (_) async => <OverviewAgentOption>[
        const OverviewAgentOption(
          agentId: 'agent-1',
          name: 'Agent One',
        ),
      ],
    );

    when(
      () => loadTrendUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<List<ProdutoVendidoTendenciaDeVendaRow>, AppFailure>(
            <ProdutoVendidoTendenciaDeVendaRow>[],
          ),
    );

    when(
      () => loadTrendSummaryUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<
            List<ProdutoVendidoTendenciaDeVendaSummaryRow>,
            AppFailure
          >(
            <ProdutoVendidoTendenciaDeVendaSummaryRow>[],
          ),
    );

    when(
      () => loadGrupoOptionsUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        searchTerm: any(named: 'searchTerm'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer(
      (_) async => const Success<List<GrupoProdutoOption>, AppFailure>(
        <GrupoProdutoOption>[],
      ),
    );

    when(
      () => loadMarcaOptionsUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
        searchTerm: any(named: 'searchTerm'),
        clientToken: any(named: 'clientToken'),
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
      ..registerSingleton<LoadSalesAvailableAgentsUseCase>(
        LoadSalesAvailableAgentsUseCase(loadAvailableAgentsForSales),
      )
      ..registerSingleton<ResolveSalesAgentClientTokenUseCase>(
        ResolveSalesAgentClientTokenUseCase(tokenReader),
      )
      ..registerSingleton<LoadProdutoVendidoTendenciaDeVendaUseCase>(
        loadTrendUseCase,
      )
      ..registerSingleton<LoadProdutoVendidoTendenciaDeVendaSummaryUseCase>(
        loadTrendSummaryUseCase,
      )
      ..registerSingleton<LoadGrupoProdutoOptionsUseCase>(
        loadGrupoOptionsUseCase,
      )
      ..registerSingleton<LoadMarcaProdutoOptionsUseCase>(
        loadMarcaOptionsUseCase,
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
    ).thenAnswer((_) async => const <OverviewAgentOption>[]);

    await _pumpTrendPage(tester, authController: authController);
    await tester.pumpAndSettle();

    expect(find.text('Branch selection required'), findsOneWidget);
  });

  testWidgets('shows loading indicators while trend requests are in flight', (
    tester,
  ) async {
    final detailCompleter =
        Completer<AppResult<List<ProdutoVendidoTendenciaDeVendaRow>>>();
    final summaryCompleter =
        Completer<AppResult<List<ProdutoVendidoTendenciaDeVendaSummaryRow>>>();

    when(
      () => loadTrendUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer((_) => detailCompleter.future);
    when(
      () => loadTrendSummaryUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer((_) => summaryCompleter.future);

    await _pumpTrendPage(tester, authController: authController);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AppSkeleton), findsNWidgets(3));
    expect(find.text('Executive summary'), findsOneWidget);
    expect(find.text('Detailed rows'), findsOneWidget);

    detailCompleter.complete(
      const Success<List<ProdutoVendidoTendenciaDeVendaRow>, AppFailure>(
        <ProdutoVendidoTendenciaDeVendaRow>[],
      ),
    );
    summaryCompleter.complete(
      const Success<List<ProdutoVendidoTendenciaDeVendaSummaryRow>, AppFailure>(
        <ProdutoVendidoTendenciaDeVendaSummaryRow>[],
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('shows inline error when detail loading fails', (tester) async {
    when(
      () => loadTrendUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer(
      (_) async =>
          const Failure<List<ProdutoVendidoTendenciaDeVendaRow>, AppFailure>(
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
    expect(find.text('Classification: Growing'), findsOneWidget);
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
        () => loadTrendUseCase.call(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          filter: any(named: 'filter'),
          clientToken: any(named: 'clientToken'),
        ),
      ).thenAnswer(
        (_) async =>
            Success<List<ProdutoVendidoTendenciaDeVendaRow>, AppFailure>(
              <ProdutoVendidoTendenciaDeVendaRow>[
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
            ),
      );
      when(
        () => loadTrendSummaryUseCase.call(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          filter: any(named: 'filter'),
          clientToken: any(named: 'clientToken'),
        ),
      ).thenAnswer(
        (_) async =>
            const Success<
              List<ProdutoVendidoTendenciaDeVendaSummaryRow>,
              AppFailure
            >(
              <ProdutoVendidoTendenciaDeVendaSummaryRow>[
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
            ),
      );

      await _pumpTrendPage(tester, authController: authController);
      await tester.pumpAndSettle();

      expect(find.text('Executive summary'), findsOneWidget);
      expect(find.text('Top movers'), findsOneWidget);
      expect(find.text('Detailed rows'), findsOneWidget);
      expect(find.text('Product A'), findsWidgets);
      expect(find.text('Product B'), findsWidgets);
    },
  );

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
}) async {
  await tester.pumpWidget(
    Provider<AuthController>.value(
      value: authController,
      child: MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SalesProdutoTendenciaPage(
            sessionService: SalesSessionService(_pumpSalesPreferences),
            loadSalesAvailableAgentsUseCase: LoadSalesAvailableAgentsUseCase(
              _pumpLoadAvailableAgentsForSales,
            ),
            resolveSalesAgentClientTokenUseCase:
                ResolveSalesAgentClientTokenUseCase(_pumpTokenReader),
            loadTrendUseCase: _pumpLoadTrendUseCase,
            loadTrendSummaryUseCase: _pumpLoadTrendSummaryUseCase,
            loadGrupoProdutoOptionsUseCase: _pumpLoadGrupoOptionsUseCase,
            loadMarcaProdutoOptionsUseCase: _pumpLoadMarcaOptionsUseCase,
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
