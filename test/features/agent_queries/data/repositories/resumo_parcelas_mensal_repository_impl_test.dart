import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_mensal_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late ResumoParcelasMensalRepositoryImpl repository;

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
    repository = ResumoParcelasMensalRepositoryImpl(
      agentQueriesRepository,
    );
  });

  test('returns validation failure when date range is invalid', () async {
    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime.utc(2026, 4, 30),
        dataVendaFim: DateTime.utc(2026, 4),
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test('builds request and maps rows for the report query', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 6,
              'Ano': 2026,
              'Mes': 4,
              'QtdVendas': 42,
              'ValorParcela': 1250.5,
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.load(
      userId: 'user-1',
      agentId: ' agent-1 ',
      clientToken: ' token-123 ',
      filter: ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );

    check(result.isSuccess()).isTrue();
    final rows = result.getOrNull()!;
    check(rows).has((it) => it.length, 'length').equals(1);
    check(rows.single.codEmpresa).equals(1);
    check(rows.single.codFilial).equals(6);
    check(rows.single.ano).equals(2026);
    check(rows.single.mes).equals(4);
    check(rows.single.anoMes).equals('2026/04');
    check(rows.single.qtdVendas).equals(42);
    check(rows.single.valorParcela).equals(1250.5);

    final capturedRequest =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(capturedRequest.trimmedAgentId).equals('agent-1');
    check(capturedRequest.trimmedClientToken).equals('token-123');
    check(capturedRequest.bridgeTimeoutMs).equals(240000);
    check(capturedRequest.executeOptions!.executionMode?.name).equals(
      'preserve',
    );
    check(capturedRequest.executeOptions!.maxRows).equals(8000);
    check(capturedRequest.namedParams['dataVendaInicio']).equals('2026-01-01');
    check(capturedRequest.namedParams['dataVendaFim']).equals('2026-12-31');
    check(capturedRequest.namedParams['origem']).equals('FrenteLoja');
    check(capturedRequest.namedParams['geraFinanceiro']).equals('S');
    check(capturedRequest.namedParams['preVenda']).equals('N');
    check(capturedRequest.namedParams['codEmpresa']).isNull();
    check(capturedRequest.namedParams['codFilial']).isNull();
    check(capturedRequest.namedParams['codVendedor']).isNull();
    check(capturedRequest.namedParams.length).equals(5);
    check(capturedRequest.sql).contains('ResumoParcelasMensal');
    expect(capturedRequest.sql, isNot(contains(':codEmpresa')));
    check(capturedRequest.sql).contains(':dataVendaInicio');
    check(capturedRequest.sql.contains(':codEmpresa')).isFalse();
  });

  test('inlines dimension filters in SQL when dimension filters are set', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
        codEmpresa: 9,
        codFilial: 2,
      ),
    );

    final capturedRequest =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(capturedRequest.namedParams.length).equals(5);
    expect(capturedRequest.sql, isNot(contains(':codEmpresa')));
    check(capturedRequest.sql).contains('AND CodEmpresa = 9');
    check(capturedRequest.sql).contains('AND CodFilial = 2');
  });

  test('maps row when bridge uses camelCase keys', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'codEmpresa': 1,
              'codFilial': 2,
              'ano': 2025,
              'mes': 8,
              'qtdVendas': 1,
              'valorParcela': 10,
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime.utc(2025),
        dataVendaFim: DateTime.utc(2025, 12, 31),
      ),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrNull()!.single.ano).equals(2025);
    check(result.getOrNull()!.single.mes).equals(8);
    check(result.getOrNull()!.single.anoMes).equals('2025/08');
    check(result.getOrNull()!.single.valorParcela).equals(10);
  });

  test('returns UnknownFailure when row mapping fails', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{'Ano': 2026, 'Mes': 1},
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<UnknownFailure>();
  });

  test('returns UnknownFailure when Mes is out of range for label', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 1,
              'Ano': 2026,
              'Mes': 13,
              'QtdVendas': 1,
              'ValorParcela': 1.0,
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoParcelasMensalFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<UnknownFailure>();
  });
}
