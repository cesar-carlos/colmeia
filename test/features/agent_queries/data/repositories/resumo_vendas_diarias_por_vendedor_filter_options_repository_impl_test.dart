import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_bairro_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_municipio_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_vendas_diarias_por_vendedor_vendedor_options_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_filter_options_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/resumo_vendas_diarias_suggestion_sql_params.dart';
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
  late ResumoVendasDiariasPorVendedorFilterOptionsRepositoryImpl repository;

  final dataInicio = DateTime.utc(2026, 4);
  final dataFim = DateTime.utc(2026, 4, 30);

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
    repository = ResumoVendasDiariasPorVendedorFilterOptionsRepositoryImpl(
      agentQueriesRepository,
    );
  });

  test('returns validation failure when date range is inverted', () async {
    final result = await repository.loadVendedorOptions(
      userId: 'user-1',
      agentId: 'agent-1',
      dataVendaInicio: dataFim,
      dataVendaFim: dataInicio,
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test(
    'loadVendedorOptions sends exact namedParams and vendedor SQL',
    () async {
      when(
        () => agentQueriesRepository.executeSql(any()),
      ).thenAnswer(
        (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
        ),
      );

      await repository.loadVendedorOptions(
        userId: 'user-1',
        agentId: 'agent-1',
        dataVendaInicio: dataInicio,
        dataVendaFim: dataFim,
      );

      final captured =
          verify(
                () => agentQueriesRepository.executeSql(captureAny()),
              ).captured.single
              as AgentSqlExecuteRequest;
      check(captured.namedParams.keys.toSet()).deepEquals(<String>{
        'searchPattern',
        'limit',
      });
      check(captured.namedParams['searchPattern']).isNull();
      check(captured.namedParams['limit']).equals(20);
      check(captured.bridgeTimeoutMs).equals(120000);
      check(captured.useRelay).isTrue();
      check(captured.executeOptions!.executionMode?.name).equals('preserve');
      check(
        captured.sql,
      ).equals(ResumoVendasDiariasPorVendedorVendedorOptionsSql.query);
    },
  );

  test('maps searchTerm to escaped searchPattern and clamps limit', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadBairroOptions(
      userId: 'user-1',
      agentId: 'agent-1',
      dataVendaInicio: dataInicio,
      dataVendaFim: dataFim,
      searchTerm: 'a_%b',
      limit: 0,
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.namedParams['searchPattern']).equals('a[_][%]b%');
    check(captured.namedParams['limit']).equals(1);
  });

  test(
    'loadBairroOptions sends only searchPattern and limit in namedParams',
    () async {
      when(
        () => agentQueriesRepository.executeSql(any()),
      ).thenAnswer(
        (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
        ),
      );

      await repository.loadBairroOptions(
        userId: 'user-1',
        agentId: 'agent-1',
        dataVendaInicio: dataInicio,
        dataVendaFim: dataFim,
      );

      final captured =
          verify(
                () => agentQueriesRepository.executeSql(captureAny()),
              ).captured.single
              as AgentSqlExecuteRequest;
      check(captured.namedParams.keys.toSet()).deepEquals(<String>{
        'searchPattern',
        'limit',
      });
      check(captured.sql).equals(
        ResumoVendasDiariasPorVendedorBairroOptionsSql.query,
      );
    },
  );

  test(
    'loadMunicipioOptions sends only searchPattern and limit in namedParams',
    () async {
      when(
        () => agentQueriesRepository.executeSql(any()),
      ).thenAnswer(
        (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
        ),
      );

      await repository.loadMunicipioOptions(
        userId: 'user-1',
        agentId: 'agent-1',
        dataVendaInicio: dataInicio,
        dataVendaFim: dataFim,
      );

      final captured =
          verify(
                () => agentQueriesRepository.executeSql(captureAny()),
              ).captured.single
              as AgentSqlExecuteRequest;
      check(captured.namedParams.keys.toSet()).deepEquals(<String>{
        'searchPattern',
        'limit',
      });
      check(captured.sql).equals(
        ResumoVendasDiariasPorVendedorMunicipioOptionsSql.query,
      );
    },
  );

  test('caps limit at maxSuggestionFetchLimit', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadVendedorOptions(
      userId: 'user-1',
      agentId: 'agent-1',
      dataVendaInicio: dataInicio,
      dataVendaFim: dataFim,
      limit: 500,
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.namedParams['limit']).equals(
      ResumoVendasDiariasSuggestionSqlParams.maxSuggestionFetchLimit,
    );
  });

  test('trims searchTerm and treats whitespace-only as null pattern', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadMunicipioOptions(
      userId: 'user-1',
      agentId: 'agent-1',
      dataVendaInicio: dataInicio,
      dataVendaFim: dataFim,
      searchTerm: '   ',
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.namedParams['searchPattern']).isNull();
  });

  test('returns UnknownFailure when row shape is invalid', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{'CodVendedor': 1},
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadVendedorOptions(
      userId: 'user-1',
      agentId: 'agent-1',
      dataVendaInicio: dataInicio,
      dataVendaFim: dataFim,
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<UnknownFailure>();
  });

  test('maps valid vendedor rows', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'CodVendedor': 3,
              'NomeVendedor': 'Lia',
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadVendedorOptions(
      userId: 'user-1',
      agentId: 'agent-1',
      dataVendaInicio: dataInicio,
      dataVendaFim: dataFim,
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow().single.codVendedor).equals(3);
    check(result.getOrThrow().single.nomeVendedor).equals('Lia');
  });
}
