import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_data_source.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:colmeia/shared/widgets/forms/app_slider_field.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
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
      padding: EdgeInsets.only(
        left: tokens.contentSpacing,
        right: tokens.contentSpacing,
        top: tokens.contentSpacing,
        bottom: tokens.contentSpacing + MediaQuery.paddingOf(context).bottom,
      ),
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
        _SafeTerritoryExplorer(
          dataSource: _dataSource,
          filtersBuilder: _buildFilters,
          onPointTap: (event) {
            final store = event.point.payload! as _TerritoryStore;
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  content: Text(
                    '${store.name} - ${store.cityLabel}: '
                    '${AppBrFormatters.compactCurrency(store.revenue)}',
                  ),
                ),
              );
          },
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

    return AbsorbPointer(
      absorbing: state.isLoading,
      child: Opacity(
        opacity: state.isLoading ? 0.6 : 1,
        child: AppSectionCardWithHeading(
          title: 'Filtros da fonte',
          subtitle: 'Período, canal e corte mínimo de receita.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppSegmentedControl<_SalesPeriod>(
                options: const <AppSegmentedControlOption<_SalesPeriod>>[
                  AppSegmentedControlOption<_SalesPeriod>(
                    value: _SalesPeriod.month,
                    label: 'Mês',
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
                    label: 'Loja física',
                  ),
                  AppSegmentedControlOption<_SalesChannel>(
                    value: _SalesChannel.digital,
                    label: 'Digital',
                  ),
                ],
                value: filters.channel,
                onChanged: (selection) {
                  onFiltersChanged(filters.copyWith(channel: selection));
                },
              ),
              SizedBox(height: tokens.gapMd),
              AppSliderField(
                label: 'Receita mínima por recorte',
                valueLabelBuilder: AppBrFormatters.compactCurrency,
                helperText: filters.minRevenue == 0
                    ? 'Use 0 para ver todos os recortes.'
                    : null,
                value: filters.minRevenue,
                min: 0,
                max: 2400000,
                divisions: 12,
                enabled: !state.isLoading,
                // Sem `onChanged`: o slider mantem o thumb animado pelo
                // estado interno e so emite o valor canonico no fim do
                // arrasto, evitando rebuilds em cascata do explorer e do
                // mapa a cada tick.
                onChangeEnd: (value) {
                  onFiltersChanged(filters.copyWith(minRevenue: value));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafeTerritoryExplorer extends StatefulWidget {
  const _SafeTerritoryExplorer({
    required this.dataSource,
    required this.filtersBuilder,
    required this.onPointTap,
  });

  final _BrazilTerritoryDataSource dataSource;
  final Widget Function(
    BuildContext context,
    _TerritoryFilters filters,
    ValueChanged<_TerritoryFilters> onFiltersChanged,
    ({bool isLoading}) state,
  )
  filtersBuilder;
  final ValueChanged<AppMapPointTapEvent> onPointTap;

  @override
  State<_SafeTerritoryExplorer> createState() => _SafeTerritoryExplorerState();
}

class _SafeTerritoryExplorerState extends State<_SafeTerritoryExplorer> {
  _TerritoryFilters _filters = const _TerritoryFilters();
  AppMapDrillLevel _drillLevel = AppMapDrillLevel.region;
  String? _focusedRegionKey;
  String? _selectedRegionKey;
  String? _selectedMetricKey;
  AppRegionMapDataSnapshot<_TerritoryMapRow>? _snapshot;
  String? _loadErrorMessage;
  bool _isLoading = false;
  int _requestToken = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  @override
  void dispose() {
    _requestToken += 1;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final filters = widget.filtersBuilder(
      context,
      _filters,
      _handleFiltersChanged,
      (isLoading: _isLoading),
    );
    final snapshot = _snapshot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        filters,
        SizedBox(height: tokens.gapMd),
        if (snapshot == null && _loadErrorMessage != null)
          AppInlineErrorPanel(
            title: 'Erro ao carregar',
            message: _loadErrorMessage!,
            onRetry: () {
              setState(() => _loadErrorMessage = null);
              unawaited(_loadData());
            },
            variant: AppInlineErrorPanelVariant.plain,
          )
        else if (snapshot == null)
          const _TerritoryLoadingCard()
        else
          _TerritoryMapCard(
            snapshot: snapshot,
            drillLevel: _drillLevel,
            selectedRegionKey: _selectedRegionKey,
            selectedMetric: _resolveMetric(snapshot),
            selectedMetricKey: _resolveMetric(snapshot).key,
            isLoading: _isLoading,
            onMetricChanged: _handleMetricChanged,
            onScopeSelected: _handleScopeSelected,
            onShapeTap: _handleShapeTap,
            onPointTap: widget.onPointTap,
          ),
      ],
    );
  }

  AppMapMetric<_TerritoryMapRow> _resolveMetric(
    AppRegionMapDataSnapshot<_TerritoryMapRow> snapshot,
  ) {
    final requestedKey =
        _selectedMetricKey ??
        snapshot.selectedMetricKey ??
        snapshot.metrics.first.key;
    return snapshot.metrics.firstWhere(
      (metric) => metric.key == requestedKey,
      orElse: () => snapshot.metrics.first,
    );
  }

  Future<void> _loadData({bool resetSelection = false}) async {
    final token = ++_requestToken;
    setState(() => _isLoading = true);

    final result = await widget.dataSource.load(
      AppRegionMapDataQuery<_TerritoryFilters>(
        drillLevel: _drillLevel,
        focusedRegionKey: _focusedRegionKey,
        filters: _filters,
        selectedMetricKey: _selectedMetricKey,
      ),
    );

    if (!mounted || token != _requestToken) {
      return;
    }

    result.fold(
      (snapshot) {
        if (!mounted || token != _requestToken) {
          return;
        }
        setState(() {
          _snapshot = snapshot;
          _isLoading = false;
          _loadErrorMessage = null;
          _selectedMetricKey = snapshot.selectedMetricKey;
          if (resetSelection) {
            _selectedRegionKey = null;
          }
        });
      },
      (failure) {
        if (!mounted || token != _requestToken) {
          return;
        }
        setState(() {
          _isLoading = false;
          _loadErrorMessage = failure.displayMessage;
        });
      },
    );
  }

  void _handleFiltersChanged(_TerritoryFilters filters) {
    setState(() {
      _filters = filters;
      _drillLevel = AppMapDrillLevel.region;
      _focusedRegionKey = null;
      _selectedRegionKey = null;
      _selectedMetricKey = null;
    });
    unawaited(_loadData(resetSelection: true));
  }

  void _handleMetricChanged(String metricKey) {
    setState(() => _selectedMetricKey = metricKey);
  }

  void _handleScopeSelected(String? scopeKey) {
    setState(() {
      _drillLevel = scopeKey == null
          ? AppMapDrillLevel.region
          : AppMapDrillLevel.state;
      _focusedRegionKey = scopeKey;
      _selectedRegionKey = null;
      _selectedMetricKey = null;
    });
    unawaited(_loadData(resetSelection: true));
  }

  void _handleShapeTap(_TerritoryMapRow item) {
    if (_drillLevel == AppMapDrillLevel.region) {
      setState(() {
        _drillLevel = AppMapDrillLevel.state;
        _focusedRegionKey = item.id;
        _selectedRegionKey = null;
        _selectedMetricKey = null;
      });
      unawaited(_loadData(resetSelection: true));
      return;
    }

    setState(() {
      _selectedRegionKey = _selectedRegionKey == item.id ? null : item.id;
    });
  }
}

class _TerritoryLoadingCard extends StatelessWidget {
  const _TerritoryLoadingCard();

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return AppSectionCardWithHeading(
      title: 'Performance territorial',
      subtitle: 'Toque no mapa ou use a navegação por região para filtrar.',
      child: SizedBox(
        height: 260,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(strokeWidth: 3),
              SizedBox(height: tokens.gapMd),
              Text(
                'Carregando mapa...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TerritoryMapCard extends StatelessWidget {
  const _TerritoryMapCard({
    required this.snapshot,
    required this.drillLevel,
    required this.selectedMetric,
    required this.selectedMetricKey,
    required this.isLoading,
    required this.onMetricChanged,
    required this.onScopeSelected,
    required this.onShapeTap,
    required this.onPointTap,
    this.selectedRegionKey,
  });

  final AppRegionMapDataSnapshot<_TerritoryMapRow> snapshot;
  final AppMapDrillLevel drillLevel;
  final String? selectedRegionKey;
  final AppMapMetric<_TerritoryMapRow> selectedMetric;
  final String selectedMetricKey;
  final bool isLoading;
  final ValueChanged<String> onMetricChanged;
  final ValueChanged<String?> onScopeSelected;
  final ValueChanged<_TerritoryMapRow> onShapeTap;
  final ValueChanged<AppMapPointTapEvent> onPointTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return AppSectionCardWithHeading(
      title: 'Performance territorial',
      subtitle: 'Toque no mapa ou use a navegação por região para filtrar.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (snapshot.metrics.length > 1) ...<Widget>[
            AppSegmentedControl<String>(
              options: snapshot.metrics
                  .map(
                    (metric) => AppSegmentedControlOption<String>(
                      value: metric.key,
                      label: metric.label,
                    ),
                  )
                  .toList(growable: false),
              value: selectedMetricKey,
              onChanged: onMetricChanged,
            ),
            SizedBox(height: tokens.gapMd),
          ],
          _TerritoryScopeChips(
            activeScopeKey: snapshot.activeScopeKey,
            scopes: snapshot.availableScopes,
            onScopeSelected: onScopeSelected,
          ),
          SizedBox(height: tokens.gapMd),
          if (isLoading) const LinearProgressIndicator(minHeight: 2),
          _TerritorySketchMap(
            snapshot: snapshot,
            drillLevel: drillLevel,
            selectedRegionKey: selectedRegionKey,
            metric: selectedMetric,
            onShapeTap: onShapeTap,
            onPointTap: onPointTap,
          ),
          SizedBox(height: tokens.gapSm),
          _TerritoryMetricLegend(
            items: snapshot.items,
            metric: selectedMetric,
          ),
        ],
      ),
    );
  }
}

class _TerritoryScopeChips extends StatelessWidget {
  const _TerritoryScopeChips({
    required this.activeScopeKey,
    required this.scopes,
    required this.onScopeSelected,
  });

  final String? activeScopeKey;
  final List<AppMapScopeOption> scopes;
  final ValueChanged<String?> onScopeSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        ChoiceChip(
          label: const Text('Brasil'),
          selected: activeScopeKey == null,
          onSelected: (_) => onScopeSelected(null),
        ),
        for (final scope in scopes)
          ChoiceChip(
            label: Text(scope.label),
            selected: activeScopeKey == scope.key,
            onSelected: (_) => onScopeSelected(scope.key),
          ),
      ],
    );
  }
}

