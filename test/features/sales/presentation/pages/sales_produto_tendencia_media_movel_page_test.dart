import 'dart:async';

import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_grupo_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_marca_produto_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_page_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_summary_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/marca_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_hub_page.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_produto_tendencia_media_movel_page.dart';
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

class _MockLoadPageUseCase extends Mock
    implements LoadProdutoVendidoTendenciaDeVendaMediaMovelPageUseCase {}

class _MockLoadSummaryUseCase extends Mock
    implements LoadProdutoVendidoTendenciaDeVendaMediaMovelSummaryUseCase {}

class _MockLoadGrupoProdutoOptionsUseCase extends Mock
    implements LoadGrupoProdutoOptionsUseCase {}

class _MockLoadMarcaProdutoOptionsUseCase extends Mock
    implements LoadMarcaProdutoOptionsUseCase {}

void main() {
  late _MockAuthController authController;
  late _MockSalesPreferences salesPreferences;
  late _MockAgentClientTokenReader tokenReader;
  late _MockLoadAvailableAgentsForSales loadAvailableAgentsForSales;
  late _MockLoadPageUseCase loadPageUseCase;
  late _MockLoadSummaryUseCase loadSummaryUseCase;
  late _MockLoadGrupoProdutoOptionsUseCase loadGrupoOptionsUseCase;
  late _MockLoadMarcaProdutoOptionsUseCase loadMarcaOptionsUseCase;

  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
    registerFallbackValue(
      const ProdutoVendidoTendenciaDeVendaMediaMovelFilter(quantidadeDias: 7),
    );
    registerFallbackValue(<String>[]);
  });

  setUp(() async {
    await getIt.reset();

    authController = _MockAuthController();
    salesPreferences = _MockSalesPreferences();
    tokenReader = _MockAgentClientTokenReader();
    loadAvailableAgentsForSales = _MockLoadAvailableAgentsForSales();
    loadPageUseCase = _MockLoadPageUseCase();
    loadSummaryUseCase = _MockLoadSummaryUseCase();
    loadGrupoOptionsUseCase = _MockLoadGrupoProdutoOptionsUseCase();
    loadMarcaOptionsUseCase = _MockLoadMarcaProdutoOptionsUseCase();

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
      () => loadPageUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<
            ProdutoVendidoTendenciaDeVendaMediaMovelPageResult,
            AppFailure
          >(
            ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
              items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
              totalCount: 0,
            ),
          ),
    );

    when(
      () => loadSummaryUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<
            List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>,
            AppFailure
          >(
            <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[],
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
      ..registerSingleton<
        LoadProdutoVendidoTendenciaDeVendaMediaMovelPageUseCase
      >(
        loadPageUseCase,
      )
      ..registerSingleton<
        LoadProdutoVendidoTendenciaDeVendaMediaMovelSummaryUseCase
      >(loadSummaryUseCase)
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

    await _pumpPage(tester, authController: authController);
    await tester.pumpAndSettle();

    expect(
      find.text('Select a branch to view this information.'),
      findsWidgets,
    );
  });

  testWidgets('shows loading indicators while summary and detail load', (
    tester,
  ) async {
    final detailCompleter =
        Completer<
          AppResult<ProdutoVendidoTendenciaDeVendaMediaMovelPageResult>
        >();
    final summaryCompleter =
        Completer<
          AppResult<List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>>
        >();

    when(
      () => loadPageUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer((_) => detailCompleter.future);
    when(
      () => loadSummaryUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer((_) => summaryCompleter.future);

    await _pumpPage(tester, authController: authController);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AppSkeleton), findsNWidgets(3));
    expect(find.text('Executive summary'), findsOneWidget);
    expect(find.text('Detailed rows'), findsOneWidget);

    detailCompleter.complete(
      const Success<
        ProdutoVendidoTendenciaDeVendaMediaMovelPageResult,
        AppFailure
      >(
        ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
          items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
          totalCount: 0,
        ),
      ),
    );
    summaryCompleter.complete(
      const Success<
        List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>,
        AppFailure
      >(
        <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[],
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('shows inline error when detail loading fails', (tester) async {
    when(
      () => loadPageUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer(
      (_) async =>
          const Failure<
            ProdutoVendidoTendenciaDeVendaMediaMovelPageResult,
            AppFailure
          >(
            UnknownFailure(
              message: 'detail_failed',
              userMessage: 'Test detail error',
            ),
          ),
    );

    await _pumpPage(tester, authController: authController);
    await tester.pumpAndSettle();

    expect(find.text('Test detail error'), findsOneWidget);
  });

  testWidgets('shows summary-unavailable notice when summary loading fails', (
    tester,
  ) async {
    when(
      () => loadPageUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer(
      (_) async =>
          Success<
            ProdutoVendidoTendenciaDeVendaMediaMovelPageResult,
            AppFailure
          >(
            ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
              items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[
                _row(codProduto: 1, nomeProduto: 'Product A'),
              ],
              totalCount: 1,
            ),
          ),
    );
    when(
      () => loadSummaryUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer(
      (_) async =>
          const Failure<
            List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>,
            AppFailure
          >(
            UnknownFailure(
              message: 'summary_failed',
              userMessage: 'Summary error',
            ),
          ),
    );

    await _pumpPage(tester, authController: authController);
    await tester.pumpAndSettle();

    expect(find.text('Summary unavailable'), findsOneWidget);
    expect(find.text('Executive summary'), findsNothing);
    expect(find.text('Product A'), findsWidgets);
  });

  testWidgets('renders dashboard and details when loaded', (tester) async {
    when(
      () => loadPageUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer(
      (_) async =>
          Success<
            ProdutoVendidoTendenciaDeVendaMediaMovelPageResult,
            AppFailure
          >(
            ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
              items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[
                _row(codProduto: 1, nomeProduto: 'Product A'),
                _row(
                  codProduto: 2,
                  nomeProduto: 'Product B',
                  classificacao: 'CAINDO',
                  diferenca: -2,
                  tendenciaPercentual: -15,
                ),
              ],
              totalCount: 2,
            ),
          ),
    );
    when(
      () => loadSummaryUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<
            List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>,
            AppFailure
          >(
            <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[
              ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow(
                classificacao: 'CRESCENDO',
                quantidadeProdutos: 1,
                impactoLiquido: 4,
              ),
              ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow(
                classificacao: 'CAINDO',
                quantidadeProdutos: 1,
                impactoLiquido: -2,
              ),
            ],
          ),
    );

    await _pumpPage(tester, authController: authController);
    await tester.pumpAndSettle();

    expect(find.text('Executive summary'), findsOneWidget);
    expect(find.text('Products by classification'), findsOneWidget);
    expect(find.text('Detailed rows'), findsOneWidget);
    expect(find.text('Product A'), findsWidgets);
    expect(find.text('Product B'), findsWidgets);
  });

  testWidgets('shows empty-state message when summary and details are empty', (
    tester,
  ) async {
    await _pumpPage(tester, authController: authController);
    await tester.pumpAndSettle();

    expect(
      find.text('No moving-average trend data for the selected filters.'),
      findsOneWidget,
    );
  });

  testWidgets('applies filters, persists them, and reloads with new days', (
    tester,
  ) async {
    await _pumpPage(tester, authController: authController);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.filter_list_rounded).last);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(DraggableScrollableSheet),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();

    final applyButton = find.widgetWithText(FilledButton, 'Apply filters');

    await tester.enterText(find.byType(TextFormField).first, '30');
    await tester.pumpAndSettle();
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    verify(
      () => salesPreferences.persistCardFilters(
        'produto_tendencia_venda_media_movel',
        any(),
      ),
    ).called(greaterThanOrEqualTo(1));

    final capturedFilters = verify(
      () => loadPageUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: captureAny(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).captured;

    expect(
      capturedFilters
          .cast<ProdutoVendidoTendenciaDeVendaMediaMovelFilter>()
          .any((filter) => filter.quantidadeDias == 30),
      isTrue,
    );
  });

  testWidgets('shows quick window presets and sort filter in sheet', (
    tester,
  ) async {
    await _pumpPage(tester, authController: authController);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.filter_list_rounded).last);
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(DraggableScrollableSheet),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quick windows'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '7 days'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '14 days'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '30 days'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '60 days'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('SORT ROWS BY'), findsWidgets);
  });

  testWidgets('supports pagination with totalCount', (tester) async {
    when(
      () => loadPageUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer(
      (_) async =>
          Success<
            ProdutoVendidoTendenciaDeVendaMediaMovelPageResult,
            AppFailure
          >(
            ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
              items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[
                _row(codProduto: 1, nomeProduto: 'Product A'),
              ],
              totalCount: 25,
            ),
          ),
    );
    when(
      () => loadSummaryUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<
            List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>,
            AppFailure
          >(
            <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[
              ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow(
                classificacao: 'CRESCENDO',
                quantidadeProdutos: 25,
                impactoLiquido: 80,
              ),
            ],
          ),
    );

    await _pumpPage(tester, authController: authController);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.textContaining('25 rows'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('validates quantidadeDias before enabling filter apply', (
    tester,
  ) async {
    await _pumpPage(tester, authController: authController);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.filter_list_rounded).last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '0');
    await tester.pumpAndSettle();

    expect(
      find.text('Enter a valid number of days greater than zero.'),
      findsOneWidget,
    );

    final applyButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Apply filters'),
    );
    expect(applyButton.onPressed, isNull);
  });

  testWidgets('navigates from sales hub card to moving-average page route', (
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
    await tester.tap(find.text('Sales trend (moving average)'));
    await tester.pumpAndSettle();

    expect(find.byType(SalesProdutoTendenciaMediaMovelPage), findsOneWidget);
  });
}

Future<void> _pumpPage(
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
        home: const Scaffold(
          body: SalesProdutoTendenciaMediaMovelPage(),
        ),
      ),
    ),
  );
}

ProdutoVendidoTendenciaDeVendaMediaMovelRow _row({
  required int codProduto,
  required String nomeProduto,
  String classificacao = 'CRESCENDO',
  double mediaAtual = 12,
  double mediaAnterior = 8,
  double diferenca = 4,
  double tendenciaPercentual = 25,
}) {
  return ProdutoVendidoTendenciaDeVendaMediaMovelRow(
    codEmpresa: 1,
    codFilial: 1,
    codProduto: codProduto,
    nomeProduto: nomeProduto,
    codUnidadeMedida: 'UN',
    mediaAtual: mediaAtual,
    mediaAnterior: mediaAnterior,
    diferenca: diferenca,
    tendenciaPercentual: tendenciaPercentual,
    classificacao: classificacao,
    codGrupoProduto: 10,
    nomeGrupoProduto: 'Group',
    codMarca: 20,
    nomeMarca: 'Brand',
  );
}
