import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_scatter_bubble_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppScatterBubbleChartDemoPage extends StatelessWidget {
  const AppScatterBubbleChartDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Scatter e bubble',
          title: 'AppScatterBubbleChart',
          subtitle:
              'Bom para correlacao entre metricas como ticket, margem, volume '
              'e receita.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppScatterBubbleChart<_StoreCorrelation>(
          title: '1. Scatter: ticket medio x margem',
          subtitle: 'Cada ponto representa uma loja.',
          items: _storeCorrelation,
          xValueBuilder: (item) => item.avgTicket,
          yValueBuilder: (item) => item.marginPercent,
          labelBuilder: (item) => item.store,
          tooltipLabelBuilder: (item) =>
              '${item.store}: ${item.avgTicket.toStringAsFixed(0)} / '
              '${item.marginPercent.toStringAsFixed(1)}%',
          style: AppScatterBubbleChartStyle(
            xAxisTitle: 'Ticket medio',
            yAxisTitle: 'Margem %',
            xAxisFormat: AppBrFormatters.compactCurrencyFormat,
            yAxisFormat: NumberFormat("0'%'", 'pt_BR'),
            showDataLabels: true,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppScatterBubbleChart<_StoreCorrelation>(
          title: '2. Bubble: receita, margem e volume',
          subtitle: 'Tamanho da bolha representa volume de pedidos.',
          items: _storeCorrelation,
          xValueBuilder: (item) => item.revenue,
          yValueBuilder: (item) => item.marginPercent,
          bubbleSizeBuilder: (item) => item.orders,
          labelBuilder: (item) => item.store,
          colorBuilder: (item) => item.color,
          tooltipLabelBuilder: (item) =>
              '${item.store}: ${AppBrFormatters.currency(item.revenue)}',
          style: AppScatterBubbleChartStyle(
            xAxisTitle: 'Receita',
            yAxisTitle: 'Margem %',
            xAxisFormat: AppBrFormatters.compactCurrencyFormat,
            yAxisFormat: NumberFormat("0'%'", 'pt_BR'),
            showDataLabels: true,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: '3. Compacto com tap',
          subtitle: 'Preset compacto para cards exploratorios.',
          child: AppScatterBubbleChart<_StoreCorrelation>(
            items: _storeCorrelation,
            xValueBuilder: (item) => item.revenue,
            yValueBuilder: (item) => item.marginPercent,
            bubbleSizeBuilder: (item) => item.orders,
            colorBuilder: (item) => item.color,
            preset: AppChartPreset.compact,
            style: AppScatterBubbleChartStyle(
              xAxisFormat: AppBrFormatters.compactCurrencyFormat,
              yAxisFormat: NumberFormat("0'%'", 'pt_BR'),
            ),
            onPointTap: (item, index) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.store}: ${item.orders} pedidos'),
                ),
              );
            },
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppScatterBubbleChart<String>(
          title: '4. Estado de loading',
          items: <String>[],
          xValueBuilder: _zero,
          yValueBuilder: _zero,
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppScatterBubbleChart<String>(
          title: '5. Estado vazio',
          items: const <String>[],
          xValueBuilder: _zero,
          yValueBuilder: _zero,
          emptyPlaceholder: Text(
            'Sem pontos para o recorte atual.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

num _zero(String _) => 0;

class _StoreCorrelation {
  const _StoreCorrelation({
    required this.store,
    required this.avgTicket,
    required this.marginPercent,
    required this.revenue,
    required this.orders,
    required this.color,
  });

  final String store;
  final double avgTicket;
  final double marginPercent;
  final double revenue;
  final int orders;
  final Color color;
}

const List<_StoreCorrelation> _storeCorrelation = <_StoreCorrelation>[
  _StoreCorrelation(
    store: 'Centro',
    avgTicket: 88,
    marginPercent: 24,
    revenue: 248000,
    orders: 2810,
    color: Color(0xFF5B8DEF),
  ),
  _StoreCorrelation(
    store: 'Norte',
    avgTicket: 79,
    marginPercent: 19,
    revenue: 194000,
    orders: 2450,
    color: Color(0xFFF6A623),
  ),
  _StoreCorrelation(
    store: 'Sul',
    avgTicket: 92,
    marginPercent: 27,
    revenue: 226000,
    orders: 2140,
    color: Color(0xFF4CAF50),
  ),
  _StoreCorrelation(
    store: 'Leste',
    avgTicket: 74,
    marginPercent: 17,
    revenue: 168000,
    orders: 2315,
    color: Color(0xFFE57373),
  ),
];
