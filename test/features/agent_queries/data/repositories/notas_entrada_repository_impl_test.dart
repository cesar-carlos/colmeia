import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/queries/notas_entrada_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/notas_entrada_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/resumo_vendas_diarias_suggestion_sql_params.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late NotasEntradaRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteRequest(agentId: 'fallback-agent', sql: 'SELECT 1'),
    );
  });

  setUp(() {
    agentQueriesRepository = _MockAgentQueriesRepository();
    repository = NotasEntradaRepositoryImpl(agentQueriesRepository);
  });

  test(
    'returns validation failure without executing an invalid scope',
    () async {
      final result = await repository.loadPage(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: NotasEntradaFilter(codEmpresa: 0),
      );

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()).isA<ValidationFailure>();
      verifyNever(() => agentQueriesRepository.executeSql(any()));
    },
  );

  test('sends scope, dates, and the numbered page window', () async {
    when(() => agentQueriesRepository.executeSql(any())).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[],
          rowCount: 0,
        ),
      ),
    );

    await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: NotasEntradaFilter(
        dataLancamentoInicio: DateTime(2026, 3, 1, 12),
        dataLancamentoFim: DateTime(2026, 3, 31, 23, 59),
        codEmpresa: 2,
        codFilial: 17,
        page: 2,
        pageSize: 25,
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.sql).equals(
      NotasEntradaSql.pagedQuery(
        hasDataLancamentoInicio: true,
        hasDataLancamentoFim: true,
      ),
    );
    check(captured.namedParams['codEmpresa']).equals(2);
    check(captured.namedParams['codFilial']).equals(17);
    check(captured.namedParams['dataLancamentoInicio']).equals('2026-03-01');
    check(captured.namedParams['dataLancamentoFim']).equals('2026-03-31');
    check(captured.namedParams['startRow']).equals(26);
    check(captured.namedParams['endRow']).equals(50);
    check(captured.namedParams['nomeFornecedorPattern']).equals(
      ResumoVendasDiariasSuggestionSqlParams.matchAllLikePattern,
    );
    check(captured.namedParams.containsKey('limit')).isFalse();
    check(captured.executeOptions?.maxRows).equals(25);
    check(captured.executeOptions?.executionMode).equals(
      AgentSqlExecutionMode.preserve,
    );
    check(captured.executeOptions?.preferDbStreaming).equals(false);
    check(captured.useRelay).isTrue();
    check(captured.relayMode).equals(AgentSqlRelayMode.unary);
    check(captured.skipTransportCache).isTrue();
  });

  test('maps a numbered page and the catalog total', () async {
    when(() => agentQueriesRepository.executeSql(any())).thenAnswer(
      (_) async => Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            _row(
              compraId: 80,
              dataLancamento: '2026-02-03T10:00:00',
              totalCount: 86,
            ),
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: NotasEntradaFilter(
        dataLancamentoInicio: DateTime(2026, 2),
        dataLancamentoFim: DateTime(2026, 2, 28),
      ),
    );

    check(result.isSuccess()).isTrue();
    final page = result.getOrThrow();
    check(page.items.length).equals(1);
    check(page.items.single.compraId).equals(80);
    check(page.totalCount).equals(86);
  });

  test('maps an empty numbered page from a total-only row', () async {
    when(() => agentQueriesRepository.executeSql(any())).thenAnswer(
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
      filter: NotasEntradaFilter(referenceDate: DateTime(2026, 2, 3)),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow().items).isEmpty();
    check(result.getOrThrow().totalCount).equals(0);
    verify(() => agentQueriesRepository.executeSql(any())).called(1);
  });

  test('omits an unspecified date parameter and predicate', () async {
    when(() => agentQueriesRepository.executeSql(any())).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[],
          rowCount: 0,
        ),
      ),
    );

    await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: NotasEntradaFilter(
        dataLancamentoInicio: DateTime(2026, 2),
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.namedParams.containsKey('dataLancamentoInicio')).isTrue();
    check(captured.namedParams.containsKey('dataLancamentoFim')).isFalse();
    check(captured.sql).equals(
      NotasEntradaSql.pagedQuery(
        hasDataLancamentoInicio: true,
        hasDataLancamentoFim: false,
      ),
    );
  });

  test('binds the supplier search pattern once', () async {
    when(() => agentQueriesRepository.executeSql(any())).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[],
          rowCount: 0,
        ),
      ),
    );

    await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: NotasEntradaFilter(
        dataLancamentoInicio: DateTime(2026, 3),
        dataLancamentoFim: DateTime(2026, 3, 31),
        searchTerm: 'Mel',
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.namedParams['nomeFornecedorPattern']).equals('%Mel%');
    check(captured.sql).contains(':nomeFornecedorPattern');
  });
}

Map<String, dynamic> _row({
  required int compraId,
  required String dataLancamento,
  required int totalCount,
}) {
  return <String, dynamic>{
    'TotalCount': totalCount,
    'CompraId': compraId,
    'CodEmpresa': 1,
    'CodFilial': 1,
    'NomeFilial': 'Matriz',
    'CodTipoOperacaoCompra': 2,
    'DescricaoTipoOperacaoCompra': 'Compra',
    'NumeroDocumento': '100',
    'DataEmissao': '2026-02-01',
    'DataEntrada': '2026-02-02',
    'DataLancamento': dataLancamento,
    'CodFornecedor': 7,
    'NomeFornecedor': 'Fornecedor',
    'ValorTotalCompra': 45.75,
  };
}
