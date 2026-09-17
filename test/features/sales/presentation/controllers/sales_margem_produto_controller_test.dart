import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_margem_produto_page_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_direction.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/sales/application/load_margem_produto_rows_for_share_use_case.dart';
import 'package:colmeia/features/sales/application/ports/sales_preferences_port.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_margem_produto_controller.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_margem_produto_sort.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockSalesPreferences extends Mock implements SalesPreferencesPort {}

class _MockLoadAvailableAgentsForSales extends Mock
    implements LoadAvailableAgentsForSales {}

class _MockResolveClientToken extends Mock
    implements ResolveSalesAgentClientTokenUseCase {}

class _MockLoadPage extends Mock implements LoadMargemProdutoPageUseCase {}

class _MockLoadShare extends Mock
    implements LoadMargemProdutoRowsForShareUseCase {}

void main() {
  late _MockSalesPreferences preferences;
  late _MockLoadAvailableAgentsForSales loadAgents;
  late _MockResolveClientToken resolveToken;
  late _MockLoadPage loadPage;
  late _MockLoadShare loadShare;
  late SalesSessionService sessionService;
  late SalesMargemProdutoController controller;

  const row = MargemProdutoRow(
    codEmpresa: 1,
    codFilial: 1,
    nomeFilial: 'Centro',
    codProduto: 10,
    nomeProduto: 'Mel',
    custoReposicao: 1,
    precoVendaProduto: 2,
    percentualMarkupCustoCompraProduto: 100,
    margemLucroProduto: 50,
  );

  setUpAll(() {
    registerFallbackValue(const MargemProdutoFilter());
    registerFallbackValue(AgentQueriesCancelScope());
  });

  setUp(() {
    preferences = _MockSalesPreferences();
    loadAgents = _MockLoadAvailableAgentsForSales();
    resolveToken = _MockResolveClientToken();
    loadPage = _MockLoadPage();
    loadShare = _MockLoadShare();
    sessionService = SalesSessionService(preferences);

    when(
      () => preferences.restoreCardFilters(SalesMargemProdutoSort.cardId),
    ).thenReturn(const <String, Object?>{});
    when(() => preferences.selectedAgentId).thenReturn('agent-1');
    when(() => preferences.setSelectedAgentId(any())).thenAnswer((_) async {});
    when(
      () => preferences.persistCardFilters(any(), any()),
    ).thenAnswer((_) async {});
    when(() => loadAgents.call('user-1')).thenAnswer(
      (_) async => const <DashboardAgentOption>[
        DashboardAgentOption(agentId: 'agent-1', name: 'Filial Centro'),
      ],
    );
    when(
      () => resolveToken(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer((_) async => 'token-1');
    when(
      () => loadPage(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async => const Success<MargemProdutoPageResult, AppFailure>(
        MargemProdutoPageResult(items: <MargemProdutoRow>[row], totalCount: 1),
      ),
    );

    controller = SalesMargemProdutoController(
      sessionService: sessionService,
      loadSalesAvailableAgentsUseCase: loadAgents,
      resolveSalesAgentClientTokenUseCase: resolveToken,
      loadMargemProdutoPageUseCase: loadPage,
      loadRowsForShareUseCase: loadShare,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('restores page size, search and sort from session', () {
    when(
      () => preferences.restoreCardFilters(SalesMargemProdutoSort.cardId),
    ).thenReturn(<String, Object?>{
      SalesMargemProdutoSort.persistPageSizeKey: 50,
      SalesMargemProdutoSort.persistSearchTermKey: '  cabo  ',
      SalesMargemProdutoSort.persistSortByKey: 'percentualMarkup',
      SalesMargemProdutoSort.persistSortDirectionKey: 'descending',
    });
    final restored = SalesMargemProdutoController(
      sessionService: sessionService,
      loadSalesAvailableAgentsUseCase: loadAgents,
      resolveSalesAgentClientTokenUseCase: resolveToken,
      loadMargemProdutoPageUseCase: loadPage,
      loadRowsForShareUseCase: loadShare,
    );
    addTearDown(restored.dispose);

    expect(restored.pageSize, 50);
    expect(restored.query.searchTerm, 'cabo');
    expect(restored.query.sorts.single.columnKey, 'percentualMarkup');
    expect(
      restored.query.sorts.single.direction,
      AppReportSortDirection.descending,
    );
  });

  test('bindUser then loadCatalog maps the first page', () async {
    await controller.bindUser('user-1');
    final outcome = await controller.loadCatalog();

    expect(outcome.isSuccess, isTrue);
    expect(controller.selectedAgentId, 'agent-1');
    expect(controller.rows, const <MargemProdutoRow>[row]);
    expect(controller.totalCount, 1);
    expect(controller.isLoading, isFalse);
    verify(
      () => loadPage(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: any(named: 'filter'),
        clientToken: 'token-1',
        cancelScope: any(named: 'cancelScope'),
      ),
    ).called(1);
  });

  test('missing client token is a session failure', () async {
    when(
      () => resolveToken(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer((_) async => null);
    await controller.bindUser('user-1');
    final outcome = await controller.loadCatalog();

    expect(outcome.isFailure, isTrue);
    expect(outcome.loadFailure, isA<SessionFailure>());
    expect(controller.rows, isEmpty);
    expect(controller.isLoading, isFalse);
  });

  test('applySearch resets to page 1, persists, and reloads', () async {
    when(
      () => loadPage(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async => const Success<MargemProdutoPageResult, AppFailure>(
        MargemProdutoPageResult(
          items: <MargemProdutoRow>[row],
          totalCount: 40,
        ),
      ),
    );
    await controller.bindUser('user-1');
    await controller.loadCatalog();
    await controller.applyPaging(page: 2, pageSize: 20);

    final outcome = await controller.applySearch('mel');

    expect(outcome.isSuccess, isTrue);
    expect(controller.page, 1);
    expect(controller.query.searchTerm, 'mel');
    final captured =
        verify(
              () => preferences.persistCardFilters(
                SalesMargemProdutoSort.cardId,
                captureAny(),
              ),
            ).captured.last
            as Map<String, Object?>;
    expect(captured[SalesMargemProdutoSort.persistSearchTermKey], 'mel');
    final filter =
        verify(
              () => loadPage(
                userId: any(named: 'userId'),
                agentId: any(named: 'agentId'),
                filter: captureAny(named: 'filter'),
                clientToken: any(named: 'clientToken'),
                cancelScope: any(named: 'cancelScope'),
              ),
            ).captured.last
            as MargemProdutoFilter;
    expect(filter.searchTerm, 'mel');
    expect(filter.page, 1);
  });

  test('applySort persists markup DESC and sends it on the filter', () async {
    await controller.bindUser('user-1');
    await controller.loadCatalog();

    final outcome = await controller.applySort(
      SalesMargemProdutoSort.descriptorsFor(
        sortBy: MargemProdutoSortBy.percentualMarkup,
        sortDirection: MargemProdutoSortDirection.descending,
      ),
    );

    expect(outcome.isSuccess, isTrue);
    final filter =
        verify(
              () => loadPage(
                userId: any(named: 'userId'),
                agentId: any(named: 'agentId'),
                filter: captureAny(named: 'filter'),
                clientToken: any(named: 'clientToken'),
                cancelScope: any(named: 'cancelScope'),
              ),
            ).captured.last
            as MargemProdutoFilter;
    expect(filter.sortBy, MargemProdutoSortBy.percentualMarkup);
    expect(filter.sortDirection, MargemProdutoSortDirection.descending);
  });

  test('loadRowsForShare copies search and sort', () async {
    when(
      () => loadShare(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        totalCount: any(named: 'totalCount'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async => const Success<List<MargemProdutoRow>, AppFailure>(
        <MargemProdutoRow>[row],
      ),
    );
    await controller.bindUser('user-1');
    await controller.loadCatalog();
    await controller.applySearch('mel');
    await controller.applySort(
      SalesMargemProdutoSort.descriptorsFor(
        sortBy: MargemProdutoSortBy.codProduto,
        sortDirection: MargemProdutoSortDirection.descending,
      ),
    );

    final result = await controller.loadRowsForShare();

    expect(result.isSuccess(), isTrue);
    final filter =
        verify(
              () => loadShare(
                userId: 'user-1',
                agentId: 'agent-1',
                filter: captureAny(named: 'filter'),
                totalCount: 1,
                clientToken: 'token-1',
                cancelScope: any(named: 'cancelScope'),
              ),
            ).captured.single
            as MargemProdutoFilter;
    expect(filter.searchTerm, 'mel');
    expect(filter.sortBy, MargemProdutoSortBy.codProduto);
    expect(filter.sortDirection, MargemProdutoSortDirection.descending);
  });
}
