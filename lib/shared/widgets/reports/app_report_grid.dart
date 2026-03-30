import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_events.dart';
import 'package:colmeia/shared/widgets/reports/app_report_grid_source.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

/// Grid widget backed by [SfDataGrid] that consumes [AppReportColumn]
/// definitions and handles responsive column visibility, sorting callbacks,
/// and row interaction events.
class AppReportGrid<T> extends StatefulWidget {
  const AppReportGrid({
    required this.columns,
    required this.rows,
    required this.style,
    super.key,
    this.events = const AppReportEvents(),
    this.currentSorts = const <AppReportSortDescriptor>[],
    this.emptyMessage,
  });

  final List<AppReportColumn<T>> columns;
  final List<T> rows;
  final AppReportViewerStyle style;
  final AppReportEvents<T> events;
  final List<AppReportSortDescriptor> currentSorts;
  final String? emptyMessage;

  @override
  State<AppReportGrid<T>> createState() => _AppReportGridState<T>();
}

class _AppReportGridState<T> extends State<AppReportGrid<T>> {
  late AppReportGridSource<T> _source;
  bool _hasBuiltSource = false;
  final DataGridController _gridController = DataGridController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasBuiltSource) {
      return;
    }
    _source = _buildSource();
    _hasBuiltSource = true;
    _scheduleSyncSortFromParent();
  }

  @override
  void didUpdateWidget(covariant AppReportGrid<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final columnsChanged = oldWidget.columns != widget.columns;
    final rowsChanged = oldWidget.rows != widget.rows;
    final styleChanged =
        oldWidget.style.alternateRowColor != widget.style.alternateRowColor;
    final trustOrderChanged =
        oldWidget.style.trustServerRowOrder != widget.style.trustServerRowOrder;
    final sortsChanged = !listEquals(
      oldWidget.currentSorts,
      widget.currentSorts,
    );
    if (columnsChanged || rowsChanged || styleChanged) {
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
    if (columnsChanged ||
        rowsChanged ||
        styleChanged ||
        sortsChanged ||
        trustOrderChanged) {
      _scheduleSyncSortFromParent();
    }
  }

  void _scheduleSyncSortFromParent() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      final visible = _visibleColumns;
      final keys = visible.map((c) => c.key).toSet();
      await _source.applyExternalSortDescriptors(
        widget.currentSorts,
        keys,
        reorderRows: !widget.style.trustServerRowOrder,
      );
    });
  }

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
  }

  AppReportGridSource<T> _buildSource() {
    return AppReportGridSource<T>(
      rows: widget.rows,
      visibleColumns: _visibleColumns,
      context: context,
      alternateRowColor: widget.style.alternateRowColor,
      dataTextStyle: widget.style.dataTextStyle,
      onSortChanged: widget.events.onSortChanged,
    );
  }

  List<AppReportColumn<T>> get _visibleColumns {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return widget.columns
        .where((col) {
          final breakpoint = col.hideBelowBreakpoint;
          if (breakpoint != null && screenWidth < breakpoint) return false;
          return true;
        })
        .toList(growable: false);
  }

  List<GridColumn> _buildGridColumns(List<AppReportColumn<T>> visible) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final density = widget.style.density;
    final headerHeight = widget.style.resolvedHeaderRowHeight(density);
    final defaultHeaderTextStyle =
        widget.style.headerTextStyle ??
        theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        );

    return visible
        .map((col) {
          final labelWidget = col.headerBuilder != null
              ? col.headerBuilder!(context, col.label)
              : Container(
                  alignment: _sfAlignment(col.effectiveAlignment),
                  padding: EdgeInsets.symmetric(horizontal: tokens.gapMd),
                  height: headerHeight,
                  child: Text(
                    col.label,
                    style: col.headerTextStyle ?? defaultHeaderTextStyle,
                    overflow: TextOverflow.ellipsis,
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
  }

  List<GridTableSummaryRow> _buildSummaryRows(
    List<AppReportColumn<T>> visible,
  ) {
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

    if (summaryColumns.isEmpty) return <GridTableSummaryRow>[];

    return <GridTableSummaryRow>[
      GridTableSummaryRow(
        showSummaryInRow: false,
        columns: summaryColumns,
        position: GridTableSummaryRowPosition.bottom,
      ),
    ];
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
    if (widget.events.onRowSelection == null) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final density = widget.style.density;
    final visible = _visibleColumns;

    if (widget.rows.isEmpty) {
      return _EmptyGridPlaceholder(
        message:
            widget.emptyMessage ??
            widget.style.emptyMessage ??
            'Nenhum resultado encontrado.',
      );
    }

    final frozenCount = _resolvedFrozenColumnsCount(visible);

    final grid = SfDataGrid(
      source: _source,
      controller: _gridController,
      columns: _buildGridColumns(visible),
      tableSummaryRows: _buildSummaryRows(visible),
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
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(tokens.cardRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(tokens.cardRadius),
        ),
        child: widget.style.gridHeight != null
            ? SizedBox(height: widget.style.gridHeight, child: grid)
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

// ---------------------------------------------------------------------------
// Empty placeholder
// ---------------------------------------------------------------------------

class _EmptyGridPlaceholder extends StatelessWidget {
  const _EmptyGridPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Padding(
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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
