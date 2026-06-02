import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_events.dart';
import 'package:colmeia/shared/widgets/reports/app_report_grid_source.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

/// Right strip reserved when the grid has a fixed height and may scroll
/// vertically, so the Syncfusion scrollbar does not cover the last column.
const double kAppReportGridVerticalScrollbarGutter = 14;

/// Grid widget backed by [SfDataGrid] that consumes [AppReportColumn]
/// definitions and handles responsive column visibility, sorting callbacks,
/// and row interaction events.
class AppReportGroupController {
  VoidCallback? _expandAll;
  VoidCallback? _collapseAll;
  ValueChanged<int>? _expandToLevel;
  ValueChanged<int>? _collapseToLevel;

  void _bind({
    required VoidCallback expandAll,
    required VoidCallback collapseAll,
    required ValueChanged<int> expandToLevel,
    required ValueChanged<int> collapseToLevel,
  }) {
    _expandAll = expandAll;
    _collapseAll = collapseAll;
    _expandToLevel = expandToLevel;
    _collapseToLevel = collapseToLevel;
  }

  void _unbind() {
    _expandAll = null;
    _collapseAll = null;
    _expandToLevel = null;
    _collapseToLevel = null;
  }

  void expandAll() => _expandAll?.call();

  void collapseAll() => _collapseAll?.call();

  void expandToLevel(int level) => _expandToLevel?.call(level);

  void collapseToLevel(int level) => _collapseToLevel?.call(level);
}

class AppReportGrid<T> extends StatefulWidget {
  const AppReportGrid({
    required this.columns,
    required this.rows,
    required this.style,
    super.key,
    this.events = const AppReportEvents(),
    this.currentSorts = const <AppReportSortDescriptor>[],
    this.currentGroups = const <AppReportGroupDescriptor>[],
    this.selectedRows = const [],
    this.groupController,
    this.emptyMessage,
    this.emptyAction,
    this.isLoading = false,
  });

  final List<AppReportColumn<T>> columns;
  final List<T> rows;
  final AppReportViewerStyle style;
  final AppReportEvents<T> events;
  final List<AppReportSortDescriptor> currentSorts;
  final List<AppReportGroupDescriptor> currentGroups;

  /// Rows currently selected in the grid.
  ///
  /// Selection resolution matches [DataGridRow] instances to [rows] by **object
  /// identity** after sort/group. Prefer the same [T] instances as in [rows]
  /// (or stable references the grid can resolve) so selection stays correct.
  final List<T> selectedRows;
  final AppReportGroupController? groupController;
  final String? emptyMessage;

  /// Optional widget rendered below the empty-state message — typically a
  /// secondary CTA such as "Limpar filtros" when active filters yield no
  /// results.
  final Widget? emptyAction;

  /// When [rows] is empty and this is true, shows a loading surface instead of
  /// the empty state (avoids "no results" while data is still fetching).
  final bool isLoading;

  @override
  State<AppReportGrid<T>> createState() => _AppReportGridState<T>();
}

class _AppReportGridState<T> extends State<AppReportGrid<T>> {
  late AppReportGridSource<T> _source;
  bool _hasBuiltSource = false;
  final DataGridController _gridController = DataGridController();
  bool _suppressSelectionCallback = false;

  // ---- Memoization caches --------------------------------------------------
  // Recomputing `_visibleColumns`, `_buildGridColumns` and `_buildSummaryRows`
  // on every `build()` was the largest avoidable cost in the report grid:
  // each touched the column list and theme to rebuild widget subtrees that
  // only change when columns, density, theme or screen width change. We cache
  // the results and invalidate them with explicit signatures.
  List<AppReportColumn<T>>? _cachedVisibleColumns;
  double? _cachedVisibleColumnsScreenWidth;
  Object? _cachedVisibleColumnsSignature;

  List<GridColumn>? _cachedGridColumns;
  Object? _cachedGridColumnsSignature;

  List<GridTableSummaryRow>? _cachedSummaryRows;
  Object? _cachedSummaryRowsSignature;

