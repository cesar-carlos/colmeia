import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';

/// Visual and behavioural configuration for the report viewer
/// (AppReportViewer).
///
/// All properties are optional with sensible defaults. Pass only the knobs
/// you need to change.
class AppReportViewerStyle {
  const AppReportViewerStyle({
    this.gridHeight,
    this.headerRowHeight,
    this.dataRowHeight,
    this.groupRowHeight,
    this.summaryRowHeight,
    this.showColumnHeaders = true,
    this.showGridLines = false,
    this.allowSorting = true,
    this.allowMultiSort = false,
    this.allowSelection = false,
    this.allowMultiSelection = false,
    this.frozenColumnsCount = 0,
    this.showSearchBar = false,
    this.showDensityToggle = false,
    this.showColumnChooser = false,
    this.showExportActions = true,
    this.showPrintAction = false,
    this.showRefreshAction = true,
    this.showFiltersPanel = true,
    this.showSummaryBar = true,
    this.showPagination = true,
    this.showRowDetailOnTap = false,
    this.enablePullToRefresh = true,
    this.headerTextStyle,
    this.dataTextStyle,
    this.groupTextStyle,
    this.summaryTextStyle,
    this.density = AppReportDensity.comfortable,
    this.filtersStartExpanded = true,
    this.availablePageSizes,
    this.emptyMessage,
    this.alternateRowColor,
  });

  /// Fixed grid height. When null the grid fills the available height or
  /// falls back to a sensible default.
  final double? gridHeight;

  /// Height of the header row. When null defaults by density.
  final double? headerRowHeight;

  /// Height of each data row. When null defaults by density.
  final double? dataRowHeight;

  /// Height of group header rows.
  final double? groupRowHeight;

  /// Height of summary/footer rows.
  final double? summaryRowHeight;

  final bool showColumnHeaders;
  final bool showGridLines;
  final bool allowSorting;

  /// Allow sorting by multiple columns simultaneously (shift+tap header).
  final bool allowMultiSort;

  final bool allowSelection;
  final bool allowMultiSelection;

  /// Number of columns frozen on the left edge (pinned).
  final int frozenColumnsCount;

  final bool showSearchBar;
  final bool showDensityToggle;
  final bool showColumnChooser;
  final bool showExportActions;
  final bool showPrintAction;
  final bool showRefreshAction;
  final bool showFiltersPanel;
  final bool showSummaryBar;
  final bool showPagination;

  /// When true, tapping a row opens the detail panel (bottom sheet on mobile).
  final bool showRowDetailOnTap;

  final bool enablePullToRefresh;

  final TextStyle? headerTextStyle;
  final TextStyle? dataTextStyle;
  final TextStyle? groupTextStyle;
  final TextStyle? summaryTextStyle;

  final AppReportDensity density;

  /// Whether the filters panel starts expanded (true) or collapsed (false).
  final bool filtersStartExpanded;

  /// Available page sizes shown in the pagination bar selector.
  /// Defaults to [5, 10, 20, 50].
  final List<int>? availablePageSizes;

  /// Message shown when the grid has no rows to display.
  final String? emptyMessage;

  /// Alternate background color applied to even rows. When null rows share
  /// the surface color.
  final Color? alternateRowColor;

  List<int> get resolvedPageSizes =>
      availablePageSizes ?? const <int>[5, 10, 20, 50];

  /// Row height resolved from density when [dataRowHeight] is null.
  double resolvedDataRowHeight(AppReportDensity effectiveDensity) {
    if (dataRowHeight != null) return dataRowHeight!;
    return switch (effectiveDensity) {
      AppReportDensity.compact => 36,
      AppReportDensity.comfortable => 48,
      AppReportDensity.expanded => 60,
    };
  }

  /// Header row height resolved from density when [headerRowHeight] is null.
  double resolvedHeaderRowHeight(AppReportDensity effectiveDensity) {
    if (headerRowHeight != null) return headerRowHeight!;
    return switch (effectiveDensity) {
      AppReportDensity.compact => 40,
      AppReportDensity.comfortable => 52,
      AppReportDensity.expanded => 64,
    };
  }

  AppReportViewerStyle copyWith({
    double? gridHeight,
    double? headerRowHeight,
    double? dataRowHeight,
    double? groupRowHeight,
    double? summaryRowHeight,
    bool? showColumnHeaders,
    bool? showGridLines,
    bool? allowSorting,
    bool? allowMultiSort,
    bool? allowSelection,
    bool? allowMultiSelection,
    int? frozenColumnsCount,
    bool? showSearchBar,
    bool? showDensityToggle,
    bool? showColumnChooser,
    bool? showExportActions,
    bool? showPrintAction,
    bool? showRefreshAction,
    bool? showFiltersPanel,
    bool? showSummaryBar,
    bool? showPagination,
    bool? showRowDetailOnTap,
    bool? enablePullToRefresh,
    TextStyle? headerTextStyle,
    TextStyle? dataTextStyle,
    TextStyle? groupTextStyle,
    TextStyle? summaryTextStyle,
    AppReportDensity? density,
    bool? filtersStartExpanded,
    List<int>? availablePageSizes,
    String? emptyMessage,
    Color? alternateRowColor,
  }) {
    return AppReportViewerStyle(
      gridHeight: gridHeight ?? this.gridHeight,
      headerRowHeight: headerRowHeight ?? this.headerRowHeight,
      dataRowHeight: dataRowHeight ?? this.dataRowHeight,
      groupRowHeight: groupRowHeight ?? this.groupRowHeight,
      summaryRowHeight: summaryRowHeight ?? this.summaryRowHeight,
      showColumnHeaders: showColumnHeaders ?? this.showColumnHeaders,
      showGridLines: showGridLines ?? this.showGridLines,
      allowSorting: allowSorting ?? this.allowSorting,
      allowMultiSort: allowMultiSort ?? this.allowMultiSort,
      allowSelection: allowSelection ?? this.allowSelection,
      allowMultiSelection: allowMultiSelection ?? this.allowMultiSelection,
      frozenColumnsCount: frozenColumnsCount ?? this.frozenColumnsCount,
      showSearchBar: showSearchBar ?? this.showSearchBar,
      showDensityToggle: showDensityToggle ?? this.showDensityToggle,
      showColumnChooser: showColumnChooser ?? this.showColumnChooser,
      showExportActions: showExportActions ?? this.showExportActions,
      showPrintAction: showPrintAction ?? this.showPrintAction,
      showRefreshAction: showRefreshAction ?? this.showRefreshAction,
      showFiltersPanel: showFiltersPanel ?? this.showFiltersPanel,
      showSummaryBar: showSummaryBar ?? this.showSummaryBar,
      showPagination: showPagination ?? this.showPagination,
      showRowDetailOnTap: showRowDetailOnTap ?? this.showRowDetailOnTap,
      enablePullToRefresh: enablePullToRefresh ?? this.enablePullToRefresh,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      dataTextStyle: dataTextStyle ?? this.dataTextStyle,
      groupTextStyle: groupTextStyle ?? this.groupTextStyle,
      summaryTextStyle: summaryTextStyle ?? this.summaryTextStyle,
      density: density ?? this.density,
      filtersStartExpanded: filtersStartExpanded ?? this.filtersStartExpanded,
      availablePageSizes: availablePageSizes ?? this.availablePageSizes,
      emptyMessage: emptyMessage ?? this.emptyMessage,
      alternateRowColor: alternateRowColor ?? this.alternateRowColor,
    );
  }
}
