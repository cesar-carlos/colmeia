import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';

class ProdutoVendidoTendenciaDeVendaScreenData {
  const ProdutoVendidoTendenciaDeVendaScreenData({
    required this.rows,
    required this.totalCount,
    required this.summaryRows,
    required this.topGainers,
    required this.topLosers,
  });

  final List<ProdutoVendidoTendenciaDeVendaRow> rows;
  final int totalCount;
  final List<ProdutoVendidoTendenciaDeVendaSummaryRow> summaryRows;
  final List<ProdutoVendidoTendenciaDeVendaRow> topGainers;
  final List<ProdutoVendidoTendenciaDeVendaRow> topLosers;
}
