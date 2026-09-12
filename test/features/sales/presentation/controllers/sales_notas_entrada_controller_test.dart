import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/notas_entrada_repository.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/sales/application/ports/sales_preferences_port.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_notas_entrada_controller.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockSalesPreferences extends Mock implements SalesPreferencesPort {}

class _MockLoadAvailableAgentsForSales extends Mock
    implements LoadAvailableAgentsForSales {}

class _MockAgentClientTokenReader extends Mock
    implements AgentClientTokenReader {}

class _MockNotasEntradaRepository extends Mock
    implements NotasEntradaRepository {}

void main() {
  late _MockSalesPreferences preferences;
  late _MockLoadAvailableAgentsForSales loadAgents;
  late _MockAgentClientTokenReader tokenReader;
  late _MockNotasEntradaRepository repository;
  late SalesNotasEntradaController controller;

  setUpAll(() {
    registerFallbackValue(
      NotasEntradaFilter(referenceDate: DateTime(2026, 9, 12)),
    );
    registerFallbackValue(AgentQueriesCancelScope());
  });

  setUp(() {
    preferences = _MockSalesPreferences();
    loadAgents = _MockLoadAvailableAgentsForSales();
    tokenReader = _MockAgentClientTokenReader();
    repository = _MockNotasEntradaRepository();

    when(
      () => preferences.restoreCardFilters(SalesNotasEntradaController.cardId),
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
      () => tokenReader.readMany(
        userId: 'user-1',
        agentIds: any(named: 'agentIds'),
      ),
    ).thenAnswer((_) async => const <String, String>{'agent-1': 'token-1'});
    when(
      () => repository.loadPage(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: any(named: 'filter'),
        clientToken: 'token-1',
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer((invocation) async {
      final filter = invocation.namedArguments[#filter] as NotasEntradaFilter;
      return Success<NotasEntradaPageResult, AppFailure>(
        filter.page == 1 ? _firstPage() : _secondPage(),
      );
    });
    controller = SalesNotasEntradaController(
      sessionService: SalesSessionService(preferences),
      loadSalesAvailableAgentsUseCase: loadAgents,
      resolveSalesAgentClientToken: ResolveSalesAgentClientTokenUseCase(
        tokenReader,
      ),
      notasEntradaRepository: repository,
      referenceDate: DateTime(2026, 9, 12),
    );
  });

  tearDown(() => controller.dispose());

  test('loads the selected branch and jumps to a numbered page', () async {
    await controller.bindUser('user-1');

    expect(controller.rows.single.numeroDocumento, 'NF-001');
    expect(controller.page, 1);
    expect(controller.pageSize, 50);
    expect(controller.totalCount, 86);
    expect(controller.rangeStart, 1);
    expect(controller.rangeEnd, 1);
    expect(controller.hasPreviousPage, isFalse);
    expect(controller.hasNextPage, isTrue);

    await controller.showPage(2);

    expect(controller.rows.single.numeroDocumento, 'NF-002');
    expect(controller.page, 2);
    expect(controller.rangeStart, 51);
    expect(controller.hasPreviousPage, isTrue);
    expect(controller.hasNextPage, isFalse);

    await controller.showPage(1);

    expect(controller.rows.single.numeroDocumento, 'NF-001');
    expect(controller.page, 1);
    verify(
      () => repository.loadPage(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: any(named: 'filter'),
        clientToken: 'token-1',
        cancelScope: any(named: 'cancelScope'),
      ),
    ).called(3);
  });

  test('applies the requested launch-date range to a new first page', () async {
    await controller.bindUser('user-1');
    clearInteractions(repository);

    await controller.applyFilters(
      selectedAgentId: 'agent-1',
      dataLancamentoInicio: DateTime(2026, 8, 2, 14),
      dataLancamentoFim: DateTime(2026, 8, 10, 22),
    );

    final filter =
        verify(
              () => repository.loadPage(
                userId: 'user-1',
                agentId: 'agent-1',
                filter: captureAny(named: 'filter'),
                clientToken: 'token-1',
                cancelScope: any(named: 'cancelScope'),
              ),
            ).captured.single
            as NotasEntradaFilter;
    expect(filter.dataLancamentoInicio, DateTime(2026, 8, 2));
    expect(filter.dataLancamentoFim, DateTime(2026, 8, 10));
    expect(filter.page, 1);
    expect(controller.page, 1);
  });

  test('keeps the current page visible while the next page loads', () async {
    await controller.bindUser('user-1');
    final nextPage = Completer<AppResult<NotasEntradaPageResult>>();
    when(
      () => repository.loadPage(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: any(named: 'filter'),
        clientToken: 'token-1',
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer((invocation) async {
      final filter = invocation.namedArguments[#filter] as NotasEntradaFilter;
      if (filter.page == 1) {
        return Success<NotasEntradaPageResult, AppFailure>(_firstPage());
      }
      return nextPage.future;
    });

    final pending = controller.showPage(2);

    expect(controller.isLoading, isTrue);
    expect(controller.showsLoadingSkeleton, isFalse);
    expect(controller.rows.single.numeroDocumento, 'NF-001');

    nextPage.complete(
      Success<NotasEntradaPageResult, AppFailure>(_secondPage()),
    );
    await pending;

    expect(controller.rows.single.numeroDocumento, 'NF-002');
    expect(controller.isLoading, isFalse);
  });

  test('reloads the first page when the page size changes', () async {
    await controller.bindUser('user-1');
    clearInteractions(repository);

    await controller.setPageSize(20);

    final filter =
        verify(
              () => repository.loadPage(
                userId: 'user-1',
                agentId: 'agent-1',
                filter: captureAny(named: 'filter'),
                clientToken: 'token-1',
                cancelScope: any(named: 'cancelScope'),
              ),
            ).captured.single
            as NotasEntradaFilter;
    expect(filter.page, 1);
    expect(filter.pageSize, 20);
    expect(controller.page, 1);
    expect(controller.pageSize, 20);
  });

  test('reloads the first page when the supplier search changes', () async {
    await controller.bindUser('user-1');
    clearInteractions(repository);

    await controller.applySearch('  Mel  ');

    final filter =
        verify(
              () => repository.loadPage(
                userId: 'user-1',
                agentId: 'agent-1',
                filter: captureAny(named: 'filter'),
                clientToken: 'token-1',
                cancelScope: any(named: 'cancelScope'),
              ),
            ).captured.single
            as NotasEntradaFilter;
    expect(filter.searchTerm, 'Mel');
    expect(filter.page, 1);
    expect(controller.searchTerm, 'Mel');
    expect(controller.page, 1);
    verify(
      () => preferences.persistCardFilters(
        SalesNotasEntradaController.cardId,
        any(),
      ),
    ).called(1);
  });

  test('restores a persisted supplier search', () {
    when(
      () => preferences.restoreCardFilters(SalesNotasEntradaController.cardId),
    ).thenReturn(const <String, Object?>{
      'searchTerm': '  Apiário  ',
      'pageSize': 20,
    });
    final restored = SalesNotasEntradaController(
      sessionService: SalesSessionService(preferences),
      loadSalesAvailableAgentsUseCase: loadAgents,
      resolveSalesAgentClientToken: ResolveSalesAgentClientTokenUseCase(
        tokenReader,
      ),
      notasEntradaRepository: repository,
      referenceDate: DateTime(2026, 9, 12),
    );
    addTearDown(restored.dispose);

    expect(restored.searchTerm, 'Apiário');
    expect(restored.pageSize, 20);
  });

  test('does not surface a cancelled query as a load failure', () async {
    when(
      () => repository.loadPage(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: any(named: 'filter'),
        clientToken: 'token-1',
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async => const Failure<NotasEntradaPageResult, AppFailure>(
        OperationCancelledFailure(),
      ),
    );

    await controller.bindUser('user-1');

    expect(controller.loadFailure, isNull);
    expect(controller.rows, isEmpty);
    expect(controller.isLoading, isFalse);
  });
}

NotasEntradaPageResult _firstPage() {
  return NotasEntradaPageResult(
    items: <NotaEntradaRow>[_row(compraId: 2, document: 'NF-001')],
    totalCount: 86,
  );
}

NotasEntradaPageResult _secondPage() {
  return NotasEntradaPageResult(
    items: <NotaEntradaRow>[_row(compraId: 1, document: 'NF-002')],
    totalCount: 86,
  );
}

NotaEntradaRow _row({required int compraId, required String document}) {
  return NotaEntradaRow(
    compraId: compraId,
    codEmpresa: 1,
    codFilial: 1,
    nomeFilial: 'Filial Centro',
    codTipoOperacaoCompra: 1,
    descricaoTipoOperacaoCompra: 'Compra',
    numeroDocumento: document,
    dataLancamento: DateTime(2026, 9, compraId),
    codFornecedor: 8,
    nomeFornecedor: 'Fornecedor Exemplo',
    valorTotalCompra: 100,
  );
}
