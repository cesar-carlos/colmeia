import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_produto_rank_lucro_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/produto_vendido_produto_rank_lucro_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_produto_rank_lucro_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_sort_direction.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late ProdutoVendidoProdutoRankLucroRepositoryImpl repository;

  final periodStart = DateTime(2026, 3, 10);
  final periodEnd = DateTime(2026, 4, 8);

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
    repository = ProdutoVendidoProdutoRankLucroRepositoryImpl(
      agentQueriesRepository,
    );
  });

  test('returns validation failure when filter is invalid', () async {
    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ProdutoVendidoProdutoRankLucroFilter(
        dataVendaInicio: periodEnd,
        dataVendaFim: periodStart,
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test('returns validation failure when origem is empty', () async {
    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ProdutoVendidoProdutoRankLucroFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
        origem: '   ',
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test('returns empty list when agent returns no rows', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ProdutoVendidoProdutoRankLucroFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow()).isEmpty();
  });

  test(
    'execute sends SQL, dates, options (default sort by quantity DESC)',
    () async {
      when(
        () => agentQueriesRepository.executeSql(any()),
      ).thenAnswer(
        (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
        ),
      );

      await repository.loadAll(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: ProdutoVendidoProdutoRankLucroFilter(
          dataVendaInicio: periodStart,
          dataVendaFim: periodEnd,
        ),
      );

      final captured =
          verify(
                () => agentQueriesRepository.executeSql(captureAny()),
              ).captured.single
              as AgentSqlExecuteRequest;

      check(captured.sql).equals(
        ProdutoVendidoProdutoRankLucroSql.query(
          sortBy: ProdutoVendidoProdutoRankLucroSortBy.qtdItensVendido,
        ),
      );
      check(captured.namedParams['dataVendaInicio']).equals('2026-03-10');
      check(captured.namedParams['dataVendaFim']).equals('2026-04-08');
      check(captured.namedParams['origem']).equals('FrenteLoja');
      check(captured.namedParams.containsKey('startRow')).isFalse();
      check(captured.executeOptions?.maxRows).equals(
        AgentQueriesBoundedResultMaxRows.produtoVendidoProdutoRankLucro,
      );
      check(captured.executeOptions?.sqlTimeoutMs).equals(162000);
      check(captured.executeOptions?.executionMode).equals(
        AgentSqlExecutionMode.preserve,
      );
      check(captured.useRelay).isTrue();
      check(captured.sql).contains('Resultado.QtdItensVendido DESC');
    },
  );

  test(
    'sort by TotalValorLucro ascending uses correct ORDER BY clause',
    () async {
      when(
        () => agentQueriesRepository.executeSql(any()),
      ).thenAnswer(
        (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
        ),
      );

      await repository.loadAll(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: ProdutoVendidoProdutoRankLucroFilter(
          dataVendaInicio: periodStart,
          dataVendaFim: periodEnd,
          sortBy: ProdutoVendidoProdutoRankLucroSortBy.totalValorLucro,
          sortDirection: ResumoProdutoVendaSortDirection.ascending,
        ),
      );

      final captured =
          verify(
                () => agentQueriesRepository.executeSql(captureAny()),
              ).captured.single
              as AgentSqlExecuteRequest;

      check(captured.sql).equals(
        ProdutoVendidoProdutoRankLucroSql.query(
          sortBy: ProdutoVendidoProdutoRankLucroSortBy.totalValorLucro,
          sortDirection: ResumoProdutoVendaSortDirection.ascending,
        ),
      );
      check(captured.sql).contains('Resultado.TotalValorLucro ASC');
    },
  );

  test('custom bridgeTimeoutMs adjusts sql timeout', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ProdutoVendidoProdutoRankLucroFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
      bridgeTimeoutMs: 60000,
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.bridgeTimeoutMs).equals(60000);
    check(captured.executeOptions?.sqlTimeoutMs).equals(54000);
  });

  test('maps rows to entities correctly', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 1,
              'CodProduto': 43171,
              'NomeProduto': 'CAMARA AR 17X 2.50',
              'CodGrupoProduto': 13,
              'NomeGrupoProduto': 'PNEUMATICO',
              'CodMarca': 19,
              'NomeMarca': 'APOLLO',
              'QtdItensVendido': 8619.0,
              'ValorTotal': 100000.5,
              'CustoTotal': 37100.0,
              'LucroUnitario': 7.3008,
              'TotalValorLucro': 62900.5005,
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ProdutoVendidoProdutoRankLucroFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
    );

    check(result.isSuccess()).isTrue();
    final rows = result.getOrThrow();
    check(rows.length).equals(1);
    final row = rows.single;
    check(row.codEmpresa).equals(1);
    check(row.codFilial).equals(1);
    check(row.codProduto).equals(43171);
    check(row.nomeProduto).equals('CAMARA AR 17X 2.50');
    check(row.codGrupoProduto).equals(13);
    check(row.nomeGrupoProduto).equals('PNEUMATICO');
    check(row.codMarca).equals(19);
    check(row.nomeMarca).equals('APOLLO');
    check(row.qtdItensVendido).equals(8619);
    check(row.valorTotal).equals(100000.5);
    check(row.custoTotal).equals(37100);
    check(row.lucroUnitario).equals(7.3008);
    check(row.totalValorLucro).equals(62900.5005);
  });
}
