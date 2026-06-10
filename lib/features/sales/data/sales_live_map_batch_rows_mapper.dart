import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_batch_item_rows_mapper.dart';
import 'package:colmeia/features/agent_queries/data/models/cadastro_filial_row_model.dart';
import 'package:colmeia/features/agent_queries/data/models/resumo_total_vendas_municipio_filial_periodo_row_model.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/sales/data/sales_live_map_batch_command_builder.dart';
import 'package:colmeia/features/sales/data/sales_live_map_batch_target_result.dart';

abstract final class SalesLiveMapBatchRowsMapper {
  static const String _operation = 'loadSalesLiveMapBatch';

  static SalesLiveMapBatchTargetResult mapMergedExecution({
    required AgentQueryTarget target,
    required AgentSqlBatchExecutionResult execution,
    required SalesLiveMapBatchCommandIndexes indexes,
  }) {
    final byIndex = <int, AgentSqlBatchExecutionItem>{
      for (final item in execution.items) item.index: item,
    };
    final catalog = mapCatalogExecution(
      execution: execution,
      catalogIndex: indexes.catalog,
    );
    final sales = AgentSqlBatchItemRowsMapper.mapRowsForIndex(
      byIndex,
      indexes.sales,
      (row) => ResumoTotalVendasMunicipioFilialPeriodoRowModel.fromMap(
        row,
      ).toEntity(),
      operation: _operation,
    );
    return SalesLiveMapBatchTargetResult(
      target: target,
      elapsedMs: 0,
      catalogRows: catalog.rows,
      catalogSourceRowCount: catalog.sourceRowCount,
      salesRows: sales.rows,
      catalogFailure: catalog.failure,
      salesFailure: sales.failure,
    );
  }

  static ({
    List<CadastroFilialRow> rows,
    int sourceRowCount,
    AppFailure? failure,
  })
  mapCatalogExecution({
    required AgentSqlBatchExecutionResult execution,
    required int catalogIndex,
  }) {
    final byIndex = <int, AgentSqlBatchExecutionItem>{
      for (final item in execution.items) item.index: item,
    };
    final item = byIndex[catalogIndex];
    if (item == null || !item.ok) {
      final failure = AgentSqlBatchItemRowsMapper.mapRowsForIndex(
        byIndex,
        catalogIndex,
        (row) => CadastroFilialRowModel.fromMap(row).toEntity(),
        operation: _operation,
      ).failure;
      return (
        rows: const <CadastroFilialRow>[],
        sourceRowCount: 0,
        failure: failure,
      );
    }
    final page = mapCatalogPage(item.rows);
    return (
      rows: page.items,
      sourceRowCount: page.totalCount,
      failure: null,
    );
  }

  static CadastroFilialPageResult mapCatalogPage(
    List<Map<String, dynamic>> rows,
  ) {
    if (rows.isEmpty) {
      return const CadastroFilialPageResult(
        items: <CadastroFilialRow>[],
        totalCount: 0,
      );
    }
    final totalCount = AgentQueriesSqlRowMapReader.readRequiredInt(
      rows.first,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('TotalCount'),
    );
    final items = rows
        .where(_rowHasBranchKey)
        .map((row) => CadastroFilialRowModel.fromMap(row).toEntity())
        .toList(growable: false);
    return CadastroFilialPageResult(items: items, totalCount: totalCount);
  }

  static bool _rowHasBranchKey(Map<String, dynamic> row) {
    final raw = AgentQueriesSqlRowMapReader.lookupFirst(
      row,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
    );
    return raw != null;
  }
}
