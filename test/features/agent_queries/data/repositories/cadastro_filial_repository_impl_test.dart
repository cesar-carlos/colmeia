import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/queries/cadastro_filial_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/cadastro_filial_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late CadastroFilialRepositoryImpl repository;

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
    repository = CadastroFilialRepositoryImpl(agentQueriesRepository);
  });

  test('returns validation failure when filter is invalid', () async {
    final result = await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const CadastroFilialFilter(codEmpresa: 0),
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
      filter: const CadastroFilialFilter(),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow().totalCount).equals(0);
    check(result.getOrThrow().items).isEmpty();
    verify(() => agentQueriesRepository.executeSql(any())).called(1);
  });

  test('single execute sends paged SQL, filters, and relay route', () async {
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
      filter: const CadastroFilialFilter(
        codEmpresa: 1,
        codFilial: 2,
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
      CadastroFilialSql.query(codEmpresa: 1, codFilial: 2),
    );
    check(captured.sql).contains('f.CodEmpresa = 1');
    check(captured.sql).contains('f.CodFilial = 2');
    check(captured.namedParams['startRow']).equals(11);
    check(captured.namedParams['endRow']).equals(20);
    check(captured.namedParams.containsKey('codEmpresa')).isFalse();
    check(captured.namedParams.containsKey('codFilial')).isFalse();
    check(captured.clientToken).equals('tok');
    check(captured.bridgeTimeoutMs).equals(5000);
    check(captured.useRelay).isTrue();
  });

  test('map catalog filter uses slim SQL projection', () async {
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
      filter: const CadastroFilialFilter(mapCatalogProjection: true),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.sql).equals(
      CadastroFilialSql.query(
        projection: CadastroFilialSqlProjection.mapCatalog,
      ),
    );
    check(captured.sql).not((it) => it.contains('f.CNPJ'));
  });

  test('builds exact selected-branch SQL for one branch', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-a',
      filter: const CadastroFilialFilter(
        selectedBranches: <CadastroFilialBranchRef>[
          CadastroFilialBranchRef(
            agentId: 'agent-a',
            codEmpresa: 1,
            codFilial: 7,
          ),
        ],
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.sql).contains('(f.CodEmpresa = 1 AND f.CodFilial = 7)');
    check(captured.namedParams.keys.toSet()).deepEquals(
      <String>{'startRow', 'endRow'},
    );
  });

  test('builds exact selected-branch SQL with IN for same company', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-a',
      filter: const CadastroFilialFilter(
        selectedBranches: <CadastroFilialBranchRef>[
          CadastroFilialBranchRef(
            agentId: 'agent-a',
            codEmpresa: 1,
            codFilial: 7,
          ),
          CadastroFilialBranchRef(
            agentId: 'agent-a',
            codEmpresa: 1,
            codFilial: 2,
          ),
          CadastroFilialBranchRef(
            agentId: 'agent-b',
            codEmpresa: 5,
            codFilial: 9,
          ),
        ],
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.sql).contains('f.CodFilial IN (2, 7)');
    check(captured.sql).not((it) => it.contains('CodEmpresa = 5'));
  });

  test('builds exact selected-branch SQL across multiple companies', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-a',
      filter: const CadastroFilialFilter(
        selectedBranches: <CadastroFilialBranchRef>[
          CadastroFilialBranchRef(
            agentId: 'agent-a',
            codEmpresa: 1,
            codFilial: 2,
          ),
          CadastroFilialBranchRef(
            agentId: 'agent-a',
            codEmpresa: 3,
            codFilial: 4,
          ),
        ],
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.sql).contains(
      '(f.CodEmpresa = 1 AND f.CodFilial = 2) OR '
      '(f.CodEmpresa = 3 AND f.CodFilial = 4)',
    );
  });

  test(
    'generates AND 1 = 0 when selected branches do not match the agent',
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
        agentId: 'agent-a',
        filter: const CadastroFilialFilter(
          selectedBranches: <CadastroFilialBranchRef>[
            CadastroFilialBranchRef(
              agentId: 'agent-b',
              codEmpresa: 1,
              codFilial: 2,
            ),
          ],
        ),
      );

      final captured =
          verify(
                () => agentQueriesRepository.executeSql(captureAny()),
              ).captured.single
              as AgentSqlExecuteRequest;
      check(captured.sql).contains('AND 1 = 0');
    },
  );

  test('maps branch rows and totalCount', () async {
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
              'NomeFilial': 'Filial',
              'NomeFantasia': 'Fantasia',
              'CEP': '78005-123',
              'NomeMunicipio': ' Cuiaba ',
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const CadastroFilialFilter(),
    );

    check(result.isSuccess()).isTrue();
    final page = result.getOrThrow();
    check(page.totalCount).equals(1);
    final row = page.items.single;
    check(row.nomeFantasia).equals('Fantasia');
    check(row.cep).equals('78005123');
    check(row.nomeMunicipio).equals('Cuiaba');
  });
}
