import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_area_trend_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppAreaTrendChartDemoPage extends StatelessWidget {
  const AppAreaTrendChartDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Graficos de area',
          title: 'AppAreaTrendChart',
          subtitle:
              'Tendencia temporal com area preenchida: gradiente, marcadores, '
              'zoom e variantes de estilo.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppAreaTrendChart(
          title: '1. Faturamento semanal',
          subtitle: 'Area com gradiente, eixo formatado e tooltip.',
          points: _weeklyRevenueSamples,
          style: AppAreaTrendChartStyle(
            yAxisFormat: AppBrFormatters.compactCurrencyFormat,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppAreaTrendChart(
          title: '2. Com marcadores de ponto',
          subtitle: 'Cada ponto recebe um marcador visivel.',
          points: _weeklyRevenueSamples,
          style: AppAreaTrendChartStyle(
            yAxisFormat: AppBrFormatters.compactCurrencyFormat,
            showMarkers: true,
            markerSize: 7,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppAreaTrendChart(
          title: '3. Sem gradiente (area solida)',
          subtitle: 'showGradientFill: false para area plana.',
          points: _weeklyRevenueSamples,
          style: AppAreaTrendChartStyle(
            yAxisFormat: AppBrFormatters.compactCurrencyFormat,
            showGradientFill: false,
            showMarkers: true,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppAreaTrendChart(
          title: '4. Pedidos por hora',
          subtitle: 'Pico operacional do dia — escala de unidades.',
          points: _hourlyOrderSamples,
          style: AppAreaTrendChartStyle(
            showMarkers: true,
            lineWidth: 2,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppSectionCardWithHeading(
          title: '5. Compacto sem shell',
          subtitle: 'Preset compact, sem eixos e sem shell interno.',
          child: AppAreaTrendChart(
            points: _weeklyRevenueSamples,
            preset: AppChartPreset.compact,
            style: AppAreaTrendChartStyle(
              showYGridLines: false,
              showTooltip: false,
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppAreaTrendChart(
          title: '6. Estado de loading',
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppAreaTrendChart(
          title: '7. Estado vazio',
          emptyPlaceholder: Text(
            'Sem dados para o periodo selecionado.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),

        // Multi-series
        AppAreaTrendChart(
          title: '8. Multi-series (comparativo de lojas)',
          subtitle:
              'Tres lojas sobrepostas com palette automatica. '
              'Legenda ativada.',
          entries: const <AppAreaTrendEntry>[
            AppAreaTrendEntry(
              label: 'Centro',
              points: _centroPoints,
            ),
            AppAreaTrendEntry(
              label: 'Norte',
              points: _nortePoints,
            ),
            AppAreaTrendEntry(
              label: 'Sul',
              points: _sulPoints,
            ),
          ],
          style: AppAreaTrendChartStyle(
            yAxisFormat: AppBrFormatters.compactCurrencyFormat,
            showMarkers: true,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),

        // Trackball
        AppAreaTrendChart(
          title: '9. Multi-series com trackball',
          subtitle:
              'Toque na area para ver os valores de todas as series '
              'na mesma posicao do eixo X.',
          entries: const <AppAreaTrendEntry>[
            AppAreaTrendEntry(
              label: 'Centro',
              points: _centroPoints,
            ),
            AppAreaTrendEntry(
              label: 'Norte',
              points: _nortePoints,
            ),
          ],
          style: AppAreaTrendChartStyle(
            yAxisFormat: AppBrFormatters.compactCurrencyFormat,
            showTrackball: true,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),

        // Custom colors per entry
        _TrackballCalloutDemo(tokens: tokens, cs: cs),
      ],
    );
  }
}

class _TrackballCalloutDemo extends StatefulWidget {
  const _TrackballCalloutDemo({
    required this.tokens,
    required this.cs,
  });

  final AppThemeTokens tokens;
  final ColorScheme cs;

  @override
  State<_TrackballCalloutDemo> createState() => _TrackballCalloutDemoState();
}

class _TrackballCalloutDemoState extends State<_TrackballCalloutDemo> {
  @override
  Widget build(BuildContext context) {
    return AppSectionCardWithHeading(
      title: '10. Cores por entrada',
      subtitle: 'Cor customizada por AppAreaTrendEntry.',
      child: AppAreaTrendChart(
        entries: <AppAreaTrendEntry>[
          AppAreaTrendEntry(
            label: 'Faturamento',
            points: _centroPoints,
            color: widget.cs.primary,
          ),
          AppAreaTrendEntry(
            label: 'Meta',
            points: _metaPoints,
            color: widget.cs.tertiary,
          ),
        ],
        style: AppAreaTrendChartStyle(
          yAxisFormat: AppBrFormatters.compactCurrencyFormat,
          showMarkers: true,
          showTrackball: true,
          lineWidth: 2,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sample data (demo only)
// ---------------------------------------------------------------------------

const List<AppChartPoint> _weeklyRevenueSamples = <AppChartPoint>[
  AppChartPoint(label: 'Seg', value: 92000),
  AppChartPoint(label: 'Ter', value: 108500),
  AppChartPoint(label: 'Qua', value: 97300),
  AppChartPoint(label: 'Qui', value: 115200),
  AppChartPoint(label: 'Sex', value: 131400),
  AppChartPoint(label: 'Sab', value: 148600),
  AppChartPoint(label: 'Dom', value: 119800),
];

const List<AppChartPoint> _hourlyOrderSamples = <AppChartPoint>[
  AppChartPoint(label: '08h', value: 12),
  AppChartPoint(label: '09h', value: 28),
  AppChartPoint(label: '10h', value: 45),
  AppChartPoint(label: '11h', value: 82),
  AppChartPoint(label: '12h', value: 118),
  AppChartPoint(label: '13h', value: 104),
  AppChartPoint(label: '14h', value: 73),
  AppChartPoint(label: '15h', value: 57),
  AppChartPoint(label: '16h', value: 48),
  AppChartPoint(label: '17h', value: 61),
  AppChartPoint(label: '18h', value: 88),
  AppChartPoint(label: '19h', value: 76),
];

const List<AppChartPoint> _centroPoints = <AppChartPoint>[
  AppChartPoint(label: 'Seg', value: 92000),
  AppChartPoint(label: 'Ter', value: 108500),
  AppChartPoint(label: 'Qua', value: 97300),
  AppChartPoint(label: 'Qui', value: 115200),
  AppChartPoint(label: 'Sex', value: 131400),
  AppChartPoint(label: 'Sab', value: 148600),
  AppChartPoint(label: 'Dom', value: 119800),
];

const List<AppChartPoint> _nortePoints = <AppChartPoint>[
  AppChartPoint(label: 'Seg', value: 62000),
  AppChartPoint(label: 'Ter', value: 74800),
  AppChartPoint(label: 'Qua', value: 68900),
  AppChartPoint(label: 'Qui', value: 81400),
  AppChartPoint(label: 'Sex', value: 93200),
  AppChartPoint(label: 'Sab', value: 107600),
  AppChartPoint(label: 'Dom', value: 85400),
];

const List<AppChartPoint> _sulPoints = <AppChartPoint>[
  AppChartPoint(label: 'Seg', value: 48000),
  AppChartPoint(label: 'Ter', value: 55300),
  AppChartPoint(label: 'Qua', value: 51200),
  AppChartPoint(label: 'Qui', value: 61800),
  AppChartPoint(label: 'Sex', value: 72400),
  AppChartPoint(label: 'Sab', value: 81900),
  AppChartPoint(label: 'Dom', value: 64200),
];

const List<AppChartPoint> _metaPoints = <AppChartPoint>[
  AppChartPoint(label: 'Seg', value: 100000),
  AppChartPoint(label: 'Ter', value: 100000),
  AppChartPoint(label: 'Qua', value: 100000),
  AppChartPoint(label: 'Qui', value: 100000),
  AppChartPoint(label: 'Sex', value: 130000),
  AppChartPoint(label: 'Sab', value: 130000),
  AppChartPoint(label: 'Dom', value: 110000),
];
