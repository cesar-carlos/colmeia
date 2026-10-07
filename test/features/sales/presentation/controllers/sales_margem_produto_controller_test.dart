import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_margem_produto_page_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_progress.dart';
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
import 'package:fake_async/fake_async.dart';
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
    when(() => loadPage.usesProgressiveCatalog).thenReturn(false);
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

  test('progressive catalog shows partial rows, publishes totals only at completion and reuses pages for share', () async {
    when(() => loadPage.usesProgressiveCatalog).thenReturn(true);
    final source =
        StreamController<AppResult<AgentQueryProgress<MargemProdutoRow>>>();
    when(
      () => loadPage.watchCatalog(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer((_) => source.stream);
    final rows = List.generate(
      65,
      (index) => MargemProdutoRow(
        codEmpresa: 1,
        codFilial: 1,
        nomeFilial: 'Centro',
        codProduto: index + 1,
        nomeProduto: 'Produto $index',
        precoVendaProduto: 2,
      ),
    );
    await controller.bindUser('user-1');
    final loading = controller.loadCatalog();
    await Future<void>.delayed(Duration.zero);
    source.add(
      Success(
        AgentQueryProgress(
          rows: rows.take(20),
          isComplete: false,
          receivedRowCount: 20,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(controller.rows, rows.take(controller.pageSize));
    expect(controller.isLoading, true);
    expect(controller.isIncomplete, true);
    expect(controller.totalCount, 0);
    expect(controller.canShare, false);
    source.add(
      Success(
        AgentQueryProgress(
          rows: rows,
          isComplete: true,
          receivedRowCount: rows.length,
        ),
      ),
    );
    expect((await loading).isSuccess, true);
    expect(controller.totalCount, 65);
    expect(controller.isIncomplete, false);
    await controller.applyPaging(page: 2, pageSize: 20);
    expect(controller.rows, rows.sublist(20, 40));
    expect((await controller.loadRowsForShare()).getOrThrow(), rows);
    verifyNever(
      () => loadPage(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    );
    verifyNever(
      () => loadShare(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        totalCount: any(named: 'totalCount'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    );
    await source.close();
  });

  test('partial failure preserves visible rows and blocks sharing; changing the agent cancels the stream', () async {
    when(() => loadPage.usesProgressiveCatalog).thenReturn(true);
    final source =
        StreamController<AppResult<AgentQueryProgress<MargemProdutoRow>>>();
    AgentQueriesCancelScope? scope;
    when(
      () => loadPage.watchCatalog(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer((invocation) {
      scope =
          invocation.namedArguments[#cancelScope] as AgentQueriesCancelScope;
      return source.stream;
    });
    await controller.bindUser('user-1');
    final loading = controller.loadCatalog();
    await Future<void>.delayed(Duration.zero);
    source
      ..add(
        Success(
          AgentQueryProgress(
            rows: [row],
            isComplete: false,
            receivedRowCount: 1,
          ),
        ),
      )
      ..add(const Failure(NetworkFailure(message: 'lost')));
    expect((await loading).isFailure, true);
    expect(controller.rows, [row]);
    expect(controller.isIncomplete, true);
    expect(controller.canShare, false);
    expect(scope!.isCancelled, true);
    await controller.bindUser(null);
    expect(controller.rows, isEmpty);
    expect(controller.isIncomplete, false);
    await source.close();
  });

  test('restores page size and search, ignoring persisted sort', () {
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
    expect(
      restored.query.sorts,
      SalesMargemProdutoSort.defaultSorts,
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

  test('applySort keeps the fixed name order on the filter', () async {
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
    expect(filter.sortBy, MargemProdutoSortBy.nomeProduto);
    expect(filter.sortDirection, MargemProdutoSortDirection.ascending);
  });

  test('loadRowsForShare copies search and sort', () async {
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
        MargemProdutoPageResult(items: <MargemProdutoRow>[row], totalCount: 2),
      ),
    );
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

    final result = await controller.loadRowsForShare();

    expect(result.isSuccess(), isTrue);
    final filter =
        verify(
              () => loadShare(
                userId: 'user-1',
                agentId: 'agent-1',
                filter: captureAny(named: 'filter'),
                totalCount: 2,
                clientToken: 'token-1',
                cancelScope: any(named: 'cancelScope'),
              ),
            ).captured.single
            as MargemProdutoFilter;
    expect(filter.searchTerm, 'mel');
    expect(filter.sortBy, MargemProdutoSortBy.nomeProduto);
    expect(filter.sortDirection, MargemProdutoSortDirection.ascending);
  });

  test(
    'should share the complete loaded catalog without another query',
    () async {
      await controller.bindUser('user-1');
      await controller.loadCatalog();

      final result = await controller.loadRowsForShare();

      expect(result.getOrNull(), <MargemProdutoRow>[row]);
      verifyZeroInteractions(loadShare);
    },
  );

  test('should time out and cancel when export loading never completes', () {
    fakeAsync((async) {
      final pending = Completer<AppResult<List<MargemProdutoRow>>>();
      AgentQueriesCancelScope? scope;
      when(
        () => loadShare(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          filter: any(named: 'filter'),
          totalCount: any(named: 'totalCount'),
          clientToken: any(named: 'clientToken'),
          cancelScope: any(named: 'cancelScope'),
        ),
      ).thenAnswer((invocation) {
        scope =
            invocation.namedArguments[#cancelScope] as AgentQueriesCancelScope;
        return pending.future;
      });
      unawaited(controller.bindUser('user-1'));
      async.flushMicrotasks();
      AppResult<List<MargemProdutoRow>>? result;
      unawaited(controller.loadRowsForShare().then((value) => result = value));
      async
        ..flushMicrotasks()
        ..elapse(controller.shareLoadTimeout)
        ..flushMicrotasks();

      expect(result?.exceptionOrNull(), isA<NetworkFailure>());
      expect(result?.exceptionOrNull()?.message, 'share_export_load_timeout');
      expect(scope?.isCancelled, isTrue);
      expect(pending.isCompleted, isFalse);
    });
  });

  test('should bound token resolution and stop a late token from querying', () {
    fakeAsync((async) {
      final token = Completer<String?>();
      when(
        () => resolveToken(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
        ),
      ).thenAnswer((_) => token.future);
      unawaited(controller.bindUser('user-1'));
      async.flushMicrotasks();
      AppResult<List<MargemProdutoRow>>? result;
      unawaited(controller.loadRowsForShare().then((value) => result = value));
      async
        ..flushMicrotasks()
        ..elapse(controller.shareLoadTimeout)
        ..flushMicrotasks();
      expect(result?.exceptionOrNull(), isA<NetworkFailure>());

      token.complete('late-token');
      async.flushMicrotasks();
      verifyZeroInteractions(loadShare);
    });
  });

  test(
    'should finish sharing promptly when the user session is cleared',
    () async {
      final token = Completer<String?>();
      when(
        () => resolveToken(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
        ),
      ).thenAnswer((_) => token.future);
      await controller.bindUser('user-1');

      final pendingShare = controller.loadRowsForShare();
      await controller.bindUser(null);
      final result = await pendingShare;

      expect(result.exceptionOrNull(), isA<OperationCancelledFailure>());
      expect(token.isCompleted, isFalse);
      token.complete('late-token');
      await Future<void>.delayed(Duration.zero);
      verifyZeroInteractions(loadShare);
    },
  );

  test('should return a failure when token resolution throws', () async {
    when(
      () => resolveToken(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenThrow(StateError('token lookup failed'));
    await controller.bindUser('user-1');

    final result = await controller.loadRowsForShare();

    expect(result.exceptionOrNull(), isA<UnknownFailure>());
    verifyZeroInteractions(loadShare);
  });
}
