import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppComboChartDemoPage extends StatefulWidget {
  const AppComboChartDemoPage({super.key});

  @override
  State<AppComboChartDemoPage> createState() => _AppComboChartDemoPageState();
}

class _AppComboChartDemoPageState extends State<AppComboChartDemoPage> {
  String? _lastTapInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Graficos combinados',
          title: 'AppComboChart',
          subtitle:
              'Barra + linha num mesmo eixo X: pedidos vs ticket medio, '
              'faturamento vs margem e outras combinacoes.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppComboChart<_DaySummary>(
          title: '1. Pedidos e ticket medio (semanal)',
          subtitle:
              'Barras: quantidade de pedidos. Linha: ticket medio em reais.',
          items: _daySummarySamples,
          xLabelBuilder: (d) => d.label,
          barValueBuilder: (d) => d.orders,
          barSeriesLabel: 'Pedidos',
          lineValueBuilder: (d) => d.avgTicket,
          lineSeriesLabel: 'Ticket medio',
          style: AppComboChartStyle(
            rightAxisFormat: AppBrFormatters.compactCurrencyFormat,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppComboChart<_MonthlyMargin>(
          title: '2. Faturamento e margem bruta',
          subtitle: r'Eixos independentes: R$ (esquerda) e % (direita).',
          items: _monthlyMarginSamples,
          xLabelBuilder: (m) => m.month,
          barValueBuilder: (m) => m.revenue,
          barSeriesLabel: 'Faturamento',
          lineValueBuilder: (m) => m.marginPercent,
          lineSeriesLabel: 'Margem %',
          style: AppComboChartStyle(
            leftAxisFormat: AppBrFormatters.compactCurrencyFormat,
            rightAxisFormat: NumberFormat.percentPattern('pt_BR'),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppComboChart<_DaySummary>(
          title: '3. Marcadores e cores customizadas',
          subtitle: 'Cores customizadas para barra e linha.',
          items: _daySummarySamples,
          xLabelBuilder: (d) => d.label,
          barValueBuilder: (d) => d.orders,
          barSeriesLabel: 'Pedidos',
          lineValueBuilder: (d) => d.avgTicket,
          lineSeriesLabel: 'Ticket medio',
          style: AppComboChartStyle(
            barColor: cs.tertiary,
            lineColor: cs.error,
            rightAxisFormat: AppBrFormatters.compactCurrencyFormat,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: '4. Compacto sem shell e sem legenda',
          subtitle: 'Preset compact para uso dentro de cards.',
          child: AppComboChart<_DaySummary>(
            items: _daySummarySamples,
            xLabelBuilder: (d) => d.label,
            barValueBuilder: (d) => d.orders,
            barSeriesLabel: 'Pedidos',
            lineValueBuilder: (d) => d.avgTicket,
            lineSeriesLabel: 'Ticket',
            style: const AppComboChartStyle(
              showLegend: false,
              showYGridLines: false,
            ),
            preset: AppChartPreset.compact,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppComboChart<String>(
          title: '5. Estado de loading',
          items: const <String>[],
          xLabelBuilder: (item) => item,
          barValueBuilder: (item) => 0,
          barSeriesLabel: 'Barra',
          lineValueBuilder: (item) => 0,
          lineSeriesLabel: 'Linha',
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppComboChart<String>(
          title: '6. Estado vazio',
          items: const <String>[],
          xLabelBuilder: (item) => item,
          barValueBuilder: (item) => 0,
          barSeriesLabel: 'Barra',
          lineValueBuilder: (item) => 0,
          lineSeriesLabel: 'Linha',
          emptyPlaceholder: Text(
            'Sem dados para o recorte atual.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),

        // onBarTap + onLineTap demo
        AppSectionCardWithHeading(
          title: '7. onBarTap e onLineTap',
          subtitle: 'Toque na barra ou na linha para ver o item do callback.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppComboChart<_DaySummary>(
                items: _daySummarySamples,
                xLabelBuilder: (d) => d.label,
                barValueBuilder: (d) => d.orders,
                barSeriesLabel: 'Pedidos',
                lineValueBuilder: (d) => d.avgTicket,
                lineSeriesLabel: 'Ticket medio',
                style: AppComboChartStyle(
                  rightAxisFormat: AppBrFormatters.compactCurrencyFormat,
                  showDataLabels: true,
                ),
                onBarTap: (item, index) {
                  setState(() {
                    _lastTapInfo =
                        'Barra: ${item.label} — ${item.orders} pedidos';
                  });
                },
                onLineTap: (item, index) {
                  setState(() {
                    _lastTapInfo =
                        'Linha: ${item.label}'
                        ' — R\$ ${item.avgTicket.toStringAsFixed(2)}';
                  });
                },
              ),
              if (_lastTapInfo != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _lastTapInfo!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sample data (demo only)
// ---------------------------------------------------------------------------

class _DaySummary {
  const _DaySummary({
    required this.label,
    required this.orders,
    required this.avgTicket,
  });

  final String label;
  final int orders;
  final double avgTicket;
}

class _MonthlyMargin {
  const _MonthlyMargin({
    required this.month,
    required this.revenue,
    required this.marginPercent,
  });

  final String month;
  final double revenue;
  final double marginPercent;
}

const List<_DaySummary> _daySummarySamples = <_DaySummary>[
  _DaySummary(label: 'Seg', orders: 148, avgTicket: 82.5),
  _DaySummary(label: 'Ter', orders: 163, avgTicket: 79),
  _DaySummary(label: 'Qua', orders: 157, avgTicket: 84.2),
  _DaySummary(label: 'Qui', orders: 181, avgTicket: 88.6),
  _DaySummary(label: 'Sex', orders: 214, avgTicket: 91.3),
  _DaySummary(label: 'Sab', orders: 236, avgTicket: 95.8),
  _DaySummary(label: 'Dom', orders: 198, avgTicket: 93.1),
];

const List<_MonthlyMargin> _monthlyMarginSamples = <_MonthlyMargin>[
  _MonthlyMargin(month: 'Out', revenue: 218000, marginPercent: 0.241),
  _MonthlyMargin(month: 'Nov', revenue: 235000, marginPercent: 0.253),
  _MonthlyMargin(month: 'Dez', revenue: 312000, marginPercent: 0.228),
  _MonthlyMargin(month: 'Jan', revenue: 198000, marginPercent: 0.247),
  _MonthlyMargin(month: 'Fev', revenue: 214000, marginPercent: 0.261),
  _MonthlyMargin(month: 'Mar', revenue: 241000, marginPercent: 0.255),
];
