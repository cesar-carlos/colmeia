import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_produto_venda_lucratividade_mensal_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_total_diario_vendas_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';

final class SalesMonthlyPnlBatchCommandIndexes {
  const SalesMonthlyPnlBatchCommandIndexes({
    required this.monthlyPnl,
    required this.dailyTotals,
  });

  final int monthlyPnl;
  final int dailyTotals;
}

final class SalesMonthlyPnlBatchCommands {
  const SalesMonthlyPnlBatchCommands({
    required this.commands,
    required this.indexes,
  });

  final List<AgentSqlExecuteBatchCommand> commands;
  final SalesMonthlyPnlBatchCommandIndexes indexes;
}

/// Builds the two read-only SQLs for Resultado mensal in one `sql.executeBatch`.
abstract final class SalesMonthlyPnlBatchCommandBuilder {
  static SalesMonthlyPnlBatchCommands build({
    required ResumoProdutoVendaLucratividadeMensalFilter monthlyFilter,
    required ResumoTotalDiarioVendasFilter dailyFilter,
  }) {
    final commands = <AgentSqlExecuteBatchCommand>[];
    final monthlyPnl = _addMonthlyCommand(commands, monthlyFilter);
    final dailyTotals = _addDailyCommand(commands, dailyFilter);
    return SalesMonthlyPnlBatchCommands(
      commands: commands,
      indexes: SalesMonthlyPnlBatchCommandIndexes(
        monthlyPnl: monthlyPnl,
        dailyTotals: dailyTotals,
      ),
    );
  }

  static int _addMonthlyCommand(
    List<AgentSqlExecuteBatchCommand> commands,
    ResumoProdutoVendaLucratividadeMensalFilter filter,
  ) {
    final index = commands.length;
    commands.add(
      AgentSqlExecuteBatchCommand(
        sql: ResumoProdutoVendaLucratividadeMensalSql.query,
        namedParams: <String, Object?>{
          'dataVendaInicio': AgentQueriesSqlLocalDate.format(
            filter.dataVendaInicio,
          ),
          'dataVendaFim': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
          'origem': filter.trimmedOrigem,
        },
        executionOrder: index,
      ),
    );
    return index;
  }

  static int _addDailyCommand(
    List<AgentSqlExecuteBatchCommand> commands,
    ResumoTotalDiarioVendasFilter filter,
  ) {
    final index = commands.length;
    commands.add(
      AgentSqlExecuteBatchCommand(
        sql: ResumoTotalDiarioVendasSql.query,
        namedParams: <String, Object?>{
          'dataVendaInicio': AgentQueriesSqlLocalDate.format(
            filter.dataVendaInicio,
          ),
          'dataVendaFim': AgentQueriesSqlLocalDate.format(filter.dataVendaFim),
          'origem': filter.trimmedOrigem,
          'geraFinanceiro': filter.trimmedGeraFinanceiro,
          'preVenda': filter.trimmedPreVenda,
        },
        executionOrder: index,
      ),
    );
    return index;
  }
}
