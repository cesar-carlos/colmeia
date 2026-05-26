import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';

/// Breakdown of how each branch coordinate was resolved during a live map
/// load — exposed for logging, e2e assertions, and UI banners that explain
/// "X branches were located via CEP, Y via city/UF, Z remained unresolved".
class SalesLiveMapLocationDiagnostics {
  const SalesLiveMapLocationDiagnostics({
    this.resolvedByProvidedGeoPointCount = 0,
    this.resolvedByIbgeMunicipalityCodeCount = 0,
    this.resolvedByCepCount = 0,
    this.resolvedByCityUfCount = 0,
    this.resolvedByCapitalUfCount = 0,
    this.resolvedByStateUfCount = 0,
    this.unknownResolutionCount = 0,
    this.unresolvedBranchCount = 0,
  });

  factory SalesLiveMapLocationDiagnostics.fromPoints({
    required Iterable<SalesLiveMapPoint> points,
    required int totalBranchCount,
  }) {
    var resolvedByProvidedGeoPointCount = 0;
    var resolvedByIbgeMunicipalityCodeCount = 0;
    var resolvedByCepCount = 0;
    var resolvedByCityUfCount = 0;
    var resolvedByCapitalUfCount = 0;
    var resolvedByStateUfCount = 0;
    var unknownResolutionCount = 0;
    var resolvedPointCount = 0;

    for (final point in points) {
      resolvedPointCount += 1;
      switch (point.locationResolution) {
        case SalesLiveMapLocationResolution.providedGeoPoint:
          resolvedByProvidedGeoPointCount += 1;
        case SalesLiveMapLocationResolution.ibgeMunicipalityCode:
          resolvedByIbgeMunicipalityCodeCount += 1;
        case SalesLiveMapLocationResolution.cep:
          resolvedByCepCount += 1;
        case SalesLiveMapLocationResolution.cityUf:
          resolvedByCityUfCount += 1;
        case SalesLiveMapLocationResolution.capitalUf:
          resolvedByCapitalUfCount += 1;
        case SalesLiveMapLocationResolution.stateUf:
          resolvedByStateUfCount += 1;
        case null:
          unknownResolutionCount += 1;
      }
    }

    return SalesLiveMapLocationDiagnostics(
      resolvedByProvidedGeoPointCount: resolvedByProvidedGeoPointCount,
      resolvedByIbgeMunicipalityCodeCount: resolvedByIbgeMunicipalityCodeCount,
      resolvedByCepCount: resolvedByCepCount,
      resolvedByCityUfCount: resolvedByCityUfCount,
      resolvedByCapitalUfCount: resolvedByCapitalUfCount,
      resolvedByStateUfCount: resolvedByStateUfCount,
      unknownResolutionCount: unknownResolutionCount,
      unresolvedBranchCount: totalBranchCount - resolvedPointCount,
    );
  }

  final int resolvedByProvidedGeoPointCount;
  final int resolvedByIbgeMunicipalityCodeCount;
  final int resolvedByCepCount;
  final int resolvedByCityUfCount;
  final int resolvedByCapitalUfCount;
  final int resolvedByStateUfCount;
  final int unknownResolutionCount;
  final int unresolvedBranchCount;

  bool get hasAnySignal =>
      resolvedByProvidedGeoPointCount > 0 ||
      resolvedByIbgeMunicipalityCodeCount > 0 ||
      resolvedByCepCount > 0 ||
      resolvedByCityUfCount > 0 ||
      resolvedByCapitalUfCount > 0 ||
      resolvedByStateUfCount > 0 ||
      unknownResolutionCount > 0 ||
      unresolvedBranchCount > 0;
}
