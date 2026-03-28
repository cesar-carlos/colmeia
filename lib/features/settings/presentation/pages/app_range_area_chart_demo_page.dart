import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_range_area_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppRangeAreaChartDemoPage extends StatelessWidget {
  const AppRangeAreaChartDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Range area',
          title: 'AppRangeAreaChart',
          subtitle:
              'Mostra faixa minima/maxima, banda de confianca ou variacao '
              'esperada ao longo do tempo.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppRangeAreaChart(
          title: '1. Temperatura operacional',
          subtitle: 'Faixa minima e maxima por dia.',
          points: _temperatureRange,
          style: AppRangeAreaChartStyle(showMarkers: true),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppRangeAreaChart(
          title: '2. Faixa de faturamento esperado',
          subtitle: 'Minimo e maximo previstos para a semana.',
          points: _revenueBand,
          style: AppRangeAreaChartStyle(
            yAxisFormat: AppBrFormatters.compactCurrencyFormat,
            showTrackball: true,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: '3. Compacto com tap',
          subtitle: 'Uso em cards resumidos.',
          child: AppRangeAreaChart(
            points: _revenueBand,
            preset: AppChartPreset.compact,
            style: AppRangeAreaChartStyle(
              yAxisFormat: AppBrFormatters.compactCurrencyFormat,
              showYGridLines: false,
            ),
            onPointTap: (point, index) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${point.label}: ${point.low} - ${point.high}',
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppRangeAreaChart(
          title: '4. Estado de loading',
          points: <AppRangeAreaPoint>[],
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppRangeAreaChart(
          title: '5. Estado vazio',
          points: const <AppRangeAreaPoint>[],
          emptyPlaceholder: Text(
            'Sem faixas para este periodo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

const List<AppRangeAreaPoint> _temperatureRange = <AppRangeAreaPoint>[
  AppRangeAreaPoint(label: 'Seg', low: 17, high: 26),
  AppRangeAreaPoint(label: 'Ter', low: 18, high: 28),
  AppRangeAreaPoint(label: 'Qua', low: 19, high: 27),
  AppRangeAreaPoint(label: 'Qui', low: 20, high: 31),
  AppRangeAreaPoint(label: 'Sex', low: 18, high: 30),
  AppRangeAreaPoint(label: 'Sab', low: 21, high: 32),
  AppRangeAreaPoint(label: 'Dom', low: 19, high: 29),
];

const List<AppRangeAreaPoint> _revenueBand = <AppRangeAreaPoint>[
  AppRangeAreaPoint(label: 'Seg', low: 92000, high: 118000),
  AppRangeAreaPoint(label: 'Ter', low: 98000, high: 126000),
  AppRangeAreaPoint(label: 'Qua', low: 95000, high: 121000),
  AppRangeAreaPoint(label: 'Qui', low: 102000, high: 132000),
  AppRangeAreaPoint(label: 'Sex', low: 118000, high: 149000),
  AppRangeAreaPoint(label: 'Sab', low: 125000, high: 164000),
  AppRangeAreaPoint(label: 'Dom', low: 108000, high: 138000),
];
