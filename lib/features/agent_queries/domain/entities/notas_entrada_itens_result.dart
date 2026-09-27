import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_item_row.dart';

/// Line items of one entrada note, with a truncation flag when `max_rows` hit.
class NotasEntradaItensResult {
  const NotasEntradaItensResult({
    required this.items,
    required this.isTruncated,
    required this.maxRows,
  });

  final List<NotaEntradaItemRow> items;
  final bool isTruncated;

  /// `max_rows` sent with the query that produced [items].
  final int maxRows;

  String? get compraCancelada {
    if (items.isEmpty) {
      return null;
    }
    return items.first.compraCancelada;
  }

  bool get isCancelled => items.any((row) => row.isCancelled);

  double get totalValorItens {
    var total = 0.0;
    for (final row in items) {
      total += row.valorTotal;
    }
    return total;
  }
}