class _TerritorySketchMap extends StatelessWidget {
  const _TerritorySketchMap({
    required this.snapshot,
    required this.drillLevel,
    required this.metric,
    required this.onShapeTap,
    required this.onPointTap,
    this.selectedRegionKey,
  });

  static const double _west = -74;
  static const double _east = -34;
  static const double _south = -34;
  static const double _north = 6;

  final AppRegionMapDataSnapshot<_TerritoryMapRow> snapshot;
  final AppMapDrillLevel drillLevel;
  final String? selectedRegionKey;
  final AppMapMetric<_TerritoryMapRow> metric;
  final ValueChanged<_TerritoryMapRow> onShapeTap;
  final ValueChanged<AppMapPointTapEvent> onPointTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final itemsByKey = <String, _TerritoryMapRow>{
      for (final item in snapshot.items) item.id: item,
    };
    final values = snapshot.items.map(
      (item) => metric.valueBuilder(item).toDouble(),
    );
    final minValue = values.isEmpty ? 0.0 : values.reduce(math.min);
    final maxValue = values.isEmpty ? 0.0 : values.reduce(math.max);
    final range = (maxValue - minValue).abs() < 0.0001
        ? 1.0
        : maxValue - minValue;

    Color colorFor(_TerritoryMapRow item) {
      final normalized =
          ((metric.valueBuilder(item).toDouble() - minValue) / range).clamp(
            0.0,
            1.0,
          );
      return Color.lerp(
        colors.primaryContainer.withValues(alpha: 0.35),
        colors.primary,
        normalized,
      )!;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = math.max(260, width * 0.72).toDouble();
        final visibleBoxes = _stateShapeBoxes
            .where((box) {
              return snapshot.activeScopeKey == null ||
                  box.regionId == snapshot.activeScopeKey;
            })
            .toList(growable: false);

        return SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              children: <Widget>[
                for (final box in visibleBoxes)
                  _buildShape(
                    context,
                    box: box,
                    width: width,
                    height: height,
                    item:
                        itemsByKey[drillLevel == AppMapDrillLevel.region
                            ? box.regionId
                            : box.uf],
                    colorFor: colorFor,
                  ),
                for (final (index, point) in snapshot.points.indexed)
                  _buildPoint(
                    context,
                    point: point,
                    index: index,
                    width: width,
                    height: height,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShape(
    BuildContext context, {
    required _StateShapeBox box,
    required double width,
    required double height,
    required _TerritoryMapRow? item,
    required Color Function(_TerritoryMapRow item) colorFor,
  }) {
    final colors = Theme.of(context).colorScheme;
    final key = drillLevel == AppMapDrillLevel.region ? box.regionId : box.uf;
    final selected = selectedRegionKey == key;
    final left = ((box.west - _west) / (_east - _west)) * width;
    final top = ((_north - box.north) / (_north - _south)) * height;
    final boxWidth = ((box.east - box.west) / (_east - _west)) * width;
    final boxHeight = ((box.north - box.south) / (_north - _south)) * height;

    final label = drillLevel == AppMapDrillLevel.region
        ? _regionNamesById[box.regionId] ?? box.regionId
        : box.uf;
    final valueLabel = item == null
        ? label
        : metric.tooltipBuilder?.call(item) ??
              '$label: ${metric.valueBuilder(item).toStringAsFixed(1)}';

    return Positioned(
      left: left,
      top: top,
      width: math.max(18, boxWidth),
      height: math.max(18, boxHeight),
      child: Tooltip(
        message: valueLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: item == null ? null : () => onShapeTap(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item == null
                    ? colors.surfaceContainerHighest
                    : colorFor(item),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? colors.primary : colors.outlineVariant,
                  width: selected ? 2.4 : 0.8,
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.fade,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoint(
    BuildContext context, {
    required AppMapPoint point,
    required int index,
    required double width,
    required double height,
  }) {
    final style = point.style ?? const AppMapMarkerStyle(size: 12);
    final left = ((point.longitude - _west) / (_east - _west)) * width;
    final top = ((_north - point.latitude) / (_north - _south)) * height;
    final colors = Theme.of(context).colorScheme;

    return Positioned(
      left: left - style.size / 2,
      top: top - style.size / 2,
      width: style.size,
      height: style.size,
      child: Tooltip(
        message: point.tooltip ?? point.label ?? '',
        child: GestureDetector(
          onTap: () =>
              onPointTap(AppMapPointTapEvent(point: point, index: index)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: style.color ?? colors.secondary,
              shape: BoxShape.circle,
              border: Border.all(
                color: style.strokeColor ?? colors.surface,
                width: style.strokeWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TerritoryMetricLegend extends StatelessWidget {
  const _TerritoryMetricLegend({required this.items, required this.metric});

  final List<_TerritoryMapRow> items;
  final AppMapMetric<_TerritoryMapRow> metric;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final colors = Theme.of(context).colorScheme;
    final values = items.map((item) => metric.valueBuilder(item).toDouble());
    final minValue = values.isEmpty ? 0.0 : values.reduce(math.min);
    final maxValue = values.isEmpty ? 0.0 : values.reduce(math.max);

    String format(double value) {
      if (metric.key == 'revenue') {
        return AppBrFormatters.compactCurrency(value);
      }
      return value.toStringAsFixed(1);
    }

    return Row(
      children: <Widget>[
        Text(format(minValue), style: Theme.of(context).textTheme.bodySmall),
        SizedBox(width: tokens.gapSm),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  colors.primaryContainer.withValues(alpha: 0.35),
                  colors.primary,
                ],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const SizedBox(height: 10),
          ),
        ),
        SizedBox(width: tokens.gapSm),
        Text(format(maxValue), style: Theme.of(context).textTheme.bodySmall),
      ],
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

@immutable
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TerritoryFilters &&
          other.period == period &&
          other.channel == channel &&
          other.minRevenue == minRevenue;

  @override
  int get hashCode => Object.hash(period, channel, minRevenue);
}

@immutable
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TerritoryMapRow &&
          other.id == id &&
          other.name == name &&
          other.regionId == regionId &&
          other.regionLabel == regionLabel &&
          other.revenue == revenue &&
          other.orders == orders &&
          other.margin == margin;

  @override
  int get hashCode =>
      Object.hash(id, name, regionId, regionLabel, revenue, orders, margin);
}

@immutable
class _StateShapeBox {
  const _StateShapeBox({
    required this.uf,
    required this.regionId,
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  final String uf;
  final String regionId;
  final double west;
  final double south;
  final double east;
  final double north;
}

String _buildBrazilStatesGeoJson() {
  return jsonEncode(<String, Object?>{
    'type': 'FeatureCollection',
    'features': _stateShapeBoxes
        .map(
          (box) => <String, Object?>{
            'type': 'Feature',
            'properties': <String, String>{
              'UF': box.uf,
              'REGIAO': box.regionId,
            },
            'geometry': <String, Object?>{
              'type': 'Polygon',
              'coordinates': <List<List<double>>>[
                <List<double>>[
                  <double>[box.west, box.south],
                  <double>[box.east, box.south],
                  <double>[box.east, box.north],
                  <double>[box.west, box.north],
                  <double>[box.west, box.south],
                ],
              ],
            },
          },
        )
        .toList(growable: false),
  });
}

const List<_StateShapeBox> _stateShapeBoxes = <_StateShapeBox>[
  _StateShapeBox(
    uf: 'AC',
    regionId: 'NO',
    west: -73.9,
    south: -11.2,
    east: -66.5,
    north: -7,
  ),
  _StateShapeBox(
    uf: 'AL',
    regionId: 'NE',
    west: -38,
    south: -10.5,
    east: -35,
    north: -8.5,
  ),
  _StateShapeBox(
    uf: 'AM',
    regionId: 'NO',
    west: -73,
    south: -9,
    east: -56,
    north: 3,
  ),
  _StateShapeBox(
    uf: 'AP',
    regionId: 'NO',
    west: -54,
    south: 0,
    east: -50,
    north: 4,
  ),
  _StateShapeBox(
    uf: 'BA',
    regionId: 'NE',
    west: -46,
    south: -18,
    east: -37,
    north: -9,
  ),
  _StateShapeBox(
    uf: 'CE',
    regionId: 'NE',
    west: -41,
    south: -8,
    east: -37,
    north: -2,
  ),
  _StateShapeBox(
    uf: 'DF',
    regionId: 'CO',
    west: -48.4,
    south: -16.2,
    east: -47.4,
    north: -15.4,
  ),
  _StateShapeBox(
    uf: 'ES',
    regionId: 'SE',
    west: -41.5,
    south: -21.5,
    east: -39,
    north: -17.5,
  ),
  _StateShapeBox(
    uf: 'GO',
    regionId: 'CO',
    west: -53,
    south: -19,
    east: -46,
    north: -12,
  ),
  _StateShapeBox(
    uf: 'MA',
    regionId: 'NE',
    west: -48,
    south: -10,
    east: -41,
    north: -1,
  ),
  _StateShapeBox(
    uf: 'MG',
    regionId: 'SE',
    west: -51,
    south: -22,
    east: -39,
    north: -14,
  ),
  _StateShapeBox(
    uf: 'MS',
    regionId: 'CO',
    west: -58,
    south: -24,
    east: -51,
    north: -17,
  ),
  _StateShapeBox(
    uf: 'MT',
    regionId: 'CO',
    west: -61,
    south: -18,
    east: -51,
    north: -8,
  ),
  _StateShapeBox(
    uf: 'PA',
    regionId: 'NO',
    west: -58,
    south: -8,
    east: -46,
    north: 2,
  ),
  _StateShapeBox(
    uf: 'PB',
    regionId: 'NE',
    west: -38.5,
    south: -8.5,
    east: -34.5,
    north: -6,
  ),
  _StateShapeBox(
    uf: 'PE',
    regionId: 'NE',
    west: -41,
    south: -9.5,
    east: -34.5,
    north: -7,
  ),
  _StateShapeBox(
    uf: 'PI',
    regionId: 'NE',
    west: -45,
    south: -11,
    east: -40,
    north: -2,
  ),
  _StateShapeBox(
    uf: 'PR',
    regionId: 'SU',
    west: -54,
    south: -26.8,
    east: -48,
    north: -22.4,
  ),
  _StateShapeBox(
    uf: 'RJ',
    regionId: 'SE',
    west: -44.8,
    south: -23.5,
    east: -40.8,
    north: -20.5,
  ),
  _StateShapeBox(
    uf: 'RN',
    regionId: 'NE',
    west: -38,
    south: -7,
    east: -35,
    north: -4,
  ),
  _StateShapeBox(
    uf: 'RO',
    regionId: 'NO',
    west: -66,
    south: -13.7,
    east: -60,
    north: -8,
  ),
  _StateShapeBox(
    uf: 'RR',
    regionId: 'NO',
    west: -65,
    south: 0,
    east: -59,
    north: 5,
  ),
  _StateShapeBox(
    uf: 'RS',
    regionId: 'SU',
    west: -57.7,
    south: -33.8,
    east: -49.5,
    north: -27,
  ),
  _StateShapeBox(
    uf: 'SC',
    regionId: 'SU',
    west: -53.9,
    south: -29.4,
    east: -48.2,
    north: -25.8,
  ),
  _StateShapeBox(
    uf: 'SE',
    regionId: 'NE',
    west: -38.5,
    south: -11.5,
    east: -36,
    north: -9.5,
  ),
  _StateShapeBox(
    uf: 'SP',
    regionId: 'SE',
    west: -53,
    south: -25.5,
    east: -44,
    north: -19.5,
  ),
  _StateShapeBox(
    uf: 'TO',
    regionId: 'NO',
    west: -51,
    south: -13,
    east: -46,
    north: -5,
  ),
];

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

  static final Uint8List _statesGeoJsonBytes = Uint8List.fromList(
    utf8.encode(_buildBrazilStatesGeoJson()),
  );

  static final AppMapDefinition _regionMap = AppMapDefinition.memory(
    sourceBytes: _statesGeoJsonBytes,
    shapeDataField: 'REGIAO',
    regionLevel: AppMapRegionLevel.region,
  );

  static final AppMapDefinition _stateMap = AppMapDefinition.memory(
    sourceBytes: _statesGeoJsonBytes,
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
          scopeLabel: 'Brasil (agregado por região)',
          availableScopes: _regionScopes,
          preferredViewport: _brazilViewport,
          loadedAt: DateTime.now(),
          points: _pointsForFilters(query.filters, focusedRegionId: null),
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
        points: _pointsForFilters(
          query.filters,
          focusedRegionId: focusedRegionId,
        ),
      ),
    );
  }

  /// Builds map markers for the current filters. When [focusedRegionId] is
  /// null, returns stores from all regions; otherwise restricts to that
  /// region. The marker style varies with revenue tier so that high-revenue
  /// stores stand out.
  List<AppMapPoint> _pointsForFilters(
    _TerritoryFilters filters, {
    required String? focusedRegionId,
  }) {
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
    final result = <AppMapPoint>[];
    for (final store in _baseStores) {
      if (focusedRegionId != null && store.regionId != focusedRegionId) {
        continue;
      }
      final revenue = store.baseRevenue * periodMultiplier * channelMultiplier;
      // Tier-based marker size: heavier stores draw a larger pin.
      final size = revenue > 90000
          ? 16.0
          : revenue > 45000
          ? 13.0
          : 10.0;
      final tooltipText =
          '${store.name} - ${store.cityLabel}: '
          '${AppBrFormatters.compactCurrency(revenue)}';
      result.add(
        AppMapPoint(
          latitude: store.latitude,
          longitude: store.longitude,
          label: store.name,
          tooltip: tooltipText,
          payload: store.copyWith(revenue: revenue),
          style: AppMapMarkerStyle(size: size),
        ),
      );
    }
    return result;
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
    name: 'Amapá',
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
    name: 'Ceará',
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
    name: 'Espírito Santo',
    regionId: 'SE',
    regionLabel: 'Sudeste',
    revenue: 286000,
    orders: 3600,
    margin: 18.9,
  ),
  _TerritoryMapRow(
    id: 'GO',
    name: 'Goiás',
    regionId: 'CO',
    regionLabel: 'Centro-Oeste',
    revenue: 410000,
    orders: 5200,
    margin: 17.6,
  ),
  _TerritoryMapRow(
    id: 'MA',
    name: 'Maranhão',
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
    name: 'Pará',
    regionId: 'NO',
    regionLabel: 'Norte',
    revenue: 364000,
    orders: 4700,
    margin: 15.4,
  ),
  _TerritoryMapRow(
    id: 'PB',
    name: 'Paraíba',
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
    name: 'Piauí',
    regionId: 'NE',
    regionLabel: 'Nordeste',
    revenue: 154000,
    orders: 2200,
    margin: 12.9,
  ),
  _TerritoryMapRow(
    id: 'PR',
    name: 'Paraná',
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
    name: 'Rondônia',
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
    name: 'São Paulo',
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

/// Loja fictícia usada como payload dos marcadores de pontos da demo.
@immutable
class _TerritoryStore {
  const _TerritoryStore({
    required this.name,
    required this.cityLabel,
    required this.regionId,
    required this.latitude,
    required this.longitude,
    required this.baseRevenue,
    this.revenue = 0,
  });

  final String name;
  final String cityLabel;
  final String regionId;
  final double latitude;
  final double longitude;

  /// Receita base em reais, antes dos multiplicadores de período/canal.
  final double baseRevenue;

  /// Receita resolvida após multiplicadores. Preenchida pelo data source ao
  /// produzir os pontos da snapshot atual.
  final double revenue;

  _TerritoryStore copyWith({double? revenue}) {
    return _TerritoryStore(
      name: name,
      cityLabel: cityLabel,
      regionId: regionId,
      latitude: latitude,
      longitude: longitude,
      baseRevenue: baseRevenue,
      revenue: revenue ?? this.revenue,
    );
  }
}

/// 30 capitais e cidades brasileiras com coordenadas reais. Receita base
/// foi distribuída de forma a variar tiers (alta/média/baixa) para que os
/// marcadores tenham tamanhos visualmente distintos na demo.
const List<_TerritoryStore> _baseStores = <_TerritoryStore>[
  // Sudeste
  _TerritoryStore(
    name: 'Loja Centro SP',
    cityLabel: 'São Paulo, SP',
    regionId: 'SE',
    latitude: -23.5505,
    longitude: -46.6333,
    baseRevenue: 162000,
  ),
  _TerritoryStore(
    name: 'Loja Guarulhos',
    cityLabel: 'Guarulhos, SP',
    regionId: 'SE',
    latitude: -23.4628,
    longitude: -46.5333,
    baseRevenue: 88000,
  ),
  _TerritoryStore(
    name: 'Loja Campinas',
    cityLabel: 'Campinas, SP',
    regionId: 'SE',
    latitude: -22.9099,
    longitude: -47.0626,
    baseRevenue: 71000,
  ),
  _TerritoryStore(
    name: 'Loja Copacabana',
    cityLabel: 'Rio de Janeiro, RJ',
    regionId: 'SE',
    latitude: -22.9068,
    longitude: -43.1729,
    baseRevenue: 124000,
  ),
  _TerritoryStore(
    name: 'Loja Savassi',
    cityLabel: 'Belo Horizonte, MG',
    regionId: 'SE',
    latitude: -19.9167,
    longitude: -43.9345,
    baseRevenue: 96000,
  ),
  _TerritoryStore(
    name: 'Loja Uberlândia',
    cityLabel: 'Uberlândia, MG',
    regionId: 'SE',
    latitude: -18.9186,
    longitude: -48.2772,
    baseRevenue: 42000,
  ),
  _TerritoryStore(
    name: 'Loja Vitória',
    cityLabel: 'Vitória, ES',
    regionId: 'SE',
    latitude: -20.3155,
    longitude: -40.3128,
    baseRevenue: 38000,
  ),
  // Sul
  _TerritoryStore(
    name: 'Loja Curitiba',
    cityLabel: 'Curitiba, PR',
    regionId: 'SU',
    latitude: -25.4290,
    longitude: -49.2671,
    baseRevenue: 84000,
  ),
  _TerritoryStore(
    name: 'Loja Porto Alegre',
    cityLabel: 'Porto Alegre, RS',
    regionId: 'SU',
    latitude: -30.0346,
    longitude: -51.2177,
    baseRevenue: 92000,
  ),
  _TerritoryStore(
    name: 'Loja Florianópolis',
    cityLabel: 'Florianópolis, SC',
    regionId: 'SU',
    latitude: -27.5954,
    longitude: -48.5480,
    baseRevenue: 64000,
  ),
  // Nordeste
  _TerritoryStore(
    name: 'Loja Pelourinho',
    cityLabel: 'Salvador, BA',
    regionId: 'NE',
    latitude: -12.9714,
    longitude: -38.5011,
    baseRevenue: 78000,
  ),
  _TerritoryStore(
    name: 'Loja Beira-Mar',
    cityLabel: 'Fortaleza, CE',
    regionId: 'NE',
    latitude: -3.7172,
    longitude: -38.5433,
    baseRevenue: 73000,
  ),
  _TerritoryStore(
    name: 'Loja Boa Viagem',
    cityLabel: 'Recife, PE',
    regionId: 'NE',
    latitude: -8.0476,
    longitude: -34.8770,
    baseRevenue: 67000,
  ),
  _TerritoryStore(
    name: 'Loja Maceió',
    cityLabel: 'Maceió, AL',
    regionId: 'NE',
    latitude: -9.6658,
    longitude: -35.7353,
    baseRevenue: 34000,
  ),
  _TerritoryStore(
    name: 'Loja Natal',
    cityLabel: 'Natal, RN',
    regionId: 'NE',
    latitude: -5.7945,
    longitude: -35.2110,
    baseRevenue: 36000,
  ),
  _TerritoryStore(
    name: 'Loja João Pessoa',
    cityLabel: 'João Pessoa, PB',
    regionId: 'NE',
    latitude: -7.1195,
    longitude: -34.8450,
    baseRevenue: 31000,
  ),
  _TerritoryStore(
    name: 'Loja Aracaju',
    cityLabel: 'Aracaju, SE',
    regionId: 'NE',
    latitude: -10.9091,
    longitude: -37.0735,
    baseRevenue: 28000,
  ),
  _TerritoryStore(
    name: 'Loja Teresina',
    cityLabel: 'Teresina, PI',
    regionId: 'NE',
    latitude: -5.0892,
    longitude: -42.8019,
    baseRevenue: 26000,
  ),
  _TerritoryStore(
    name: 'Loja São Luís',
    cityLabel: 'São Luís, MA',
    regionId: 'NE',
    latitude: -2.5391,
    longitude: -44.2829,
    baseRevenue: 33000,
  ),
  // Norte
  _TerritoryStore(
    name: 'Loja Ponta Negra',
    cityLabel: 'Manaus, AM',
    regionId: 'NO',
    latitude: -3.1190,
    longitude: -60.0217,
    baseRevenue: 56000,
  ),
  _TerritoryStore(
    name: 'Loja Belém',
    cityLabel: 'Belém, PA',
    regionId: 'NO',
    latitude: -1.4558,
    longitude: -48.5039,
    baseRevenue: 49000,
  ),
  _TerritoryStore(
    name: 'Loja Macapá',
    cityLabel: 'Macapá, AP',
    regionId: 'NO',
    latitude: 0.0349,
    longitude: -51.0694,
    baseRevenue: 22000,
  ),
  _TerritoryStore(
    name: 'Loja Boa Vista',
    cityLabel: 'Boa Vista, RR',
    regionId: 'NO',
    latitude: 2.8235,
    longitude: -60.6758,
    baseRevenue: 19000,
  ),
  _TerritoryStore(
    name: 'Loja Rio Branco',
    cityLabel: 'Rio Branco, AC',
    regionId: 'NO',
    latitude: -9.9747,
    longitude: -67.8100,
    baseRevenue: 21000,
  ),
  _TerritoryStore(
    name: 'Loja Palmas',
    cityLabel: 'Palmas, TO',
    regionId: 'NO',
    latitude: -10.1849,
    longitude: -48.3336,
    baseRevenue: 24000,
  ),
  _TerritoryStore(
    name: 'Loja Porto Velho',
    cityLabel: 'Porto Velho, RO',
    regionId: 'NO',
    latitude: -8.7619,
    longitude: -63.9039,
    baseRevenue: 23000,
  ),
  // Centro-Oeste
  _TerritoryStore(
    name: 'Loja Brasília',
    cityLabel: 'Brasília, DF',
    regionId: 'CO',
    latitude: -15.7975,
    longitude: -47.8919,
    baseRevenue: 102000,
  ),
  _TerritoryStore(
    name: 'Loja Goiânia',
    cityLabel: 'Goiânia, GO',
    regionId: 'CO',
    latitude: -16.6869,
    longitude: -49.2648,
    baseRevenue: 58000,
  ),
  _TerritoryStore(
    name: 'Loja Campo Grande',
    cityLabel: 'Campo Grande, MS',
    regionId: 'CO',
    latitude: -20.4697,
    longitude: -54.6201,
    baseRevenue: 41000,
  ),
  _TerritoryStore(
    name: 'Loja Cuiabá',
    cityLabel: 'Cuiabá, MT',
    regionId: 'CO',
    latitude: -15.6010,
    longitude: -56.0974,
    baseRevenue: 44000,
  ),
];
