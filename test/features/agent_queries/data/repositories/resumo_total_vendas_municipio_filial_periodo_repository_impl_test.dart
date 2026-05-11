import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_total_vendas_municipio_filial_periodo_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late ResumoTotalVendasMunicipioFilialPeriodoRepositoryImpl repository;

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
    repository = ResumoTotalVendasMunicipioFilialPeriodoRepositoryImpl(
      agentQueriesRepository,
    );
  });

  test('returns validation failure when date range is invalid', () async {
    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoTotalVendasMunicipioFilialPeriodoFilter(
        dataVendaInicio: DateTime.utc(2026, 4, 30),
        dataVendaFim: DateTime.utc(2026, 4),
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test('builds request and maps rows for the period query', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 6,
              'NomeFilial': 'Filial Centro',
              'NomeFantasiaFilial': 'Fantasia',
              'CEPFilial': '01310100',
              'CodMunicipioFilial': 3550308,
              'NomeMunicipioFilial': 'Sao Paulo',
              'UFMunicipioFilial': 'SP',
              'CodigoIBGEMunicipioFilial': '3550308',
              'QtdVendas': 5,
              'TotalVenda': 200.25,
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
      filter: ResumoTotalVendasMunicipioFilialPeriodoFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );

    check(result.isSuccess()).isTrue();
    final loadedRows = result.getOrNull()!;
    check(loadedRows.sourceRowCount).equals(1);
    final rows = loadedRows.rows;
    check(rows).has((it) => it.length, 'length').equals(1);
    final row = rows.single;
    check(row.codEmpresa).equals(1);
    check(row.codFilial).equals(6);
    check(row.nomeFilial).equals('Filial Centro');
    check(row.nomeFantasiaFilial).equals('Fantasia');
    check(row.cepFilial).equals('01310100');
    check(row.codMunicipioFilial).equals(3550308);
    check(row.nomeMunicipioFilial).equals('Sao Paulo');
    check(row.ufMunicipioFilial).equals('SP');
    check(row.codigoIbgeMunicipioFilial).equals('3550308');
    check(row.qtdVendas).equals(5);
    check(row.totalVenda).equals(200.25);

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
      AgentQueriesBoundedResultMaxRows.resumoTotalVendasMunicipioFilialPeriodo,
    );
    check(capturedRequest.namedParams['dataVendaInicio']).equals('2026-01-01');
    check(capturedRequest.namedParams['dataVendaFim']).equals('2026-12-31');
    check(capturedRequest.namedParams.length).equals(5);
    check(capturedRequest.sql).contains(
      'pv.DataVenda >= CAST(:dataVendaInicio AS DATE)',
    );
    check(capturedRequest.sql).contains(
      'DATEADD(day, 1, CAST(:dataVendaFim AS DATE))',
    );
    check(capturedRequest.sql).contains('pv.Origem = :origem');
    check(capturedRequest.sql).contains(
      'MAX(mf.CodigoIBGE) AS CodigoIBGEMunicipioFilial',
    );
    check(capturedRequest.sql).contains('LEFT JOIN Municipio mf');
    check(capturedRequest.sql.contains('FROM (')).isFalse();
    check(capturedRequest.sql.contains('DataVenda,')).isFalse();
    check(capturedRequest.sql.contains('ORDER BY')).isFalse();
    check(capturedRequest.sql.contains('INNER JOIN Municipio mc')).isFalse();
    expect(capturedRequest.sql, isNot(contains(':codEmpresa')));
  });

  test('maps sales rows even when branch municipality is missing', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 6,
              'NomeFilial': 'Filial sem municipio',
              'NomeFantasiaFilial': null,
              'CEPFilial': null,
              'CodMunicipioFilial': null,
              'NomeMunicipioFilial': null,
              'UFMunicipioFilial': null,
              'CodigoIBGEMunicipioFilial': null,
              'QtdVendas': 5,
              'TotalVenda': 200.25,
            },
          ],
          rowCount: 12,
        ),
      ),
    );

    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoTotalVendasMunicipioFilialPeriodoFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 12, 31),
      ),
    );

    check(result.isSuccess()).isTrue();
    final loadedRows = result.getOrNull()!;
    check(loadedRows.sourceRowCount).equals(12);
    final row = loadedRows.rows.single;
    check(row.nomeFilial).equals('Filial sem municipio');
    check(row.codMunicipioFilial).isNull();
    check(row.nomeMunicipioFilial).isNull();
    check(row.ufMunicipioFilial).isNull();
    check(row.qtdVendas).equals(5);
    check(row.totalVenda).equals(200.25);
  });
}
