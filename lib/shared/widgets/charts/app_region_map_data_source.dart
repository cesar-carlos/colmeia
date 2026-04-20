import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';

/// Query context consumed by generic map data sources.
class AppRegionMapDataQuery<TFilters> {
  const AppRegionMapDataQuery({
    required this.drillLevel,
    required this.filters,
    this.focusedRegionKey,
    this.selectedMetricKey,
  });

  final AppMapDrillLevel drillLevel;

  /// Region or scope key in focus when drilled below national view.
  ///
  /// Alias: [scopeKey]. Matches [AppRegionMapDataSnapshot.activeScopeKey].
  final String? focusedRegionKey;
  final TFilters filters;
  final String? selectedMetricKey;
}

/// Same as [AppRegionMapDataQuery.focusedRegionKey] (snapshot: activeScopeKey).
extension AppRegionMapDataQueryScopeX<TFilters>
    on AppRegionMapDataQuery<TFilters> {
  String? get scopeKey => focusedRegionKey;
}

/// Snapshot returned by generic map data sources for the current view state.
class AppRegionMapDataSnapshot<TItem> {
  const AppRegionMapDataSnapshot({
    required this.items,
    required this.mapDefinition,
    required this.metrics,
    required this.scopeLabel,
    this.selectedMetricKey,
    this.activeScopeKey,
    this.availableScopes = const <AppMapScopeOption>[],
    this.preferredViewport,
    this.loadedAt,
    this.isStale = false,
    this.emptyHint,
    this.points = const <AppMapPoint>[],
  });

  final List<TItem> items;
  final AppMapDefinition mapDefinition;
  final List<AppMapMetric<TItem>> metrics;
  final String scopeLabel;

  /// Suggested metric from the server; the user may still override in the UI.
  final String? selectedMetricKey;
  final String? activeScopeKey;
  final List<AppMapScopeOption> availableScopes;
  final AppMapViewport? preferredViewport;

  /// When the snapshot was produced (client or server clock).
  final DateTime? loadedAt;

  /// When true, UI may nudge refresh (e.g. stale cache or old period).
  final bool isStale;

  /// Optional hint when [items] is empty (e.g. filters, permissions).
  final String? emptyHint;

  /// Geographic markers overlaid on top of region shapes (lat/lng pins).
  /// Empty by default; populate when the data source resolves coordinate
  /// data (stores, agencies, events).
  final List<AppMapPoint> points;
}

/// Generic data source contract used by map explorers.
// ignore: one_member_abstracts
abstract interface class AppRegionMapDataSource<TItem, TFilters> {
  Future<AppResult<AppRegionMapDataSnapshot<TItem>>> load(
    AppRegionMapDataQuery<TFilters> query,
  );
}
