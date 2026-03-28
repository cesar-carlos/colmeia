import 'package:flutter/material.dart';

enum AppReportColumnAlignment { start, center, end }

enum AppReportAggregation { sum, average, count, min, max }

/// Declarative column definition for the report viewer (AppReportViewer).
///
/// Generic on the row type [T]. Pass a list of these to describe every column
/// the viewer can display, sort, group or aggregate.
class AppReportColumn<T> {
  const AppReportColumn({
    required this.key,
    required this.label,
    required this.valueGetter,
    this.cellBuilder,
    this.headerBuilder,
    this.formatter,
    this.alignment = AppReportColumnAlignment.start,
    this.width,
    this.minWidth = 80,
    this.flex,
    this.visibleByDefault = true,
    this.hideBelowBreakpoint,
    this.pinned = false,
    this.sortable = true,
    this.filterable = false,
    this.groupable = false,
    this.aggregations = const <AppReportAggregation>[],
    this.textStyle,
    this.headerTextStyle,
    this.numeric = false,
  });

  /// Unique identifier used to match column definitions to sort/filter state.
  final String key;

  /// Display label shown in the column header.
  final String label;

  /// Extracts the raw cell value from a row object.
  ///
  /// Returns [Object?] so it works with String, num, DateTime, bool or enum.
  final Object? Function(T row) valueGetter;

  /// Custom widget builder for the cell content. When null the column renders
  /// [formatter](value) or value.toString().
  final Widget Function(BuildContext context, T row, Object? value)?
      cellBuilder;

  /// Custom widget builder for the header label cell. When null the column
  /// renders [label] with [headerTextStyle] or the theme's labelLarge.
  final Widget Function(BuildContext context, String label)? headerBuilder;

  /// Converts [valueGetter] output to a display string. Used when
  /// [cellBuilder] is null.
  final String Function(Object? value)? formatter;

  final AppReportColumnAlignment alignment;

  /// Fixed pixel width. When null the column participates in flexible layout
  /// driven by [flex] or ColumnWidthMode.fill.
  final double? width;

  /// Minimum pixel width enforced in responsive layout.
  final double minWidth;

  /// Flex factor. When set, the column behaves like [Flexible] in the grid.
  final int? flex;

  /// Whether this column is visible by default (can still be toggled by user).
  final bool visibleByDefault;

  /// Screen width (logical pixels) below which this column is automatically
  /// hidden to keep the grid readable on small screens.
  final double? hideBelowBreakpoint;

  /// When true the column is frozen on the left edge and never scrolls.
  final bool pinned;

  /// Whether tapping the header toggles sort on this column.
  final bool sortable;

  /// Whether an inline quick-filter control is shown for this column.
  final bool filterable;

  /// Whether this column can be used as a grouping key.
  final bool groupable;

  /// Summary functions this column should participate in (sum, avg, etc.).
  final List<AppReportAggregation> aggregations;

  /// Text style applied to data cells. Falls back to the theme default.
  final TextStyle? textStyle;

  /// Text style applied to the header cell. Falls back to the theme default.
  final TextStyle? headerTextStyle;

  /// When true, the cell value is right-aligned by default (overridden by
  /// [alignment]).
  final bool numeric;

  /// Resolves the effective alignment taking [numeric] into account.
  AppReportColumnAlignment get effectiveAlignment =>
      alignment != AppReportColumnAlignment.start
          ? alignment
          : (numeric ? AppReportColumnAlignment.end : alignment);

  /// Returns the display string for a given value using [formatter] if
  /// provided, otherwise toString.
  String formatValue(Object? value) {
    if (value == null) return '';
    if (formatter != null) return formatter!(value);
    return value.toString();
  }
}
