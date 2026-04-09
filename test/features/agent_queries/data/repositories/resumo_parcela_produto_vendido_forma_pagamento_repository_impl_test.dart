import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_produto_vendido_forma_pagamento_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_produto_vendido_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late ResumoParcelaProdutoVendidoFormaPagamentoRepositoryImpl repository;

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
    repository = ResumoParcelaProdutoVendidoFormaPagamentoRepositoryImpl(
      agentQueriesRepository,
    );
  });

  test('should return validation failure when date range is invalid', () async {
    final result = await repository.load(
      agentId: 'agent-1',
      filter: ResumoParcelaProdutoVendidoFormaPagamentoFilter(
        dataVendaInicio: DateTime.utc(2026, 4, 30),
        dataVendaFim: DateTime.utc(2026, 4),
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    check(result.exceptionOrNull()?.displayMessage).equals(
      'Os filtros da consulta sao invalidos.',
    );
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test('should build request and map rows for the report query', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 2,
              'NomeUsuario': 'Caixa 01',
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
      agentId: ' agent-1 ',
      clientToken: ' token-123 ',
      filter: ResumoParcelaProdutoVendidoFormaPagamentoFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
      ),
    );

    check(result.isSuccess()).isTrue();
    final rows = result.getOrNull()!;
    check(rows).has((it) => it.length, 'length').equals(1);
    check(rows.single.codEmpresa).equals(1);
    check(rows.single.codFilial).equals(2);
    check(rows.single.nomeUsuario).equals('Caixa 01');
    check(rows.single.codFormaPagamento).equals('PIX');
    check(rows.single.descricaoFormaPagamento).equals('Pix');
    check(rows.single.qtdVendas).equals(3);
    check(rows.single.valorParcela).equals(155.75);

    final capturedRequest =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(capturedRequest.trimmedAgentId).equals('agent-1');
    check(capturedRequest.trimmedClientToken).equals('token-123');
    check(capturedRequest.bridgeTimeoutMs).equals(120000);
    check(capturedRequest.executeOptions).isNotNull();
    check(capturedRequest.executeOptions!.executionMode?.name).equals(
      'preserve',
    );
    check(capturedRequest.namedParams['dataVendaInicio']).equals('2026-04-01');
    check(capturedRequest.namedParams['dataVendaFim']).equals('2026-04-30');
    check(capturedRequest.namedParams['origem']).equals('FrenteLoja');
    check(capturedRequest.namedParams['geraFinanceiro']).equals('S');
    check(capturedRequest.namedParams['preVenda']).equals('N');
    check(capturedRequest.sql).contains(
      'ResumoParcelaProdutoVendidoFormaPagamento',
    );
  });
}
