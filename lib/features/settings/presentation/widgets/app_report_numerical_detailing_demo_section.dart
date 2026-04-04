import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:colmeia/shared/widgets/reports/app_report_events.dart';
import 'package:colmeia/shared/widgets/reports/app_report_export_handler.dart';
import 'package:colmeia/shared/widgets/reports/app_report_header_actions.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:colmeia/shared/widgets/reports/app_report_query.dart';
import 'package:colmeia/shared/widgets/reports/app_report_rich_cells.dart';
import 'package:colmeia/shared/widgets/reports/app_report_style.dart';
import 'package:colmeia/shared/widgets/reports/app_report_viewer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum _NumericalChannelStatus { stable, rising, normal }

class _NumericalDetailRow {
  const _NumericalDetailRow({
    required this.channelLabel,
    required this.channelSubtitle,
    required this.iconData,
    required this.iconBackground,
    required this.volume,
    required this.revenue,
    required this.marginPct,
    required this.emphasizeMargin,
    required this.status,
  });

  final String channelLabel;
  final String channelSubtitle;
  final IconData iconData;
  final Color iconBackground;
  final int volume;
  final double revenue;
  final double marginPct;
  final bool emphasizeMargin;
  final _NumericalChannelStatus status;
}

const List<_NumericalDetailRow> _kNumericalDemoRows = <_NumericalDetailRow>[
  _NumericalDetailRow(
    channelLabel: 'Mercearia',
    channelSubtitle: 'Principal Core Business',
    iconData: Icons.storefront_outlined,
    iconBackground: Color(0xFFFFF4CC),
    volume: 3132,
    revenue: 496200,
    marginPct: 22.4,
    emphasizeMargin: true,
    status: _NumericalChannelStatus.stable,
  ),
  _NumericalDetailRow(
    channelLabel: 'Bebidas',
    channelSubtitle: 'Sazonalidade Alta',
    iconData: Icons.local_bar_outlined,
    iconBackground: Color(0xFFE0F2FE),
    volume: 2104,
    revenue: 372150,
    marginPct: 31.2,
    emphasizeMargin: true,
    status: _NumericalChannelStatus.rising,
  ),
  _NumericalDetailRow(
    channelLabel: 'Lanches',
    channelSubtitle: 'Operacao Regular',
    iconData: Icons.lunch_dining_outlined,
    iconBackground: Color(0xFFFFE4EC),
    volume: 980,
    revenue: 248100,
    marginPct: 18.5,
    emphasizeMargin: false,
    status: _NumericalChannelStatus.normal,
  ),
];

class AppReportNumericalDetailingDemoSection extends StatefulWidget {
  const AppReportNumericalDetailingDemoSection({super.key});

  @override
  State<AppReportNumericalDetailingDemoSection> createState() =>
      _AppReportNumericalDetailingDemoSectionState();
}

