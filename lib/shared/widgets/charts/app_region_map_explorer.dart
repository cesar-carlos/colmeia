import 'dart:async';
import 'dart:developer' as developer;

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_region_map_data_source.dart';
import 'package:colmeia/shared/widgets/feedback/app_data_stale_banner.dart';
import 'package:flutter/material.dart';
import 'package:result_dart/result_dart.dart';

typedef AppRegionMapFiltersBuilder<TFilters> =
    Widget Function(
      BuildContext context,
      TFilters filters,
      ValueChanged<TFilters> onFiltersChanged,
      ({bool isLoading}) state,
    );

class AppRegionMapExplorer<TItem, TFilters> extends StatefulWidget {
  const AppRegionMapExplorer({
    required this.dataSource,
    required this.initialFilters,
    required this.regionKeyBuilder,
    required this.regionLabelBuilder,
    super.key,
    this.title,
    this.subtitle,
    this.titleTrailing,
    this.belowSubtitle,
    this.filtersBuilder,
    this.style = const AppRegionMapChartStyle(),
    this.preset = AppChartPreset.explorable,
    this.initialDrillLevel = AppMapDrillLevel.region,
    this.initialMapDefinition,
    this.onLoadError,
    this.onViewportChanged,
    this.scopeInSubtitle = false,
    this.markerStyle = const AppMapMarkerStyle(),
    this.markerBuilder,
    this.onPointTap,
  });

  final AppRegionMapDataSource<TItem, TFilters> dataSource;
  final TFilters initialFilters;
  final String Function(TItem item) regionKeyBuilder;
  final String Function(TItem item) regionLabelBuilder;

  final String? title;
  final String? subtitle;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;
  final AppRegionMapFiltersBuilder<TFilters>? filtersBuilder;
  final AppRegionMapChartStyle style;
  final AppChartPreset preset;
  final AppMapDrillLevel initialDrillLevel;

  /// Optional map definition used as the warmup source during the initial
  /// loading state. When provided, the map engine pre-fetches and parses the
  /// GeoJSON in parallel with the first data load, so the map renders as soon
  /// as the data arrives instead of waiting for the GeoJSON download to
  /// complete afterwards.
  ///
  /// Ideally this matches the [AppMapDefinition] that the data source returns
  /// for the first [AppMapDrillLevel] (typically the broadest view). If omitted
  /// the explorer falls back to a generic Brazil-states GeoJSON.
  final AppMapDefinition? initialMapDefinition;

  /// Called when the data source returns a failure (after UI state updates).
  final void Function(AppFailure failure)? onLoadError;

  /// Forwards to [AppRegionMapChart.onViewportChanged].
  final ValueChanged<AppMapViewportChangedEvent>? onViewportChanged;

  /// Quando `true`, anexa "Escopo: <label>" ao subtitulo. Por padrao `false`
  /// porque o navegador de escopos do proprio chart ja exibe a selecao ativa
  /// e duplicar a informacao polui o cabecalho em layouts mobile.
  final bool scopeInSubtitle;

  /// Estilo padrao dos marcadores quando o snapshot retorna `points` sem
  /// estilo proprio.
  final AppMapMarkerStyle markerStyle;

  /// Builder opcional para o widget desenhado dentro do marcador. Quando
  /// `null`, o engine usa um shape colorido conforme [markerStyle].
  final Widget Function(BuildContext context, AppMapPoint point, int index)?
  markerBuilder;

  /// Disparado ao tocar em um ponto do mapa.
  final ValueChanged<AppMapPointTapEvent>? onPointTap;

  @override
  State<AppRegionMapExplorer<TItem, TFilters>> createState() =>
      _AppRegionMapExplorerState<TItem, TFilters>();
}

