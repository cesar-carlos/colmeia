import 'dart:convert';
import 'dart:typed_data';

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppRegionMapChartDemoPage extends StatefulWidget {
  const AppRegionMapChartDemoPage({super.key});

  @override
  State<AppRegionMapChartDemoPage> createState() =>
      _AppRegionMapChartDemoPageState();
}

class _AppRegionMapChartDemoPageState extends State<AppRegionMapChartDemoPage> {
  static final AppMapDefinition _mapDefinition = AppMapDefinition.memory(
    sourceBytes: Uint8List.fromList(utf8.encode(_brazilRegionsGeoJson)),
    shapeDataField: 'id',
    regionLevel: AppMapRegionLevel.region,
  );

  String _selectedMetricKey = _revenueMetricKey;
  String? _selectedRegionKey;
  String? _selectionSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Graficos territoriais',
          title: 'AppRegionMapChart',
          subtitle:
              'Mapa interativo para dashboards de gestao com troca de metrica, '
              'selecao territorial e eventos tipados para sincronizar '
              'cards, grids e outros graficos.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppRegionMapChart<_RegionMetric>(
          title: '1. Vendas por regiao',
          subtitle:
              'Troque a metrica no seletor e toque em uma regiao para '
              'navegacao analitica.',
          items: _regionMetrics,
          mapDefinition: _mapDefinition,
          metrics: _metrics,
          selectedMetricKey: _selectedMetricKey,
          selectedRegionKey: _selectedRegionKey,
          regionKeyBuilder: (item) => item.regionKey,
          regionLabelBuilder: (item) => item.regionLabel,
          onMetricChanged: (event) {
            setState(() {
              _selectedMetricKey = event.metricKey;
            });
          },
          onSelectionChanged: (event) {
            setState(() {
              _selectedRegionKey = event.currentRegionKey;
            });
          },
          onRegionTapEvent: (event) {
            setState(() {
              _selectionSummary =
                  'Selecionado: ${event.regionLabel} '
                  '(metrica: ${event.metricKey}, valor: '
                  '${event.metricValue.toStringAsFixed(1)})';
            });
          },
          style: AppRegionMapChartStyle(
            showDataLabels: true,
            selectionColor: cs.primary.withValues(alpha: 0.24),
          ),
          preset: AppChartPreset.explorable,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: '2. Evento de interatividade',
          subtitle:
              _selectionSummary ??
              'Toque no mapa para emitir `onRegionTapEvent` e sincronizar '
                  'com outros componentes.',
          child: const SizedBox.shrink(),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppRegionMapChart<_RegionMetric>(
          title: '3. Preset compacto',
          subtitle: 'Leitura rapida para cards executivos.',
          items: _regionMetrics,
          mapDefinition: _mapDefinition,
          metrics: _metrics,
          selectedMetricKey: _marginMetricKey,
          regionKeyBuilder: _regionKeyOf,
          regionLabelBuilder: _regionLabelOf,
          preset: AppChartPreset.compact,
          style: const AppRegionMapChartStyle(
            showLegend: false,
            showTooltip: false,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppRegionMapChart<String>(
          title: '4. Estado de loading',
          items: const <String>[],
          mapDefinition: _mapDefinition,
          metrics: const <AppMapMetric<String>>[
            AppMapMetric<String>(
              key: 'placeholder',
              label: 'Placeholder',
              valueBuilder: _zeroMetric,
            ),
          ],
          selectedMetricKey: 'placeholder',
          regionKeyBuilder: _identity,
          regionLabelBuilder: _identity,
          isLoading: true,
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppRegionMapChart<String>(
          title: '5. Estado vazio',
          items: const <String>[],
          mapDefinition: _mapDefinition,
          metrics: const <AppMapMetric<String>>[
            AppMapMetric<String>(
              key: 'placeholder',
              label: 'Placeholder',
              valueBuilder: _zeroMetric,
            ),
          ],
          selectedMetricKey: 'placeholder',
          regionKeyBuilder: _identity,
          regionLabelBuilder: _identity,
          emptyPlaceholder: Text(
            'Nenhum dado territorial disponivel para este recorte.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

String _identity(String value) => value;

num _zeroMetric(String _) => 0;

String _regionKeyOf(_RegionMetric item) => item.regionKey;

String _regionLabelOf(_RegionMetric item) => item.regionLabel;

const String _revenueMetricKey = 'revenue';
const String _marginMetricKey = 'margin';
const String _growthMetricKey = 'growth';

class _RegionMetric {
  const _RegionMetric({
    required this.regionKey,
    required this.regionLabel,
    required this.revenue,
    required this.margin,
    required this.growth,
  });

  final String regionKey;
  final String regionLabel;
  final double revenue;
  final double margin;
  final double growth;
}

const List<_RegionMetric> _regionMetrics = <_RegionMetric>[
  _RegionMetric(
    regionKey: 'north',
    regionLabel: 'Norte',
    revenue: 1380000,
    margin: 17.4,
    growth: 9.2,
  ),
  _RegionMetric(
    regionKey: 'northeast',
    regionLabel: 'Nordeste',
    revenue: 1640000,
    margin: 15.3,
    growth: 7.1,
  ),
  _RegionMetric(
    regionKey: 'midwest',
    regionLabel: 'Centro-Oeste',
    revenue: 1210000,
    margin: 18.9,
    growth: 8.4,
  ),
  _RegionMetric(
    regionKey: 'southeast',
    regionLabel: 'Sudeste',
    revenue: 2740000,
    margin: 16.1,
    growth: 6.2,
  ),
  _RegionMetric(
    regionKey: 'south',
    regionLabel: 'Sul',
    revenue: 1980000,
    margin: 19.4,
    growth: 7.8,
  ),
];

final List<AppMapMetric<_RegionMetric>> _metrics =
    <AppMapMetric<_RegionMetric>>[
      AppMapMetric<_RegionMetric>(
        key: _revenueMetricKey,
        label: 'Receita',
        valueBuilder: (item) => item.revenue,
        tooltipBuilder: (item) =>
            '${item.regionLabel}: ${AppBrFormatters.currency(item.revenue)}',
        legendLabel: 'Receita',
      ),
      AppMapMetric<_RegionMetric>(
        key: _marginMetricKey,
        label: 'Margem %',
        valueBuilder: (item) => item.margin,
        tooltipBuilder: (item) =>
            '${item.regionLabel}: ${item.margin.toStringAsFixed(1)}%',
        legendLabel: 'Margem',
      ),
      AppMapMetric<_RegionMetric>(
        key: _growthMetricKey,
        label: 'Crescimento %',
        valueBuilder: (item) => item.growth,
        tooltipBuilder: (item) =>
            '${item.regionLabel}: ${item.growth.toStringAsFixed(1)}%',
        legendLabel: 'Crescimento',
      ),
    ];

const String _brazilRegionsGeoJson = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {"id": "north", "name": "Norte"},
      "geometry": {
        "type": "Polygon",
        "coordinates": [[
          [-73.0, -2.0], [-58.0, 5.0], [-47.0, 1.0], [-52.0, -9.0],
          [-65.0, -13.0], [-73.0, -2.0]
        ]]
      }
    },
    {
      "type": "Feature",
      "properties": {"id": "northeast", "name": "Nordeste"},
      "geometry": {
        "type": "Polygon",
        "coordinates": [[
          [-52.0, -9.0], [-47.0, 1.0], [-34.0, -5.0], [-36.0, -13.0],
          [-44.0, -18.0], [-52.0, -9.0]
        ]]
      }
    },
    {
      "type": "Feature",
      "properties": {"id": "midwest", "name": "Centro-Oeste"},
      "geometry": {
        "type": "Polygon",
        "coordinates": [[
          [-65.0, -13.0], [-52.0, -9.0], [-44.0, -18.0], [-51.0, -24.0],
          [-60.0, -23.0], [-65.0, -13.0]
        ]]
      }
    },
    {
      "type": "Feature",
      "properties": {"id": "southeast", "name": "Sudeste"},
      "geometry": {
        "type": "Polygon",
        "coordinates": [[
          [-51.0, -24.0], [-44.0, -18.0], [-39.0, -20.0], [-40.0, -25.0],
          [-45.0, -25.0], [-51.0, -24.0]
        ]]
      }
    },
    {
      "type": "Feature",
      "properties": {"id": "south", "name": "Sul"},
      "geometry": {
        "type": "Polygon",
        "coordinates": [[
          [-51.0, -24.0], [-45.0, -25.0], [-48.0, -33.0], [-55.0, -33.0],
          [-56.0, -27.0], [-51.0, -24.0]
        ]]
      }
    }
  ]
}
''';
