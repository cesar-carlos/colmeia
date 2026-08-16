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

const _emptyCatalogSuccess = Success<AgentSqlExecutionResult, AppFailure>(
  AgentSqlExecutionResult(
    rows: <Map<String, dynamic>>[
      <String, dynamic>{'TotalCount': 0},
    ],
    rowCount: 1,
  ),
);

const _emptyPayloadSuccess = Success<AgentSqlExecutionResult, AppFailure>(
  AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
);

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
    repository = CadastroFilialRepositoryImpl(
      agentQueriesRepository,
      emptySuccessRetryDelay: Duration.zero,
    );
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
      (_) async => _emptyCatalogSuccess,
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
    check(captured.relayMode).equals(AgentSqlRelayMode.unary);
    check(captured.executeOptions?.preferDbStreaming).equals(false);
    check(captured.skipTransportCache).isTrue();
  });

  test('map catalog filter uses slim SQL projection', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => _emptyCatalogSuccess,
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

  test(
    'branch options filter uses identity-only SQL without Municipio',
    () async {
      when(
        () => agentQueriesRepository.executeSql(any()),
      ).thenAnswer(
        (_) async => _emptyCatalogSuccess,
      );

      await repository.loadPage(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: const CadastroFilialFilter(branchOptionsProjection: true),
      );

      final captured =
          verify(
                () => agentQueriesRepository.executeSql(captureAny()),
              ).captured.single
              as AgentSqlExecuteRequest;

      check(captured.sql).equals(
        CadastroFilialSql.query(
          projection: CadastroFilialSqlProjection.branchOptions,
        ),
      );
      check(captured.sql).not((it) => it.contains('LEFT JOIN Municipio'));
      check(captured.executeOptions?.preferDbStreaming).equals(false);
    },
  );

  test('builds exact selected-branch SQL for one branch', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => _emptyCatalogSuccess,
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
      (_) async => _emptyCatalogSuccess,
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
      (_) async => _emptyCatalogSuccess,
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
        (_) async => _emptyCatalogSuccess,
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

  test('empty CTE payload retries and maps the second response', () async {
    var calls = 0;
    when(() => agentQueriesRepository.executeSql(any())).thenAnswer((
      _,
    ) async {
      calls += 1;
      if (calls == 1) {
        return _emptyPayloadSuccess;
      }
      return const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'TotalCount': 1,
              'CodEmpresa': 1,
              'CodFilial': 2,
              'NomeFilial': 'Filial',
            },
          ],
          rowCount: 1,
        ),
      );
    });

    final result = await repository.loadPage(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const CadastroFilialFilter(),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow().items.single.codFilial).equals(2);
    verify(() => agentQueriesRepository.executeSql(any())).called(2);
  });

  test(
    'empty CTE payload twice falls back to simple Filial SELECT for pickers',
    () async {
      var calls = 0;
      when(() => agentQueriesRepository.executeSql(any())).thenAnswer((
        _,
      ) async {
        calls += 1;
        if (calls <= 2) {
          return _emptyPayloadSuccess;
        }
        return const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(
            rows: <Map<String, dynamic>>[
              <String, dynamic>{
                'CodEmpresa': 1,
                'CodFilial': 7,
                'NomeFilial': 'Loja',
              },
            ],
            rowCount: 1,
          ),
        );
      });

      final result = await repository.loadPage(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: const CadastroFilialFilter(branchOptionsProjection: true),
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrThrow().items.single.codFilial).equals(7);
      final captured = verify(
        () => agentQueriesRepository.executeSql(captureAny()),
      ).captured;
      check(captured.length).equals(3);
      final fallback = captured[2] as AgentSqlExecuteRequest;
      check(fallback.sql).contains('SELECT TOP');
      check(fallback.sql).not((it) => it.contains('ROW_NUMBER'));
      check(fallback.namedParams).isEmpty();
    },
  );

  test(
    'empty CTE payload twice falls back to simple Filial SELECT for registration',
    () async {
      var calls = 0;
      when(() => agentQueriesRepository.executeSql(any())).thenAnswer((
        _,
      ) async {
        calls += 1;
        if (calls <= 2) {
          return _emptyPayloadSuccess;
        }
        return const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(
            rows: <Map<String, dynamic>>[
              <String, dynamic>{
                'TotalCount': 1,
                'CodEmpresa': 1,
                'CodFilial': 4,
                'NomeFilial': 'Matriz',
              },
            ],
            rowCount: 1,
          ),
        );
      });

      final result = await repository.loadPage(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: const CadastroFilialFilter(),
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrThrow().items.single.codFilial).equals(4);
      check(result.getOrThrow().totalCount).equals(1);
      final captured = verify(
        () => agentQueriesRepository.executeSql(captureAny()),
      ).captured;
      check(captured.length).equals(3);
      final fallback = captured[2] as AgentSqlExecuteRequest;
      check(fallback.sql).contains('SELECT TOP');
      check(fallback.sql).contains('LEFT JOIN Municipio');
      check(fallback.sql).not((it) => it.contains('ROW_NUMBER'));
      check(fallback.namedParams).isEmpty();
    },
  );

  test(
    'empty CTE payload twice plus empty large simple SELECT retries default page size',
    () async {
      var calls = 0;
      when(() => agentQueriesRepository.executeSql(any())).thenAnswer((
        _,
      ) async {
        calls += 1;
        if (calls <= 3) {
          return _emptyPayloadSuccess;
        }
        return const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(
            rows: <Map<String, dynamic>>[
              <String, dynamic>{
                'TotalCount': 2,
                'CodEmpresa': 1,
                'CodFilial': 1,
                'NomeFilial': 'Matriz',
              },
            ],
            rowCount: 1,
          ),
        );
      });

      final result = await repository.loadPage(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: const CadastroFilialFilter(
          pageSize: CadastroFilialFilter.maxPageSize,
        ),
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrThrow().items.single.codFilial).equals(1);
      check(result.getOrThrow().fetchedPageSize).equals(
        CadastroFilialFilter.defaultPageSize,
      );
      final captured = verify(
        () => agentQueriesRepository.executeSql(captureAny()),
      ).captured;
      check(captured.length).equals(4);
      final largeSimple = captured[2] as AgentSqlExecuteRequest;
      final smallSimple = captured[3] as AgentSqlExecuteRequest;
      check(largeSimple.sql).contains('SELECT TOP 500');
      check(smallSimple.sql).contains('SELECT TOP 20');
    },
  );

  test(
    'empty CTE payload twice plus empty simple SELECT is a failure not empty catalog',
    () async {
      when(
        () => agentQueriesRepository.executeSql(any()),
      ).thenAnswer((_) async => _emptyPayloadSuccess);

      final result = await repository.loadPage(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: const CadastroFilialFilter(),
      );

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()).isA<UnknownFailure>();
      verify(() => agentQueriesRepository.executeSql(any())).called(3);
    },
  );
}
