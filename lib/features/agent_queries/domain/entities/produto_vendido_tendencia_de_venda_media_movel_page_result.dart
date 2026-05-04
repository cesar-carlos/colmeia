import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_row.dart';

/// Paged moving-average trend rows with total grouped row count for the UI.
class ProdutoVendidoTendenciaDeVendaMediaMovelPageResult {
  const ProdutoVendidoTendenciaDeVendaMediaMovelPageResult({
    required this.items,
    required this.totalCount,
  });

  final List<ProdutoVendidoTendenciaDeVendaMediaMovelRow> items;
  final int totalCount;
}
