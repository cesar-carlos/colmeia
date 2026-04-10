import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late ResumoVendasDiariasPorVendedorRepositoryImpl repository;

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
    repository = ResumoVendasDiariasPorVendedorRepositoryImpl(
      agentQueriesRepository,
    );
  });

  test('returns validation failure when date range is invalid', () async {
    final result = await repository.load(
      agentId: 'agent-1',
      filter: ResumoVendasDiariasPorVendedorFilter(
        dataVendaInicio: DateTime.utc(2026, 4, 30),
        dataVendaFim: DateTime.utc(2026, 4),
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test('builds request with optional null named params', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.load(
      agentId: 'agent-1',
      filter: ResumoVendasDiariasPorVendedorFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.namedParams['codVendedor']).isNull();
    check(captured.namedParams['bairro']).isNull();
    check(captured.namedParams['municipio']).isNull();
    check(captured.bridgeTimeoutMs).equals(120000);
    check(captured.executeOptions!.executionMode?.name).equals('preserve');
    check(captured.sql).contains('ResumoVendasDiario');
  });

  test('sends codVendedor bairro municipio when provided', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.load(
      agentId: 'agent-1',
      filter: ResumoVendasDiariasPorVendedorFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
        codVendedor: 7,
        bairro: 'Centro',
        municipio: 'Sao Paulo',
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.namedParams['codVendedor']).equals(7);
    check(captured.namedParams['bairro']).equals('Centro');
    check(captured.namedParams['municipio']).equals('Sao Paulo');
  });

  test('formats date named params as yyyy-MM-dd', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.load(
      agentId: 'agent-1',
      filter: ResumoVendasDiariasPorVendedorFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.namedParams['dataVendaInicio']).equals('2026-04-01');
    check(captured.namedParams['dataVendaFim']).equals('2026-04-30');
  });

  test('returns UnknownFailure when row mapping fails', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{'CodEmpresa': 1},
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.load(
      agentId: 'agent-1',
      filter: ResumoVendasDiariasPorVendedorFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<UnknownFailure>();
  });

  test('maps a valid row', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 2,
              'DataVenda': '2026-04-15',
              'CodVendedor': 3,
              'NomeVendedor': 'Bob',
              'QtdeItens': 2,
              'ValorAcrescimo': 0,
              'ValorDesconto': 0,
              'ValorBruto': 50,
              'ValorLiquido': 50,
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.load(
      agentId: 'agent-1',
      filter: ResumoVendasDiariasPorVendedorFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
      ),
    );

    check(result.isSuccess()).isTrue();
    final row = result.getOrNull()!.single;
    check(row.nomeVendedor).equals('Bob');
    check(row.valorLiquido).equals(50);
  });
}
