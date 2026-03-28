import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';
import 'package:flutter/foundation.dart';

/// Typed callback container for all interactions the report viewer emits.
///
/// Every callback is optional. The consumer wires only the events it needs.
/// The viewer merges interaction-driven state changes internally and fires
/// onQueryChanged with the full updated AppReportQuery when any
/// query-affecting interaction occurs.
class AppReportEvents<T> {
  const AppReportEvents({
    this.onQueryChanged,
    this.onSortChanged,
    this.onPageChanged,
    this.onPageSizeChanged,
    this.onFiltersApplied,
    this.onFilterCleared,
    this.onGroupChanged,
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
