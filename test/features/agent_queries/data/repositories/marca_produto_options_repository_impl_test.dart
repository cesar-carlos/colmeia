import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
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
    check(captured.sql).equals(MarcaProdutoOptionsSql.query);
    check(captured.namedParams).isEmpty();
    check(captured.bridgeTimeoutMs).equals(120000);
    check(captured.executeOptions?.maxRows).equals(
      AgentQueriesBoundedResultMaxRows.marcaProdutoOptions,
    );
    check(captured.useRelay).isTrue();
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

    final result = await repository.loadAll(userId: 'user-1', agentId: 'agent-1');

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

    final result = await repository.loadAll(userId: 'user-1', agentId: 'agent-1');

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<UnknownFailure>();
  });
}
