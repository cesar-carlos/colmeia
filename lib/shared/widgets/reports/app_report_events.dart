import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';
import 'package:flutter/foundation.dart';

@immutable
class AppReportGroupToggleEvent {
  const AppReportGroupToggleEvent({
    required this.columnKey,
    required this.groupKey,
    required this.groupLevel,
    required this.isExpanded,
  });

  final String columnKey;
  final String groupKey;
  final int groupLevel;
  final bool isExpanded;
}

/// Typed callback container for all interactions the report viewer emits.
///
/// Every callback is optional. The consumer wires only the events it needs.
/// The viewer merges interaction-driven state changes internally and fires
/// [onQueryChanged] with the full updated [AppReportQuery] when any
/// query-affecting interaction occurs.
///
/// Prefer implementing data reloads from [onQueryChanged] alone: sort changes
/// invoke both [onSortChanged] and [onQueryChanged], so listening to both can
/// duplicate work.
class AppReportEvents<T> {
  const AppReportEvents({
    this.onQueryChanged,
    this.onSortChanged,
    this.onPageChanged,
    this.onPageSizeChanged,
    this.onFiltersApplied,
    this.onFilterCleared,
    this.onGroupChanged,
    this.onGroupStateChanged,
    this.onGroupExpanded,
    this.onGroupCollapsed,
    this.onRowTap,
    this.onRowDoubleTap,
    this.onRowLongPress,
    this.onRowSelection,
    this.onExportRequested,
    this.onPrintRequested,
    this.onRefresh,
    this.onColumnVisibilityChanged,
    this.onDensityChanged,
    this.onSearchChanged,
  });

  /// Fired whenever any query-affecting interaction changes the query state.
  /// This is the primary callback the consumer should use to trigger data
  /// fetches.
  final ValueChanged<AppReportQuery>? onQueryChanged;

  /// Fired when the user changes column sort (tap on header).
  ///
  /// Also causes [onQueryChanged] with updated sorts; avoid handling both
  /// unless you need side effects that apply only to sort.
  final ValueChanged<List<AppReportSortDescriptor>>? onSortChanged;

  /// Fired when the user navigates to a different page.
  final ValueChanged<int>? onPageChanged;

  /// Fired when the user selects a different page size.
  final ValueChanged<int>? onPageSizeChanged;

  /// Fired when the user applies the filters panel.
  final ValueChanged<Map<String, Object?>>? onFiltersApplied;

  /// Fired when the user clears all filters.
  final VoidCallback? onFilterCleared;

  /// Fired when the user changes grouping configuration.
  final ValueChanged<List<AppReportGroupDescriptor>>? onGroupChanged;

  /// Fired when the visual expanded/collapsed state of grouped levels changes.
  ///
  /// Unlike [onGroupChanged], this should not imply a data reload by itself.
  final ValueChanged<List<AppReportGroupDescriptor>>? onGroupStateChanged;

  /// Fired after a grouped section is expanded in the grid.
  final ValueChanged<AppReportGroupToggleEvent>? onGroupExpanded;

  /// Fired after a grouped section is collapsed in the grid.
  final ValueChanged<AppReportGroupToggleEvent>? onGroupCollapsed;

  /// Fired when the user taps a data row.
  final void Function(T row, int index)? onRowTap;

  /// Fired when the user double-taps a data row.
  final void Function(T row, int index)? onRowDoubleTap;

  /// Fired when the user long-presses a data row.
  final void Function(T row, int index)? onRowLongPress;

  /// Fired when row selection changes (single or multi).
  final ValueChanged<List<T>>? onRowSelection;

  /// Fired when the user requests export via the toolbar.
  final ValueChanged<AppReportExportRequest>? onExportRequested;

  /// Fired when the user taps the print action.
  final VoidCallback? onPrintRequested;

  /// Fired when the user pulls to refresh or taps the refresh button.
  final AsyncCallback? onRefresh;

  /// Fired when the user changes visible columns via the column chooser.
  final ValueChanged<Set<String>>? onColumnVisibilityChanged;

  /// Fired when the user changes the grid density.
  final ValueChanged<AppReportDensity>? onDensityChanged;

  /// Fired as the user types in the global search bar.
  final ValueChanged<String>? onSearchChanged;
}
