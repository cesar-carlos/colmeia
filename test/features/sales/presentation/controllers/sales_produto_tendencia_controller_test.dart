import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_screen_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_screen_data.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_produto_tendencia_controller.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockSalesPreferences extends Mock implements SalesPreferences {}

class _MockAgentClientTokenReader extends Mock
    implements AgentClientTokenReader {}

class _MockLoadAvailableAgentsForSales extends Mock
    implements LoadAvailableAgentsForSales {}

class _MockLoadTrendScreenUseCase extends Mock
    implements LoadProdutoVendidoTendenciaDeVendaScreenUseCase {}

class _MockLoadTrendPageUseCase extends Mock
    implements LoadProdutoVendidoTendenciaDeVendaUseCase {}

void main() {
  late _MockSalesPreferences salesPreferences;
  late _MockAgentClientTokenReader tokenReader;
  late _MockLoadAvailableAgentsForSales loadAgents;
  late _MockLoadTrendScreenUseCase loadTrendScreen;
  late _MockLoadTrendPageUseCase loadTrendPage;
  late SalesProdutoTendenciaController controller;

  const screenData = ProdutoVendidoTendenciaDeVendaScreenData(
    rows: <ProdutoVendidoTendenciaDeVendaRow>[],
    totalCount: 42,
    summaryRows: <ProdutoVendidoTendenciaDeVendaSummaryRow>[],
    topGainers: <ProdutoVendidoTendenciaDeVendaRow>[],
    topLosers: <ProdutoVendidoTendenciaDeVendaRow>[],
  );

  const pageResult = ProdutoVendidoTendenciaDeVendaPageResult(
    items: <ProdutoVendidoTendenciaDeVendaRow>[
      ProdutoVendidoTendenciaDeVendaRow(
        codEmpresa: 1,
        codFilial: 1,
        codProduto: 10,
        nomeProduto: 'Product A',
        codUnidadeMedida: 'UN',
        qtdAnterior: 1,
        qtdAtual: 2,
        diferenca: 1,
        percentualTendencia: 100,
        classificacao: 'CRESCENDO',
      ),
    ],
    totalCount: 42,
  );

  setUpAll(() {
    registerFallbackValue(
      ProdutoVendidoTendenciaDeVendaFilter(
        periodoAtualInicio: DateTime(2026),
        periodoAtualFim: DateTime(2026, 1, 31),
        periodoAnteriorInicio: DateTime(2025, 12),
        periodoAnteriorFim: DateTime(2025, 12, 31),
      ),
    );
  });

  setUp(() {
    salesPreferences = _MockSalesPreferences();
    tokenReader = _MockAgentClientTokenReader();
    loadAgents = _MockLoadAvailableAgentsForSales();
    loadTrendScreen = _MockLoadTrendScreenUseCase();
    loadTrendPage = _MockLoadTrendPageUseCase();
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
    ).thenAnswer((_) async => <String, String>{'agent-1': 'token'});

    when(() => loadAgents.call(any())).thenAnswer(
      (_) async => <DashboardAgentOption>[
        const DashboardAgentOption(agentId: 'agent-1', name: 'Agent One'),
      ],
    );

    when(
      () => loadTrendScreen.call(
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
            screenData,
          ),
    );

    when(
      () => loadTrendPage.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<ProdutoVendidoTendenciaDeVendaPageResult, AppFailure>(
            pageResult,
          ),
    );

    controller = SalesProdutoTendenciaController(
      sessionService: SalesSessionService(salesPreferences),
      loadSalesAvailableAgentsUseCase: loadAgents,
      resolveSalesAgentClientTokenUseCase: ResolveSalesAgentClientTokenUseCase(
        tokenReader,
      ),
      loadTrendScreenUseCase: loadTrendScreen,
      loadTrendPageUseCase: loadTrendPage,
    );
  });

  test('selectPage uses page-only load and keeps summary data', () async {
    await controller.bindUser('user-1');
    verify(
      () => loadTrendScreen.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        pageFilter: any(named: 'pageFilter'),
        summaryFilter: any(named: 'summaryFilter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).called(1);

    clearInteractions(loadTrendScreen);
    clearInteractions(loadTrendPage);

    await controller.selectPage(2);

    verifyNever(
      () => loadTrendScreen.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        pageFilter: any(named: 'pageFilter'),
        summaryFilter: any(named: 'summaryFilter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    );
    final capturedCancelScopes = verify(
      () => loadTrendPage.call(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: any(
          named: 'filter',
          that: predicate<ProdutoVendidoTendenciaDeVendaFilter>(
            (filter) => filter.page == 2,
          ),
        ),
        clientToken: 'token',
        cancelScope: captureAny(named: 'cancelScope'),
      ),
    ).captured;
    expect(capturedCancelScopes, hasLength(1));
    expect(capturedCancelScopes.single, isNotNull);

    expect(controller.state.page, 2);
    expect(controller.state.rows, pageResult.items);
    expect(controller.state.totalCount, pageResult.totalCount);
  });

  test('applyFilters persists grupo and marca display labels', () async {
    await controller.applyFilters(<String, Object?>{
      'agentId': 'agent-1',
      'codGrupoProduto': 10,
      'grupoProdutoLabel': 'Bebidas',
      'codMarca': 42,
      'marcaProdutoLabel': 'Marca X',
    });

    final captured = verify(
      () => salesPreferences.persistCardFilters(
        SalesProdutoTendenciaController.cardFilterId,
        captureAny(),
      ),
    ).captured.last as Map<String, Object?>;

    expect(captured['grupo_produto_label'], 'Bebidas');
    expect(captured['marca_produto_label'], 'Marca X');
    expect(controller.state.grupoProdutoLabel, 'Bebidas');
    expect(controller.state.marcaProdutoLabel, 'Marca X');
  });

  test('restores grupo and marca display labels from persisted filters', () {
    when(() => salesPreferences.restoreCardFilters(any())).thenReturn(
      <String, Object?>{
        'cod_grupo_produto': 10,
        'grupo_produto_label': 'Bebidas',
        'cod_marca': 42,
        'marca_produto_label': 'Marca X',
      },
    );

    final restoredController = SalesProdutoTendenciaController(
      sessionService: SalesSessionService(salesPreferences),
      loadSalesAvailableAgentsUseCase: loadAgents,
      resolveSalesAgentClientTokenUseCase: ResolveSalesAgentClientTokenUseCase(
        tokenReader,
      ),
      loadTrendScreenUseCase: loadTrendScreen,
      loadTrendPageUseCase: loadTrendPage,
    );

    expect(restoredController.state.codGrupoProduto, 10);
    expect(restoredController.state.grupoProdutoLabel, 'Bebidas');
    expect(restoredController.state.codMarca, 42);
    expect(restoredController.state.marcaProdutoLabel, 'Marca X');
  });
}