class _AppRegionMapExplorerState<TItem, TFilters>
    extends State<AppRegionMapExplorer<TItem, TFilters>> {
  static const Duration _filterReloadDebounce = Duration(milliseconds: 150);

  AppMapDrillLevel _drillLevel = AppMapDrillLevel.region;
  String? _focusedRegionKey;
  String? _selectedRegionKey;
  String? _selectedMetricKey;
  late TFilters _filters;
  bool _isLoading = false;
  int _requestToken = 0;
  AppRegionMapDataSnapshot<TItem>? _snapshot;
  String? _loadErrorMessage;
  Timer? _filterReloadDebounceTimer;

  // Last viewport explicitly changed by the user (pan/zoom).
  // Preserved across metric changes so the map stays in the same position.
  // Reset when the scope, drill level, or filters change.
  AppMapViewport? _lastUserViewport;

  @override
  void initState() {
    super.initState();
    _drillLevel = widget.initialDrillLevel;
    _filters = widget.initialFilters;
    unawaited(_loadData());
  }

  @override
  void didUpdateWidget(
    covariant AppRegionMapExplorer<TItem, TFilters> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataSource != widget.dataSource) {
      unawaited(_loadData(resetSelection: true));
    }
  }

  @override
  void dispose() {
    _filterReloadDebounceTimer?.cancel();
    _filterReloadDebounceTimer = null;
    // Invalida qualquer request in-flight: o token aumenta para que o fold
    // que retornar apos dispose seja descartado pelo guard `token != _requestToken`.
    _requestToken += 1;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final gapMd = Theme.of(context).extension<AppThemeTokens>()!.gapMd;

    final filters = widget.filtersBuilder?.call(
      context,
      _filters,
      _handleFiltersChanged,
      (isLoading: _isLoading),
    );

    if (snapshot == null) {
      if (_loadErrorMessage != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (filters != null) ...<Widget>[
              filters,
              SizedBox(height: gapMd),
            ],
            AppInlineErrorPanel(
              title: 'Erro ao carregar',
              message: _loadErrorMessage!,
              onRetry: () {
                setState(() => _loadErrorMessage = null);
                unawaited(_loadData());
              },
              variant: AppInlineErrorPanelVariant.plain,
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (filters != null) ...<Widget>[
            filters,
            SizedBox(height: gapMd),
          ],
          RepaintBoundary(
            child: AppRegionMapChart<TItem>(
              title: widget.title,
              subtitle: widget.subtitle,
              titleTrailing: widget.titleTrailing,
              belowSubtitle: widget.belowSubtitle,
              items: List<TItem>.empty(),
              mapDefinition:
                  widget.initialMapDefinition ??
                  const AppMapDefinition.network(
                    url:
                        'https://raw.githubusercontent.com/luizpedone/'
                        'municipal-brazilian-geodata/master/data/Brasil.json',
                    shapeDataField: 'UF',
                    regionLevel: AppMapRegionLevel.state,
                  ),
              metrics: <AppMapMetric<TItem>>[
                AppMapMetric<TItem>(
                  key: 'loading',
                  label: AppLocalizations.of(context).appLoading,
                  valueBuilder: _zeroMetric,
                ),
              ],
              selectedMetricKey: 'loading',
              regionKeyBuilder: widget.regionKeyBuilder,
              regionLabelBuilder: widget.regionLabelBuilder,
              isLoading: true,
              style: widget.style,
              preset: widget.preset,
              markerStyle: widget.markerStyle,
              markerBuilder: widget.markerBuilder,
              onPointTap: widget.onPointTap,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (filters != null) ...<Widget>[
          filters,
          SizedBox(height: gapMd),
        ],
        if (_loadErrorMessage != null) ...<Widget>[
          AppInlineErrorPanel(
            title: 'Erro ao atualizar',
            message: _loadErrorMessage!,
            onRetry: () {
              setState(() => _loadErrorMessage = null);
              unawaited(_loadData());
            },
            variant: AppInlineErrorPanelVariant.plain,
          ),
          SizedBox(height: gapMd),
        ],
        if (snapshot.isStale && _loadErrorMessage == null) ...<Widget>[
          AppDataStaleBanner(onRefresh: () => unawaited(_loadData())),
          SizedBox(height: gapMd),
        ],
        RepaintBoundary(
          child: AppRegionMapChart<TItem>(
            title: widget.title,
            subtitle: _composeSubtitle(snapshot.scopeLabel),
            titleTrailing: widget.titleTrailing,
            belowSubtitle: widget.belowSubtitle,
            scopeOptions: snapshot.availableScopes,
            activeScopeKey: snapshot.activeScopeKey,
            preferredViewport: snapshot.preferredViewport,
            items: snapshot.items,
            mapDefinition: snapshot.mapDefinition,
            metrics: snapshot.metrics,
            selectedMetricKey:
                _selectedMetricKey ??
                snapshot.selectedMetricKey ??
                snapshot.metrics.first.key,
            selectedRegionKey: _selectedRegionKey,
            currentDrillLevel: _drillLevel,
            regionKeyBuilder: widget.regionKeyBuilder,
            regionLabelBuilder: widget.regionLabelBuilder,
            onSelectionChanged: (event) {
              setState(() {
                _selectedRegionKey = event.currentRegionKey;
              });
            },
            onMetricChanged: (event) {
              setState(() {
                _selectedMetricKey = event.metricKey;
              });
              unawaited(_loadData(preserveViewport: true));
            },
            onScopeChanged: _handleScopeChanged,
            onDrillDownRequested: _handleDrillDownRequested,
            onDrillUpRequested: _drillLevel == AppMapDrillLevel.region
                ? null
                : _handleDrillUpRequested,
            onViewportChanged: (event) {
              // Capture the user's viewport so it can be preserved across
              // metric changes. No setState needed; only used at load time.
              _lastUserViewport = event.viewport;
              widget.onViewportChanged?.call(event);
            },
            style: widget.style,
            preset: widget.preset,
            isRefreshing: _isLoading,
            emptyPlaceholder:
                snapshot.items.isEmpty && snapshot.emptyHint != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      snapshot.emptyHint!,
                      textAlign: TextAlign.center,
                    ),
                  )
                : null,
            points: snapshot.points,
            markerStyle: widget.markerStyle,
            markerBuilder: widget.markerBuilder,
            onPointTap: widget.onPointTap,
          ),
        ),
      ],
    );
  }

  String? _composeSubtitle(String scopeLabel) {
    final baseSubtitle = widget.subtitle;
    if (!widget.scopeInSubtitle) {
      return baseSubtitle;
    }
    if (baseSubtitle == null || baseSubtitle.isEmpty) {
      return 'Escopo: $scopeLabel';
    }
    return '$baseSubtitle  •  Escopo: $scopeLabel';
  }

  Future<void> _loadData({
    bool resetSelection = false,
    bool preserveViewport = false,
  }) async {
    _filterReloadDebounceTimer?.cancel();
    _filterReloadDebounceTimer = null;

    final token = ++_requestToken;
    setState(() {
      _isLoading = true;
      if (resetSelection) {
        _selectedRegionKey = null;
      }
    });

    late final AppResult<AppRegionMapDataSnapshot<TItem>> result;
    try {
      result = await widget.dataSource.load(
        AppRegionMapDataQuery<TFilters>(
          drillLevel: _drillLevel,
          focusedRegionKey: _focusedRegionKey,
          filters: _filters,
          selectedMetricKey: _selectedMetricKey,
        ),
      );
    } on Object catch (error, stackTrace) {
      developer.log(
        'AppRegionMapExplorer load threw',
        name: 'app.region_map_explorer',
        error: error,
        stackTrace: stackTrace,
      );
      result = Failure<AppRegionMapDataSnapshot<TItem>, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackUserMessage:
              'Nao foi possivel carregar os dados do mapa. Tente novamente.',
        ),
      );
    }

    if (!mounted || token != _requestToken) {
      return;
    }

    result.fold(
      (snapshot) {
        if (!mounted || token != _requestToken) {
          return;
        }
        setState(() {
          final userViewport = _lastUserViewport;
          _snapshot = preserveViewport && userViewport != null
              ? _withViewport(snapshot, userViewport)
              : snapshot;
          _isLoading = false;
          _loadErrorMessage = null;
          _selectedMetricKey = snapshot.selectedMetricKey ?? _selectedMetricKey;
          if (resetSelection) {
            _selectedRegionKey = null;
          }
        });
      },
      (failure) {
        if (!mounted || token != _requestToken) {
          return;
        }
        widget.onLoadError?.call(failure);
        setState(() {
          _isLoading = false;
          _loadErrorMessage = failure.displayMessage;
        });
      },
    );
  }

  void _handleFiltersChanged(TFilters filters) {
    _filterReloadDebounceTimer?.cancel();
    _lastUserViewport = null;
    setState(() {
      _filters = filters;
      _selectedRegionKey = null;
      // Intentionally preserve _selectedMetricKey so the user's metric choice
      // survives filter changes (e.g. switching the period).
      _drillLevel = AppMapDrillLevel.region;
      _focusedRegionKey = null;
    });
    _filterReloadDebounceTimer = Timer(_filterReloadDebounce, () {
      _filterReloadDebounceTimer = null;
      if (!mounted) {
        return;
      }
      unawaited(_loadData(resetSelection: true));
    });
  }

  void _handleDrillDownRequested(AppMapDrillDownEvent<TItem> event) {
    // Do not drill past the terminal level.
    if (event.toLevel == AppMapDrillLevel.custom &&
        _drillLevel == AppMapDrillLevel.custom) {
      return;
    }

    _lastUserViewport = null;
    setState(() {
      _drillLevel = event.toLevel;
      _focusedRegionKey = event.regionKey;
      _selectedRegionKey = null;
      _selectedMetricKey = null;
    });
    unawaited(_loadData(resetSelection: true));
  }

  void _handleDrillUpRequested(AppMapDrillUpEvent _) {
    if (_drillLevel == AppMapDrillLevel.region) {
      return;
    }

    _lastUserViewport = null;
    setState(() {
      _drillLevel = AppMapDrillLevel.region;
      _focusedRegionKey = null;
      _selectedRegionKey = null;
      _selectedMetricKey = null;
    });
    unawaited(_loadData(resetSelection: true));
  }

  void _handleScopeChanged(AppMapScopeChangedEvent event) {
    _lastUserViewport = null;
    final scopeKey = event.currentScopeKey;
    if (scopeKey == _focusedRegionKey &&
        _drillLevel != AppMapDrillLevel.region) {
      return;
    }

    setState(() {
      _selectedRegionKey = null;
      _selectedMetricKey = null;
      if (scopeKey == null) {
        _drillLevel = AppMapDrillLevel.region;
        _focusedRegionKey = null;
      } else {
        _drillLevel = AppMapDrillLevel.state;
        _focusedRegionKey = scopeKey;
      }
    });
    unawaited(_loadData(resetSelection: true));
  }
}

num _zeroMetric<TItem>(TItem _) => 0;

// Returns a snapshot identical to [source] but with [viewport] as the
// preferred viewport. Used to preserve the user's pan/zoom across metric
// changes without mutating the original snapshot.
AppRegionMapDataSnapshot<TItem> _withViewport<TItem>(
  AppRegionMapDataSnapshot<TItem> source,
  AppMapViewport viewport,
) {
  return AppRegionMapDataSnapshot<TItem>(
    items: source.items,
    mapDefinition: source.mapDefinition,
    metrics: source.metrics,
    scopeLabel: source.scopeLabel,
    selectedMetricKey: source.selectedMetricKey,
    activeScopeKey: source.activeScopeKey,
    availableScopes: source.availableScopes,
    preferredViewport: viewport,
    loadedAt: source.loadedAt,
    isStale: source.isStale,
    emptyHint: source.emptyHint,
    points: source.points,
  );
}
