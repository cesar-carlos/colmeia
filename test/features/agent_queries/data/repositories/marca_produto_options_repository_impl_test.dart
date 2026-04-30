import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/queries/marca_produto_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/marca_produto_options_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late MarcaProdutoOptionsRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteRequest(agentId: 'fallback-agent', sql: 'SELECT 1'),
    );
  });

  setUp(() {
    agentQueriesRepository = _MockAgentQueriesRepository();
    repository = MarcaProdutoOptionsRepositoryImpl(agentQueriesRepository);
  });

  test('loadAll sends SQL with expected options', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadAll(userId: 'user-1', agentId: 'agent-1');

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.sql).equals(MarcaProdutoOptionsSql.pagedQuery);
    check(captured.namedParams.keys.toSet()).deepEquals(<String>{
      'startRow',
      'endRow',
      'nomeMarca',
    });
    check(captured.namedParams['startRow']).equals(1);
    check(captured.namedParams['endRow']).equals(20);
    check(captured.namedParams['nomeMarca']).isNull();
    check(captured.bridgeTimeoutMs).equals(120000);
    check(captured.executeOptions?.maxRows).equals(
      45,
    );
    check(captured.useRelay).isTrue();
  });

  test('loadAll maps custom page/pageSize to startRow/endRow', () async {
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
      page: 2,
      pageSize: 30,
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.namedParams['startRow']).equals(31);
    check(captured.namedParams['endRow']).equals(60);
    check(captured.namedParams['nomeMarca']).isNull();
    check(captured.executeOptions?.maxRows).equals(55);
  });

  test('loadAll sends NomeMarca filter as LIKE pattern', () async {
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
      searchTerm: 'smart',
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.namedParams['nomeMarca']).equals('%smart%');
  });

  test('loadAll sends searchTerm as LIKE pattern', () async {
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
      searchTerm: 'fox',
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.namedParams['nomeMarca']).equals('%fox%');
  });

  test('loadAll prioritizes searchTerm over legacy nomeMarca', () async {
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
      searchTerm: 'bosch',
      // Legacy nomeMarca exercises merge priority until migration completes.
      // ignore: deprecated_member_use_from_same_package
      nomeMarca: 'smart',
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.namedParams['nomeMarca']).equals('%bosch%');
  });

  test('loadAll normalizes blank NomeMarca as null', () async {
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
      searchTerm: '   ',
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.namedParams['nomeMarca']).isNull();
  });

  test('returns validation failure when pageSize is invalid', () async {
    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      pageSize: 0,
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test('maps valid rows to entities', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{'CodMarca': 490, 'NomeMarca': 'SMART FOX'},
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow().single.codMarca).equals(490);
    check(result.getOrThrow().single.nomeMarca).equals('SMART FOX');
  });

  test('returns UnknownFailure when row shape is invalid', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{'CodMarca': 1},
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<UnknownFailure>();
  });
}
