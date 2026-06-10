import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_page_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_produto_vendido_tendencia_de_venda_media_movel_screen_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_screen_data.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/sales/application/resolve_sales_agent_client_token_use_case.dart';
import 'package:colmeia/features/sales/application/sales_session_service.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_produto_tendencia_media_movel_controller.dart';
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
    implements LoadProdutoVendidoTendenciaDeVendaMediaMovelScreenUseCase {}

class _MockLoadTrendPageUseCase extends Mock
    implements LoadProdutoVendidoTendenciaDeVendaMediaMovelPageUseCase {}

void main() {
  late _MockSalesPreferences salesPreferences;
  late _MockAgentClientTokenReader tokenReader;
  late _MockLoadAvailableAgentsForSales loadAgents;
  late _MockLoadTrendScreenUseCase loadTrendScreen;
  late _MockLoadTrendPageUseCase loadTrendPage;
  late SalesProdutoTendenciaMediaMovelController controller;

  const summaryRows = <ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow>[];

  const screenData = ProdutoVendidoTendenciaDeVendaMediaMovelScreenData(
    page: ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
      items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[],
      totalCount: 30,
    ),
    summaryRows: summaryRows,
  );

  const pageResult = ProdutoVendidoTendenciaDeVendaMediaMovelPageResult(
    items: <ProdutoVendidoTendenciaDeVendaMediaMovelRow>[
      ProdutoVendidoTendenciaDeVendaMediaMovelRow(
        codEmpresa: 1,
        codFilial: 1,
        codProduto: 7,
        nomeProduto: 'Product B',
        codUnidadeMedida: 'UN',
        mediaAnterior: 1,
        mediaAtual: 3,
        diferenca: 2,
        tendenciaPercentual: 200,
        classificacao: 'CRESCENDO',
      ),
    ],
    totalCount: 30,
  );

  setUpAll(() {
    registerFallbackValue(
      const ProdutoVendidoTendenciaDeVendaMediaMovelFilter(quantidadeDias: 7),
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
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async =>
          const Success<
            ProdutoVendidoTendenciaDeVendaMediaMovelScreenData,
            AppFailure
          >(screenData),
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
          const Success<
            ProdutoVendidoTendenciaDeVendaMediaMovelPageResult,
            AppFailure
          >(pageResult),
    );

    controller = SalesProdutoTendenciaMediaMovelController(
      sessionService: SalesSessionService(salesPreferences),
      loadSalesAvailableAgentsUseCase: loadAgents,
      resolveSalesAgentClientTokenUseCase: ResolveSalesAgentClientTokenUseCase(
        tokenReader,
      ),
      loadTrendScreenUseCase: loadTrendScreen,
      loadTrendPageUseCase: loadTrendPage,
    );
  });

  test('selectPage uses page-only load and keeps summary rows', () async {
    await controller.bindUser('user-1');
    verify(
      () => loadTrendScreen.call(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
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
        filter: any(named: 'filter'),
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
          that: predicate<ProdutoVendidoTendenciaDeVendaMediaMovelFilter>(
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
    expect(controller.state.pageResult.items, pageResult.items);
    expect(controller.state.summaryRows, summaryRows);
  });

  test('shareDetailFilter includes codMarca when set', () async {
    await controller.applyFilters(<String, Object?>{
      'agentId': 'agent-1',
      'quantidadeDias': 7,
      'searchTerm': '',
      'codMarca': 42,
    });

    expect(controller.shareDetailFilter().codMarca, 42);
  });

  test('applyFilters persists grupo and marca display labels', () async {
    await controller.applyFilters(<String, Object?>{
      'agentId': 'agent-1',
      'quantidadeDias': 7,
      'codGrupoProduto': 10,
      'grupoProdutoLabel': 'Bebidas',
      'codMarca': 42,
      'marcaProdutoLabel': 'Marca X',
    });

    final captured =
        verify(
              () => salesPreferences.persistCardFilters(
                SalesProdutoTendenciaMediaMovelController.cardFilterId,
                captureAny(),
              ),
            ).captured.last
            as Map<String, Object?>;

    expect(captured['grupo_produto_label'], 'Bebidas');
    expect(captured['marca_produto_label'], 'Marca X');
    expect(controller.state.grupoProdutoLabel, 'Bebidas');
    expect(controller.state.marcaProdutoLabel, 'Marca X');
  });

  test('restores grupo and marca display labels from persisted filters', () {
    when(() => salesPreferences.restoreCardFilters(any())).thenReturn(
      <String, Object?>{
        'quantidade_dias': 7,
        'cod_grupo_produto': 10,
        'grupo_produto_label': 'Bebidas',
        'cod_marca': 42,
        'marca_produto_label': 'Marca X',
      },
    );

    final restoredController = SalesProdutoTendenciaMediaMovelController(
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
