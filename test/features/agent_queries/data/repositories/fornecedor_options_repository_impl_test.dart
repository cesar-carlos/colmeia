import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/queries/fornecedor_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/fornecedor_options_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/resumo_vendas_diarias_suggestion_sql_params.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/fornecedor_options_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late FornecedorOptionsRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteRequest(agentId: 'fallback-agent', sql: 'SELECT 1'),
    );
  });

  setUp(() {
    agentQueriesRepository = _MockAgentQueriesRepository();
    repository = FornecedorOptionsRepositoryImpl(agentQueriesRepository);
  });

  test('returns validation failure when filter is invalid', () async {
    final result = await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const FornecedorOptionsFilter(page: 0),
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
      filter: const FornecedorOptionsFilter(),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow().totalCount).equals(0);
    check(result.getOrThrow().items).isEmpty();
    verify(() => agentQueriesRepository.executeSql(any())).called(1);
  });

  test('single execute sends paged SQL, search pattern, and relay route',
      () async {
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
      clientToken: 'tok',
      bridgeTimeoutMs: 5000,
      filter: const FornecedorOptionsFilter(
        searchTerm: 'acme',
        page: 2,
        pageSize: 10,
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.sql).equals(FornecedorOptionsSql.pagedQuery);
    check(captured.namedParams.keys.toSet()).deepEquals(<String>{
      'searchPattern',
      'searchDigitsPattern',
      'startRow',
      'endRow',
    });
    check(captured.namedParams['searchDigitsPattern']).isNull();
    check(captured.namedParams['startRow']).equals(11);
    check(captured.namedParams['endRow']).equals(20);
    check(captured.namedParams['searchPattern']).equals(
      ResumoVendasDiariasSuggestionSqlParams.buildSearchPattern('acme'),
    );
    check(captured.clientToken).equals('tok');
    check(captured.bridgeTimeoutMs).equals(5000);
    check(captured.executeOptions?.maxRows).equals(
      AgentQueriesBoundedResultMaxRows.fornecedorOptionsPage,
    );
    check(captured.useRelay).isTrue();
  });

  test('normalizes blank searchTerm as null searchPattern', () async {
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
      filter: const FornecedorOptionsFilter(searchTerm: '   '),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.namedParams['searchPattern']).isNull();
  });

  test('escapes LIKE metacharacters in searchPattern', () async {
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
      filter: const FornecedorOptionsFilter(searchTerm: '10%_a'),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.namedParams['searchPattern']).equals('%10[%][_]a%');
  });

  test('maps valid rows to entities with all columns', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'TotalCount': 1,
              'CodFornecedor': 42,
              'NomeFornecedor': 'ACME LTDA',
              'NomeFantasia': 'ACME',
              'CNPJ_CPF': '12.345.678/0001-90',
              'EMail': 'contato@acme.com',
              'Telefone': '1133334444',
              'Endereco': 'Rua A',
              'NumeroEndereco': '100',
              'Bairro': 'Centro',
              'Complemento': null,
              'CEP': '01000-000',
              'CodMunicipio': 3550308,
              'NomeMunicipio': 'São Paulo',
              'UFMunicipio': 'SP',
              'CodigoIBGE': '3550308',
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const FornecedorOptionsFilter(),
    );

    check(result.isSuccess()).isTrue();
    final page = result.getOrThrow();
    check(page.totalCount).equals(1);
    final item = page.items.single;
    check(item.codFornecedor).equals(42);
    check(item.nomeFornecedor).equals('ACME LTDA');
    check(item.nomeFantasia).equals('ACME');
    check(item.cnpjCpf).equals('12.345.678/0001-90');
    check(item.email).equals('contato@acme.com');
    check(item.complemento).isNull();
    check(item.codigoIbge).equals('3550308');
    check(item.displayLabel).equals('ACME LTDA (ACME · 12.345.678/0001-90)');
  });

  test('returns UnknownFailure when row shape is invalid', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'TotalCount': 1,
              'CodFornecedor': 1,
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const FornecedorOptionsFilter(),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<UnknownFailure>();
  });
}
