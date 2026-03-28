import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_heatmap_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppHeatmapChartDemoPage extends StatelessWidget {
  const AppHeatmapChartDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Heatmap',
          title: 'AppHeatmapChart',
          subtitle:
              'Ideal para densidade de operacao: hora x dia, loja x categoria '
              'e ocupacao em matrizes compactas.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppHeatmapChart(
          title: '1. Pedidos por dia e hora',
          subtitle: 'Mapa de calor operacional para leitura rapida.',
          cells: _trafficCells,
          style: AppHeatmapChartStyle(
            numberFormat: NumberFormat.decimalPattern('pt_BR'),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppHeatmapChart(
          title: '2. SLA por loja e etapa',
          subtitle: 'Pode usar cor custom por celula quando necessario.',
          cells: _slaCells(cs),
          style: const AppHeatmapChartStyle(showLegend: false),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: '3. Compacto com tap',
          subtitle: 'Preset compacto para cards e listas analiticas.',
          child: AppHeatmapChart(
            cells: _trafficCells,
            preset: AppChartPreset.compact,
            style: const AppHeatmapChartStyle(showLegend: false),
            onCellTap: (cell) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${cell.yLabel} / ${cell.xLabel}: ${cell.value}',
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

List<AppHeatmapCell> _slaCells(ColorScheme cs) => <AppHeatmapCell>[
  const AppHeatmapCell(xLabel: 'Picking', yLabel: 'Centro', value: 94),
  const AppHeatmapCell(xLabel: 'Packing', yLabel: 'Centro', value: 88),
  AppHeatmapCell(
    xLabel: 'Entrega',
    yLabel: 'Centro',
    value: 79,
    color: cs.error,
  ),
  const AppHeatmapCell(xLabel: 'Picking', yLabel: 'Norte', value: 91),
  const AppHeatmapCell(xLabel: 'Packing', yLabel: 'Norte', value: 85),
  const AppHeatmapCell(xLabel: 'Entrega', yLabel: 'Norte', value: 83),
  const AppHeatmapCell(xLabel: 'Picking', yLabel: 'Sul', value: 97),
  const AppHeatmapCell(xLabel: 'Packing', yLabel: 'Sul', value: 92),
  const AppHeatmapCell(xLabel: 'Entrega', yLabel: 'Sul', value: 89),
];

const List<AppHeatmapCell> _trafficCells = <AppHeatmapCell>[
  AppHeatmapCell(xLabel: '08h', yLabel: 'Seg', value: 12),
  AppHeatmapCell(xLabel: '10h', yLabel: 'Seg', value: 22),
  AppHeatmapCell(xLabel: '12h', yLabel: 'Seg', value: 48),
  AppHeatmapCell(xLabel: '14h', yLabel: 'Seg', value: 39),
  AppHeatmapCell(xLabel: '16h', yLabel: 'Seg', value: 24),
  AppHeatmapCell(xLabel: '18h', yLabel: 'Seg', value: 31),
  AppHeatmapCell(xLabel: '08h', yLabel: 'Ter', value: 10),
  AppHeatmapCell(xLabel: '10h', yLabel: 'Ter', value: 19),
  AppHeatmapCell(xLabel: '12h', yLabel: 'Ter', value: 51),
  AppHeatmapCell(xLabel: '14h', yLabel: 'Ter', value: 42),
  AppHeatmapCell(xLabel: '16h', yLabel: 'Ter', value: 28),
  AppHeatmapCell(xLabel: '18h', yLabel: 'Ter', value: 35),
  AppHeatmapCell(xLabel: '08h', yLabel: 'Qua', value: 14),
  AppHeatmapCell(xLabel: '10h', yLabel: 'Qua', value: 25),
  AppHeatmapCell(xLabel: '12h', yLabel: 'Qua', value: 58),
  AppHeatmapCell(xLabel: '14h', yLabel: 'Qua', value: 44),
  AppHeatmapCell(xLabel: '16h', yLabel: 'Qua', value: 30),
  AppHeatmapCell(xLabel: '18h', yLabel: 'Qua', value: 38),
  AppHeatmapCell(xLabel: '08h', yLabel: 'Qui', value: 16),
  AppHeatmapCell(xLabel: '10h', yLabel: 'Qui', value: 27),
  AppHeatmapCell(xLabel: '12h', yLabel: 'Qui', value: 60),
  AppHeatmapCell(xLabel: '14h', yLabel: 'Qui', value: 49),
  AppHeatmapCell(xLabel: '16h', yLabel: 'Qui', value: 33),
  AppHeatmapCell(xLabel: '18h', yLabel: 'Qui', value: 41),
  AppHeatmapCell(xLabel: '08h', yLabel: 'Sex', value: 20),
  AppHeatmapCell(xLabel: '10h', yLabel: 'Sex', value: 34),
  AppHeatmapCell(xLabel: '12h', yLabel: 'Sex', value: 73),
  AppHeatmapCell(xLabel: '14h', yLabel: 'Sex', value: 55),
  AppHeatmapCell(xLabel: '16h', yLabel: 'Sex', value: 39),
  AppHeatmapCell(xLabel: '18h', yLabel: 'Sex', value: 52),
];
