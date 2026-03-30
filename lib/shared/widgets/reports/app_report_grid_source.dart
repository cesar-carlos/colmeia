import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

/// Generic DataGridSource bridge between AppReportColumn definitions and
/// the Syncfusion SfDataGrid.
///
/// Converts rows into DataGridRow objects using each column's valueGetter,
/// cellBuilder, and formatter.
class AppReportGridSource<T> extends DataGridSource {
  AppReportGridSource({
    required List<T> rows,
    required List<AppReportColumn<T>> visibleColumns,
    required BuildContext context,
    this.onSortChanged,
    this.alternateRowColor,
    this.dataTextStyle,
  }) : _rows = rows,
       _columns = visibleColumns,
       _context = context {
    _buildRows();
  }

  final List<T> _rows;
  final List<AppReportColumn<T>> _columns;
  final BuildContext _context;

  /// Fired when the user changes column sort. Emits the new sort state.
  final ValueChanged<List<AppReportSortDescriptor>>? onSortChanged;

  final Color? alternateRowColor;
  final TextStyle? dataTextStyle;

  bool _suppressSortCallback = false;

  List<DataGridRow> _dataGridRows = <DataGridRow>[];
  final Map<DataGridRow, int> _rowIndexByDataGridRow = <DataGridRow, int>{};

  @override
  List<DataGridRow> get rows => _dataGridRows;

  void update({
    required List<T> rows,
    required List<AppReportColumn<T>> visibleColumns,
  }) {
    _rows
      ..clear()
      ..addAll(rows);
    _columns
      ..clear()
      ..addAll(visibleColumns);
    _buildRows();
    notifyListeners();
  }

  void _buildRows() {
    _rowIndexByDataGridRow.clear();
    _dataGridRows = _rows.asMap().entries.map((entry) {
      final index = entry.key;
      final row = entry.value;
      final dgRow = DataGridRow(
        cells: _columns
            .map<DataGridCell<Object?>>((col) {
              return DataGridCell<Object?>(
                columnName: col.key,
                value: col.valueGetter(row),
              );
            })
            .toList(growable: false),
      );
      _rowIndexByDataGridRow[dgRow] = index;
      return dgRow;
    }).toList();
  }

  ({T row, int sourceIndex})? resolveRowEntryAt(int visualRowIndex) {
    final rows = effectiveRows;
    if (visualRowIndex < 0 || visualRowIndex >= rows.length) {
      return null;
    }

    return _resolveRowEntry(rows[visualRowIndex]);
  }

  List<T> resolveRows(Iterable<DataGridRow> dataGridRows) {
    return dataGridRows
        .map(_resolveRowEntry)
        .whereType<({T row, int sourceIndex})>()
        .map((entry) => entry.row)
        .toList(growable: false);
  }

  ({T row, int sourceIndex})? _resolveRowEntry(DataGridRow dataGridRow) {
    final sourceIndex = _rowIndexByDataGridRow[dataGridRow];
    if (sourceIndex == null || sourceIndex < 0 || sourceIndex >= _rows.length) {
      return null;
    }

    return (row: _rows[sourceIndex], sourceIndex: sourceIndex);
  }

  /// Aligns Syncfusion [sortedColumns] with app-level [sorts] without
  /// notifying [onSortChanged] (avoids feedback loops).
  ///
  /// When [reorderRows] is false, only indicators refresh — row order stays
  /// as built from the last [rows] list (e.g. server-sorted).
  Future<void> applyExternalSortDescriptors(
    List<AppReportSortDescriptor> sorts,
    Set<String> visibleColumnKeys, {
    bool reorderRows = true,
  }) async {
    _suppressSortCallback = true;
    try {
      sortedColumns.clear();
      for (final s in sorts) {
        if (!visibleColumnKeys.contains(s.columnKey)) {
          continue;
        }
        sortedColumns.add(
          SortColumnDetails(
            name: s.columnKey,
            sortDirection: s.direction == AppReportSortDirection.ascending
                ? DataGridSortDirection.ascending
                : DataGridSortDirection.descending,
          ),
        );
      }
      if (reorderRows) {
        await sort();
      } else {
        notifyListeners();
      }
    } finally {
      _suppressSortCallback = false;
    }
  }

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final index = _rowIndexByDataGridRow[row] ?? -1;
    final sourceRow = index >= 0 && index < _rows.length ? _rows[index] : null;
    final useAltColor = alternateRowColor != null && index.isOdd;

    return DataGridRowAdapter(
      color: useAltColor ? alternateRowColor : null,
      cells: row
          .getCells()
          .asMap()
          .entries
          .map<Widget>((entry) {
            final colIndex = entry.key;
            final cell = entry.value;
            final col = colIndex < _columns.length ? _columns[colIndex] : null;

            if (col != null && col.cellBuilder != null && sourceRow != null) {
              return col.cellBuilder!(_context, sourceRow, cell.value);
            }

            final displayText = col?.formatValue(cell.value) ?? '${cell.value}';
            final alignment = _resolveAlignment(col?.effectiveAlignment);

            return Container(
              alignment: alignment,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                displayText,
                style: col?.textStyle ?? dataTextStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          })
          .toList(growable: false),
    );
  }

  /// Overridden to intercept sort state changes and propagate them externally.
  @override
  Future<void> performSorting(List<DataGridRow> rows) async {
    await super.performSorting(rows);
    if (_suppressSortCallback || onSortChanged == null) {
      return;
    }
    final descriptors = sortedColumns
        .map((sc) {
          return AppReportSortDescriptor(
            columnKey: sc.name,
            direction: sc.sortDirection == DataGridSortDirection.ascending
                ? AppReportSortDirection.ascending
                : AppReportSortDirection.descending,
          );
        })
        .toList(growable: false);
    onSortChanged!(descriptors);
  }

  /// Builds a summary value string for a given [AppReportAggregation] on the
  /// provided column. Used by the grid summary row.
  String buildSummaryValue(
    AppReportColumn<T> column,
    AppReportAggregation aggregation,
  ) {
    final values = _rows
        .map(column.valueGetter)
        .whereType<num>()
        .toList(growable: false);

    if (values.isEmpty) return '';

    final result = switch (aggregation) {
      AppReportAggregation.sum => values.fold<num>(0, (acc, v) => acc + v),
      AppReportAggregation.average =>
        values.fold<num>(0, (acc, v) => acc + v) / values.length,
      AppReportAggregation.count => values.length,
      AppReportAggregation.min => values.reduce((a, b) => a < b ? a : b),
      AppReportAggregation.max => values.reduce((a, b) => a > b ? a : b),
    };

    return column.formatValue(result);
  }

  static Alignment _resolveAlignment(AppReportColumnAlignment? alignment) {
    return switch (alignment) {
      AppReportColumnAlignment.end => Alignment.centerRight,
      AppReportColumnAlignment.center => Alignment.center,
      _ => Alignment.centerLeft,
    };
  }
}
