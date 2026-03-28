import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_polar_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppPolarChartDemoPage extends StatelessWidget {
  const AppPolarChartDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Graficos polar',
          title: 'AppPolarChart',
          subtitle:
              'Comparacao circular por eixo angular, util para sazonalidade, '
              'janela horaria e leitura radial de intensidade.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppPolarChart(
          title: '1. Fluxo por turno',
          subtitle: 'Leitura unica por janela de operacao.',
          points: _flowByShift,
          style: AppPolarChartStyle(
            showAreaFill: true,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppPolarChart(
          title: '2. Comparativo por loja',
          subtitle: 'Series multiplas para intensidade por direcao/turno.',
          entries: <AppPolarChartEntry>[
            AppPolarChartEntry(
              label: 'Centro',
              points: _polarStoreCentro,
              color: cs.primary,
            ),
            AppPolarChartEntry(
              label: 'Norte',
              points: _polarStoreNorte,
              color: cs.tertiary,
            ),
          ],
          style: const AppPolarChartStyle(
            maxValue: 100,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppSectionCardWithHeading(
          title: '3. Preset compacto',
          subtitle: 'Formato enxuto para cards analiticos.',
          child: AppPolarChart(
            points: _flowByShift,
            preset: AppChartPreset.compact,
            style: AppPolarChartStyle(
              showLegend: false,
              showAreaFill: true,
              gridDivisions: 3,
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppPolarChart(
          title: '4. Estado de loading',
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppPolarChart(
          title: '5. Estado vazio',
          emptyPlaceholder: Text(
            'Nenhum eixo polar disponivel para este recorte.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

const List<AppChartPoint> _flowByShift = <AppChartPoint>[
  AppChartPoint(label: 'Madrugada', value: 22),
  AppChartPoint(label: 'Manha', value: 64),
  AppChartPoint(label: 'Almoco', value: 92),
  AppChartPoint(label: 'Tarde', value: 71),
  AppChartPoint(label: 'Noite', value: 88),
  AppChartPoint(label: 'Fechamento', value: 40),
];

const List<AppChartPoint> _polarStoreCentro = <AppChartPoint>[
  AppChartPoint(label: 'Madrugada', value: 18),
  AppChartPoint(label: 'Manha', value: 59),
  AppChartPoint(label: 'Almoco', value: 94),
  AppChartPoint(label: 'Tarde', value: 73),
  AppChartPoint(label: 'Noite', value: 91),
  AppChartPoint(label: 'Fechamento', value: 36),
];

const List<AppChartPoint> _polarStoreNorte = <AppChartPoint>[
  AppChartPoint(label: 'Madrugada', value: 26),
  AppChartPoint(label: 'Manha', value: 48),
  AppChartPoint(label: 'Almoco', value: 78),
  AppChartPoint(label: 'Tarde', value: 67),
  AppChartPoint(label: 'Noite', value: 80),
  AppChartPoint(label: 'Fechamento', value: 44),
];
