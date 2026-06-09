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
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_page_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_screen_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/marca_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_screen_data.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/sales/application/load_media_movel_rows_for_share_use_case.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/auto_refresh/sales_auto_refresh_support.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_hub_page.dart';
import 'package:colmeia/features/sales/presentation/pages/sales_produto_tendencia_media_movel_page.dart';
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

class _MockLoadTrendScreenUseCase extends Mock
    implements LoadProdutoVendidoTendenciaDeVendaMediaMovelScreenUseCase {}

class _MockLoadTrendPageUseCase extends Mock
    implements LoadProdutoVendidoTendenciaDeVendaMediaMovelPageUseCase {}

class _MockLoadGrupoProdutoOptionsUseCase extends Mock
    implements LoadGrupoProdutoOptionsUseCase {}

class _MockLoadMarcaProdutoOptionsUseCase extends Mock
    implements LoadMarcaProdutoOptionsUseCase {}

class _MockLoadMediaMovelRowsForShareUseCase extends Mock
    implements LoadMediaMovelRowsForShareUseCase {}

late SalesPreferences _pumpSalesPreferences;
late LoadAvailableAgentsForSales _pumpLoadAvailableAgentsForSales;
late AgentClientTokenReader _pumpTokenReader;
late LoadProdutoVendidoTendenciaDeVendaMediaMovelScreenUseCase
_pumpLoadTrendScreenUseCase;
late LoadProdutoVendidoTendenciaDeVendaMediaMovelPageUseCase
_pumpLoadTrendPageUseCase;
late LoadGrupoProdutoOptionsUseCase _pumpLoadGrupoProdutoOptionsUseCase;
late LoadMarcaProdutoOptionsUseCase _pumpLoadMarcaProdutoOptionsUseCase;
late LoadMediaMovelRowsForShareUseCase _pumpLoadRowsForShareUseCase;