  void _invalidateColumnCaches() {
    _cachedVisibleColumns = null;
    _cachedVisibleColumnsScreenWidth = null;
    _cachedVisibleColumnsSignature = null;
    _cachedGridColumns = null;
    _cachedGridColumnsSignature = null;
    _cachedSummaryRows = null;
    _cachedSummaryRowsSignature = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasBuiltSource) {
      return;
    }
    _source = _buildSource();
    _hasBuiltSource = true;
    _bindGroupController();
    _scheduleSyncGridStateFromParent();
  }

  @override
  void didUpdateWidget(covariant AppReportGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupController != widget.groupController) {
      oldWidget.groupController?._unbind();
      _bindGroupController();
    }
    final columnsChanged = oldWidget.columns != widget.columns;
    final rowsChanged = oldWidget.rows != widget.rows;
    final styleChanged = _sourceStyleChanged(oldWidget.style, widget.style);
    final trustOrderChanged =
        oldWidget.style.trustServerRowOrder != widget.style.trustServerRowOrder;
    final sortsChanged = !listEquals(
      oldWidget.currentSorts,
      widget.currentSorts,
    );
    final groupsChanged = !listEquals(
      oldWidget.currentGroups,
      widget.currentGroups,
    );
    final selectionChanged = !listEquals(
      oldWidget.selectedRows,
      widget.selectedRows,
    );
    if (columnsChanged || rowsChanged || styleChanged) {
      if (columnsChanged || styleChanged) {
        _invalidateColumnCaches();
      }
      if (styleChanged) {
        _source = _buildSource();
      } else {
        _source.update(
          rows: widget.rows,
          visibleColumns: _visibleColumns,
        );
      }
      _hasBuiltSource = true;
    }
    final gridStateChanged =
        columnsChanged ||
        rowsChanged ||
        styleChanged ||
        sortsChanged ||
        groupsChanged ||
        trustOrderChanged ||
        selectionChanged;
    if (gridStateChanged) {
      _scheduleSyncGridStateFromParent();
    }
  }

  /// [AppReportGridSource] stores [AppReportViewerStyle.alternateRowColor] and
  /// [AppReportViewerStyle.dataTextStyle] at construction; recreate when either
  /// changes so cell rendering matches the theme.
  static bool _sourceStyleChanged(
    AppReportViewerStyle oldStyle,
    AppReportViewerStyle newStyle,
  ) {
    return oldStyle.alternateRowColor != newStyle.alternateRowColor ||
        oldStyle.zebraRows != newStyle.zebraRows ||
        oldStyle.dataTextStyle != newStyle.dataTextStyle;
  }

  /// Syncfusion wires [DataGridSource] to grid state only while [SfDataGrid] is
  /// mounted. With no rows we render [_EmptyGridPlaceholder] instead, so APIs
  /// like [DataGridSource.clearColumnGroups] must not run (they force-unwrap
  /// internal grid state).
  bool get _hasSfDataGrid => widget.rows.isNotEmpty;

  /// One post-frame pass: sort → column groups + expansion → selection.
  ///
  /// Order matters: grouping builds on [DataGridSource.sortedColumns]; applying
  /// selection last avoids transient indices while the grid rebuilds.
  void _scheduleSyncGridStateFromParent() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      if (_hasSfDataGrid) {
        final keys = _visibleColumns.map((c) => c.key).toSet();
        await _source.applyExternalSortDescriptors(
          widget.currentSorts,
          keys,
          reorderRows: !widget.style.trustServerRowOrder,
        );
        if (!mounted) {
          return;
        }
        _source.applyExternalGroupDescriptors(widget.currentGroups, keys);
        _syncGroupExpansionFromParent();
      }
      if (!mounted) {
        return;
      }
      _applySelectionFromParent();
    });
  }

  void _syncGroupExpansionFromParent() {
    for (var i = 0; i < widget.currentGroups.length; i++) {
      final level = i + 1;
      final descriptor = widget.currentGroups[i];
      if (descriptor.expanded) {
        _gridController.expandGroupsAtLevel(level);
      } else {
        _gridController.collapseGroupsAtLevel(level);
      }
    }
  }

  void _expandAllGroups() {
    if (widget.currentGroups.isEmpty) {
      return;
    }
    _gridController.expandAllGroup();
  }

  void _collapseAllGroups() {
    if (widget.currentGroups.isEmpty) {
      return;
    }
    _gridController.collapseAllGroup();
  }

  void _expandGroupsToLevel(int level) {
    if (widget.currentGroups.isEmpty) {
      return;
    }
    _gridController.expandGroupsAtLevel(level);
  }

  void _collapseGroupsToLevel(int level) {
    if (widget.currentGroups.isEmpty) {
      return;
    }
    _gridController.collapseGroupsAtLevel(level);
  }

  void _applySelectionFromParent() {
    _suppressSelectionCallback = true;
    try {
      if (widget.selectedRows.isEmpty ||
          (!widget.style.allowSelection && !widget.style.allowMultiSelection)) {
        _gridController.selectedRows = <DataGridRow>[];
        _gridController.selectedIndex = -1;
        return;
      }

      final selectedGridRows = _source.resolveDataGridRows(
        widget.selectedRows,
      );

      if (widget.style.allowMultiSelection) {
        _gridController.selectedRows = selectedGridRows;
        return;
      }

      if (selectedGridRows.isEmpty) {
        _gridController.selectedRows = <DataGridRow>[];
        _gridController.selectedIndex = -1;
        return;
      }

      _gridController.selectedRow = selectedGridRows.first;
    } finally {
      _suppressSelectionCallback = false;
    }
  }

  @override
  void dispose() {
    widget.groupController?._unbind();
    _gridController.dispose();
    super.dispose();
  }

  void _bindGroupController() {
    widget.groupController?._bind(
      expandAll: _expandAllGroups,
      collapseAll: _collapseAllGroups,
      expandToLevel: _expandGroupsToLevel,
      collapseToLevel: _collapseGroupsToLevel,
    );
  }

  AppReportGridSource<T> _buildSource() {
    return AppReportGridSource<T>(
      rows: widget.rows,
      visibleColumns: _visibleColumns,
      context: context,
      alternateRowColor: _resolvedAlternateRowColor,
      dataTextStyle: widget.style.dataTextStyle,
      onSortChanged: widget.events.onSortChanged,
    );
  }

  /// Resolves the effective zebra-row color: an explicit
  /// [AppReportViewerStyle.alternateRowColor] override wins; otherwise a
  /// theme-aware color is used when [AppReportViewerStyle.zebraRows] is set so
  /// striping adapts to light/dark mode instead of a baked light-only color.
  Color? get _resolvedAlternateRowColor {
    final override = widget.style.alternateRowColor;
    if (override != null) {
      return override;
    }
    if (!widget.style.zebraRows) {
      return null;
    }
    return Theme.of(context).colorScheme.surfaceContainerLow;
  }

  /// Columns visible at the current breakpoint; non-growable for stable layout.
  ///
  /// `AppReportGridSource` copies this list internally so grid source updates
  /// are not limited by fixed-length lists. The result is memoized per
  /// (column list identity, screen width) so repeated `build()` passes do not
  /// re-filter the columns.
  List<AppReportColumn<T>> get _visibleColumns {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final signature = identityHashCode(widget.columns);
    final cached = _cachedVisibleColumns;
    if (cached != null &&
        _cachedVisibleColumnsScreenWidth == screenWidth &&
        _cachedVisibleColumnsSignature == signature) {
      return cached;
    }

    final visible = widget.columns
        .where((col) {
          final breakpoint = col.hideBelowBreakpoint;
          if (breakpoint != null && screenWidth < breakpoint) return false;
          return true;
        })
        .toList(growable: false);
    _cachedVisibleColumns = visible;
    _cachedVisibleColumnsScreenWidth = screenWidth;
    _cachedVisibleColumnsSignature = signature;
    // The downstream column/summary caches depend on the visible column list,
    // so invalidate them when the visible set changes.
    _cachedGridColumns = null;
    _cachedGridColumnsSignature = null;
    _cachedSummaryRows = null;
    _cachedSummaryRowsSignature = null;
    return visible;
  }

  List<GridColumn> _buildGridColumns(List<AppReportColumn<T>> visible) {
    final theme = Theme.of(context);
    final density = widget.style.density;
    final signature = Object.hash(
      identityHashCode(visible),
      identityHashCode(widget.style),
      density,
      theme.brightness,
      identityHashCode(theme.colorScheme),
      identityHashCode(theme.appTypography),
    );
    final cached = _cachedGridColumns;
    if (cached != null && _cachedGridColumnsSignature == signature) {
      return cached;
    }

    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final headerHeight = widget.style.resolvedHeaderRowHeight(density);
    final headerBackgroundColor =
        widget.style.headerBackgroundColor ??
        (widget.style.variant == AppReportViewerVariant.minimal
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceContainerHigh);
    final headerDividerColor =
        widget.style.headerDividerColor ??
        theme.colorScheme.outlineVariant.withValues(alpha: 0.48);
    final defaultHeaderTextStyle =
        widget.style.headerTextStyle ??
        typography.utilityOverline.copyWith(
          letterSpacing: widget.style.headerLetterSpacing ?? 0.2,
          fontWeight: FontWeight.w700,
        );

    final result = visible
        .map((col) {
          final labelWidget = col.headerBuilder != null
              ? col.headerBuilder!(context, col.label)
              : _ReportGridColumnHeader(
                  label: widget.style.uppercaseHeaderLabels
                      ? col.label.toUpperCase()
                      : col.label,
                  alignment: _sfAlignment(col.effectiveAlignment),
                  height: headerHeight,
                  horizontalPadding: tokens.gapMd,
                  backgroundColor: headerBackgroundColor,
                  dividerColor: headerDividerColor,
                  textStyle: (col.headerTextStyle ?? defaultHeaderTextStyle)
                      .copyWith(
                        letterSpacing:
                            widget.style.headerLetterSpacing ??
                            defaultHeaderTextStyle.letterSpacing,
                      ),
                );

          return GridColumn(
            columnName: col.key,
            minimumWidth: col.minWidth,
            width: col.width ?? double.nan,
            columnWidthMode: col.width != null
                ? ColumnWidthMode.none
                : ColumnWidthMode.fill,
            allowSorting: widget.style.allowSorting && col.sortable,
            label: labelWidget,
          );
        })
        .toList(growable: false);
    _cachedGridColumns = result;
    _cachedGridColumnsSignature = signature;
    return result;
  }

  List<GridTableSummaryRow> _buildSummaryRows(
    List<AppReportColumn<T>> visible,
  ) {
    final signature = identityHashCode(visible);
    final cached = _cachedSummaryRows;
    if (cached != null && _cachedSummaryRowsSignature == signature) {
      return cached;
    }

    final summaryColumns = <GridSummaryColumn>[];
    for (final col in visible) {
      if (col.aggregations.isEmpty) continue;
      final aggregation = col.aggregations.first;
      final sfType = _sfSummaryType(aggregation);
      summaryColumns.add(
        GridSummaryColumn(
          name: col.key,
          columnName: col.key,
          summaryType: sfType,
        ),
      );
    }

    final result = summaryColumns.isEmpty
        ? const <GridTableSummaryRow>[]
        : <GridTableSummaryRow>[
            GridTableSummaryRow(
              showSummaryInRow: false,
              columns: summaryColumns,
              position: GridTableSummaryRowPosition.bottom,
            ),
          ];
    _cachedSummaryRows = result;
    _cachedSummaryRowsSignature = signature;
    return result;
  }

  void _handleCellTap(DataGridCellTapDetails details) {
    if (details.rowColumnIndex.rowIndex < 1) return;
    final entry = _source.resolveRowEntryAt(
      details.rowColumnIndex.rowIndex - 1,
    );
    if (entry == null) return;
    widget.events.onRowTap?.call(entry.row, entry.sourceIndex);
  }

  void _handleCellDoubleTap(DataGridCellDoubleTapDetails details) {
    if (details.rowColumnIndex.rowIndex < 1) return;
    final entry = _source.resolveRowEntryAt(
      details.rowColumnIndex.rowIndex - 1,
    );
    if (entry == null) return;
    widget.events.onRowDoubleTap?.call(entry.row, entry.sourceIndex);
  }

  void _handleCellLongPress(DataGridCellLongPressDetails details) {
    if (details.rowColumnIndex.rowIndex < 1) return;
    final entry = _source.resolveRowEntryAt(
      details.rowColumnIndex.rowIndex - 1,
    );
    if (entry == null) return;
    widget.events.onRowLongPress?.call(entry.row, entry.sourceIndex);
  }

  void _handleSelectionChanged(
    List<DataGridRow> addedRows,
    List<DataGridRow> removedRows,
  ) {
    if (_suppressSelectionCallback || widget.events.onRowSelection == null) {
      return;
    }

    final selectedGridRows = widget.style.allowMultiSelection
        ? _gridController.selectedRows
        : <DataGridRow>[
            if (_gridController.selectedRow case final DataGridRow row) row,
          ];
    final selectedRows = _source.resolveRows(selectedGridRows);
    widget.events.onRowSelection?.call(selectedRows);
  }

  void _handleGroupExpanded(DataGridGroupChangedDetails details) {
    final event = _resolveGroupToggleEvent(details);
    if (event == null) {
      return;
    }
    widget.events.onGroupExpanded?.call(event);
  }

  void _handleGroupCollapsed(DataGridGroupChangedDetails details) {
    final event = _resolveGroupToggleEvent(details);
    if (event == null) {
      return;
    }
    widget.events.onGroupCollapsed?.call(event);
  }

  AppReportGroupToggleEvent? _resolveGroupToggleEvent(
    DataGridGroupChangedDetails details,
  ) {
    if (details.groupLevel < 0 ||
        details.groupLevel >= widget.currentGroups.length) {
      return null;
    }

    final descriptor = widget.currentGroups[details.groupLevel];
    return AppReportGroupToggleEvent(
      columnKey: descriptor.columnKey,
      groupKey: details.key,
      groupLevel: details.groupLevel,
      isExpanded: details.isExpanded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final density = widget.style.density;
    final visible = _visibleColumns;
    final borderAlpha = widget.style.cardBorderAlpha;

    if (widget.rows.isEmpty) {
      if (widget.isLoading) {
        return _LoadingGridPlaceholder(style: widget.style);
      }
      return _EmptyGridPlaceholder(
        message:
            widget.emptyMessage ??
            widget.style.emptyMessage ??
            AppLocalizations.of(context).reportEmptyDefaultMessage,
        style: widget.style,
        action: widget.emptyAction,
      );
    }

    final frozenCount = _resolvedFrozenColumnsCount(visible);

    final grid = SfDataGrid(
      source: _source,
      controller: _gridController,
      columns: _buildGridColumns(visible),
      tableSummaryRows: _buildSummaryRows(visible),
      allowExpandCollapseGroup: widget.currentGroups.isNotEmpty,
      groupCaptionTitleFormat: '{ColumnName}|{Key}|{ItemsCount}',
      allowSorting: widget.style.allowSorting,
      allowMultiColumnSorting: widget.style.allowMultiSort,
      allowColumnsResizing: true,
      showSortNumbers: widget.style.allowMultiSort,
      headerGridLinesVisibility: widget.style.showGridLines
          ? GridLinesVisibility.both
          : GridLinesVisibility.none,
      gridLinesVisibility: widget.style.showGridLines
          ? GridLinesVisibility.horizontal
          : GridLinesVisibility.none,
      columnWidthMode: ColumnWidthMode.fill,
      selectionMode: _sfSelectionMode,
      frozenColumnsCount: frozenCount,
      rowHeight: widget.style.resolvedDataRowHeight(density),
      headerRowHeight: widget.style.showColumnHeaders
          ? widget.style.resolvedHeaderRowHeight(density)
          : 0,
      onCellTap: _handleCellTap,
      onCellDoubleTap: _handleCellDoubleTap,
      onCellLongPress: _handleCellLongPress,
      onSelectionChanged: _handleSelectionChanged,
      groupExpanded: _handleGroupExpanded,
      groupCollapsed: _handleGroupCollapsed,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.cardRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(
              alpha: borderAlpha,
            ),
          ),
        ),
        child: widget.style.gridHeight != null
            ? SizedBox(
                height: widget.style.gridHeight,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      right: kAppReportGridVerticalScrollbarGutter,
                      child: grid,
                    ),
                  ],
                ),
              )
            : grid,
      ),
    );
  }

  SelectionMode get _sfSelectionMode {
    if (widget.style.allowMultiSelection) return SelectionMode.multiple;
    if (widget.style.allowSelection) return SelectionMode.single;
    return SelectionMode.none;
  }

  static Alignment _sfAlignment(AppReportColumnAlignment alignment) {
    return switch (alignment) {
      AppReportColumnAlignment.end => Alignment.centerRight,
      AppReportColumnAlignment.center => Alignment.center,
      AppReportColumnAlignment.start => Alignment.centerLeft,
    };
  }

  static GridSummaryType _sfSummaryType(AppReportAggregation agg) {
    return switch (agg) {
      AppReportAggregation.sum => GridSummaryType.sum,
      AppReportAggregation.average => GridSummaryType.average,
      AppReportAggregation.count => GridSummaryType.count,
      AppReportAggregation.min => GridSummaryType.minimum,
      AppReportAggregation.max => GridSummaryType.maximum,
    };
  }

  int _resolvedFrozenColumnsCount(List<AppReportColumn<T>> visible) {
    var leadingPinned = 0;
    for (final col in visible) {
      if (col.pinned) {
        leadingPinned++;
      } else {
        break;
      }
    }
    final n = leadingPinned > 0
        ? leadingPinned
        : widget.style.frozenColumnsCount;
    return n.clamp(0, visible.length);
  }
}

