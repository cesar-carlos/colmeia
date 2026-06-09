import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/sales/application/sales_live_map_batch_load_result.dart';

export 'package:colmeia/features/sales/application/sales_live_map_batch_load_result.dart';

/// Merges catalog and period-sales SQL per agent target for the live map.
abstract interface class SalesLiveMapBatchLoader {
  Future<AppResult<SalesLiveMapBatchLoadResult>> load({
    required String userId,
    required CadastroFilialFilter catalogFilter,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter salesFilter,
    required AgentQueryTargetResolution preResolvedResolution,
    AgentQueriesCancelScope? cancelScope,
    int? bridgeTimeoutMs,
    int? targetWaveConcurrency,
  });

  Stream<AppResult<SalesLiveMapBatchLoadResult>> loadProgressively({
    required String userId,
    required CadastroFilialFilter catalogFilter,
    required ResumoTotalVendasMunicipioFilialPeriodoFilter salesFilter,
    required AgentQueryTargetResolution preResolvedResolution,
    AgentQueriesCancelScope? cancelScope,
    int? bridgeTimeoutMs,
    int? targetWaveConcurrency,
  });
}
