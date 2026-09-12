import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';

/// Catalog-wide count and purchase total from the shared `Tot` CTE.
abstract final class NotasEntradaSqlPageTotals {
  static const int emptyCount = 0;
  static const double emptyValorCompra = 0;

  static int readTotalCount(Map<String, dynamic> row) {
    return AgentQueriesSqlRowMapReader.readRequiredInt(
      row,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('TotalCount'),
    );
  }

  static double readTotalValorCompra(Map<String, dynamic> row) {
    return AgentQueriesSqlRowMapReader.readRequiredDouble(
      row,
      AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('TotalValorCompra'),
    );
  }
}
