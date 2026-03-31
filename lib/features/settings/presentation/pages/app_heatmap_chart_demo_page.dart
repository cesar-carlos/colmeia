import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_heatmap_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppHeatmapChartDemoPage extends StatefulWidget {
  const AppHeatmapChartDemoPage({super.key});

  @override
  State<AppHeatmapChartDemoPage> createState() =>
      _AppHeatmapChartDemoPageState();
}

class _AppHeatmapChartDemoPageState extends State<AppHeatmapChartDemoPage> {
  _SalesPeriod _period = _SalesPeriod.month;
  _SalesChannel _channel = _SalesChannel.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;
    final salesFormat = NumberFormat.compactCurrency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 1,
    );
    final salesCells = _resolveSalesByHourCells(
      period: _period,
      channel: _channel,
    );
    final ticketCells = _resolveAverageTicketCells(
      cs,
      period: _period,
      channel: _channel,
    );

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Heatmap',
          title: 'AppHeatmapChart',
          subtitle:
              'Ideal para leitura de vendas: dia x hora, regiao x canal e '
              'matrizes compactas para identificar picos e quedas.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        _SalesHeatmapFilters(
          period: _period,
          channel: _channel,
          onPeriodChanged: (value) {
            setState(() {
              _period = value;
            });
          },
          onChannelChanged: (value) {
            setState(() {
              _channel = value;
            });
          },
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppHeatmapChart(
          title: '1. Receita de vendas por dia e hora',
          subtitle: 'Dados fake para destacar janelas de maior faturamento.',
          cells: salesCells,
          style: AppHeatmapChartStyle(
            numberFormat: salesFormat,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppHeatmapChart(
          title: '2. Ticket medio por regiao e canal',
          subtitle: 'Celulas abaixo da meta podem receber cor custom.',
          cells: ticketCells,
          style: const AppHeatmapChartStyle(showLegend: false),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: '3. Compacto com tap',
          subtitle: 'Preset compacto para cards e listas analiticas.',
          child: AppHeatmapChart(
            cells: salesCells,
            preset: AppChartPreset.compact,
            style: const AppHeatmapChartStyle(showLegend: false),
            onCellTapEvent: (event) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${event.item.yLabel} / ${event.item.xLabel}: '
                    '${salesFormat.format(event.item.value)} '
                    '[linha ${event.yIndex}, coluna ${event.xIndex}]',
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppHeatmapChart(
          title: '4. Estado de loading',
          cells: <AppHeatmapCell>[],
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppHeatmapChart(
          title: '5. Estado vazio',
          cells: const <AppHeatmapCell>[],
          emptyPlaceholder: Text(
            'Sem dados para a matriz atual.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

enum _SalesPeriod { month, quarter, year }

enum _SalesChannel { all, store, digital }

class _SalesHeatmapFilters extends StatelessWidget {
  const _SalesHeatmapFilters({
    required this.period,
    required this.channel,
    required this.onPeriodChanged,
    required this.onChannelChanged,
  });

  final _SalesPeriod period;
  final _SalesChannel channel;
  final ValueChanged<_SalesPeriod> onPeriodChanged;
  final ValueChanged<_SalesChannel> onChannelChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(tokens.cardRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.gapMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Filtros de vendas', style: theme.textTheme.titleSmall),
            SizedBox(height: tokens.gapSm),
            SegmentedButton<_SalesPeriod>(
              segments: const <ButtonSegment<_SalesPeriod>>[
                ButtonSegment<_SalesPeriod>(
                  value: _SalesPeriod.month,
                  label: Text('Mes'),
                ),
                ButtonSegment<_SalesPeriod>(
                  value: _SalesPeriod.quarter,
                  label: Text('Trimestre'),
                ),
                ButtonSegment<_SalesPeriod>(
                  value: _SalesPeriod.year,
                  label: Text('Ano'),
                ),
              ],
              selected: <_SalesPeriod>{period},
              onSelectionChanged: (selection) {
                onPeriodChanged(selection.first);
              },
            ),
            SizedBox(height: tokens.gapSm),
            SegmentedButton<_SalesChannel>(
              segments: const <ButtonSegment<_SalesChannel>>[
                ButtonSegment<_SalesChannel>(
                  value: _SalesChannel.all,
                  label: Text('Todos canais'),
                ),
                ButtonSegment<_SalesChannel>(
                  value: _SalesChannel.store,
                  label: Text('Loja fisica'),
                ),
                ButtonSegment<_SalesChannel>(
                  value: _SalesChannel.digital,
                  label: Text('Digital'),
                ),
              ],
              selected: <_SalesChannel>{channel},
              onSelectionChanged: (selection) {
                onChannelChanged(selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}

const List<AppHeatmapCell> _baseSalesByHourCells = <AppHeatmapCell>[
  AppHeatmapCell(xLabel: '08h', yLabel: 'Seg', value: 18000),
  AppHeatmapCell(xLabel: '10h', yLabel: 'Seg', value: 32000),
  AppHeatmapCell(xLabel: '12h', yLabel: 'Seg', value: 76000),
  AppHeatmapCell(xLabel: '14h', yLabel: 'Seg', value: 61000),
  AppHeatmapCell(xLabel: '16h', yLabel: 'Seg', value: 39000),
  AppHeatmapCell(xLabel: '18h', yLabel: 'Seg', value: 47000),
  AppHeatmapCell(xLabel: '08h', yLabel: 'Ter', value: 16000),
  AppHeatmapCell(xLabel: '10h', yLabel: 'Ter', value: 28000),
  AppHeatmapCell(xLabel: '12h', yLabel: 'Ter', value: 81000),
  AppHeatmapCell(xLabel: '14h', yLabel: 'Ter', value: 67000),
  AppHeatmapCell(xLabel: '16h', yLabel: 'Ter', value: 43000),
  AppHeatmapCell(xLabel: '18h', yLabel: 'Ter', value: 54000),
  AppHeatmapCell(xLabel: '08h', yLabel: 'Qua', value: 21000),
  AppHeatmapCell(xLabel: '10h', yLabel: 'Qua', value: 35000),
  AppHeatmapCell(xLabel: '12h', yLabel: 'Qua', value: 92000),
  AppHeatmapCell(xLabel: '14h', yLabel: 'Qua', value: 70000),
  AppHeatmapCell(xLabel: '16h', yLabel: 'Qua', value: 48000),
  AppHeatmapCell(xLabel: '18h', yLabel: 'Qua', value: 58000),
  AppHeatmapCell(xLabel: '08h', yLabel: 'Qui', value: 24000),
  AppHeatmapCell(xLabel: '10h', yLabel: 'Qui', value: 42000),
  AppHeatmapCell(xLabel: '12h', yLabel: 'Qui', value: 98000),
  AppHeatmapCell(xLabel: '14h', yLabel: 'Qui', value: 79000),
  AppHeatmapCell(xLabel: '16h', yLabel: 'Qui', value: 53000),
  AppHeatmapCell(xLabel: '18h', yLabel: 'Qui', value: 62000),
  AppHeatmapCell(xLabel: '08h', yLabel: 'Sex', value: 30000),
  AppHeatmapCell(xLabel: '10h', yLabel: 'Sex', value: 55000),
  AppHeatmapCell(xLabel: '12h', yLabel: 'Sex', value: 124000),
  AppHeatmapCell(xLabel: '14h', yLabel: 'Sex', value: 93000),
  AppHeatmapCell(xLabel: '16h', yLabel: 'Sex', value: 68000),
  AppHeatmapCell(xLabel: '18h', yLabel: 'Sex', value: 87000),
];

List<AppHeatmapCell> _resolveSalesByHourCells({
  required _SalesPeriod period,
  required _SalesChannel channel,
}) {
  final periodMultiplier = switch (period) {
    _SalesPeriod.month => 1.0,
    _SalesPeriod.quarter => 2.9,
    _SalesPeriod.year => 11.8,
  };
  final channelMultiplier = switch (channel) {
    _SalesChannel.all => 1.0,
    _SalesChannel.store => 0.72,
    _SalesChannel.digital => 0.28,
  };
  final multiplier = periodMultiplier * channelMultiplier;

  return _baseSalesByHourCells
      .map(
        (cell) => AppHeatmapCell(
          xLabel: cell.xLabel,
          yLabel: cell.yLabel,
          value: cell.value * multiplier,
        ),
      )
      .toList(growable: false);
}

List<AppHeatmapCell> _resolveAverageTicketCells(
  ColorScheme cs, {
  required _SalesPeriod period,
  required _SalesChannel channel,
}) {
  final periodDelta = switch (period) {
    _SalesPeriod.month => 0.0,
    _SalesPeriod.quarter => 6.0,
    _SalesPeriod.year => 12.0,
  };
  final channelDelta = switch (channel) {
    _SalesChannel.all => 0.0,
    _SalesChannel.store => 10.0,
    _SalesChannel.digital => -8.0,
  };
  final delta = periodDelta + channelDelta;

  AppHeatmapCell ticketCell({
    required String region,
    required String channelLabel,
    required num value,
    bool belowTarget = false,
  }) {
    final resolvedValue = (value + delta).clamp(80.0, 250.0);
    return AppHeatmapCell(
      xLabel: channelLabel,
      yLabel: region,
      value: resolvedValue,
      color: belowTarget ? cs.error : null,
    );
  }

  return <AppHeatmapCell>[
    ticketCell(region: 'Centro-Oeste', channelLabel: 'Loja', value: 165),
    ticketCell(region: 'Centro-Oeste', channelLabel: 'Digital', value: 142),
    ticketCell(
      region: 'Centro-Oeste',
      channelLabel: 'Marketplace',
      value: 118,
      belowTarget: true,
    ),
    ticketCell(region: 'Nordeste', channelLabel: 'Loja', value: 149),
    ticketCell(region: 'Nordeste', channelLabel: 'Digital', value: 136),
    ticketCell(region: 'Nordeste', channelLabel: 'Marketplace', value: 121),
    ticketCell(region: 'Sudeste', channelLabel: 'Loja', value: 182),
    ticketCell(region: 'Sudeste', channelLabel: 'Digital', value: 158),
    ticketCell(region: 'Sudeste', channelLabel: 'Marketplace', value: 133),
  ];
}
