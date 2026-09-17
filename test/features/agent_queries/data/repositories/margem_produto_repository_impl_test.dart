import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/queries/margem_produto_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/margem_produto_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_by.dart';
import 'package:colmeia/features/agent_queries/domain/entities/margem_produto_sort_direction.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late MargemProdutoRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteRequest(
        agentId: 'fallback-agent',
        sql: 'SELECT 1',
      ),
    );
    registerFallbackValue(AgentQueriesCancelScope());
  });

  setUp(() {
    agentQueriesRepository = _MockAgentQueriesRepository();
    repository = MargemProdutoRepositoryImpl(
      agentQueriesRepository,
      emptySuccessRetryDelay: Duration.zero,
    );
  });

  test('returns validation failure when filter is invalid', () async {
    final result = await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const MargemProdutoFilter(page: 0),
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
      filter: const MargemProdutoFilter(),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow().totalCount).equals(0);
    check(result.getOrThrow().items).isEmpty();
    verify(() => agentQueriesRepository.executeSql(any())).called(1);
  });

  test('execute sends pagedQuery binds and startRow endRow', () async {
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

    await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const MargemProdutoFilter(
        page: 2,
        pageSize: 10,
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.sql).equals(MargemProdutoSql.pagedQuery());
    check(captured.namedParams['codEmpresa']).equals(1);
    check(captured.namedParams['codFilial']).equals(1);
    check(captured.namedParams.containsKey('nomeProdutoPattern')).isFalse();
    check(captured.sql.contains('LIKE')).isFalse();
    check(captured.namedParams['startRow']).equals(11);
    check(captured.namedParams['endRow']).equals(20);
    check(captured.executeOptions?.maxRows).equals(35);
    check(captured.executeOptions?.sqlTimeoutMs).equals(162000);
    check(captured.executeOptions?.executionMode).equals(
      AgentSqlExecutionMode.preserve,
    );
    check(captured.executeOptions?.preferDbStreaming).equals(false);
    check(captured.useRelay).isTrue();
    check(captured.relayMode).equals(AgentSqlRelayMode.unary);
    check(captured.skipTransportCache).isTrue();
  });

  test('execute uses fixed NomeProduto ROW_NUMBER SQL', () async {
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

    await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const MargemProdutoFilter(),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.sql).equals(MargemProdutoSql.pagedQuery());
    check(captured.sql).contains('m.NomeProduto ASC');
    check(captured.sql).contains('m.CodProduto ASC');
  });

  test(
    'execute uses markup DESC ROW_NUMBER when the filter asks for it',
    () async {
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

      const filter = MargemProdutoFilter(
        sortBy: MargemProdutoSortBy.percentualMarkup,
        sortDirection: MargemProdutoSortDirection.descending,
      );
      await repository.loadPage(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: filter,
      );

      final captured =
          verify(
                () => agentQueriesRepository.executeSql(captureAny()),
              ).captured.single
              as AgentSqlExecuteRequest;

      check(captured.sql).equals(
        MargemProdutoSql.pagedQuery(
          sortBy: filter.sortBy,
          sortDirection: filter.sortDirection,
        ),
      );
      check(captured.sql).contains('m.PercentualMarkupCustoCompraProduto DESC');
    },
  );

  test('binds a contains LIKE pattern for product name search', () async {
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

    await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const MargemProdutoFilter(
        searchTerm: '  a%b_c[d  ',
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.sql).equals(MargemProdutoSql.pagedQuery(applySearch: true));
    check(captured.namedParams['nomeProdutoPattern']).equals(
      '%a[%]b[_]c[[]d%',
    );
    check(captured.sql).contains('LIKE');
    check(captured.sql).contains('REPLACE(');
  });

  test('blank product name search omits LIKE pattern bind', () async {
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

    await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const MargemProdutoFilter(
        searchTerm: '   ',
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.sql).equals(MargemProdutoSql.pagedQuery());
    check(captured.namedParams.containsKey('nomeProdutoPattern')).isFalse();
    check(captured.sql.contains('LIKE')).isFalse();
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
              'NomeFilial': 'Loja Centro',
              'NomeFantasiaFilial': 'Centro',
              'CodProduto': 99,
              'NomeProduto': 'Mel 500g',
              'CodGrupoProduto': 5,
              'NomeGrupoProduto': 'Mel',
              'CodMarca': 7,
              'NomeMarca': 'Casa',
              'CustoReposicao': 10.0,
              'PrecoVendaProduto': 25.0,
              'PercentualMarkupCustoCompraProduto': 150.0,
              'MargemLucroProduto': 60.0,
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const MargemProdutoFilter(),
    );

    check(result.isSuccess()).isTrue();
    final page = result.getOrThrow();
    check(page.totalCount).equals(1);
    final row = page.items.single;
    check(row.codProduto).equals(99);
    check(row.nomeProduto).equals('Mel 500g');
    check(row.nomeFilial).equals('Loja Centro');
    check(row.custoReposicao).equals(10);
    check(row.precoVendaProduto).equals(25);
    check(row.percentualMarkupCustoCompraProduto).equals(150);
    check(row.margemLucroProduto).equals(60);
    check(row.markupSobreCustoPercent).equals(150);
    check(row.margemLucroBrutoPercent).equals(60);
  });

  test('maps missing replacement cost as null metrics', () async {
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
              'NomeFilial': 'Loja Centro',
              'CodProduto': 99,
              'NomeProduto': 'Mel 500g',
              'CustoReposicao': null,
              'PrecoVendaProduto': 25.0,
              'PercentualMarkupCustoCompraProduto': null,
              'MargemLucroProduto': null,
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const MargemProdutoFilter(),
    );

    check(result.isSuccess()).isTrue();
    final row = result.getOrThrow().items.single;
    check(row.custoReposicao).isNull();
    check(row.percentualMarkupCustoCompraProduto).isNull();
    check(row.margemLucroProduto).isNull();
    check(row.lucro).isNull();
    check(row.markupSobreCustoPercent).isNull();
    check(row.margemLucroBrutoPercent).isNull();
    check(row.precoVendaProduto).equals(25);
  });

  test('empty payload retries and maps the second response', () async {
    var calls = 0;
    when(() => agentQueriesRepository.executeSql(any())).thenAnswer((
      _,
    ) async {
      calls += 1;
      if (calls == 1) {
        return const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
        );
      }
      return const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'TotalCount': 1,
              'CodEmpresa': 1,
              'CodFilial': 2,
              'NomeFilial': 'Loja Centro',
              'CodProduto': 10,
              'NomeProduto': 'Mel',
              'CustoReposicao': 1.0,
              'PrecoVendaProduto': 2.0,
              'PercentualMarkupCustoCompraProduto': 100.0,
              'MargemLucroProduto': 50.0,
            },
          ],
          rowCount: 1,
        ),
      );
    });

    final result = await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const MargemProdutoFilter(),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow().items.single.codProduto).equals(10);
    verify(() => agentQueriesRepository.executeSql(any())).called(2);
  });

  test(
    'does not retry empty payload when cancel scope is already cancelled',
    () async {
      final cancelScope = AgentQueriesCancelScope();
      when(
        () => agentQueriesRepository.executeSql(
          any(),
          cancelScope: any(named: 'cancelScope'),
        ),
      ).thenAnswer((_) async {
        cancelScope.cancelAll();
        return const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
        );
      });

      final result = await repository.loadPage(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: const MargemProdutoFilter(),
        cancelScope: cancelScope,
      );

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()).isA<OperationCancelledFailure>();
      verify(
        () => agentQueriesRepository.executeSql(
          any(),
          cancelScope: any(named: 'cancelScope'),
        ),
      ).called(1);
    },
  );

  test('empty payload twice is a failure not empty catalog', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    final result = await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const MargemProdutoFilter(),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<UnknownFailure>();
    verify(() => agentQueriesRepository.executeSql(any())).called(2);
  });
}
