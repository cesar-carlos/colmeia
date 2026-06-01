import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_repository_impl_v2.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter_v2.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late ResumoParcelaFormaPagamentoRepositoryImplV2 repository;

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
    repository = ResumoParcelaFormaPagamentoRepositoryImplV2(
      agentQueriesRepository,
    );
  });

  test('should return validation failure when date range is invalid', () async {
    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoParcelaFormaPagamentoFilterV2(
        dataVendaInicio: DateTime.utc(2026, 4, 30),
        dataVendaFim: DateTime.utc(2026, 4),
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test('should build request and map rows for the V2 report query', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 2,
              'CodFormaPagamento': 'PIX',
              'DescricaoFormaPagamento': 'Pix',
              'QtdVendas': 3,
              'ValorParcela': 155.75,
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
      filter: ResumoParcelaFormaPagamentoFilterV2(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
      ),
    );

    check(result.isSuccess()).isTrue();
    final rows = result.getOrNull()!;
    check(rows).has((it) => it.length, 'length').equals(1);
    check(rows.single.codEmpresa).equals(1);
    check(rows.single.codFilial).equals(2);
    check(rows.single.codFormaPagamento).equals('PIX');
    check(rows.single.descricaoFormaPagamento).equals('Pix');
    check(rows.single.qtdVendas).equals(3);
    check(rows.single.valorParcela).equals(155.75);

    final capturedRequest =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(capturedRequest.sql).contains('ResumoParcelaFormaPagamentoV2');
    check(capturedRequest.namedParams['dataVendaInicio']).equals('2026-04-01');
    check(capturedRequest.namedParams['dataVendaFim']).equals('2026-04-30');
    final groupByClause = capturedRequest.sql.substring(
      capturedRequest.sql.indexOf('GROUP BY'),
    );
    check(groupByClause).not((it) => it.contains('NomeUsuario'));
    check(groupByClause).not((it) => it.contains('AnoMes'));
  });
}
