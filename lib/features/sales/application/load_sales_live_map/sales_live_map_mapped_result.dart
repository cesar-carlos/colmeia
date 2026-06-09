import 'package:colmeia/features/sales/application/load_sales_live_map/sales_live_map_load_result.dart';

/// Intermediate mapping outcome produced while progressively emitting live map
/// load results. Carries timing splits used by refresh metrics.
class SalesLiveMapMappedResult {
  const SalesLiveMapMappedResult({
    required this.result,
    this.mapDurationMs = 0,
    this.geoDurationMs = 0,
  });

  final SalesLiveMapLoadResult result;
  final int mapDurationMs;
  final int geoDurationMs;
}
