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
  bool get hasNextPage => currentPage < totalPages;

  /// Index of the first row on the current page (1-based).
  int get firstRowIndex => ((currentPage - 1) * pageSize) + 1;

  /// Index of the last row on the current page (1-based, capped at totalRows).
  int get lastRowIndex => (currentPage * pageSize).clamp(0, totalRows);

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
  });

  final AppReportExportFormat format;
  final AppReportExportScope scope;
  final String? title;
  final String? subtitle;
  final bool includeHeaders;
  final bool includeSummary;
  final bool includeFilters;
  final bool landscape;
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
