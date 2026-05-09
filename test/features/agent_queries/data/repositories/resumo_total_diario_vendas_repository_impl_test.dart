import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_total_diario_vendas_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late ResumoTotalDiarioVendasRepositoryImpl repository;

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
    repository = ResumoTotalDiarioVendasRepositoryImpl(agentQueriesRepository);
  });

  test('returns validation failure when date range is invalid', () async {
    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoTotalDiarioVendasFilter(
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
              'DataVenda': '2026-04-08',
              'QtdVendas': 5,
              'ValorTotalDiarioVenda': 200.25,
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
      filter: ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );

    check(result.isSuccess()).isTrue();
    final rows = result.getOrNull()!;
    check(rows).has((it) => it.length, 'length').equals(1);
    check(rows.single.codEmpresa).equals(1);
    check(rows.single.codFilial).equals(6);
    check(rows.single.qtdVendas).equals(5);
    check(rows.single.valorTotalDiarioVenda).equals(200.25);

    final capturedRequest =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(capturedRequest.trimmedAgentId).equals('agent-1');
    check(capturedRequest.trimmedClientToken).equals('token-123');
    check(capturedRequest.useRelay).isTrue();
    check(capturedRequest.bridgeTimeoutMs).equals(120000);
    check(capturedRequest.executeOptions!.executionMode?.name).equals(
      'preserve',
    );
    check(capturedRequest.executeOptions!.maxRows).equals(
      AgentQueriesBoundedResultMaxRows.resumoTotalDiarioVendas,
    );
    check(capturedRequest.namedParams['dataVendaInicio']).equals('2026-01-01');
    check(capturedRequest.namedParams['dataVendaFim']).equals('2026-12-31');
    check(capturedRequest.namedParams.length).equals(5);
    check(capturedRequest.sql).contains('ResumoTotalDiarioVendasInner');
    check(capturedRequest.sql).contains(
      'pv.DataVenda >= CAST(:dataVendaInicio AS DATE)',
    );
    check(capturedRequest.sql).contains(
      'DATEADD(day, 1, CAST(:dataVendaFim AS DATE))',
    );
    check(capturedRequest.sql).contains('pv.Origem = :origem');
    check(
      capturedRequest.sql.contains(
        'CAST(pv.DataVenda AS DATE) BETWEEN :dataVendaInicio',
      ),
    ).isFalse();
    check(capturedRequest.sql.contains('WHERE pv.DataVenda BETWEEN')).isFalse();
    expect(capturedRequest.sql, isNot(contains(':codEmpresa')));
  });
}
