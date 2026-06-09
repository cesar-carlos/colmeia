import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';

/// Paged product sales trend rows with total grouped row count for the UI.
class ProdutoVendidoTendenciaDeVendaPageResult {
  const ProdutoVendidoTendenciaDeVendaPageResult({
    required this.items,
    required this.totalCount,
  });

  final List<ProdutoVendidoTendenciaDeVendaRow> items;
  final int totalCount;
}
