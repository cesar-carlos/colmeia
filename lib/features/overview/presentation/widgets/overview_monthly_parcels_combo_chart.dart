import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String _monthlyXLabel(OverviewMonthlyParcelPoint p) => p.anoMes;

num _monthlyBarBySales(OverviewMonthlyParcelPoint p) => p.qtdVendas;

num _monthlyLineBySales(OverviewMonthlyParcelPoint p) => p.valorParcela;

num _monthlyBarByValue(OverviewMonthlyParcelPoint p) => p.valorParcela;

num _monthlyLineByValue(OverviewMonthlyParcelPoint p) => p.qtdVendas;

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
    super.key,
  });

  final AppLocalizations l10n;
  final List<OverviewMonthlyParcelPoint> points;
  final bool loadFailed;

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
  static const int _panCategoryDelta = 6;

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

  String _styleCacheKeyFor(
    AppThemeTokens tokens,
    int pointCount,
    bool showCategoryPanHints,
  ) =>
      '$_formatsLocaleTag|${showCategoryPanHints ? 1 : 0}|'
      '${tokens.gapSm}|${tokens.contentSpacing}|${tokens.chartStandardHeight}|'
      '${tokens.chartOverviewMonthlyCategoryMinSlotWidth}|$pointCount';

  void _ensureComboStyles({
    required AppThemeTokens tokens,
    required AppLocalizations l10n,
    required int pointCount,
    required bool showCategoryPanHints,
  }) {
    final key = _styleCacheKeyFor(tokens, pointCount, showCategoryPanHints);
    if (_cachedStyleKey == key &&
        _cachedStyleSales != null &&
        _cachedStyleValue != null) {
      return;
    }
    _cachedStyleKey = key;
    _cachedStyleSales = AppComboChartStyle(
      height: tokens.chartStandardHeight + tokens.contentSpacing * 2,
      animationDuration: Duration.zero,
      leftAxisFormat: _decimalFormat,
      rightAxisFormat: _compactCurrencyFormat,
      chartPadding: EdgeInsets.zero,
      showRightYAxis: false,
      showDataLabels: true,
      barDataLabelOffset: Offset(0, tokens.gapSm),
      minCategorySlotWidth: tokens.chartOverviewMonthlyCategoryMinSlotWidth,
      horizontalScrollSemanticsHint:
          l10n.overviewComparisonBarHorizontalScrollHint,
      stickyPrimaryYAxisWhileScrolling: false,
      enableAutoScroll: false,
      loadingLabel: l10n.overviewComparisonChartLoading,
      categoryAutoScrollingDelta:
          showCategoryPanHints ? _panCategoryDelta : null,
      categoryViewportFootnote: showCategoryPanHints
          ? l10n.chartComboPanGestureHint
          : null,
      categoryViewportPanSemanticsLabel: showCategoryPanHints
          ? l10n.chartComboPanChartA11y(pointCount)
          : null,
    );
    _cachedStyleValue = AppComboChartStyle(
      height: tokens.chartStandardHeight + tokens.contentSpacing * 2,
      animationDuration: Duration.zero,
      leftAxisFormat: _compactCurrencyFormat,
      rightAxisFormat: _decimalFormat,
      chartPadding: EdgeInsets.zero,
      showRightYAxis: false,
      showDataLabels: true,
      barDataLabelOffset: Offset(0, tokens.gapSm),
      minCategorySlotWidth: tokens.chartOverviewMonthlyCategoryMinSlotWidth,
      horizontalScrollSemanticsHint:
          l10n.overviewComparisonBarHorizontalScrollHint,
      stickyPrimaryYAxisWhileScrolling: false,
      enableAutoScroll: false,
      loadingLabel: l10n.overviewComparisonChartLoading,
      categoryAutoScrollingDelta:
          showCategoryPanHints ? _panCategoryDelta : null,
      categoryViewportFootnote: showCategoryPanHints
          ? l10n.chartComboPanGestureHint
          : null,
      categoryViewportPanSemanticsLabel: showCategoryPanHints
          ? l10n.chartComboPanChartA11y(pointCount)
          : null,
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
    final showCategoryPanHints = pointCount > _panCategoryDelta;

    _ensureComboStyles(
      tokens: tokens,
      l10n: l10n,
      pointCount: pointCount,
      showCategoryPanHints: showCategoryPanHints,
    );

    final emptyMessage = widget.loadFailed
        ? l10n.overviewMonthlyParcelsLoadFailed
        : l10n.overviewMonthlyParcelsEmpty;

    final activeStyle =
        valuePrimary ? _cachedStyleValue! : _cachedStyleSales!;

    return Semantics(
      label: valuePrimary
          ? l10n.overviewMonthlyParcelsChartSemanticsValueView
          : l10n.overviewMonthlyParcelsChartSemantics,
      child: RepaintBoundary(
        child: AppComboChart<OverviewMonthlyParcelPoint>(
          key: ObjectKey(widget.points),
          title: l10n.overviewMonthlyParcelsTitle,
          subtitle: valuePrimary
              ? l10n.overviewMonthlyParcelsSubtitleValueView
              : l10n.overviewMonthlyParcelsSubtitle,
          belowSubtitle: AppSegmentedControl<_OverviewMonthlyParcelDisplay>(
            options: <AppSegmentedControlOption<_OverviewMonthlyParcelDisplay>>[
              AppSegmentedControlOption<_OverviewMonthlyParcelDisplay>(
                value: _OverviewMonthlyParcelDisplay.bySalesCount,
                label: l10n.overviewMonthlyParcelsSwitchSalesLabel,
              ),
              AppSegmentedControlOption<_OverviewMonthlyParcelDisplay>(
                value: _OverviewMonthlyParcelDisplay.byParcelValue,
                label: l10n.overviewMonthlyParcelsSwitchValueLabel,
              ),
            ],
            value: _display,
            onChanged: (v) => setState(() => _display = v),
          ),
          items: widget.points,
          xLabelBuilder: _monthlyXLabel,
          barValueBuilder:
              valuePrimary ? _monthlyBarByValue : _monthlyBarBySales,
          barSeriesLabel: valuePrimary
              ? l10n.overviewMonthlyParcelsAmountSeriesLabel
              : l10n.overviewMonthlyParcelsSalesSeriesLabel,
          lineValueBuilder:
              valuePrimary ? _monthlyLineByValue : _monthlyLineBySales,
          lineSeriesLabel: valuePrimary
              ? l10n.overviewMonthlyParcelsSalesSeriesLabel
              : l10n.overviewMonthlyParcelsAmountSeriesLabel,
          barDataLabelBuilder: valuePrimary
              ? _barDataLabelCurrency
              : _barDataLabelDecimal,
          style: activeStyle,
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
