import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';

abstract final class SalesLiveMapBatchLoadConfig {
  static int get bridgeTimeoutMs => AppEnvironment.salesLiveMapBridgeTimeoutMs;

  static int get sqlTimeoutMs => AppEnvironment.salesLiveMapBridgeTimeoutMs;

  static int get batchMaxRows =>
      AgentQueriesBoundedResultMaxRows.resumoTotalVendasMunicipioFilialPeriodo;

  static const int maxAllPagesPerAgent = 400;
}
