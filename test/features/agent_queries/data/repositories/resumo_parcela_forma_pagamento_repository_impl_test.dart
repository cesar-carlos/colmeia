import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_forma_pagamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late ResumoParcelaFormaPagamentoRepositoryImpl repository;

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
    repository = ResumoParcelaFormaPagamentoRepositoryImpl(
      agentQueriesRepository,
    );
  });

  test('should return validation failure when date range is invalid', () async {
    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoParcelaFormaPagamentoFilter(
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
              'AnoDataVenda': 2026,
              'MesDataVenda': 4,
              'AnoMesDataVenda': '2026/04',
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
      filter: ResumoParcelaFormaPagamentoFilter(
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
    check(rows.single.anoDataVenda).equals(2026);
    check(rows.single.mesDataVenda).equals(4);
    check(rows.single.anoMesDataVenda).equals('2026/04');
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
    check(capturedRequest.useRelay).isTrue();
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
      'ResumoParcelaFormaPagamento',
    );
    check(rows.single.isAnoMesConsistentWithParts).isTrue();
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
              'nomeUsuario': 'Caixa 01',
              'anoDataVenda': 2026,
              'mesDataVenda': 4,
              'anoMesDataVenda': '2026/04',
              'codFormaPagamento': 'PIX',
              'descricaoFormaPagamento': 'Pix',
              'qtdVendas': 1,
              'valorParcela': 10.0,
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoParcelaFormaPagamentoFilter(
        dataVendaInicio: DateTime.utc(2026, 4),
        dataVendaFim: DateTime.utc(2026, 4, 30),
      ),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrNull()!.single.codEmpresa).equals(1);
    check(result.getOrNull()!.single.anoMesDataVenda).equals('2026/04');
  });

  test('maps AnoMesDataVenda when bridge sends a number', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 1,
              'NomeUsuario': 'X',
              'AnoDataVenda': 2025,
              'MesDataVenda': 12,
              'AnoMesDataVenda': 202512,
              'CodFormaPagamento': 'A',
              'DescricaoFormaPagamento': 'B',
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
      filter: ResumoParcelaFormaPagamentoFilter(
        dataVendaInicio: DateTime.utc(2025, 12),
        dataVendaFim: DateTime.utc(2025, 12, 31),
      ),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrNull()!.single.anoMesDataVenda).equals('202512');
    check(result.getOrNull()!.single.isAnoMesConsistentWithParts).isFalse();
  });
}