/// Default header cell for a report grid column: background, bottom divider
/// and an aligned, optionally-uppercased label.
class _ReportGridColumnHeader extends StatelessWidget {
  const _ReportGridColumnHeader({
    required this.label,
    required this.alignment,
    required this.height,
    required this.horizontalPadding,
    required this.backgroundColor,
    required this.dividerColor,
    required this.textStyle,
  });

  final String label;
  final Alignment alignment;
  final double height;
  final double horizontalPadding;
  final Color backgroundColor;
  final Color dividerColor;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
      child: Container(
        alignment: alignment,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        height: height,
        child: Text(
          label,
          style: textStyle,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / loading placeholders
// ---------------------------------------------------------------------------

/// Single rounded placeholder bar used by the loading-grid skeleton.
class _GridSkeletonBar extends StatelessWidget {
  const _GridSkeletonBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      ),
    );
  }
}

class _LoadingGridPlaceholder extends StatelessWidget {
  const _LoadingGridPlaceholder({required this.style});

  final AppReportViewerStyle style;

  static const int _skeletonRowCount = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    final density = style.density;
    final headerHeight = style.showColumnHeaders
        ? style.resolvedHeaderRowHeight(density)
        : 0.0;

    final shell = ClipRRect(
      borderRadius: BorderRadius.circular(tokens.cardRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(
              alpha: style.cardBorderAlpha,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.gapMd),
          child: style.gridHeight != null
              ? _fixedHeightSkeleton(tokens, headerHeight)
              : _intrinsicSkeleton(tokens, headerHeight, density),
        ),
      ),
    );

    return shell;
  }

  Widget _fixedHeightSkeleton(AppThemeTokens tokens, double headerHeight) {
    return SizedBox(
      height: style.gridHeight,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (headerHeight > 0) ...<Widget>[
            SizedBox(height: headerHeight, child: const _GridSkeletonBar()),
            SizedBox(height: tokens.gapSm),
          ],
          Expanded(
            child: Column(
              children: List<Widget>.generate(_skeletonRowCount, (i) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i < _skeletonRowCount - 1 ? tokens.gapXs : 0,
                    ),
                    child: const _GridSkeletonBar(),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _intrinsicSkeleton(
    AppThemeTokens tokens,
    double headerHeight,
    AppReportDensity density,
  ) {
    final rowHeight = style.resolvedDataRowHeight(density);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (headerHeight > 0) ...<Widget>[
          SizedBox(height: headerHeight, child: const _GridSkeletonBar()),
          SizedBox(height: tokens.gapSm),
        ],
        ...List<Widget>.generate(_skeletonRowCount, (i) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: i < _skeletonRowCount - 1 ? tokens.gapXs : 0,
            ),
            child: SizedBox(height: rowHeight, child: const _GridSkeletonBar()),
          );
        }),
      ],
    );
  }
}

class _EmptyGridPlaceholder extends StatelessWidget {
  const _EmptyGridPlaceholder({
    required this.message,
    required this.style,
    this.action,
  });

  final String message;
  final AppReportViewerStyle style;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;

    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.cardRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(
              alpha: style.cardBorderAlpha,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.contentSpacing),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.table_rows_outlined,
                  size: 40,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(height: tokens.gapMd),
                Text(
                  message,
                  style: typography.body.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (action != null) ...<Widget>[
                  SizedBox(height: tokens.gapMd),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
