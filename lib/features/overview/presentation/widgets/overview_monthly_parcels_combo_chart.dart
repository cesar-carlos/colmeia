import 'dart:async';

import 'package:colmeia/app/router/app_chart_fullscreen_routes.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart'
    show formatComparisonBarXAxisLabelWrapped;
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

String _monthlyXLabel(OverviewMonthlyParcelPoint p) =>
    formatComparisonBarXAxisLabelWrapped(
      p.anoMes,
      maxCharsPerLine: 11,
      maxLines: 3,
    );

num _monthlyBarBySales(OverviewMonthlyParcelPoint p) => p.qtdVendas;

num _monthlyLineBySales(OverviewMonthlyParcelPoint p) => p.valorParcela;

num _monthlyBarByValue(OverviewMonthlyParcelPoint p) => p.valorParcela;

num _monthlyLineByValue(OverviewMonthlyParcelPoint p) => p.qtdVendas;

/// Optional copy for [OverviewMonthlyParcelsComboChart] outside the overview
/// (e.g. Sales hub) so titles do not imply multi-branch scope.
@immutable
class MonthlyParcelsComboChartStrings {
  const MonthlyParcelsComboChartStrings({
    required this.chartTitle,
    required this.subtitleWhenSalesPrimary,
    required this.subtitleWhenValuePrimary,
    required this.switchSalesLabel,
    required this.switchParcelValueLabel,
    required this.seriesSalesLabel,
    required this.seriesParcelAmountLabel,
    required this.emptyMessage,
    required this.loadFailedMessage,
    required this.semanticsWhenSalesPrimary,
    required this.semanticsWhenValuePrimary,
  });

  final String chartTitle;
  final String subtitleWhenSalesPrimary;
  final String subtitleWhenValuePrimary;
  final String switchSalesLabel;
  final String switchParcelValueLabel;
  final String seriesSalesLabel;
  final String seriesParcelAmountLabel;
  final String emptyMessage;
  final String loadFailedMessage;
  final String semanticsWhenSalesPrimary;
  final String semanticsWhenValuePrimary;
}

/// Last-12-months parcel trend (bar + line) with a sales vs parcel-value
/// toggle.
///
/// **Data contract:** do not mutate [points] in place after passing them to
/// this widget; replace the list when the payload changes.
class OverviewMonthlyParcelsComboChart extends StatefulWidget {
  const OverviewMonthlyParcelsComboChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    this.loadFailureMessage,
    this.chartStrings,
    this.isLoading = false,
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewMonthlyParcelPoint> points;
  final bool loadFailed;

  /// When true, shows the chart loading state (e.g. first fetch on a page).
  final bool isLoading;

  /// Copy for titles, subtitles and semantics. When null, overview l10n keys
  /// are used.
  final MonthlyParcelsComboChartStrings? chartStrings;

  /// Specific message extracted from the underlying `AppFailure` (e.g.
  /// "Voce nao tem acesso a este agente."). When set AND [loadFailed] is
  /// true, the chart shows this instead of the generic l10n "load failed"
  /// label so the user gets actionable context (BUG #4).
  final String? loadFailureMessage;

  @override
  State<OverviewMonthlyParcelsComboChart> createState() =>
      _OverviewMonthlyParcelsComboChartState();
}

enum _OverviewMonthlyParcelDisplay {
  /// Bars = sales count; line = parcel amount (default).
  bySalesCount,

  /// Bars = parcel amount; line = sales count (right axis shows counts).
  byParcelValue,
}

