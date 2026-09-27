import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_item_row.dart';

/// Local filter for entrada-note line items by product name or code.
abstract final class SalesNotasEntradaItensSearch {
  static List<NotaEntradaItemRow> filter(
    List<NotaEntradaItemRow> rows,
    String? term,
  ) {
    final query = term?.trim().toLowerCase();
    if (query == null || query.isEmpty) {
      return rows;
    }
    return rows
        .where(
          (row) =>
              row.nomeProduto.toLowerCase().contains(query) ||
              '${row.codProduto}'.contains(query),
        )
        .toList(growable: false);
  }
}
