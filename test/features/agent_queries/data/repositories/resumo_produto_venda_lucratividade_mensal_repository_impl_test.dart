import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_lucratividade_mensal_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_produto_venda_lucratividade_mensal_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late ResumoProdutoVendaLucratividadeMensalRepositoryImpl repository;

  final periodStart = DateTime(2026);
  final periodEnd = DateTime(2026, 3, 31);

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
    repository = ResumoProdutoVendaLucratividadeMensalRepositoryImpl(
      agentQueriesRepository,
    );
  });

  test('returns validation failure when filter is invalid', () async {
    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoProdutoVendaLucratividadeMensalFilter(
        dataVendaInicio: periodEnd,
        dataVendaFim: periodStart,
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
      filter: ResumoProdutoVendaLucratividadeMensalFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow()).isEmpty();
  });

  test('execute sends correct SQL, dates, and options', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoProdutoVendaLucratividadeMensalFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.sql).equals(ResumoProdutoVendaLucratividadeMensalSql.query);
    check(captured.namedParams['dataVendaInicio']).equals('2026-01-01');
    check(captured.namedParams['dataVendaFim']).equals('2026-03-31');
    check(captured.namedParams['origem']).equals('FrenteLoja');
    check(captured.namedParams.containsKey('startRow')).isFalse();
    check(captured.executeOptions?.maxRows).equals(
      AgentQueriesBoundedResultMaxRows.resumoProdutoVendaLucratividadeMensal,
    );
    check(captured.executeOptions?.sqlTimeoutMs).equals(108000);
    check(captured.executeOptions?.executionMode).equals(
      AgentSqlExecutionMode.preserve,
    );
    check(captured.useRelay).isTrue();
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
              'Ano': 2026,
              'Mes': 3,
              'AnoMes': '2026/03',
              'QtdVendas': 42,
              'QtdItensVendido': 150,
              'ValorTotalCustoMedio': 3000,
              'CustoReposicao': 2800,
              'PontoEquilibrio': 0,
              'ValorTotalItem': 5000,
              'PercentualLucro': 56,
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ResumoProdutoVendaLucratividadeMensalFilter(
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
    check(row.ano).equals(2026);
    check(row.mes).equals(3);
    check(row.anoMes).equals('2026/03');
    check(row.qtdVendas).equals(42);
    check(row.qtdItensVendido).equals(150);
    check(row.valorTotalCustoMedio).equals(3000);
    check(row.valorTotalItem).equals(5000);
    check(row.percentualLucro).equals(56);
  });
}
