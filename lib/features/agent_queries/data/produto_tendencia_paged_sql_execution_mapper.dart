import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';

/// Shared paged-row parsing for product trend SQL repositories.
abstract final class ProdutoTendenciaPagedSqlExecutionMapper {
  static bool rowHasProdutoKey(Map<String, dynamic> row) {
    final raw = AgentQueriesSqlRowMapReader.lookupFirst(
      row,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodProduto'),
    );
    return raw != null;
  }

  static ProdutoTendenciaPagedSqlRows<T> mapPagedRows<T>({
    required AgentSqlExecutionResult executionResult,
    required String operation,
    required String agentId,
    required int sqlMaxRowsCap,
    required T Function(Map<String, dynamic> row) mapRow,
  }) {
    if (executionResult.rows.isEmpty) {
      return ProdutoTendenciaPagedSqlRows<T>(
        items: <T>[],
        totalCount: 0,
      );
    }

    if (executionResult.rows.length >= sqlMaxRowsCap) {
      AppLogger.warning(
        'Agent row count reached max_rows cap (possible truncation)',
        context: <String, Object?>{
          'operation': operation,
          'agentId': agentId,
          'rowCount': executionResult.rows.length,
          'sqlMaxRowsCap': sqlMaxRowsCap,
        },
      );
    }

    final totalCount = AgentQueriesSqlRowMapReader.readRequiredInt(
      executionResult.rows.first,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('TotalCount'),
    );

    final items = executionResult.rows
        .where(rowHasProdutoKey)
        .map(mapRow)
        .toList(growable: false);

    return ProdutoTendenciaPagedSqlRows<T>(
      items: items,
      totalCount: totalCount,
    );
  }
}

class ProdutoTendenciaPagedSqlRows<T> {
  const ProdutoTendenciaPagedSqlRows({
    required this.items,
    required this.totalCount,
  });

  final List<T> items;
  final int totalCount;
}
