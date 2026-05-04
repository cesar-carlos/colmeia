import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_media_movel_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_media_movel_summary_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/produto_vendido_tendencia_de_venda_media_movel_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late ProdutoVendidoTendenciaDeVendaMediaMovelRepositoryImpl repository;

  ProdutoVendidoTendenciaDeVendaMediaMovelFilter buildValidFilter() {
    return const ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
      quantidadeDias: 7,
    );
  }

  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteRequest(
        agentId: 'fallback-agent',
        sql: 'SELECT 1',
      ),
    );
  });

  setUp(() {
    agentQueriesRepository = _MockAgentQueriesRepository();
    repository = ProdutoVendidoTendenciaDeVendaMediaMovelRepositoryImpl(
      agentQueriesRepository,
    );
  });

  test('returns validation failure when quantidadeDias is invalid', () async {
    final result = await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
        quantidadeDias: 0,
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test('total zero returns empty items in one execute', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{'TotalCount': 0},
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: buildValidFilter(),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow().totalCount).equals(0);
    check(result.getOrThrow().items).isEmpty();
  });

  test('execute sends paged SQL, dias, pagination, and options', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
        quantidadeDias: 7,
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.sql).equals(
      ProdutoVendidoTendenciaDeVendaMediaMovelSql.pagedQuery(
        quantidadeDias: 7,
      ),
    );
    check(captured.namedParams['startRow']).equals(1);
    check(captured.namedParams['endRow']).equals(20);
    check(captured.executeOptions?.maxRows).equals(45);
    check(captured.executeOptions?.sqlTimeoutMs).equals(162000);
    check(captured.executeOptions?.executionMode).equals(
      AgentSqlExecutionMode.preserve,
    );
    check(captured.useRelay).isTrue();
  });

  test('custom page and pageSize set startRow and endRow', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
        quantidadeDias: 14,
        page: 3,
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.namedParams['startRow']).equals(41);
    check(captured.namedParams['endRow']).equals(60);
    check(captured.sql).equals(
      ProdutoVendidoTendenciaDeVendaMediaMovelSql.pagedQuery(
        quantidadeDias: 14,
      ),
    );
  });

  test('optional detail filters are inlined into paged SQL', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
        quantidadeDias: 21,
        searchTerm: "fox' prime",
        classificacao: 'crescendo',
        codGrupoProduto: 14,
        codMarca: 490,
        sortBy: ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.diferencaDesc,
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.sql).contains('AND p.CodGrupoProduto = 14');
    check(captured.sql).contains('AND p.CodMarca = 490');
    check(captured.sql).contains("N'%fox'' prime%'");
    check(captured.sql).contains("WHERE Classificacao = N'CRESCENDO'");
    check(captured.sql).contains('f.Diferenca DESC');
    check(captured.namedParams.length).equals(2);
  });

  test('maps rows with CodProduto to entities and totalCount', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'TotalCount': 1,
              'CodEmpresa': 1,
              'CodFilial': 2,
              'CodProduto': 99,
              'NomeProduto': 'Prod A',
              'CodUnidadeMedida': 'UN',
              'CodGrupoProduto': 5,
              'NomeGrupoProduto': 'Grupo',
              'CodMarca': 7,
              'NomeMarca': 'Marca',
              'MediaAtual': '12.5',
              'MediaAnterior': '10.0',
              'Diferenca': '2.5',
              'TendenciaPercentual': '25.0',
              'Classificacao': 'CRESCENDO',
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: buildValidFilter(),
    );

    check(result.isSuccess()).isTrue();
    final page = result.getOrThrow();
    check(page.totalCount).equals(1);
    final row = page.items.single;
    check(row.codProduto).equals(99);
    check(row.mediaAtual).equals(12.5);
    check(row.mediaAnterior).equals(10);
    check(row.diferenca).equals(2.5);
    check(row.tendenciaPercentual).equals(25);
    check(row.classificacao).equals('CRESCENDO');
  });

  test('loadSummary executes summary SQL with bounded options', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadSummary(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const ProdutoVendidoTendenciaDeVendaMediaMovelFilter(
        quantidadeDias: 14,
        classificacao: 'NOVO',
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.sql).equals(
      ProdutoVendidoTendenciaDeVendaMediaMovelSummarySql.query(
        quantidadeDias: 14,
        classificacao: 'NOVO',
      ),
    );
    check(captured.namedParams).isEmpty();
    check(captured.executeOptions?.maxRows).equals(32);
  });

  test('loadSummary maps summary rows to entities', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'Classificacao': 'CAINDO',
              'QuantidadeProdutos': '4',
              'ImpactoLiquido': '-22.5',
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadSummary(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: buildValidFilter(),
    );

    check(result.isSuccess()).isTrue();
    final row = result.getOrThrow().single;
    check(row.classificacao).equals('CAINDO');
    check(row.quantidadeProdutos).equals(4);
    check(row.impactoLiquido).equals(-22.5);
  });
}