class _OverviewMonthlyParcelsComboChartState
    extends State<OverviewMonthlyParcelsComboChart> {
  _OverviewMonthlyParcelDisplay _display =
      _OverviewMonthlyParcelDisplay.bySalesCount;

  String _formatsLocaleTag = '';
  late NumberFormat _decimalFormat;
  late NumberFormat _compactCurrencyFormat;

  String? _emptyMessageCache;
  Widget? _emptyPlaceholderCache;

  String? _cachedStyleKey;
  AppComboChartStyle? _cachedStyleSales;
  AppComboChartStyle? _cachedStyleValue;

  @override
  void initState() {
    super.initState();
    _formatsLocaleTag = widget.l10n.localeName;
    _initFormats(_formatsLocaleTag);
  }

  void _initFormats(String localeTag) {
    _decimalFormat = NumberFormat.decimalPattern(localeTag);
    _compactCurrencyFormat = AppBrFormatters.compactCurrencyFormatForLocale(
      localeTag,
    );
  }

  void _invalidateListCaches() {
    _emptyMessageCache = null;
    _emptyPlaceholderCache = null;
  }

  void _invalidateStyleCaches() {
    _cachedStyleKey = null;
    _cachedStyleSales = null;
    _cachedStyleValue = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tag = Localizations.localeOf(context).toString();
    if (_formatsLocaleTag != tag) {
      _formatsLocaleTag = tag;
      _initFormats(tag);
      _invalidateListCaches();
      _invalidateStyleCaches();
    }
  }

  @override
  void didUpdateWidget(covariant OverviewMonthlyParcelsComboChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.l10n.localeName != oldWidget.l10n.localeName) {
      _formatsLocaleTag = widget.l10n.localeName;
      _initFormats(widget.l10n.localeName);
      _invalidateListCaches();
      _invalidateStyleCaches();
    } else if (!identical(widget.points, oldWidget.points)) {
      _invalidateListCaches();
      _invalidateStyleCaches();
    }
  }

  String _barDataLabelDecimal(OverviewMonthlyParcelPoint _, num v) =>
      _decimalFormat.format(v);

  String _barDataLabelCurrency(OverviewMonthlyParcelPoint _, num v) =>
      _compactCurrencyFormat.format(v);

  String _styleCacheKeyFor(AppThemeTokens tokens, int pointCount) =>
      '$_formatsLocaleTag|${tokens.gapSm}|${tokens.contentSpacing}|'
      '${tokens.chartStandardHeight}|'
      '${AppChartEngineCartesianBarGeometryDefaults.minCategorySlotWidth}|$pointCount';

  AppComboChartStyle _buildComboStyle({
    required AppThemeTokens tokens,
    required AppLocalizations l10n,
    required NumberFormat leftAxis,
    required NumberFormat rightAxis,
    double? heightOverride,
  }) {
    return AppComboChartStyle(
      // One [contentSpacing]: bar values use chart annotations, not Syncfusion
      // outer column labels, so we do not need the full +2* buffer used on
      // comparison column charts — extra height only adds empty band above
      // the bottom legend inside the fixed [SizedBox].
      height: heightOverride ?? (tokens.chartStandardHeight + tokens.contentSpacing),
      // Aligned with the bar charts (350 ms): the previous Duration.zero left
      // this card visually static while siblings animated in via staged
      // mounting + 350 ms entrance.
      animationDuration: const Duration(milliseconds: 350),
      leftAxisFormat: leftAxis,
      rightAxisFormat: rightAxis,
      chartPadding: EdgeInsets.only(bottom: tokens.gapSm),
      showRightYAxis: false,
      showDataLabels: true,
      barDataLabelOffset: Offset(0, tokens.gapSm),
      categoryLabelIntersectAction: AxisLabelIntersectAction.none,
      horizontalScrollSemanticsHint: l10n.overviewComparisonBarHorizontalScrollHint,
      // Use horizontal scroll (default) instead of category-axis pan: pan kept
      // the chart width fixed but Y-axis was still scaled by the full dataset.
      stickyPrimaryYAxisWhileScrolling: false,
      loadingLabel: l10n.overviewComparisonChartLoading,
    );
  }

  void _ensureComboStyles({
    required AppThemeTokens tokens,
    required AppLocalizations l10n,
    required int pointCount,
  }) {
    final key = _styleCacheKeyFor(tokens, pointCount);
    if (_cachedStyleKey == key &&
        _cachedStyleSales != null &&
        _cachedStyleValue != null) {
      return;
    }
    _cachedStyleKey = key;

    AppComboChartStyle build({
      required NumberFormat leftAxis,
      required NumberFormat rightAxis,
    }) {
      return _buildComboStyle(
        tokens: tokens,
        l10n: l10n,
        leftAxis: leftAxis,
        rightAxis: rightAxis,
      );
    }

    _cachedStyleSales = build(
      leftAxis: _decimalFormat,
      rightAxis: _compactCurrencyFormat,
    );
    _cachedStyleValue = build(
      leftAxis: _compactCurrencyFormat,
      rightAxis: _decimalFormat,
    );
  }

  Widget? _emptyPlaceholder({
    required AppThemeTokens tokens,
    required String message,
  }) {
    if (_emptyMessageCache == message && _emptyPlaceholderCache != null) {
      return _emptyPlaceholderCache;
    }
    _emptyMessageCache = message;
    return _emptyPlaceholderCache = Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.contentSpacing),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = widget.l10n;
    final valuePrimary =
        _display == _OverviewMonthlyParcelDisplay.byParcelValue;
    final pointCount = widget.points.length;

    _ensureComboStyles(
      tokens: tokens,
      l10n: l10n,
      pointCount: pointCount,
    );

    final copy = widget.chartStrings;
    final emptyMessage = widget.loadFailed
        ? (widget.loadFailureMessage ??
              (copy?.loadFailedMessage ??
                  l10n.overviewMonthlyParcelsLoadFailed))
        : (copy?.emptyMessage ?? l10n.overviewMonthlyParcelsEmpty);

    final activeStyle = valuePrimary ? _cachedStyleValue! : _cachedStyleSales!;

    final semanticsLabel = valuePrimary
        ? (copy?.semanticsWhenValuePrimary ??
              l10n.overviewMonthlyParcelsChartSemanticsValueView)
        : (copy?.semanticsWhenSalesPrimary ??
              l10n.overviewMonthlyParcelsChartSemantics);
    void openFullscreen() {
      final pointsSnapshot = List<OverviewMonthlyParcelPoint>.of(
        widget.points,
        growable: false,
      );
      final copySnapshot = copy;
      unawaited(
        context.pushChartFullscreen<void>(
          extra: AppChartFullscreenRouteExtra(
            title: copySnapshot?.chartTitle ?? l10n.overviewMonthlyParcelsTitle,
            subtitle: valuePrimary
                ? (copySnapshot?.subtitleWhenValuePrimary ??
                      l10n.overviewMonthlyParcelsSubtitleValueView)
                : (copySnapshot?.subtitleWhenSalesPrimary ??
                      l10n.overviewMonthlyParcelsSubtitle),
            chartSemanticsLabel: semanticsLabel,
            chartBuilder: (fullscreenContext) {
              final fullscreenTokens = Theme.of(
                fullscreenContext,
              ).extension<AppThemeTokens>()!;
              var fullscreenDisplay = _display;
              return StatefulBuilder(
                builder: (context, setFullscreenState) {
                  final fullscreenValuePrimary =
                      fullscreenDisplay == _OverviewMonthlyParcelDisplay.byParcelValue;
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final availableChartHeight =
                          (constraints.maxHeight -
                                  fullscreenTokens.contentSpacing -
                                  48)
                              .clamp(220.0, constraints.maxHeight);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          AppSegmentedControl<_OverviewMonthlyParcelDisplay>(
                            options: <AppSegmentedControlOption<_OverviewMonthlyParcelDisplay>>[
                              AppSegmentedControlOption<_OverviewMonthlyParcelDisplay>(
                                value: _OverviewMonthlyParcelDisplay.bySalesCount,
                                label:
                                    copySnapshot?.switchSalesLabel ??
                                    l10n.overviewMonthlyParcelsSwitchSalesLabel,
                              ),
                              AppSegmentedControlOption<_OverviewMonthlyParcelDisplay>(
                                value: _OverviewMonthlyParcelDisplay.byParcelValue,
                                label:
                                    copySnapshot?.switchParcelValueLabel ??
                                    l10n.overviewMonthlyParcelsSwitchValueLabel,
                              ),
                            ],
                            value: fullscreenDisplay,
                            onChanged: (v) =>
                                setFullscreenState(() => fullscreenDisplay = v),
                          ),
                          SizedBox(height: fullscreenTokens.contentSpacing),
                          SizedBox(
                            height: availableChartHeight,
                            child: AppComboChart<OverviewMonthlyParcelPoint>(
                              key: ValueKey<int>(identityHashCode(pointsSnapshot)),
                              items: pointsSnapshot,
                              xLabelBuilder: _monthlyXLabel,
                              barValueBuilder: fullscreenValuePrimary
                                  ? _monthlyBarByValue
                                  : _monthlyBarBySales,
                              barSeriesLabel: fullscreenValuePrimary
                                  ? (copySnapshot?.seriesParcelAmountLabel ??
                                        l10n.overviewMonthlyParcelsAmountSeriesLabel)
                                  : (copySnapshot?.seriesSalesLabel ??
                                        l10n.overviewMonthlyParcelsSalesSeriesLabel),
                              lineValueBuilder: fullscreenValuePrimary
                                  ? _monthlyLineByValue
                                  : _monthlyLineBySales,
                              lineSeriesLabel: fullscreenValuePrimary
                                  ? (copySnapshot?.seriesSalesLabel ??
                                        l10n.overviewMonthlyParcelsSalesSeriesLabel)
                                  : (copySnapshot?.seriesParcelAmountLabel ??
                                        l10n.overviewMonthlyParcelsAmountSeriesLabel),
                              barDataLabelBuilder: fullscreenValuePrimary
                                  ? _barDataLabelCurrency
                                  : _barDataLabelDecimal,
                              style: _buildComboStyle(
                                tokens: fullscreenTokens,
                                l10n: l10n,
                                leftAxis: fullscreenValuePrimary
                                    ? _compactCurrencyFormat
                                    : _decimalFormat,
                                rightAxis: fullscreenValuePrimary
                                    ? _decimalFormat
                                    : _compactCurrencyFormat,
                                heightOverride: availableChartHeight,
                              ),
                              isLoading: widget.isLoading,
                              emptyPlaceholder: pointsSnapshot.isEmpty
                                  ? Center(
                                      child: Text(
                                        emptyMessage,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      );
    }

    return Semantics(
      label: semanticsLabel,
      child: RepaintBoundary(
        // Stable key: re-mounting the SfCartesianChart on every new payload is
        // expensive (Syncfusion rebuilds painters). Pegging the key to the
        // list identity lets the engine update points in place when the parent
        // caches the list (mirrors the donut card fix).
        child: AppComboChart<OverviewMonthlyParcelPoint>(
          key: ValueKey<int>(identityHashCode(widget.points)),
          title: copy?.chartTitle ?? l10n.overviewMonthlyParcelsTitle,
          onOpenFullscreen: openFullscreen,
          subtitle: valuePrimary
              ? (copy?.subtitleWhenValuePrimary ??
                    l10n.overviewMonthlyParcelsSubtitleValueView)
              : (copy?.subtitleWhenSalesPrimary ??
                    l10n.overviewMonthlyParcelsSubtitle),
          belowSubtitle: AppSegmentedControl<_OverviewMonthlyParcelDisplay>(
            options: <AppSegmentedControlOption<_OverviewMonthlyParcelDisplay>>[
              AppSegmentedControlOption<_OverviewMonthlyParcelDisplay>(
                value: _OverviewMonthlyParcelDisplay.bySalesCount,
                label:
                    copy?.switchSalesLabel ??
                    l10n.overviewMonthlyParcelsSwitchSalesLabel,
              ),
              AppSegmentedControlOption<_OverviewMonthlyParcelDisplay>(
                value: _OverviewMonthlyParcelDisplay.byParcelValue,
                label:
                    copy?.switchParcelValueLabel ??
                    l10n.overviewMonthlyParcelsSwitchValueLabel,
              ),
            ],
            value: _display,
            onChanged: (v) => setState(() => _display = v),
          ),
          items: widget.points,
          xLabelBuilder: _monthlyXLabel,
          barValueBuilder: valuePrimary
              ? _monthlyBarByValue
              : _monthlyBarBySales,
          barSeriesLabel: valuePrimary
              ? (copy?.seriesParcelAmountLabel ??
                    l10n.overviewMonthlyParcelsAmountSeriesLabel)
              : (copy?.seriesSalesLabel ??
                    l10n.overviewMonthlyParcelsSalesSeriesLabel),
          lineValueBuilder: valuePrimary
              ? _monthlyLineByValue
              : _monthlyLineBySales,
          lineSeriesLabel: valuePrimary
              ? (copy?.seriesSalesLabel ??
                    l10n.overviewMonthlyParcelsSalesSeriesLabel)
              : (copy?.seriesParcelAmountLabel ??
                    l10n.overviewMonthlyParcelsAmountSeriesLabel),
          barDataLabelBuilder: valuePrimary
              ? _barDataLabelCurrency
              : _barDataLabelDecimal,
          style: activeStyle,
          isLoading: widget.isLoading,
          emptyPlaceholder: widget.points.isEmpty
              ? DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.bodyMedium,
                  child: _emptyPlaceholder(
                    tokens: tokens,
                    message: emptyMessage,
                  )!,
                )
              : null,
        ),
      ),
    );
  }
}
