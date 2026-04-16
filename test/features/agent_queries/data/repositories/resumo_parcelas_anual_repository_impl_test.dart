import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_anual_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late ResumoParcelasAnualRepositoryImpl repository;

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
    repository = ResumoParcelasAnualRepositoryImpl(
      agentQueriesRepository,
    );
  });

  test('returns validation failure when date range is invalid', () async {
    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoParcelasAnualFilter(
        dataVendaInicio: DateTime.utc(2026, 4, 30),
        dataVendaFim: DateTime.utc(2026, 4),
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  Map<String, dynamic> sampleRowPascal() {
    return <String, dynamic>{
      'CodEmpresa': 1,
      'CodFilial': 6,
      'AnoDataVenda': 2026,
      'QtdVendas': 42,
      'ValorTotalVenda': 1250.5,
    };
  }

  test('builds request and maps rows for the report query', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[sampleRowPascal()],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.load(
      userId: 'user-1',
      agentId: ' agent-1 ',
      clientToken: ' token-123 ',
      filter: ResumoParcelasAnualFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );

    check(result.isSuccess()).isTrue();
    final rows = result.getOrNull()!;
    check(rows).has((it) => it.length, 'length').equals(1);
    final row = rows.single;
    check(row.codEmpresa).equals(1);
    check(row.codFilial).equals(6);
    check(row.anoDataVenda).equals(2026);
    check(row.qtdVendas).equals(42);
    check(row.valorTotalVenda).equals(1250.5);

    final capturedRequest =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(capturedRequest.trimmedAgentId).equals('agent-1');
    check(capturedRequest.trimmedClientToken).equals('token-123');
    check(capturedRequest.bridgeTimeoutMs).equals(120000);
    check(capturedRequest.executeOptions!.executionMode?.name).equals(
      'preserve',
    );
    check(capturedRequest.executeOptions!.maxRows).equals(
      AgentQueriesBoundedResultMaxRows.resumoParcelasAnual,
    );
    check(capturedRequest.namedParams['dataVendaInicio']).equals('2026-01-01');
    check(capturedRequest.namedParams['dataVendaFim']).equals('2026-12-31');
    check(capturedRequest.namedParams['origem']).equals('FrenteLoja');
    check(capturedRequest.namedParams['geraFinanceiro']).equals('S');
    check(capturedRequest.namedParams['preVenda']).equals('N');
    check(capturedRequest.namedParams['codEmpresa']).isNull();
    check(capturedRequest.namedParams['codFilial']).isNull();
    check(capturedRequest.namedParams['codVendedor']).isNull();
    check(capturedRequest.sql).contains('ResumoParcelasAnual');
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
              'codFilial': 1,
              'anoDataVenda': 2025,
              'qtdVendas': 1,
              'valorTotalVenda': 10,
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoParcelasAnualFilter(
        dataVendaInicio: DateTime.utc(2025),
        dataVendaFim: DateTime.utc(2025, 12, 31),
      ),
    );

    check(result.isSuccess()).isTrue();
    final row = result.getOrNull()!.single;
    check(row.anoDataVenda).equals(2025);
    check(row.valorTotalVenda).equals(10);
    check(row.qtdVendas).equals(1);
  });

  test('returns UnknownFailure when row mapping fails', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{'AnoDataVenda': 2026},
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoParcelasAnualFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<UnknownFailure>();
  });
}
