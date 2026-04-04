import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

/// Generic DataGridSource bridge between AppReportColumn definitions and
/// the Syncfusion SfDataGrid.
///
/// Converts rows into DataGridRow objects using each column's valueGetter,
/// cellBuilder, and formatter.
///
/// Rows and visible columns are copied with `List.from` so `update` can mutate
/// internal buffers. Callers often pass fixed-length lists (for example
/// `Iterable.toList(growable: false)` from the report grid).
class AppReportGridSource<T> extends DataGridSource {
  AppReportGridSource({
    required List<T> rows,
    required List<AppReportColumn<T>> visibleColumns,
    required BuildContext context,
    this.onSortChanged,
    this.alternateRowColor,
    this.dataTextStyle,
  }) : _rows = List<T>.from(rows),
       _columns = List<AppReportColumn<T>>.from(visibleColumns),
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

  List<DataGridRow> resolveDataGridRows(Iterable<T> rows) {
    final remainingRows = List<T>.from(rows);
    final matches = <DataGridRow>[];

    for (
      var visualIndex = 0;
      visualIndex < effectiveRows.length;
      visualIndex++
    ) {
      final dataGridRow = effectiveRows[visualIndex];
      final entry = _resolveRowEntry(dataGridRow);
      if (entry == null) {
        continue;
      }

      final selectedIndex = remainingRows.indexOf(entry.row);
      if (selectedIndex == -1) {
        continue;
      }

      matches.add(dataGridRow);
      remainingRows.removeAt(selectedIndex);
      if (remainingRows.isEmpty) {
        break;
      }
    }

    return matches;
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
      for (final group in groupedColumns) {
        if (!visibleColumnKeys.contains(group.name)) {
          continue;
        }
        sortedColumns.add(
          SortColumnDetails(
            name: group.name,
            sortDirection: DataGridSortDirection.ascending,
          ),
        );
      }
      for (final s in sorts) {
        if (!visibleColumnKeys.contains(s.columnKey)) {
          continue;
        }
        if (sortedColumns.any((entry) => entry.name == s.columnKey)) {
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

  void applyExternalGroupDescriptors(
    List<AppReportGroupDescriptor> groups,
    Set<String> visibleColumnKeys,
  ) {
    _suppressSortCallback = true;
    try {
      clearColumnGroups();
      for (final group in groups) {
        if (!visibleColumnKeys.contains(group.columnKey)) {
          continue;
        }
        addColumnGroup(
          ColumnGroup(
            name: group.columnKey,
            sortGroupRows: true,
          ),
        );
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
    final tokens = Theme.of(_context).extension<AppThemeTokens>()!;

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
            final cellStyle = col?.cellStyle ?? AppReportCellStyle.plain;
            final leading = (col != null &&
                    col.leadingBuilder != null &&
                    sourceRow != null)
                ? col.leadingBuilder!(_context, sourceRow, cell.value)
                : null;

            Widget buildText(TextStyle? style, {int maxLines = 2}) {
              final text = Text(
                displayText,
                style: style,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              );
              if (leading == null) {
                return text;
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  leading,
                  SizedBox(width: tokens.gapSm),
                  Expanded(child: text),
                ],
              );
            }

            if (cellStyle == AppReportCellStyle.link) {
              final theme = Theme.of(_context);
              return Container(
                alignment: alignment,
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.gapMd,
                  vertical: tokens.gapSm,
                ),
                child: buildText(
                  (col?.textStyle ?? dataTextStyle)?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ) ??
                      TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              );
            }

            if (cellStyle == AppReportCellStyle.badge) {
              final theme = Theme.of(_context);
              return Container(
                alignment: alignment,
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.gapMd,
                  vertical: tokens.gapSm,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius:
                        BorderRadius.circular(tokens.formFieldRadius / 2),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.gapSm,
                      vertical: tokens.gapXs / 2,
                    ),
                    child: buildText(
                      (col?.textStyle ?? dataTextStyle)?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ) ??
                          const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                      maxLines: 1,
                    ),
                  ),
                ),
              );
            }

            return Container(
              alignment: alignment,
              padding: EdgeInsets.symmetric(
                horizontal: tokens.gapMd,
                vertical: tokens.gapSm,
              ),
              child: buildText(
                col?.textStyle ?? dataTextStyle,
              ),
            );
          })
          .toList(growable: false),
    );
  }

  @override
  Widget? buildGroupCaptionCellWidget(
    RowColumnIndex rowColumnIndex,
    String summaryValue,
  ) {
    final theme = Theme.of(_context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final caption = _parseGroupCaption(summaryValue);
    final labelByKey = <String, String>{
      for (final column in _columns) column.key: column.label,
    };
    final columnLabel = labelByKey[caption.columnKey] ?? caption.columnKey;
    final itemLabel = caption.itemCount == 1
        ? '1 item'
        : '${caption.itemCount} itens';

    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(
        horizontal: tokens.contentSpacing,
        vertical: tokens.gapSm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;
          final title = RichText(
            maxLines: compact ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: typography.caption.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
              children: <InlineSpan>[
                TextSpan(
                  text: '$columnLabel: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: caption.groupKey,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
          final header = Row(
            children: <Widget>[
              Icon(
                Icons.unfold_more_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: tokens.gapXs),
              Expanded(child: title),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                header,
                SizedBox(height: tokens.gapXs),
                _GroupCountChip(label: itemLabel),
              ],
            );
          }

          return Row(
            children: <Widget>[
              Expanded(child: header),
              SizedBox(width: tokens.gapSm),
              _GroupCountChip(label: itemLabel),
            ],
          );
        },
      ),
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
  ///
  /// `count` uses non-null valueGetter results only; `sum`, `average`, `min`,
  /// and `max` use numeric values only.
  String buildSummaryValue(
    AppReportColumn<T> column,
    AppReportAggregation aggregation,
  ) {
    if (aggregation == AppReportAggregation.count) {
      final nonNullCount = _rows
          .map(column.valueGetter)
          .where((v) => v != null)
          .length;
      return column.formatValue(nonNullCount);
    }

    final values = _rows
        .map(column.valueGetter)
        .whereType<num>()
        .toList(growable: false);

    if (values.isEmpty) return '';

    final result = switch (aggregation) {
      AppReportAggregation.sum => values.fold<num>(0, (acc, v) => acc + v),
      AppReportAggregation.average =>
        values.fold<num>(0, (acc, v) => acc + v) / values.length,
      AppReportAggregation.min => values.reduce((a, b) => a < b ? a : b),
      AppReportAggregation.max => values.reduce((a, b) => a > b ? a : b),
      AppReportAggregation.count => throw StateError(
        'count is handled before numeric aggregation',
      ),
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

  static ({String columnKey, String groupKey, int itemCount})
  _parseGroupCaption(
    String summaryValue,
  ) {
    final parts = summaryValue.split('|');
    if (parts.length == 3) {
      return (
        columnKey: parts[0],
        groupKey: parts[1],
        itemCount: int.tryParse(parts[2]) ?? 0,
      );
    }

    return (
      columnKey: '',
      groupKey: summaryValue,
      itemCount: 0,
    );
  }
}

class _GroupCountChip extends StatelessWidget {
  const _GroupCountChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppTagChip(
      label: label,
      foregroundColor: theme.colorScheme.onSurfaceVariant,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      borderColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
    );
  }
}
