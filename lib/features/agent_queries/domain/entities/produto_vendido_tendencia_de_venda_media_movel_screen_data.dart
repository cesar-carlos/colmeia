import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_summary_row.dart';

/// Page plus summary rows from a single `sql.executeBatch` on one agent.
class ProdutoVendidoTendenciaDeVendaMediaMovelScreenData {
  const ProdutoVendidoTendenciaDeVendaMediaMovelScreenData({
    required this.page,
    required this.summaryRows,
  });

  final ProdutoVendidoTendenciaDeVendaMediaMovelPageResult page;
  final List<ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow> summaryRows;
}
