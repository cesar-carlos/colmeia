import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';

final class SalesLiveMapBatchTargetResult {
  const SalesLiveMapBatchTargetResult({
    required this.target,
    required this.elapsedMs,
    this.catalogRows = const <CadastroFilialRow>[],
    this.catalogSourceRowCount = 0,
    this.salesRows = const <ResumoTotalVendasMunicipioFilialPeriodoRow>[],
    this.catalogFailure,
    this.salesFailure,
    this.paginationStalled = false,
  });

  final AgentQueryTarget target;
  final int elapsedMs;
  final List<CadastroFilialRow> catalogRows;
  final int catalogSourceRowCount;
  final List<ResumoTotalVendasMunicipioFilialPeriodoRow> salesRows;
  final AppFailure? catalogFailure;
  final AppFailure? salesFailure;
  final bool paginationStalled;

  static bool needsCatalogPagination(SalesLiveMapBatchTargetResult result) {
    return result.catalogFailure == null &&
        result.catalogRows.isNotEmpty &&
        result.catalogRows.length < result.catalogSourceRowCount;
  }
}
