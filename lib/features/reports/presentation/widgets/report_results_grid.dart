import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/reports/domain/entities/report_result_row.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_events.dart';
import 'package:colmeia/shared/widgets/reports/app_report_grid.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_style.dart';
import 'package:flutter/material.dart';

/// Grid panel for the report detail page.
///
/// Delegates rendering to AppReportGrid using declarative column
/// definitions instead of a bespoke Syncfusion DataGridSource subclass.
class ReportResultsGrid extends StatelessWidget {
  const ReportResultsGrid({
    required this.rows,
    super.key,
    this.onSortChanged,
    this.onRowTap,
  });

  final List<ReportResultRow> rows;
  final ValueChanged<List<AppReportSortDescriptor>>? onSortChanged;
  final void Function(ReportResultRow row, int index)? onRowTap;

  static Object? _getSeller(ReportResultRow r) => r.seller;
  static Object? _getStore(ReportResultRow r) => r.store;
  static Object? _getOrders(ReportResultRow r) => r.orders;
  static Object? _getRevenue(ReportResultRow r) => r.revenue;

  static final List<AppReportColumn<ReportResultRow>> _columns =
      <AppReportColumn<ReportResultRow>>[
    const AppReportColumn<ReportResultRow>(
      key: 'seller',
      label: 'Vendedor',
      valueGetter: _getSeller,
    ),
    const AppReportColumn<ReportResultRow>(
      key: 'store',
      label: 'Loja',
      valueGetter: _getStore,
    ),
    const AppReportColumn<ReportResultRow>(
      key: 'orders',
      label: 'Pedidos',
      valueGetter: _getOrders,
      numeric: true,
      aggregations: <AppReportAggregation>[AppReportAggregation.sum],
      width: 90,
    ),
    AppReportColumn<ReportResultRow>(
      key: 'revenue',
      label: 'Faturamento',
      valueGetter: _getRevenue,
      formatter: (v) => AppBrFormatters.currency(v! as num),
      numeric: true,
      aggregations: const <AppReportAggregation>[AppReportAggregation.sum],
      width: 140,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    final totalRevenue = rows.fold<double>(0, (s, r) => s + r.revenue);
    final totalOrders = rows.fold<int>(0, (s, r) => s + r.orders);

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
            'Base pronta para ordenação, filtros e paginação no servidor.',
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: tokens.contentSpacing),
          Row(
            children: <Widget>[
              Expanded(
                child: _ResultSnapshotTile(
                  label: 'Linhas',
                  value: rows.length.toString(),
                ),
              ),
              SizedBox(width: tokens.gapSm),
              Expanded(
                child: _ResultSnapshotTile(
                  label: 'Pedidos',
                  value: totalOrders.toString(),
                ),
              ),
              SizedBox(width: tokens.gapSm),
              Expanded(
                child: _ResultSnapshotTile(
                  label: 'Faturamento',
                  value: AppBrFormatters.currency(totalRevenue),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.contentSpacing),
          SizedBox(
            height: 280,
            child: AppReportGrid<ReportResultRow>(
              columns: _columns,
              rows: rows,
              style: const AppReportViewerStyle(),
              events: AppReportEvents<ReportResultRow>(
                onSortChanged: onSortChanged,
                onRowTap: onRowTap,
              ),
              emptyMessage:
                  'Nenhum resultado encontrado para os filtros aplicados.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultSnapshotTile extends StatelessWidget {
  const _ResultSnapshotTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.gapMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: tokens.gapXs),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