class _AppReportNumericalDetailingDemoSectionState
    extends State<AppReportNumericalDetailingDemoSection> {
  AppReportQuery _query = const AppReportQuery(pageSize: 10);

  List<_NumericalDetailRow> get _pageRows {
    final start = (_query.page - 1) * _query.pageSize;
    final end = (start + _query.pageSize).clamp(0, _kNumericalDemoRows.length);
    if (start >= _kNumericalDemoRows.length) {
      return <_NumericalDetailRow>[];
    }
    return _kNumericalDemoRows.sublist(start, end);
  }

  AppReportPageInfo get _pageInfo {
    final total = _kNumericalDemoRows.length;
    final totalPages = total == 0 ? 0 : (total / _query.pageSize).ceil();
    return AppReportPageInfo(
      currentPage: _query.page,
      pageSize: _query.pageSize,
      totalRows: total,
      totalPages: totalPages,
    );
  }

  void _onQueryChanged(AppReportQuery query) {
    setState(() {
      _query = query;
      final totalPages = _pageInfo.totalPages;
      if (totalPages == 0) {
        _query = _query.copyWith(page: 1);
        return;
      }
      final clamped = _query.page.clamp(1, totalPages);
      if (clamped != _query.page) {
        _query = _query.copyWith(page: clamped);
      }
    });
  }

  Future<void> _export(
    BuildContext context,
    AppReportExportFormat format,
  ) async {
    try {
      await AppReportExportHandler.export<_NumericalDetailRow>(
        request: AppReportExportRequest(format: format),
        columns: _columns(context),
        rows: _pageRows,
        title: 'Detalhamento Numerico',
        context: context,
      );
    } on Exception {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao exportar.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSectionCardWithHeading(
      title: 'Preset: detalhamento numerico',
      subtitle:
          'Preset com acoes compactas, hierarquia numerica e colunas '
          'responsivas para tabelas executivas.',
      child: SizedBox(
        height: 460,
        child: AppReportViewer<_NumericalDetailRow>(
          title: 'Detalhamento Numerico',
          headerActions: <Widget>[
            AppReportHeaderActionButton(
              label: 'JSON',
              icon: AppReportExportFormat.json.icon,
              tooltip: 'Exportar detalhes em JSON',
              onPressed: () => _export(context, AppReportExportFormat.json),
            ),
            AppReportHeaderActionButton(
              label: 'CSV',
              icon: AppReportExportFormat.csv.icon,
              tooltip: 'Exportar detalhes em CSV',
              tone: AppReportHeaderActionTone.primary,
              onPressed: () => _export(context, AppReportExportFormat.csv),
            ),
          ],
          columns: _columns(context),
          rows: _pageRows,
          pageInfo: _pageInfo,
          query: _query,
          events: AppReportEvents<_NumericalDetailRow>(
            onQueryChanged: _onQueryChanged,
          ),
          style: AppReportViewerStyle.numericalDetailing(
            gridHeight: 320,
          ).copyWith(enablePullToRefresh: false),
          emptyMessage: 'Sem linhas para exibir.',
        ),
      ),
    );
  }

  List<AppReportColumn<_NumericalDetailRow>> _columns(BuildContext context) {
    final theme = Theme.of(context);
    final typography = theme.appTypography;
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
    final volumeFmt = NumberFormat.decimalPattern('pt_BR');
    final marginFmt = NumberFormat('#,##0.0', 'pt_BR');

    return <AppReportColumn<_NumericalDetailRow>>[
      AppReportColumn<_NumericalDetailRow>(
        key: 'channel',
        label: 'CATEGORIA / CANAL',
        valueGetter: (row) => row.channelLabel,
        pinned: true,
        minWidth: 240,
        cellBuilder: (ctx, row, _) {
          return AppReportIconTitleSubtitleCell(
            title: row.channelLabel,
            subtitle: row.channelSubtitle,
            icon: row.iconData,
            leadingBackgroundColor: row.iconBackground,
            leadingForegroundColor: theme.colorScheme.onSurface,
          );
        },
      ),
      AppReportColumn<_NumericalDetailRow>(
        key: 'volume',
        label: 'VOLUME',
        valueGetter: (row) => row.volume,
        formatter: (value) => '${volumeFmt.format(value)} unid.',
        numeric: true,
        minWidth: 120,
        hideBelowBreakpoint: AppBreakpoints.reportColumnHideNarrow,
      ),
      AppReportColumn<_NumericalDetailRow>(
        key: 'revenue',
        label: 'FATURAMENTO BRUTO',
        valueGetter: (row) => row.revenue,
        formatter: (value) {
          if (value is! num) {
            return '';
          }
          return currencyFmt.format(value);
        },
        numeric: true,
        minWidth: 156,
        cellBuilder: (ctx, row, _) {
          return Text(
            currencyFmt.format(row.revenue),
            style: typography.body.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          );
        },
      ),
      AppReportColumn<_NumericalDetailRow>(
        key: 'margin',
        label: 'MARGEM MEDIA',
        valueGetter: (row) => row.marginPct,
        formatter: (value) => '${marginFmt.format(value)}%',
        numeric: true,
        minWidth: 110,
        hideBelowBreakpoint: AppBreakpoints.reportColumnHideMedium,
        cellBuilder: (ctx, row, _) {
          final color = row.emphasizeMargin
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface;
          return Text(
            '${marginFmt.format(row.marginPct)}%',
            style: typography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          );
        },
      ),
      AppReportColumn<_NumericalDetailRow>(
        key: 'status',
        label: 'STATUS',
        valueGetter: (row) => _statusLabel(row.status),
        sortable: false,
        minWidth: 120,
        hideBelowBreakpoint: AppBreakpoints.reportColumnHideWide,
        cellBuilder: (ctx, row, _) {
          final palette = switch (row.status) {
            _NumericalChannelStatus.stable => (
              theme.colorScheme.tertiaryContainer,
              theme.colorScheme.onTertiaryContainer,
              Icons.verified_outlined,
            ),
            _NumericalChannelStatus.rising => (
              theme.colorScheme.secondaryContainer,
              theme.colorScheme.onSecondaryContainer,
              Icons.trending_up_rounded,
            ),
            _NumericalChannelStatus.normal => (
              theme.colorScheme.surfaceContainerHighest,
              theme.colorScheme.onSurfaceVariant,
              Icons.remove_rounded,
            ),
          };
          return AppReportStatusPillCell(
            label: _statusLabel(row.status),
            icon: palette.$3,
            backgroundColor: palette.$1,
            foregroundColor: palette.$2,
          );
        },
      ),
      AppReportColumn<_NumericalDetailRow>(
        key: 'action',
        label: 'ACAO',
        valueGetter: (_) => 'view',
        sortable: false,
        width: 72,
        alignment: AppReportColumnAlignment.center,
        hideBelowBreakpoint: AppBreakpoints.reportColumnHideWide,
        cellBuilder: (ctx, row, _) {
          return AppReportIconActionCell(
            icon: Icons.visibility_outlined,
            tooltip: 'Ver detalhes',
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.44,
            ),
            borderColor: theme.colorScheme.primary.withValues(alpha: 0.16),
            size: 34,
            onPressed: () {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Detalhes: ${row.channelLabel}')),
              );
            },
          );
        },
      ),
    ];
  }
}

String _statusLabel(_NumericalChannelStatus status) {
  return switch (status) {
    _NumericalChannelStatus.stable => 'ESTAVEL',
    _NumericalChannelStatus.rising => 'CRESCENTE',
    _NumericalChannelStatus.normal => 'NORMAL',
  };
}
