import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_time_series_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppTimeSeriesChartDemoPage extends StatelessWidget {
  const AppTimeSeriesChartDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Serie temporal',
          title: 'AppTimeSeriesChart',
          subtitle:
              'Grafico de serie temporal com shell opcional, preset, estilo, '
              'loading e empty.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppTimeSeriesChart(
          title: '1. Serie principal',
          subtitle: 'Receita diaria do recorte atual.',
          points: _dailyRevenuePoints,
          style: AppTimeSeriesChartStyle(
            yAxisFormat: AppBrFormatters.compactCurrencyFormat,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppTimeSeriesChart(
          title: '2. Linha mais forte e sem grid',
          subtitle: 'Foco maior na curva principal.',
          points: _dailyRevenuePoints,
          style: AppTimeSeriesChartStyle(
            yAxisFormat: AppBrFormatters.compactCurrencyFormat,
            lineWidth: 4,
            showYGridLines: false,
            chartPadding: EdgeInsets.symmetric(horizontal: tokens.gapSm),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: '3. Compacto sem shell',
          subtitle: 'Uso interno dentro de outro card.',
          child: AppTimeSeriesChart(
            points: _compactPoints,
            preset: AppChartPreset.compact,
            style: AppTimeSeriesChartStyle(
              showTooltip: false,
              showYGridLines: false,
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppTimeSeriesChart(
          title: '4. Estado de loading',
          points: const <AppChartPoint>[],
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppTimeSeriesChart(
          title: '5. Estado vazio',
          points: const <AppChartPoint>[],
          emptyPlaceholder: Text(
            'Sem historico para o periodo selecionado.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

const List<AppChartPoint> _dailyRevenuePoints = <AppChartPoint>[
  AppChartPoint(label: '01/03', value: 18200),
  AppChartPoint(label: '05/03', value: 19650),
  AppChartPoint(label: '10/03', value: 22430),
  AppChartPoint(label: '15/03', value: 20840),
  AppChartPoint(label: '20/03', value: 24120),
  AppChartPoint(label: '25/03', value: 26380),
  AppChartPoint(label: '28/03', value: 25710),
];

const List<AppChartPoint> _compactPoints = <AppChartPoint>[
  AppChartPoint(label: 'Seg', value: 12000),
  AppChartPoint(label: 'Ter', value: 13600),
  AppChartPoint(label: 'Qua', value: 11800),
  AppChartPoint(label: 'Qui', value: 14900),
  AppChartPoint(label: 'Sex', value: 17100),
];
