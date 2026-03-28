import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_step_line_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppStepLineChartDemoPage extends StatefulWidget {
  const AppStepLineChartDemoPage({super.key});

  @override
  State<AppStepLineChartDemoPage> createState() =>
      _AppStepLineChartDemoPageState();
}

class _AppStepLineChartDemoPageState extends State<AppStepLineChartDemoPage> {
  String? _lastTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Graficos step line',
          title: 'AppStepLineChart',
          subtitle:
              'Linha em degraus para eventos discretos, mudancas de faixa, '
              'estoque, SLA e ocupacao por janela.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppStepLineChart(
          title: '1. Ocupacao por hora',
          subtitle: 'Mudancas abruptas entre faixas ao longo do dia.',
          points: _occupancyPoints,
          style: AppStepLineChartStyle(
            showMarkers: true,
            lineWidth: 3,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppStepLineChart(
          title: '2. SLA com data labels',
          subtitle: 'Quando a leitura discreta precisa reforcar cada degrau.',
          points: _slaPoints,
          style: AppStepLineChartStyle(
            showMarkers: true,
            showDataLabels: true,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: '3. Multi-series com trackball',
          subtitle:
              _lastTap ??
              'Comparativo de duas lojas com toque por ponto e legenda.',
          child: AppStepLineChart(
            entries: <AppStepLineEntry>[
              AppStepLineEntry(
                label: 'Centro',
                points: _storeCentroPoints,
                color: cs.primary,
              ),
              AppStepLineEntry(
                label: 'Norte',
                points: _storeNortePoints,
                color: cs.tertiary,
              ),
            ],
            onPointTap: (entry, point, pointIndex, seriesIndex) {
              setState(() {
                _lastTap =
                    'Toque: serie ${seriesIndex + 1} (${entry.label}), '
                    'ponto ${pointIndex + 1} (${point.label}) = ${point.value}';
              });
            },
            style: const AppStepLineChartStyle(
              showMarkers: true,
              showTrackball: true,
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppSectionCardWithHeading(
          title: '4. Preset compacto',
          subtitle: 'Para cards de acompanhamento continuo.',
          child: AppStepLineChart(
            points: _occupancyPoints,
            preset: AppChartPreset.compact,
            style: AppStepLineChartStyle(
              showTooltip: false,
              showLegend: false,
              showYGridLines: false,
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppStepLineChart(
          title: '5. Estado de loading',
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppStepLineChart(
          title: '6. Estado vazio',
          emptyPlaceholder: Text(
            'Nenhum degrau registrado para este recorte.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

const List<AppChartPoint> _occupancyPoints = <AppChartPoint>[
  AppChartPoint(label: '08h', value: 28),
  AppChartPoint(label: '09h', value: 28),
  AppChartPoint(label: '10h', value: 46),
  AppChartPoint(label: '11h', value: 46),
  AppChartPoint(label: '12h', value: 72),
  AppChartPoint(label: '13h', value: 72),
  AppChartPoint(label: '14h', value: 58),
  AppChartPoint(label: '15h', value: 58),
  AppChartPoint(label: '16h', value: 41),
  AppChartPoint(label: '17h', value: 41),
];

const List<AppChartPoint> _slaPoints = <AppChartPoint>[
  AppChartPoint(label: 'Seg', value: 74000),
  AppChartPoint(label: 'Ter', value: 74000),
  AppChartPoint(label: 'Qua', value: 68000),
  AppChartPoint(label: 'Qui', value: 68000),
  AppChartPoint(label: 'Sex', value: 81000),
  AppChartPoint(label: 'Sab', value: 81000),
  AppChartPoint(label: 'Dom', value: 76000),
];

const List<AppChartPoint> _storeCentroPoints = <AppChartPoint>[
  AppChartPoint(label: '08h', value: 32),
  AppChartPoint(label: '09h', value: 32),
  AppChartPoint(label: '10h', value: 48),
  AppChartPoint(label: '11h', value: 48),
  AppChartPoint(label: '12h', value: 75),
  AppChartPoint(label: '13h', value: 75),
  AppChartPoint(label: '14h', value: 63),
  AppChartPoint(label: '15h', value: 63),
];

const List<AppChartPoint> _storeNortePoints = <AppChartPoint>[
  AppChartPoint(label: '08h', value: 24),
  AppChartPoint(label: '09h', value: 24),
  AppChartPoint(label: '10h', value: 39),
  AppChartPoint(label: '11h', value: 39),
  AppChartPoint(label: '12h', value: 57),
  AppChartPoint(label: '13h', value: 57),
  AppChartPoint(label: '14h', value: 49),
  AppChartPoint(label: '15h', value: 49),
];
