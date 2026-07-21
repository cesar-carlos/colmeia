import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_lucratividade_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_produto_venda_lucratividade_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late ResumoProdutoVendaLucratividadeRepositoryImpl repository;

  final periodStart = DateTime(2026, 3, 10);
  final periodEnd = DateTime(2026, 4, 8);

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
    repository = ResumoProdutoVendaLucratividadeRepositoryImpl(
      agentQueriesRepository,
    );
  });

  test('returns validation failure when filter is invalid', () async {
    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoProdutoVendaLucratividadeFilter(
        dataVendaInicio: periodEnd,
        dataVendaFim: periodStart,
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test('returns validation failure when origem is empty', () async {
    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoProdutoVendaLucratividadeFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
        origem: '   ',
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test('returns empty list when agent returns no rows', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoProdutoVendaLucratividadeFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow()).isEmpty();
    verify(() => agentQueriesRepository.executeSql(any())).called(2);
  });

  test('execute sends correct SQL, dates, and options', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 2,
              'QtdVendas': 1,
              'QtdItensVendido': 1,
              'ValorTotalCustoMedio': 1,
              'CustoReposicao': 1,
              'PontoEquilibrio': 0,
              'ValorTotalItem': 2,
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoProdutoVendaLucratividadeFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.sql).equals(ResumoProdutoVendaLucratividadeSql.query);
    check(captured.namedParams['dataVendaInicio']).equals('2026-03-10');
    check(captured.namedParams['dataVendaFim']).equals('2026-04-08');
    check(captured.namedParams['origem']).equals('FrenteLoja');
    check(captured.namedParams.containsKey('startRow')).isFalse();
    check(captured.executeOptions?.maxRows).equals(
      AgentQueriesBoundedResultMaxRows.resumoProdutoVendaLucratividade,
    );
    check(captured.executeOptions?.sqlTimeoutMs).equals(108000);
    check(captured.executeOptions?.executionMode).equals(
      AgentSqlExecutionMode.preserve,
    );
    check(captured.executeOptions?.preferDbStreaming).equals(false);
    check(captured.useRelay).isTrue();
    check(captured.relayMode).equals(AgentSqlRelayMode.unary);
    check(captured.skipTransportCache).isTrue();
  });

  test('custom bridgeTimeoutMs adjusts sql timeout', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 2,
              'QtdVendas': 1,
              'QtdItensVendido': 1,
              'ValorTotalCustoMedio': 1,
              'CustoReposicao': 1,
              'PontoEquilibrio': 0,
              'ValorTotalItem': 2,
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoProdutoVendaLucratividadeFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
      bridgeTimeoutMs: 60000,
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.bridgeTimeoutMs).equals(60000);
    check(captured.executeOptions?.sqlTimeoutMs).equals(54000);
  });

  test('retries once when first unary response is empty', () async {
    var calls = 0;
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) {
        return const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
        );
      }
      return const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 2,
              'QtdVendas': 42,
              'QtdItensVendido': 150,
              'ValorTotalCustoMedio': 3000,
              'CustoReposicao': 2500,
              'PontoEquilibrio': 0,
              'ValorTotalItem': 5000,
            },
          ],
          rowCount: 1,
        ),
      );
    });

    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoProdutoVendaLucratividadeFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow()).has((it) => it.length, 'length').equals(1);
    verify(() => agentQueriesRepository.executeSql(any())).called(2);
  });

  test('maps rows to entities correctly', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 2,
              'QtdVendas': 42,
              'QtdItensVendido': 150,
              'ValorTotalCustoMedio': 3000,
              'CustoReposicao': 2500,
              'PontoEquilibrio': 0,
              'ValorTotalItem': 5000,
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoProdutoVendaLucratividadeFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
    );

    check(result.isSuccess()).isTrue();
    final rows = result.getOrThrow();
    check(rows.length).equals(1);
    final row = rows.single;
    check(row.codEmpresa).equals(1);
    check(row.codFilial).equals(2);
    check(row.filialLabel).equals('1-2');
    check(row.qtdVendas).equals(42);
    check(row.qtdItensVendido).equals(150);
    check(row.valorTotalCustoMedio).equals(3000);
    check(row.valorTotalItem).equals(5000);
    check(row.percentualCustoSobreVenda).equals(50);
    check(row.margemLucroBrutoPercent).equals(50);
    check(row.markupSobreCustoPercent).equals(100);
  });
}
