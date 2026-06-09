import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/queries/cadastro_filial_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/resumo_total_vendas_municipio_filial_periodo_sql.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';

final class SalesLiveMapBatchCommandIndexes {
  const SalesLiveMapBatchCommandIndexes({
    required this.catalog,
    required this.sales,
  });

  final int catalog;
  final int sales;
}

final class SalesLiveMapBatchCommands {
  const SalesLiveMapBatchCommands({
    required this.commands,
    required this.indexes,
  });

  final List<AgentSqlExecuteBatchCommand> commands;
  final SalesLiveMapBatchCommandIndexes indexes;
}

abstract final class SalesLiveMapBatchCommandBuilder {
  static SalesLiveMapBatchCommands build({
    required CadastroFilialFilter catalogFilter,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter salesFilter,
  }) {
    final commands = <AgentSqlExecuteBatchCommand>[];
    final catalog = _addCatalogCommand(commands, catalogFilter);
    final sales = _addSalesCommand(commands, salesFilter);
    return SalesLiveMapBatchCommands(
      commands: commands,
      indexes: SalesLiveMapBatchCommandIndexes(catalog: catalog, sales: sales),
    );
  }

  static SalesLiveMapBatchCommands buildCatalogOnly({
    required CadastroFilialFilter catalogFilter,
  }) {
    final commands = <AgentSqlExecuteBatchCommand>[];
    final catalog = _addCatalogCommand(commands, catalogFilter);
    return SalesLiveMapBatchCommands(
      commands: commands,
      indexes: SalesLiveMapBatchCommandIndexes(catalog: catalog, sales: -1),
    );
  }

  static int _addCatalogCommand(
    List<AgentSqlExecuteBatchCommand> commands,
    CadastroFilialFilter catalogFilter,
  ) {
    final index = commands.length;
    commands.add(
      AgentSqlExecuteBatchCommand(
        sql: CadastroFilialSql.query(
          branches: catalogFilter.selectedBranches,
          hasSelectedBranches: catalogFilter.hasSelectedBranches,
          codEmpresa: catalogFilter.codEmpresa,
          codFilial: catalogFilter.codFilial,
          projection: catalogFilter.mapCatalogProjection
              ? CadastroFilialSqlProjection.mapCatalog
              : CadastroFilialSqlProjection.registration,
        ),
        namedParams: <String, Object?>{
          'startRow': catalogFilter.startRow,
          'endRow': catalogFilter.endRow,
        },
        executionOrder: index,
      ),
    );
    return index;
  }

  static int _addSalesCommand(
    List<AgentSqlExecuteBatchCommand> commands,
    ResumoTotalVendasMunicipioFilialPeriodoFilter salesFilter,
  ) {
    final index = commands.length;
    commands.add(
      AgentSqlExecuteBatchCommand(
        sql: ResumoTotalVendasMunicipioFilialPeriodoSql.query(
          branches: salesFilter.selectedBranches,
          codEmpresa: salesFilter.codEmpresa,
          codFilial: salesFilter.codFilial,
        ),
        namedParams: <String, Object?>{
          'dataVendaInicio': AgentQueriesSqlLocalDate.format(
            salesFilter.dataVendaInicio,
          ),
          'dataVendaFim': AgentQueriesSqlLocalDate.format(
            salesFilter.dataVendaFim,
          ),
          'origem': salesFilter.trimmedOrigem,
          'geraFinanceiro': salesFilter.trimmedGeraFinanceiro,
          'preVenda': salesFilter.trimmedPreVenda,
        },
        executionOrder: index,
      ),
    );
    return index;
  }
}

extension SalesLiveMapCadastroFilialFilterForAgent on CadastroFilialFilter {
  CadastroFilialFilter forAgent(String agentId) {
    if (!hasSelectedBranches) {
      return this;
    }
    return copyWith(selectedBranches: branchesForAgent(agentId));
  }
}

extension SalesLiveMapSalesFilterForAgent
    on ResumoTotalVendasMunicipioFilialPeriodoFilter {
  ResumoTotalVendasMunicipioFilialPeriodoFilter forAgent(String agentId) {
    if (selectedBranches.isEmpty) {
      return this;
    }
    return ResumoTotalVendasMunicipioFilialPeriodoFilter(
      dataVendaInicio: dataVendaInicio,
      dataVendaFim: dataVendaFim,
      origem: origem,
      geraFinanceiro: geraFinanceiro,
      preVenda: preVenda,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      selectedBranches: branchesForAgent(agentId),
    );
  }
}
