import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Sort
// ---------------------------------------------------------------------------

enum AppReportSortDirection { ascending, descending }

@immutable
class AppReportSortDescriptor {
  const AppReportSortDescriptor({
    required this.columnKey,
    required this.direction,
  });

  final String columnKey;
  final AppReportSortDirection direction;

  AppReportSortDescriptor copyWith({
    String? columnKey,
    AppReportSortDirection? direction,
  }) {
    return AppReportSortDescriptor(
      columnKey: columnKey ?? this.columnKey,
      direction: direction ?? this.direction,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppReportSortDescriptor &&
      other.columnKey == columnKey &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(columnKey, direction);
}

// ---------------------------------------------------------------------------
// Grouping
// ---------------------------------------------------------------------------

@immutable
class AppReportGroupDescriptor {
  const AppReportGroupDescriptor({
    required this.columnKey,
    this.expanded = true,
  });

  final String columnKey;
  final bool expanded;

  AppReportGroupDescriptor copyWith({String? columnKey, bool? expanded}) {
    return AppReportGroupDescriptor(
      columnKey: columnKey ?? this.columnKey,
      expanded: expanded ?? this.expanded,
    );
  }
}

// ---------------------------------------------------------------------------
// Pagination
// ---------------------------------------------------------------------------

/// Server- or client-provided pagination snapshot for the report viewer.
///
/// When [totalRows] is 0, [totalPages] should be 0 and [currentPage] is
/// typically 1. When [totalRows] > 0, callers should keep [currentPage]
/// within `1..totalPages` so [firstRowIndex] and [lastRowIndex] stay aligned.
@immutable
class AppReportPageInfo {
  const AppReportPageInfo({
    required this.currentPage,
    required this.pageSize,
    required this.totalRows,
    required this.totalPages,
  });

  final int currentPage;
  final int pageSize;
  final int totalRows;
  final int totalPages;

  bool get hasPreviousPage => currentPage > 1;
  bool get hasNextPage => totalPages > 0 && currentPage < totalPages;

  /// Index of the first row on the current page (1-based).
  int get firstRowIndex => ((currentPage - 1) * pageSize) + 1;

  /// Index of the last row on the current page (1-based, capped at totalRows).
  int get lastRowIndex => (currentPage * pageSize).clamp(0, totalRows);

  /// True when [totalRows] is positive but [currentPage] points past the
  /// available range (e.g. after filters shrank the result set).
  bool get hasInvalidDisplayedRange =>
      totalRows > 0 && firstRowIndex > lastRowIndex;

  AppReportPageInfo copyWith({
    int? currentPage,
    int? pageSize,
    int? totalRows,
    int? totalPages,
  }) {
    return AppReportPageInfo(
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalRows: totalRows ?? this.totalRows,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

// ---------------------------------------------------------------------------
// Summary KPIs
// ---------------------------------------------------------------------------

class AppReportSummaryItem {
  const AppReportSummaryItem({
    required this.label,
    required this.value,
    this.detailLabel,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? detailLabel;
  final IconData? icon;

  /// Optional semantic color for the value (e.g. error for overdue metrics).
  final Color? valueColor;
}

// ---------------------------------------------------------------------------
// Density
// ---------------------------------------------------------------------------

enum AppReportDensity { compact, comfortable, expanded }

// ---------------------------------------------------------------------------
// Filter layout
// ---------------------------------------------------------------------------

/// Controls how the filters panel is displayed inside `AppReportViewer`.
///
/// [panel] renders the collapsible `AppReportFiltersPanel` card (default).
/// [inline] renders a compact horizontal `AppReportInlineFiltersBar` inside
/// the same card as the grid, applying changes immediately without a submit
/// button. Supports [AppReportFilterType.text], [AppReportFilterType.search],
/// [AppReportFilterType.singleSelect], [AppReportFilterType.dateRange] and
/// [AppReportFilterType.date]; other types are silently ignored.
enum AppReportFilterLayout { panel, inline }

// ---------------------------------------------------------------------------
// Viewer variants
// ---------------------------------------------------------------------------

/// High-level visual treatment for the report viewer shell.
enum AppReportViewerVariant { standard, minimal }

/// Controls how the toolbar is rendered above the grid.
enum AppReportToolbarMode { full, compact, hidden }

// ---------------------------------------------------------------------------
// Export
// ---------------------------------------------------------------------------

enum AppReportExportFormat { pdf, excel }

enum AppReportExportScope { currentPage, allPages, selection }

class AppReportExportRequest {
  const AppReportExportRequest({
    required this.format,
    this.scope = AppReportExportScope.currentPage,
    this.title,
    this.subtitle,
    this.includeHeaders = true,
    this.includeSummary = true,
    this.includeFilters = false,
    this.landscape = false,
    this.autoLandscape = true,
  });

  final AppReportExportFormat format;
  final AppReportExportScope scope;
  final String? title;
  final String? subtitle;
  final bool includeHeaders;
  final bool includeSummary;
  final bool includeFilters;

  /// Force landscape orientation. Overrides [autoLandscape].
  final bool landscape;

  /// When [landscape] is false, automatically switch to landscape when the
  /// column count exceeds the export handler's internal threshold. Applies to
  /// PDF only; Excel orientation is not affected by this flag.
  final bool autoLandscape;
}

// ---------------------------------------------------------------------------
// Filter descriptor (independent of feature-layer ReportParameterDescriptor)
// ---------------------------------------------------------------------------

enum AppReportFilterType {
  text,
  singleSelect,
  multiSelect,
  date,
  dateRange,
  numericRange,
  toggle,
  search,
}

class AppReportFilterOption {
  const AppReportFilterOption({required this.value, required this.label});

  final String value;
  final String label;
}

class AppReportFilterDescriptor {
  const AppReportFilterDescriptor({
    required this.name,
    required this.label,
    required this.type,
    this.required = false,
    this.initialValue,
    this.options = const <AppReportFilterOption>[],
    this.hint,
    this.minValue,
    this.maxValue,
  });

  final String name;
  final String label;
  final AppReportFilterType type;
  final bool required;
  final Object? initialValue;
  final List<AppReportFilterOption> options;
  final String? hint;
  final num? minValue;
  final num? maxValue;
}
