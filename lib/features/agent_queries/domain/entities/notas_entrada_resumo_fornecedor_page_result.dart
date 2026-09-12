import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_resumo_fornecedor_row.dart';

/// One numbered page of supplier totals, with the filtered group totals.
class NotasEntradaResumoFornecedorPageResult {
  const NotasEntradaResumoFornecedorPageResult({
    required this.items,
    required this.totalCount,
    required this.totalValorCompra,
  });

  final List<NotaEntradaResumoFornecedorRow> items;
  final int totalCount;
  final double totalValorCompra;
}
