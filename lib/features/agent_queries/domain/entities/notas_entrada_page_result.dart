import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';

/// One numbered page of entrada notes, with the filtered catalog totals.
class NotasEntradaPageResult {
  const NotasEntradaPageResult({
    required this.items,
    required this.totalCount,
    required this.totalValorCompra,
  });

  final List<NotaEntradaRow> items;
  final int totalCount;
  final double totalValorCompra;
}
