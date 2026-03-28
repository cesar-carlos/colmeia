import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_radar_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppRadarChartDemoPage extends StatelessWidget {
  const AppRadarChartDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Graficos radar',
          title: 'AppRadarChart',
          subtitle:
              'Compara perfis multidimensionais em torno de eixos comuns, '
              'muito util para scorecards, maturidade e benchmark de lojas.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppRadarChart(
          title: '1. Score operacional',
          subtitle: 'Leitura unica de desempenho por dimensao.',
          points: _operationsScore,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppRadarChart(
          title: '2. Comparativo entre lojas',
          subtitle: 'Legenda e preenchimento por serie.',
          entries: <AppRadarChartEntry>[
            AppRadarChartEntry(
              label: 'Centro',
              points: _storeCentroRadar,
              color: cs.primary,
            ),
            AppRadarChartEntry(
              label: 'Norte',
              points: _storeNorteRadar,
              color: cs.tertiary,
            ),
            AppRadarChartEntry(
              label: 'Sul',
              points: _storeSulRadar,
              color: cs.secondary,
            ),
          ],
          style: const AppRadarChartStyle(maxValue: 100),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppSectionCardWithHeading(
          title: '3. Preset compacto',
          subtitle: 'Uso em cards analiticos com menos ruído visual.',
          child: AppRadarChart(
            points: _operationsScore,
            preset: AppChartPreset.compact,
            style: AppRadarChartStyle(
              showLegend: false,
              gridDivisions: 3,
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppRadarChart(
          title: '4. Estado de loading',
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppRadarChart(
          title: '5. Estado vazio',
          emptyPlaceholder: Text(
            'Nenhuma dimensao encontrada para este radar.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

const List<AppChartPoint> _operationsScore = <AppChartPoint>[
  AppChartPoint(label: 'Vendas', value: 82),
  AppChartPoint(label: 'Margem', value: 71),
  AppChartPoint(label: 'Servico', value: 90),
  AppChartPoint(label: 'Estoque', value: 67),
  AppChartPoint(label: 'Ruptura', value: 58),
  AppChartPoint(label: 'Equipe', value: 76),
];

const List<AppChartPoint> _storeCentroRadar = <AppChartPoint>[
  AppChartPoint(label: 'Vendas', value: 88),
  AppChartPoint(label: 'Margem', value: 76),
  AppChartPoint(label: 'Servico', value: 92),
  AppChartPoint(label: 'Estoque', value: 72),
  AppChartPoint(label: 'Ruptura', value: 61),
  AppChartPoint(label: 'Equipe', value: 81),
];

const List<AppChartPoint> _storeNorteRadar = <AppChartPoint>[
  AppChartPoint(label: 'Vendas', value: 74),
  AppChartPoint(label: 'Margem', value: 69),
  AppChartPoint(label: 'Servico', value: 83),
  AppChartPoint(label: 'Estoque', value: 63),
  AppChartPoint(label: 'Ruptura', value: 57),
  AppChartPoint(label: 'Equipe', value: 70),
];

const List<AppChartPoint> _storeSulRadar = <AppChartPoint>[
  AppChartPoint(label: 'Vendas', value: 79),
  AppChartPoint(label: 'Margem', value: 73),
  AppChartPoint(label: 'Servico', value: 85),
  AppChartPoint(label: 'Estoque', value: 68),
  AppChartPoint(label: 'Ruptura', value: 54),
  AppChartPoint(label: 'Equipe', value: 75),
];
