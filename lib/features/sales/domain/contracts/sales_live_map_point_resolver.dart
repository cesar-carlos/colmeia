import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';

abstract class SalesLiveMapPointResolver {
  Future<SalesLiveMapPoint?> resolve(
    SalesLiveMapPointSource source,
  );

  Future<SalesLiveMapResolvedPoint?> resolveWithDetails(
    SalesLiveMapPointSource source,
  );

  Future<List<SalesLiveMapPoint>> resolveAll(
    Iterable<SalesLiveMapPointSource> sources,
  );

  Future<List<SalesLiveMapResolvedPoint>> resolveAllWithDetails(
    Iterable<SalesLiveMapPointSource> sources, {
    int maxConcurrent = 1,
  });
}
