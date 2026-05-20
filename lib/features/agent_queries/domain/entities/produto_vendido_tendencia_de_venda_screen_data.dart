import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_summary_row.dart';

class ProdutoVendidoTendenciaDeVendaScreenData {
  const ProdutoVendidoTendenciaDeVendaScreenData({
    required this.rows,
    required this.summaryRows,
  });

  final List<ProdutoVendidoTendenciaDeVendaRow> rows;
  final List<ProdutoVendidoTendenciaDeVendaSummaryRow> summaryRows;
}