void main() {
  late _MockAuthController authController;
  late _MockSalesPreferences salesPreferences;
  late _MockAgentClientTokenReader tokenReader;
  late _MockLoadAvailableAgentsForSales loadAvailableAgentsForSales;
  late _MockLoadTrendScreenUseCase loadTrendScreenUseCase;
  late _MockLoadTrendPageUseCase loadTrendPageUseCase;
  late _MockLoadGrupoProdutoOptionsUseCase loadGrupoProdutoOptionsUseCase;
  late _MockLoadMarcaProdutoOptionsUseCase loadMarcaProdutoOptionsUseCase;
  late _MockLoadMediaMovelRowsForShareUseCase loadRowsForShareUseCase;

  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
    registerFallbackValue(
      const ProdutoVendidoTendenciaDeVendaMediaMovelFilter(quantidadeDias: 7),
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
    loadTrendScreenUseCase = _MockLoadTrendScreenUseCase();
    loadTrendPageUseCase = _MockLoadTrendPageUseCase();
    loadGrupoProdutoOptionsUseCase = _MockLoadGrupoProdutoOptionsUseCase();
    loadMarcaProdutoOptionsUseCase = _MockLoadMarcaProdutoOptionsUseCase();
    loadRowsForShareUseCase = _MockLoadMediaMovelRowsForShareUseCase();
    _pumpSalesPreferences = salesPreferences;
    _pumpLoadAvailableAgentsForSales = loadAvailableAgentsForSales;
    _pumpTokenReader = tokenReader;
    _pumpLoadTrendScreenUseCase = loadTrendScreenUseCase;
    _pumpLoadTrendPageUseCase = loadTrendPageUseCase;
    _pumpLoadGrupoProdutoOptionsUseCase = loadGrupoProdutoOptionsUseCase;
    _pumpLoadMarcaProdutoOptionsUseCase = loadMarcaProdutoOptionsUseCase;
    _pumpLoadRowsForShareUseCase = loadRowsForShareUseCase;

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
      ),
    ).thenAnswer(
      (_) async =>
          const Success<
            ProdutoVendidoTendenciaDeVendaMediaMovelScreenData,
            AppFailure
          >(
            ProdutoVendidoTendenciaDeVendaMediaMovelScreenData(
              page: ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
                items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
                totalCount: 0,
              ),
              summaryRows:
                  <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[],
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
      (_) async => const Success<
          ProdutoVendidoTendenciaDeVendaMediaMovelPageResult,
          AppFailure>(
        ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
          items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
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
      ..registerSingleton<
        LoadProdutoVendidoTendenciaDeVendaMediaMovelScreenUseCase
      >(
        loadTrendScreenUseCase,
      )
      ..registerSingleton<LoadProdutoVendidoTendenciaDeVendaMediaMovelPageUseCase>(
        loadTrendPageUseCase,
      )
      ..registerSingleton<LoadGrupoProdutoOptionsUseCase>(
        loadGrupoProdutoOptionsUseCase,
      )
      ..registerSingleton<LoadMarcaProdutoOptionsUseCase>(
        loadMarcaProdutoOptionsUseCase,
      )
      ..registerSingleton<LoadMediaMovelRowsForShareUseCase>(
        loadRowsForShareUseCase,
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

    await _pumpPage(tester, authController: authController);
    await tester.pumpAndSettle();

    expect(
      find.text('Select a branch to view this information.'),
      findsWidgets,
    );
  });

  testWidgets('shows loading indicators while trend screen loads', (
    tester,
  ) async {
    final screenCompleter =
        Completer<
          AppResult<ProdutoVendidoTendenciaDeVendaMediaMovelScreenData>
        >();

    when(
      () => loadTrendScreenUseCase.call(
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
      ),
    ).thenAnswer((_) => screenCompleter.future);

    await _pumpPage(tester, authController: authController);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AppSkeleton), findsNWidgets(3));
    expect(find.text('Executive summary'), findsOneWidget);
    expect(find.text('Detailed rows'), findsOneWidget);

    screenCompleter.complete(
      const Success<
        ProdutoVendidoTendenciaDeVendaMediaMovelScreenData,
        AppFailure
      >(
        ProdutoVendidoTendenciaDeVendaMediaMovelScreenData(
          page: ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
            items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
            totalCount: 0,
          ),
          summaryRows: <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[],
        ),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('shows inline error when trend screen loading fails', (
    tester,
  ) async {
    when(
      () => loadTrendScreenUseCase.call(
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
      ),
    ).thenAnswer(
      (_) async =>
          const Failure<
            ProdutoVendidoTendenciaDeVendaMediaMovelScreenData,
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

  testWidgets('shows inline error when trend screen returns failure', (
    tester,
  ) async {
    when(
      () => loadTrendScreenUseCase.call(
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
      ),
    ).thenAnswer(
      (_) async =>
          const Failure<
            ProdutoVendidoTendenciaDeVendaMediaMovelScreenData,
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

    expect(find.text('Summary error'), findsOneWidget);
    expect(find.text('Executive summary'), findsNothing);
    expect(find.text('Product A'), findsNothing);
  });

  testWidgets('renders dashboard and details when loaded', (tester) async {
    when(
      () => loadTrendScreenUseCase.call(
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
      ),
    ).thenAnswer(
      (_) async =>
          Success<
            ProdutoVendidoTendenciaDeVendaMediaMovelScreenData,
            AppFailure
          >(
            ProdutoVendidoTendenciaDeVendaMediaMovelScreenData(
              page: ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
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
              summaryRows:
                  const <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[
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
      findsWidgets,
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
      () => loadTrendScreenUseCase.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: captureAny(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        hubPresenceOnlineAgentIdsSnapshot: any(
          named: 'hubPresenceOnlineAgentIdsSnapshot',
        ),
        hubConnectedFromApprovedCatalogRow: any(
          named: 'hubConnectedFromApprovedCatalogRow',
        ),
        cancelScope: any(named: 'cancelScope'),
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
      () => loadTrendScreenUseCase.call(
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
      ),
    ).thenAnswer(
      (_) async =>
          Success<
            ProdutoVendidoTendenciaDeVendaMediaMovelScreenData,
            AppFailure
          >(
            ProdutoVendidoTendenciaDeVendaMediaMovelScreenData(
              page: ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
                items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[
                  _row(codProduto: 1, nomeProduto: 'Product A'),
                ],
                totalCount: 25,
              ),
              summaryRows:
                  const <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[
                    ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow(
                      classificacao: 'CRESCENDO',
                      quantidadeProdutos: 25,
                      impactoLiquido: 80,
                    ),
                  ],
            ),
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

  testWidgets('shows snackbar when share export row limit is exceeded', (
    tester,
  ) async {
    const totalCount = 600;

    when(
      () => loadTrendScreenUseCase.call(
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
      ),
    ).thenAnswer(
      (_) async =>
          Success<
            ProdutoVendidoTendenciaDeVendaMediaMovelScreenData,
            AppFailure
          >(
            ProdutoVendidoTendenciaDeVendaMediaMovelScreenData(
              page: ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
                items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[
                  _row(codProduto: 1, nomeProduto: 'Product A'),
                ],
                totalCount: totalCount,
              ),
              summaryRows:
                  const <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[
                    ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow(
                      classificacao: 'CRESCENDO',
                      quantidadeProdutos: totalCount,
                      impactoLiquido: 80,
                    ),
                  ],
            ),
          ),
    );

    when(
      () => loadRowsForShareUseCase(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        totalCount: any(named: 'totalCount'),
        clientToken: any(named: 'clientToken'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        hubPresenceOnlineAgentIdsSnapshot: any(
          named: 'hubPresenceOnlineAgentIdsSnapshot',
        ),
        hubConnectedFromApprovedCatalogRow: any(
          named: 'hubConnectedFromApprovedCatalogRow',
        ),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async =>
          const Failure<
            List<ProdutoVendidoTendenciaDeVendaMediaMovelRow>,
            AppFailure
          >(
            ValidationFailure(
              message: 'share_export_row_limit_exceeded',
              userMessage: 'row limit exceeded',
            ),
          ),
    );

    await _pumpPage(tester, authController: authController);
    await tester.pumpAndSettle();

    final shareButtons = find.byTooltip('Share chart');
    expect(shareButtons, findsWidgets);

    await tester.ensureVisible(shareButtons.last);
    await tester.tap(shareButtons.last);
    await tester.pump();
    await tester.pumpAndSettle();

    final l10n = lookupAppLocalizations(const Locale('en'));
    expect(
      find.text(
        l10n.salesProdutoTendenciaMediaMovelShareRowLimitExceeded(
          LoadMediaMovelRowsForShareUseCase.maxExportRowCount,
          totalCount,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders pt_BR page chrome and filter summary', (tester) async {
    await _pumpPage(
      tester,
      authController: authController,
      locale: const Locale('pt', 'BR'),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Tendência de vendas (média móvel)'),
      findsOneWidget,
    );
    expect(find.text('JANELA DE DIAS'), findsOneWidget);
    expect(find.text('7 dias'), findsOneWidget);
    expect(find.text('Sem filtros adicionais'), findsOneWidget);
  });

  testWidgets('renders pt_BR summary KPIs when trend data is loaded', (
    tester,
  ) async {
    when(
      () => loadTrendScreenUseCase.call(
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
      ),
    ).thenAnswer(
      (_) async =>
          Success<
            ProdutoVendidoTendenciaDeVendaMediaMovelScreenData,
            AppFailure
          >(
            ProdutoVendidoTendenciaDeVendaMediaMovelScreenData(
              page: ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
                items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[
                  _row(codProduto: 1, nomeProduto: 'Product A'),
                ],
                totalCount: 1,
              ),
              summaryRows:
                  const <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[
                    ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow(
                      classificacao: 'CRESCENDO',
                      quantidadeProdutos: 1,
                      impactoLiquido: 4,
                    ),
                  ],
            ),
          ),
    );

    await _pumpPage(
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
          body: SalesProdutoTendenciaMediaMovelPage(
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
            loadRowsForShareUseCase: _pumpLoadRowsForShareUseCase,
          ),
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
