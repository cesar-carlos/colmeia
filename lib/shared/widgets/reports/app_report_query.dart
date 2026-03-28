import 'package:colmeia/shared/widgets/reports/app_report_models.dart';

/// Immutable snapshot of everything the viewer is currently querying.
///
/// The consumer owns this object and passes updated copies back via
/// AppReportEvents.onQueryChanged when the user interacts with filters,
/// sort, pagination, or column visibility.
class AppReportQuery {
  const AppReportQuery({
    this.filters = const <String, Object?>{},
    this.sorts = const <AppReportSortDescriptor>[],
    this.groups = const <AppReportGroupDescriptor>[],
    this.page = 1,
    this.pageSize = 20,
    this.visibleColumnKeys,
    this.searchTerm,
    this.density = AppReportDensity.comfortable,
  });

  final Map<String, Object?> filters;
  final List<AppReportSortDescriptor> sorts;
  final List<AppReportGroupDescriptor> groups;
  final int page;
  final int pageSize;

  /// When null, all columns marked visible by default on AppReportColumn are
  /// shown.
  final Set<String>? visibleColumnKeys;

  /// Global free-text search term applied client-side or sent to the server.
  final String? searchTerm;
  final AppReportDensity density;

  AppReportQuery copyWith({
    Map<String, Object?>? filters,
    List<AppReportSortDescriptor>? sorts,
    List<AppReportGroupDescriptor>? groups,
    int? page,
    int? pageSize,
    Set<String>? visibleColumnKeys,
    String? searchTerm,
    AppReportDensity? density,
  }) {
    return AppReportQuery(
      filters: filters ?? this.filters,
      sorts: sorts ?? this.sorts,
      groups: groups ?? this.groups,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      visibleColumnKeys: visibleColumnKeys ?? this.visibleColumnKeys,
      searchTerm: searchTerm ?? this.searchTerm,
      density: density ?? this.density,
    );
  }

  AppReportQuery withPage(int newPage) => copyWith(page: newPage);

  AppReportQuery withPageSize(int newPageSize) =>
      copyWith(pageSize: newPageSize, page: 1);

  AppReportQuery withFilters(Map<String, Object?> newFilters) =>
      copyWith(filters: newFilters, page: 1);

  AppReportQuery withSorts(List<AppReportSortDescriptor> newSorts) =>
      copyWith(sorts: newSorts, page: 1);

  AppReportQuery withSearchTerm(String? term) =>
      copyWith(searchTerm: term, page: 1);

  AppReportQuery withDensity(AppReportDensity newDensity) =>
      copyWith(density: newDensity);

  AppReportQuery withVisibleColumns(Set<String> keys) =>
      copyWith(visibleColumnKeys: keys);

  AppReportQuery clearFilters() =>
      copyWith(filters: const <String, Object?>{}, page: 1);
}
