import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_produto_venda_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late ResumoProdutoVendaRepositoryImpl repository;

  final periodStart = DateTime(2026, 3);
  final periodEnd = DateTime(2026, 3, 31);

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
    repository = ResumoProdutoVendaRepositoryImpl(agentQueriesRepository);
  });

  test('returns validation failure when filter is invalid', () async {
    final result = await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoProdutoVendaFilter(
        dataVendaInicio: periodEnd,
        dataVendaFim: periodStart,
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
      filter: ResumoProdutoVendaFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow().totalCount).equals(0);
    check(result.getOrThrow().items).isEmpty();
    verify(() => agentQueriesRepository.executeSql(any())).called(1);
  });

  test('execute sends pagedQuery dates and startRow endRow', () async {
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
      filter: ResumoProdutoVendaFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
        page: 2,
        pageSize: 10,
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.sql).equals(
      ResumoProdutoVendaSql.pagedQuery(
        sortBy: ResumoProdutoVendaSortBy.nomeProduto,
      ),
    );
    check(captured.namedParams['dataVendaInicio']).equals('2026-03-01');
    check(captured.namedParams['dataVendaFim']).equals('2026-03-31');
    check(captured.namedParams['origem']).equals('FrenteLoja');
    check(captured.namedParams['startRow']).equals(11);
    check(captured.namedParams['endRow']).equals(20);
    check(captured.executeOptions?.maxRows).equals(35);
    check(captured.executeOptions?.sqlTimeoutMs).equals(162000);
    check(captured.executeOptions?.executionMode).equals(
      AgentSqlExecutionMode.preserve,
    );
    check(captured.useRelay).isTrue();
  });

  test('execute uses ROW_NUMBER order from filter.sortBy qtdVendas', () async {
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
      filter: ResumoProdutoVendaFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
        sortBy: ResumoProdutoVendaSortBy.qtdVendas,
        sortDirection: ResumoProdutoVendaSortDirection.descending,
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.sql).equals(
      ResumoProdutoVendaSql.pagedQuery(
        sortBy: ResumoProdutoVendaSortBy.qtdVendas,
        sortDirection: ResumoProdutoVendaSortDirection.descending,
      ),
    );
    final numbered = captured.sql.split('Numbered AS (').last;
    final filial = numbered.indexOf('a.CodFilial ASC');
    final qtd = numbered.indexOf('a.QtdVendas DESC');
    check(filial).isLessThan(qtd);
  });

  test('execute uses ROW_NUMBER order from filter.sortBy nomeProduto', () async {
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
      filter: ResumoProdutoVendaFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    final numbered = captured.sql.split('Numbered AS (').last;
    final filial = numbered.indexOf('a.CodFilial ASC');
    final nome = numbered.indexOf('a.NomeProduto ASC');
    check(filial).isLessThan(nome);
  });

  test('execute passes sortDirection to pagedQuery', () async {
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
      filter: ResumoProdutoVendaFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
        sortBy: ResumoProdutoVendaSortBy.codProduto,
        sortDirection: ResumoProdutoVendaSortDirection.descending,
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.sql).equals(
      ResumoProdutoVendaSql.pagedQuery(
        sortBy: ResumoProdutoVendaSortBy.codProduto,
        sortDirection: ResumoProdutoVendaSortDirection.descending,
      ),
    );
    check(captured.sql.contains('a.CodProduto DESC')).isTrue();
  });

  test('maps rows with CodProduto to entities', () async {
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
              'CodGrupoProduto': 5,
              'NomeGrupoProduto': 'Grp',
              'CodMarca': 7,
              'NomeMarca': 'M',
              'CodTipoGrupoProduto': 3,
              'DescricaoTipoGrupoProduto': 'T',
              'QtdVendas': 4,
              'QtdItensVendido': 10.5,
              'ValorTotalCustoMedio': 100.0,
              'CustoReposicao': 80.0,
              'PontoEquilibrio': 0.0,
              'ValorTotalItem': 200.0,
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoProdutoVendaFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
    );

    check(result.isSuccess()).isTrue();
    final page = result.getOrThrow();
    check(page.totalCount).equals(1);
    final row = page.items.single;
    check(row.codProduto).equals(99);
    check(row.nomeProduto).equals('Prod A');
    check(row.qtdVendas).equals(4);
    check(row.qtdItensVendido).equals(10.5);
    check(row.valorTotalCustoMedio).equals(100);
    check(row.valorTotalItem).equals(200);
    // percentualLucro is computed: (custoReposicao / valorTotalItem) * 100 = (80 / 200) * 100 = 40
    check(row.percentualLucro).equals(40);
  });
}
