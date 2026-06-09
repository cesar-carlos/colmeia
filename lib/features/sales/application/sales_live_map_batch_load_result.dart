import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';

/// SQL commands in the merged sales live map batch (catalog page + period sales).
const int salesLiveMapBatchCommandCount = 2;

final class SalesLiveMapBatchLoadResult {
  const SalesLiveMapBatchLoadResult({
    required this.catalogPage,
    required this.salesReport,
    required this.totalElapsedMs,
    this.isFinal = true,
    this.salesLoadingComplete = true,
  });

  final CadastroFilialAcrossAgentsPageResult catalogPage;
  final AgentQueryExecutionReport<ResumoTotalVendasMunicipioFilialPeriodoRow>
  salesReport;
  final int totalElapsedMs;

  /// When false, more catalog pagination or target waves may still be in flight.
  final bool isFinal;

  /// When false, merged batch first pages are still loading per target wave.
  final bool salesLoadingComplete;
}
