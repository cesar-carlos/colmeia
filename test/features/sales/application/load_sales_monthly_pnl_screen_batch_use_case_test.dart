import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_lucratividade_mensal_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_total_diario_vendas_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:colmeia/features/sales/application/load_sales_monthly_pnl_screen_batch_use_case.dart';
import 'package:colmeia/features/sales/data/sales_monthly_pnl_batch_command_builder.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository repository;
  late LoadSalesMonthlyPnlScreenBatchUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteBatchRequest(
        agentId: 'agent-1',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
      ),
    );
  });

  setUp(() {
    repository = _MockAgentQueriesRepository();
    useCase = LoadSalesMonthlyPnlScreenBatchUseCase(repository);
  });

  test('command builder emits monthly then daily with shared date binds', () {
    final batch = SalesMonthlyPnlBatchCommandBuilder.build(
      monthlyFilter: ResumoProdutoVendaLucratividadeMensalFilter(
        dataVendaInicio: DateTime(2025, 8),
        dataVendaFim: DateTime(2026, 7, 31),
      ),
      dailyFilter: ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 7),
        dataVendaFim: DateTime(2026, 7, 31),
      ),
    );

    check(batch.commands.length).equals(2);
    check(batch.indexes.monthlyPnl).equals(0);
    check(batch.indexes.dailyTotals).equals(1);
    check(batch.commands[0].sql).equals(
      ResumoProdutoVendaLucratividadeMensalSql.query,
    );
    check(batch.commands[1].sql).equals(ResumoTotalDiarioVendasSql.query);
    check(batch.commands[0].namedParams['origem']).equals('FrenteLoja');
    check(batch.commands[1].namedParams['geraFinanceiro']).equals('S');
  });

  test('buildMonthlyOnly emits a single monthly command', () {
    final batch = SalesMonthlyPnlBatchCommandBuilder.buildMonthlyOnly(
      monthlyFilter: ResumoProdutoVendaLucratividadeMensalFilter(
        dataVendaInicio: DateTime(2025, 8),
        dataVendaFim: DateTime(2026, 7, 31),
      ),
    );

    check(batch.commands.length).equals(1);
    check(batch.indexes.monthlyPnl).equals(0);
    check(batch.indexes.dailyTotals).equals(-1);
    check(batch.commands.single.sql).equals(
      ResumoProdutoVendaLucratividadeMensalSql.query,
    );
  });

  test('executeSqlBatch once and maps both chart payloads', () async {
    when(
      () => repository.executeSqlBatch(
        any(),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer(
      (_) async => const Success<AgentSqlBatchExecutionResult, AppFailure>(
        AgentSqlBatchExecutionResult(
          totalCommands: 2,
          successfulCommands: 2,
          failedCommands: 0,
          items: <AgentSqlBatchExecutionItem>[
            AgentSqlBatchExecutionItem(
              index: 0,
              ok: true,
              rowCount: 1,
              rows: <Map<String, dynamic>>[
                <String, dynamic>{
                  'CodEmpresa': 1,
                  'CodFilial': 1,
                  'Ano': 2026,
                  'Mes': 7,
                  'AnoMes': '2026/07',
                  'QtdVendas': 2,
                  'QtdItensVendido': 2.0,
                  'ValorTotalCustoMedio': 0.0,
                  'CustoReposicao': 40.0,
                  'PontoEquilibrio': 0.0,
                  'ValorTotalItem': 100.0,
                },
              ],
            ),
            AgentSqlBatchExecutionItem(
              index: 1,
              ok: true,
              rowCount: 1,
              rows: <Map<String, dynamic>>[
                <String, dynamic>{
                  'CodEmpresa': 1,
                  'CodFilial': 1,
                  'DataVenda': '2026-07-15',
                  'QtdVendas': 1,
                  'ValorTotalDiarioVenda': 55.0,
                },
              ],
            ),
          ],
        ),
      ),
    );

    final result = await useCase(
      userId: 'user-1',
      agentId: 'agent-1',
      anchor: const DashboardYearMonth(year: 2026, month: 7),
      clientToken: 'token-1',
    );

    verify(
      () => repository.executeSqlBatch(
        any(),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).called(1);

    check(result.monthlyLoadFailed).isFalse();
    check(result.dailyLoadFailed).isFalse();
    check(result.monthlyPoints.length).equals(12);
    final july = result.monthlyPoints.singleWhere(
      (point) => point.anoMes == '2026/07',
    );
    check(july.venda).equals(100);
    check(july.lucro).equals(60);
    check(result.dailyPoints.any((point) => point.salesAmount == 55)).isTrue();
  });

  test('empty monthly retry re-runs monthly slot only and keeps daily', () async {
    var calls = 0;
    when(
      () => repository.executeSqlBatch(
        any(),
        cancelScope: any(named: 'cancelScope'),
      ),
    ).thenAnswer((invocation) async {
      calls++;
      final request =
          invocation.positionalArguments.first as AgentSqlExecuteBatchRequest;
      if (calls == 1) {
        check(request.commands.length).equals(2);
        return const Success<AgentSqlBatchExecutionResult, AppFailure>(
          AgentSqlBatchExecutionResult(
            totalCommands: 2,
            successfulCommands: 2,
            failedCommands: 0,
            items: <AgentSqlBatchExecutionItem>[
              AgentSqlBatchExecutionItem(
                index: 0,
                ok: true,
                rowCount: 0,
                rows: <Map<String, dynamic>>[],
              ),
              AgentSqlBatchExecutionItem(
                index: 1,
                ok: true,
                rowCount: 1,
                rows: <Map<String, dynamic>>[
                  <String, dynamic>{
                    'CodEmpresa': 1,
                    'CodFilial': 1,
                    'DataVenda': '2026-07-15',
                    'QtdVendas': 1,
                    'ValorTotalDiarioVenda': 55.0,
                  },
                ],
              ),
            ],
          ),
        );
      }

      check(request.commands.length).equals(1);
      check(
        request.commands.single.sql,
      ).equals(ResumoProdutoVendaLucratividadeMensalSql.query);
      return const Success<AgentSqlBatchExecutionResult, AppFailure>(
        AgentSqlBatchExecutionResult(
          totalCommands: 1,
          successfulCommands: 1,
          failedCommands: 0,
          items: <AgentSqlBatchExecutionItem>[
            AgentSqlBatchExecutionItem(
              index: 0,
              ok: true,
              rowCount: 1,
              rows: <Map<String, dynamic>>[
                <String, dynamic>{
                  'CodEmpresa': 1,
                  'CodFilial': 1,
                  'Ano': 2026,
                  'Mes': 7,
                  'AnoMes': '2026/07',
                  'QtdVendas': 2,
                  'QtdItensVendido': 2.0,
                  'ValorTotalCustoMedio': 0.0,
                  'CustoReposicao': 40.0,
                  'PontoEquilibrio': 0.0,
                  'ValorTotalItem': 100.0,
                },
              ],
            ),
          ],
        ),
      );
    });

    final result = await useCase(
      userId: 'user-1',
      agentId: 'agent-1',
      anchor: const DashboardYearMonth(year: 2026, month: 7),
      clientToken: 'token-1',
    );

    check(calls).equals(2);
    check(result.monthlyLoadFailed).isFalse();
    check(result.dailyLoadFailed).isFalse();
    check(result.monthlyPoints.any((point) => point.anoMes == '2026/07')).isTrue();
    check(result.dailyPoints.any((point) => point.salesAmount == 55)).isTrue();
  });
}
