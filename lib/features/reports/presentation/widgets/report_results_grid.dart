import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/reports/domain/entities/report_result_row.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class ReportResultsGrid extends StatefulWidget {
  const ReportResultsGrid({
    required this.rows,
    super.key,
  });

  final List<ReportResultRow> rows;

  @override
  State<ReportResultsGrid> createState() => _ReportResultsGridState();
}

class _ReportResultsGridState extends State<ReportResultsGrid> {
  late final _SalesReportDataSource _dataSource;

  @override
  void initState() {
    super.initState();
    _dataSource = _SalesReportDataSource(widget.rows);
  }

  @override
  void didUpdateWidget(covariant ReportResultsGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rows != widget.rows) {
      _dataSource = _SalesReportDataSource(widget.rows);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Resultado tabular',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.gapXs),
          Text(
            'Base pronta para ordenacao, filtros e paginação no servidor.',
            style: theme.textTheme.bodyMedium,
          ),
          if (widget.rows.isEmpty) ...<Widget>[
            SizedBox(height: tokens.contentSpacing),
            Text(
              'Nenhum resultado encontrado para os filtros aplicados.',
              style: theme.textTheme.bodyMedium,
            ),
          ] else ...<Widget>[
            SizedBox(height: tokens.contentSpacing),
            SizedBox(
              height: 280,
              child: SfDataGrid(
                source: _dataSource,
                allowSorting: true,
                columnWidthMode: ColumnWidthMode.fill,
                columns: <GridColumn>[
                  GridColumn(
                    columnName: 'seller',
                    label: const _HeaderLabel(text: 'Vendedor'),
                  ),
                  GridColumn(
                    columnName: 'store',
                    label: const _HeaderLabel(text: 'Loja'),
                  ),
                  GridColumn(
                    columnName: 'orders',
                    label: const _HeaderLabel(text: 'Pedidos'),
                  ),
                  GridColumn(
                    columnName: 'revenue',
                    label: const _HeaderLabel(text: 'Faturamento'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SalesReportDataSource extends DataGridSource {
  _SalesReportDataSource(List<ReportResultRow> rows)
    : _rows = rows.map<DataGridRow>((row) {
        return DataGridRow(
          cells: <DataGridCell<Object>>[
            DataGridCell<String>(columnName: 'seller', value: row.seller),
            DataGridCell<String>(columnName: 'store', value: row.store),
            DataGridCell<int>(columnName: 'orders', value: row.orders),
            DataGridCell<double>(columnName: 'revenue', value: row.revenue),
          ],
        );
      }).toList();

  final List<DataGridRow> _rows;

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row
          .getCells()
          .map<Widget>((cell) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Align(
                alignment: cell.columnName == 'revenue'
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(_formatCellValue(cell)),
              ),
            );
          })
          .toList(growable: false),
    );
  }

  String _formatCellValue(DataGridCell<dynamic> cell) {
    if (cell.columnName == 'revenue') {
      return AppBrFormatters.currency(cell.value as num);
    }

    return '${cell.value}';
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: tokens.gapMd),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
