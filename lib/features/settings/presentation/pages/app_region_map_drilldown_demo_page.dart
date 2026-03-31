import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_data_source.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_explorer.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:result_dart/result_dart.dart';

class AppRegionMapDrillDownDemoPage extends StatefulWidget {
  const AppRegionMapDrillDownDemoPage({super.key});

  @override
  State<AppRegionMapDrillDownDemoPage> createState() =>
      _AppRegionMapDrillDownDemoPageState();
}

class _AppRegionMapDrillDownDemoPageState
    extends State<AppRegionMapDrillDownDemoPage> {
  static final _BrazilTerritoryDataSource _dataSource =
      _BrazilTerritoryDataSource();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Mapas interativos',
          title: 'Drill-down territorial com fonte genérica',
          subtitle:
              'Mapa real dos estados do Brasil com visão regional, drill para '
              'UFs, troca de métricas por nível e filtros aplicados em uma '
              'fonte de dados injetada.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppRegionMapExplorer<_TerritoryMapRow, _TerritoryFilters>(
          title: 'Performance territorial',
          subtitle: 'Toque no mapa ou use a navegação por região para filtrar',
          dataSource: _dataSource,
          initialFilters: const _TerritoryFilters(),
          regionKeyBuilder: (item) => item.id,
          regionLabelBuilder: (item) => item.name,
          // Tells the engine which GeoJSON to pre-fetch during the loading
          // spinner so the map is ready as soon as the first data arrives.
          initialMapDefinition: _BrazilTerritoryDataSource._regionMap,
          filtersBuilder: _buildFilters,
          style: AppRegionMapChartStyle(
            enableAutoDrillOnTap: true,
            legendNumberFormat: NumberFormat.compact(locale: 'pt_BR'),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(
    BuildContext context,
    _TerritoryFilters filters,
    ValueChanged<_TerritoryFilters> onFiltersChanged,
    ({bool isLoading}) state,
  ) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final minRevenueLabel = AppBrFormatters.compactCurrency(filters.minRevenue);

    return AbsorbPointer(
      absorbing: state.isLoading,
      child: Opacity(
        opacity: state.isLoading ? 0.6 : 1,
        child: DecoratedBox(
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
                Text('Filtros da fonte', style: theme.textTheme.titleSmall),
                SizedBox(height: tokens.gapSm),
                AppSegmentedControl<_SalesPeriod>(
                  options: const <AppSegmentedControlOption<_SalesPeriod>>[
                    AppSegmentedControlOption<_SalesPeriod>(
                      value: _SalesPeriod.month,
                      label: 'Mes',
                    ),
                    AppSegmentedControlOption<_SalesPeriod>(
                      value: _SalesPeriod.quarter,
                      label: 'Trimestre',
                    ),
                    AppSegmentedControlOption<_SalesPeriod>(
                      value: _SalesPeriod.year,
                      label: 'Ano',
                    ),
                  ],
                  value: filters.period,
                  onChanged: (selection) {
                    onFiltersChanged(filters.copyWith(period: selection));
                  },
                ),
                SizedBox(height: tokens.gapSm),
                AppSegmentedControl<_SalesChannel>(
                  options: const <AppSegmentedControlOption<_SalesChannel>>[
                    AppSegmentedControlOption<_SalesChannel>(
                      value: _SalesChannel.all,
                      label: 'Todos canais',
                    ),
                    AppSegmentedControlOption<_SalesChannel>(
                      value: _SalesChannel.store,
                      label: 'Loja fisica',
                    ),
                    AppSegmentedControlOption<_SalesChannel>(
                      value: _SalesChannel.digital,
                      label: 'Digital',
                    ),
                  ],
                  value: filters.channel,
                  onChanged: (selection) {
                    onFiltersChanged(
                      filters.copyWith(channel: selection),
                    );
                  },
                ),
                SizedBox(height: tokens.gapSm),
                Text(
                  'Receita minima por recorte: $minRevenueLabel',
                  style: theme.textTheme.bodySmall,
                ),
                Slider(
                  value: filters.minRevenue,
                  max: 2400000,
                  divisions: 12,
                  label: minRevenueLabel,
                  onChanged: (value) {
                    onFiltersChanged(filters.copyWith(minRevenue: value));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _SalesPeriod {
  month,
  quarter,
  year,
}

enum _SalesChannel {
  all,
  store,
  digital,
}

class _TerritoryFilters {
  const _TerritoryFilters({
    this.period = _SalesPeriod.month,
    this.channel = _SalesChannel.all,
    this.minRevenue = 0,
  });

  final _SalesPeriod period;
  final _SalesChannel channel;
  final double minRevenue;

  _TerritoryFilters copyWith({
    _SalesPeriod? period,
    _SalesChannel? channel,
    double? minRevenue,
  }) {
    return _TerritoryFilters(
      period: period ?? this.period,
      channel: channel ?? this.channel,
      minRevenue: minRevenue ?? this.minRevenue,
    );
  }
}

class _TerritoryMapRow {
  const _TerritoryMapRow({
    required this.id,
    required this.name,
    required this.regionId,
    required this.regionLabel,
    required this.revenue,
    required this.orders,
    required this.margin,
  });

  final String id;
  final String name;
  final String regionId;
  final String regionLabel;
  final double revenue;
  final int orders;
  final double margin;

  _TerritoryMapRow copyWith({
    String? id,
    String? name,
    String? regionId,
    String? regionLabel,
    double? revenue,
    int? orders,
    double? margin,
  }) {
    return _TerritoryMapRow(
      id: id ?? this.id,
      name: name ?? this.name,
      regionId: regionId ?? this.regionId,
      regionLabel: regionLabel ?? this.regionLabel,
      revenue: revenue ?? this.revenue,
      orders: orders ?? this.orders,
      margin: margin ?? this.margin,
    );
  }
}

class _BrazilTerritoryDataSource
    implements AppRegionMapDataSource<_TerritoryMapRow, _TerritoryFilters> {
  static final List<AppMapScopeOption> _regionScopes = _regionNamesById.entries
      .map(
        (entry) => AppMapScopeOption(
          key: entry.key,
          label: entry.value,
        ),
      )
      .toList(growable: false);

  // Complete Brazil states GeoJSON (27 estados) with UF (sigla) and REGIAO
  // (NO/NE/SE/SU/CO) properties — compatible with both region and state maps.
  static const String _statesGeoJsonUrl =
      'https://raw.githubusercontent.com/luizpedone/'
      'municipal-brazilian-geodata/master/data/Brasil.json';

  static const AppMapDefinition _regionMap = AppMapDefinition.network(
    url: _statesGeoJsonUrl,
    shapeDataField: 'REGIAO',
    regionLevel: AppMapRegionLevel.region,
  );

  static const AppMapDefinition _stateMap = AppMapDefinition.network(
    url: _statesGeoJsonUrl,
    shapeDataField: 'UF',
    regionLevel: AppMapRegionLevel.state,
  );

  static const AppMapViewport _brazilViewport = AppMapViewport(
    zoomLevel: 1.4,
    centerLatitude: -14.235,
    centerLongitude: -51.925,
  );

  static const Map<String, AppMapViewport> _regionViewports =
      <String, AppMapViewport>{
        'NO': AppMapViewport(
          zoomLevel: 2.35,
          centerLatitude: -3.5,
          centerLongitude: -62,
        ),
        'NE': AppMapViewport(
          zoomLevel: 2.85,
          centerLatitude: -9.5,
          centerLongitude: -39.5,
        ),
        'SE': AppMapViewport(
          zoomLevel: 3,
          centerLatitude: -20,
          centerLongitude: -44.5,
        ),
        'SU': AppMapViewport(
          zoomLevel: 3.2,
          centerLatitude: -28,
          centerLongitude: -51,
        ),
        'CO': AppMapViewport(
          zoomLevel: 2.9,
          centerLatitude: -15.5,
          centerLongitude: -55,
        ),
      };

  static final List<AppMapMetric<_TerritoryMapRow>> _regionMetrics =
      <AppMapMetric<_TerritoryMapRow>>[
        AppMapMetric<_TerritoryMapRow>(
          key: 'revenue',
          label: 'Receita',
          legendLabel: 'Receita por regiao',
          valueBuilder: (item) => item.revenue,
          tooltipBuilder: (item) =>
              '${item.name}: ${AppBrFormatters.currency(item.revenue)}',
        ),
        AppMapMetric<_TerritoryMapRow>(
          key: 'orders',
          label: 'Pedidos',
          legendLabel: 'Pedidos por regiao',
          valueBuilder: (item) => item.orders,
          tooltipBuilder: (item) => '${item.name}: ${item.orders} pedidos',
        ),
      ];

  static final List<AppMapMetric<_TerritoryMapRow>> _stateMetrics =
      <AppMapMetric<_TerritoryMapRow>>[
        AppMapMetric<_TerritoryMapRow>(
          key: 'revenue',
          label: 'Receita',
          legendLabel: 'Receita por UF',
          valueBuilder: (item) => item.revenue,
          tooltipBuilder: (item) =>
              '${item.name}: ${AppBrFormatters.currency(item.revenue)}',
        ),
        AppMapMetric<_TerritoryMapRow>(
          key: 'orders',
          label: 'Pedidos',
          legendLabel: 'Pedidos por UF',
          valueBuilder: (item) => item.orders,
          tooltipBuilder: (item) => '${item.name}: ${item.orders} pedidos',
        ),
        AppMapMetric<_TerritoryMapRow>(
          key: 'margin',
          label: 'Margem %',
          legendLabel: 'Margem por UF',
          valueBuilder: (item) => item.margin,
          tooltipBuilder: (item) =>
              '${item.name}: ${item.margin.toStringAsFixed(1)}%',
        ),
      ];

  @override
  Future<AppResult<AppRegionMapDataSnapshot<_TerritoryMapRow>>> load(
    AppRegionMapDataQuery<_TerritoryFilters> query,
  ) async {
    // Simulates data processing from a remote/DI source.
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final filteredRows = _applyFilters(query.filters);

    if (query.drillLevel == AppMapDrillLevel.region) {
      final grouped = <String, _TerritoryMapRow>{};
      for (final row in filteredRows) {
        final current = grouped[row.regionId];
        if (current == null) {
          grouped[row.regionId] = _TerritoryMapRow(
            id: row.regionId,
            name: row.regionLabel,
            regionId: row.regionId,
            regionLabel: row.regionLabel,
            revenue: row.revenue,
            orders: row.orders,
            margin: row.margin,
          );
          continue;
        }

        final mergedRevenue = current.revenue + row.revenue;
        final mergedOrders = current.orders + row.orders;
        final mergedMargin =
            ((current.margin * current.revenue) + (row.margin * row.revenue)) /
            (mergedRevenue == 0 ? 1 : mergedRevenue);

        grouped[row.regionId] = current.copyWith(
          revenue: mergedRevenue,
          orders: mergedOrders,
          margin: mergedMargin,
        );
      }

      final items = grouped.values.toList(growable: false)
        ..sort((a, b) => a.regionId.compareTo(b.regionId));
      final selectedMetricKey = _resolveMetric(
        query.selectedMetricKey,
        _regionMetrics,
      );

      return Success<AppRegionMapDataSnapshot<_TerritoryMapRow>, AppFailure>(
        AppRegionMapDataSnapshot<_TerritoryMapRow>(
          items: items,
          mapDefinition: _regionMap,
          metrics: _regionMetrics,
          selectedMetricKey: selectedMetricKey,
          scopeLabel: 'Brasil (agregado por regiao)',
          availableScopes: _regionScopes,
          preferredViewport: _brazilViewport,
          loadedAt: DateTime.now(),
        ),
      );
    }

    final focusedRegionId = query.focusedRegionKey;
    final stateItems =
        filteredRows
            .where(
              (row) =>
                  focusedRegionId == null || row.regionId == focusedRegionId,
            )
            .toList(growable: false)
          ..sort((a, b) => a.name.compareTo(b.name));
    final selectedMetricKey = _resolveMetric(
      query.selectedMetricKey,
      _stateMetrics,
    );
    final scope = focusedRegionId == null
        ? 'Brasil'
        : _regionNamesById[focusedRegionId] ?? focusedRegionId;

    return Success<AppRegionMapDataSnapshot<_TerritoryMapRow>, AppFailure>(
      AppRegionMapDataSnapshot<_TerritoryMapRow>(
        items: stateItems,
        mapDefinition: _stateMap,
        metrics: _stateMetrics,
        selectedMetricKey: selectedMetricKey,
        scopeLabel: scope,
        activeScopeKey: focusedRegionId,
        availableScopes: _regionScopes,
        preferredViewport: focusedRegionId == null
            ? _brazilViewport
            : _regionViewports[focusedRegionId] ?? _brazilViewport,
        loadedAt: DateTime.now(),
      ),
    );
  }

  List<_TerritoryMapRow> _applyFilters(_TerritoryFilters filters) {
    final periodMultiplier = switch (filters.period) {
      _SalesPeriod.month => 1.0,
      _SalesPeriod.quarter => 2.9,
      _SalesPeriod.year => 11.8,
    };
    final channelMultiplier = switch (filters.channel) {
      _SalesChannel.all => 1.0,
      _SalesChannel.store => 0.74,
      _SalesChannel.digital => 0.26,
    };
    final marginDelta = switch (filters.channel) {
      _SalesChannel.all => 0.0,
      _SalesChannel.store => -1.2,
      _SalesChannel.digital => 2.0,
    };

    final threshold = filters.minRevenue;
    final rows = <_TerritoryMapRow>[];
    for (final base in _baseStateRows) {
      final revenue = base.revenue * periodMultiplier * channelMultiplier;
      if (revenue < threshold) {
        continue;
      }

      rows.add(
        base.copyWith(
          revenue: revenue,
          orders: (base.orders * periodMultiplier * channelMultiplier).round(),
          margin: (base.margin + marginDelta).clamp(3.0, 45.0),
        ),
      );
    }
    return rows;
  }

  String _resolveMetric(
    String? requestedMetricKey,
    List<AppMapMetric<_TerritoryMapRow>> metrics,
  ) {
    final availableKeys = metrics.map((metric) => metric.key);
    if (requestedMetricKey != null &&
        availableKeys.contains(requestedMetricKey)) {
      return requestedMetricKey;
    }
    return metrics.first.key;
  }
}

const Map<String, String> _regionNamesById = <String, String>{
  'NO': 'Norte',
  'NE': 'Nordeste',
  'SE': 'Sudeste',
  'SU': 'Sul',
  'CO': 'Centro-Oeste',
};

const List<_TerritoryMapRow> _baseStateRows = <_TerritoryMapRow>[
  _TerritoryMapRow(
    id: 'AC',
    name: 'Acre',
    regionId: 'NO',
    regionLabel: 'Norte',
    revenue: 122000,
    orders: 1600,
    margin: 15.1,
  ),
  _TerritoryMapRow(
    id: 'AL',
    name: 'Alagoas',
    regionId: 'NE',
    regionLabel: 'Nordeste',
    revenue: 146000,
    orders: 2100,
    margin: 14.3,
  ),
  _TerritoryMapRow(
    id: 'AM',
    name: 'Amazonas',
    regionId: 'NO',
    regionLabel: 'Norte',
    revenue: 188000,
    orders: 2600,
    margin: 16.4,
  ),
  _TerritoryMapRow(
    id: 'AP',
    name: 'Amapa',
    regionId: 'NO',
    regionLabel: 'Norte',
    revenue: 98000,
    orders: 1400,
    margin: 13.5,
  ),
  _TerritoryMapRow(
    id: 'BA',
    name: 'Bahia',
    regionId: 'NE',
    regionLabel: 'Nordeste',
    revenue: 482000,
    orders: 6200,
    margin: 15.9,
  ),
  _TerritoryMapRow(
    id: 'CE',
    name: 'Ceara',
    regionId: 'NE',
    regionLabel: 'Nordeste',
    revenue: 352000,
    orders: 5100,
    margin: 14.8,
  ),
  _TerritoryMapRow(
    id: 'DF',
    name: 'Distrito Federal',
    regionId: 'CO',
    regionLabel: 'Centro-Oeste',
    revenue: 330000,
    orders: 3900,
    margin: 20.1,
  ),
  _TerritoryMapRow(
    id: 'ES',
    name: 'Espirito Santo',
    regionId: 'SE',
    regionLabel: 'Sudeste',
    revenue: 286000,
    orders: 3600,
    margin: 18.9,
  ),
  _TerritoryMapRow(
    id: 'GO',
    name: 'Goias',
    regionId: 'CO',
    regionLabel: 'Centro-Oeste',
    revenue: 410000,
    orders: 5200,
    margin: 17.6,
  ),
  _TerritoryMapRow(
    id: 'MA',
    name: 'Maranhao',
    regionId: 'NE',
    regionLabel: 'Nordeste',
    revenue: 215000,
    orders: 3100,
    margin: 12.6,
  ),
  _TerritoryMapRow(
    id: 'MG',
    name: 'Minas Gerais',
    regionId: 'SE',
    regionLabel: 'Sudeste',
    revenue: 780000,
    orders: 9800,
    margin: 18.3,
  ),
  _TerritoryMapRow(
    id: 'MS',
    name: 'Mato Grosso do Sul',
    regionId: 'CO',
    regionLabel: 'Centro-Oeste',
    revenue: 226000,
    orders: 3200,
    margin: 16.7,
  ),
  _TerritoryMapRow(
    id: 'MT',
    name: 'Mato Grosso',
    regionId: 'CO',
    regionLabel: 'Centro-Oeste',
    revenue: 302000,
    orders: 3900,
    margin: 17.2,
  ),
  _TerritoryMapRow(
    id: 'PA',
    name: 'Para',
    regionId: 'NO',
    regionLabel: 'Norte',
    revenue: 364000,
    orders: 4700,
    margin: 15.4,
  ),
  _TerritoryMapRow(
    id: 'PB',
    name: 'Paraiba',
    regionId: 'NE',
    regionLabel: 'Nordeste',
    revenue: 192000,
    orders: 2500,
    margin: 13.8,
  ),
  _TerritoryMapRow(
    id: 'PE',
    name: 'Pernambuco',
    regionId: 'NE',
    regionLabel: 'Nordeste',
    revenue: 378000,
    orders: 5200,
    margin: 14.9,
  ),
  _TerritoryMapRow(
    id: 'PI',
    name: 'Piaui',
    regionId: 'NE',
    regionLabel: 'Nordeste',
    revenue: 154000,
    orders: 2200,
    margin: 12.9,
  ),
  _TerritoryMapRow(
    id: 'PR',
    name: 'Parana',
    regionId: 'SU',
    regionLabel: 'Sul',
    revenue: 598000,
    orders: 7300,
    margin: 19.4,
  ),
  _TerritoryMapRow(
    id: 'RJ',
    name: 'Rio de Janeiro',
    regionId: 'SE',
    regionLabel: 'Sudeste',
    revenue: 642000,
    orders: 7900,
    margin: 17.1,
  ),
  _TerritoryMapRow(
    id: 'RN',
    name: 'Rio Grande do Norte',
    regionId: 'NE',
    regionLabel: 'Nordeste',
    revenue: 171000,
    orders: 2300,
    margin: 13.7,
  ),
  _TerritoryMapRow(
    id: 'RO',
    name: 'Rondonia',
    regionId: 'NO',
    regionLabel: 'Norte',
    revenue: 137000,
    orders: 1900,
    margin: 14.8,
  ),
  _TerritoryMapRow(
    id: 'RR',
    name: 'Roraima',
    regionId: 'NO',
    regionLabel: 'Norte',
    revenue: 86000,
    orders: 1100,
    margin: 12.4,
  ),
  _TerritoryMapRow(
    id: 'RS',
    name: 'Rio Grande do Sul',
    regionId: 'SU',
    regionLabel: 'Sul',
    revenue: 689000,
    orders: 8400,
    margin: 20.2,
  ),
  _TerritoryMapRow(
    id: 'SC',
    name: 'Santa Catarina',
    regionId: 'SU',
    regionLabel: 'Sul',
    revenue: 521000,
    orders: 6900,
    margin: 19.7,
  ),
  _TerritoryMapRow(
    id: 'SE',
    name: 'Sergipe',
    regionId: 'NE',
    regionLabel: 'Nordeste',
    revenue: 126000,
    orders: 1700,
    margin: 13.1,
  ),
  _TerritoryMapRow(
    id: 'SP',
    name: 'Sao Paulo',
    regionId: 'SE',
    regionLabel: 'Sudeste',
    revenue: 1510000,
    orders: 18800,
    margin: 19.1,
  ),
  _TerritoryMapRow(
    id: 'TO',
    name: 'Tocantins',
    regionId: 'NO',
    regionLabel: 'Norte',
    revenue: 112000,
    orders: 1500,
    margin: 14.2,
  ),
];
