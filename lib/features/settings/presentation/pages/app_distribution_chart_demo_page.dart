import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_distribution_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppDistributionChartDemoPage extends StatelessWidget {
  const AppDistributionChartDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Distribuicao',
          title: 'AppDistributionChart',
          subtitle:
              'Grafico de distribuicao com shell opcional, legenda, tooltip, '
              'loading e empty.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppDistributionChart(
          title: '1. Mix de categorias',
          subtitle: 'Participacao por categoria no recorte atual.',
          points: _categoryMixPoints,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppDistributionChart(
          title: '2. Sem legenda e com area compacta',
          subtitle: 'Uso mais enxuto para cards secundarios.',
          points: _channelMixPoints,
          style: AppDistributionChartStyle(
            showLegend: false,
            chartPadding: EdgeInsets.all(tokens.gapSm),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppSectionCardWithHeading(
          title: '3. Compacto sem shell',
          subtitle: 'Ideal para composicoes dentro de outra secao.',
          child: AppDistributionChart(
            points: _paymentMixPoints,
            preset: AppChartPreset.compact,
            style: AppDistributionChartStyle(
              showTooltip: false,
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppDistributionChart(
          title: '4. Estado de loading',
          points: <AppChartPoint>[],
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppDistributionChart(
          title: '5. Estado vazio',
          points: const <AppChartPoint>[],
          emptyPlaceholder: Text(
            'Sem distribuicao disponivel para este recorte.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

const List<AppChartPoint> _categoryMixPoints = <AppChartPoint>[
  AppChartPoint(label: 'Bebidas', value: 42),
  AppChartPoint(label: 'Lanches', value: 28),
  AppChartPoint(label: 'Mercearia', value: 18),
  AppChartPoint(label: 'Outros', value: 12),
];

const List<AppChartPoint> _channelMixPoints = <AppChartPoint>[
  AppChartPoint(label: 'Balcao', value: 46),
  AppChartPoint(label: 'Delivery', value: 33),
  AppChartPoint(label: 'Retirada', value: 21),
];

const List<AppChartPoint> _paymentMixPoints = <AppChartPoint>[
  AppChartPoint(label: 'Pix', value: 37),
  AppChartPoint(label: 'Credito', value: 34),
  AppChartPoint(label: 'Debito', value: 19),
  AppChartPoint(label: 'Dinheiro', value: 10),
];
