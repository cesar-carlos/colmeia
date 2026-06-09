import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/dashboard_lucratividade_percent_metrics.dart';
import 'package:colmeia/features/overview/presentation/share/overview_lucratividade_chart_share.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_load_failure_helpers.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/metric_toggle_comparison_bar_fullscreen_body.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_actions.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart' show TooltipArgs;

num _barByProfit(ResumoProdutoVendaLucratividadeRow r) => r.lucro;
num _lineByProfit(ResumoProdutoVendaLucratividadeRow r) => r.valorTotalItem;

num _barByRevenue(ResumoProdutoVendaLucratividadeRow r) => r.valorTotalItem;
num _lineByRevenue(ResumoProdutoVendaLucratividadeRow r) => r.custoReposicao;

num _barByCost(ResumoProdutoVendaLucratividadeRow r) => r.custoReposicao;
num _lineByCost(ResumoProdutoVendaLucratividadeRow r) => r.valorTotalItem;

String? Function(TooltipArgs args)? _lucratividadeMarkupTooltipBodyResolver(
  List<ResumoProdutoVendaLucratividadeRow> points,
  LucratividadePercentMetric metric,
  AppLocalizations l10n,
) {
  if (metric != LucratividadePercentMetric.markupOverCost) return null;
  return (TooltipArgs args) {
    final dynamic raw = args.pointIndex;
    final i = raw is int ? raw : (raw as num).toInt();
    if (i < 0 || i >= points.length) return null;
    if (points[i].custoReposicao > 0) return null;
    final base = args.text ?? '';
    final extra = l10n.overviewLucratividadeMarkupUndefinedTooltip;
    if (base.isEmpty) return extra;
    return '$base\n$extra';
  };
}

enum _LucratividadeDisplay {
  /// Bars = profit (lucro), line = revenue (receita).
  profitRevenue,

  /// Bars = revenue, line = replacement cost.
  revenueCost,

  /// Bars = replacement cost, line = revenue.
  costRevenue,

  /// Bars = selected percent metric; line = revenue (hidden series).
  percentMetrics,
}

/// Period product profitability chart: **one category per agent** (all
/// branches summed) for the active overview filter date range.
///
/// When [overviewApprovedAgentCount] is zero, the empty state suggests checking
/// agent availability; otherwise an empty [points] list means no sales/cost
/// data for the period.
class OverviewLucratividadeChart extends StatefulWidget {
  const OverviewLucratividadeChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    required this.overviewApprovedAgentCount,
    this.loadFailure,
    this.loadFailureMessage,
    this.onViewAgentFailureDetails,
    this.onRequestFullscreen,
    this.onRequestShare,
    super.key,
  });

  final AppLocalizations l10n;
  final List<ResumoProdutoVendaLucratividadeRow> points;
  final bool loadFailed;
  final AppFailure? loadFailure;
  final int overviewApprovedAgentCount;
  final String? loadFailureMessage;
  final VoidCallback? onViewAgentFailureDetails;
  final AppChartFullscreenRequestCallback? onRequestFullscreen;
  final AppChartShareRequestCallback? onRequestShare;

  @override
  State<OverviewLucratividadeChart> createState() =>
      _OverviewLucratividadeChartState();
}

class _OverviewLucratividadeChartState
    extends State<OverviewLucratividadeChart> {
  final GlobalKey _shareKey = GlobalKey();

  _LucratividadeDisplay _display = _LucratividadeDisplay.profitRevenue;

  /// Default among percent KPIs: gross margin on sales.
  LucratividadePercentMetric _percentMetric =
      LucratividadePercentMetric.grossMargin;

  String _formatsLocaleTag = '';
  late NumberFormat _compactCurrencyFormat;
  late NumberFormat _percentFormat;
  late NumberFormat _markupAxisFormat;

  String? _emptyMessageCache;
  Widget? _emptyPlaceholderCache;

  @override
  void initState() {
    super.initState();
    _formatsLocaleTag = widget.l10n.localeName;
    _initFormats(_formatsLocaleTag);
  }

  void _initFormats(String localeTag) {
    _compactCurrencyFormat = AppBrFormatters.compactCurrencyFormatForLocale(
      localeTag,
    );
    _percentFormat = NumberFormat.decimalPercentPattern(
      locale: localeTag,
      decimalDigits: 1,
    );
    _markupAxisFormat = NumberFormat('#0.0', localeTag);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tag = Localizations.localeOf(context).toString();
    if (_formatsLocaleTag != tag) {
      _formatsLocaleTag = tag;
      _initFormats(tag);
      _emptyMessageCache = null;
      _emptyPlaceholderCache = null;
    }
  }

  @override
  void didUpdateWidget(covariant OverviewLucratividadeChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.l10n.localeName != oldWidget.l10n.localeName) {
      _formatsLocaleTag = widget.l10n.localeName;
      _initFormats(widget.l10n.localeName);
      _emptyMessageCache = null;
      _emptyPlaceholderCache = null;
    } else if (!identical(widget.points, oldWidget.points) ||
        widget.overviewApprovedAgentCount !=
            oldWidget.overviewApprovedAgentCount) {
      _emptyMessageCache = null;
      _emptyPlaceholderCache = null;
    }
  }

  String _barLabelCurrency(ResumoProdutoVendaLucratividadeRow _, num v) =>
      AppBrFormatters.smartCompactCurrencyForLocale(v, _formatsLocaleTag);

  String _barLabelPercentScale(ResumoProdutoVendaLucratividadeRow _, num v) =>
      _percentFormat.format(v / 100);

  String _barLabelMarkup(
    AppLocalizations l10n,
    ResumoProdutoVendaLucratividadeRow row,
    num v,
  ) {
    if (row.custoReposicao <= 0) {
      return l10n.overviewLucratividadeMarkupNotApplicable;
    }
    return '${_markupAxisFormat.format(v)}%';
  }

  Widget _emptyPlaceholder(AppThemeTokens tokens, String message) {
    if (_emptyMessageCache == message && _emptyPlaceholderCache != null) {
      return _emptyPlaceholderCache!;
    }
    _emptyMessageCache = message;
    if (widget.loadFailed) {
      return _emptyPlaceholderCache = overviewChartEmptyPlaceholder(
        emptyMessage: message,
        textStyle: Theme.of(context).textTheme.bodyMedium,
        verticalPadding: tokens.contentSpacing,
        onViewAgentFailureDetails: widget.onViewAgentFailureDetails,
        loadFailure: widget.loadFailure,
      );
    }
    return _emptyPlaceholderCache = Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.contentSpacing),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            SizedBox(height: tokens.gapMd),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  AppComboChartStyle _buildStyle(
    AppThemeTokens tokens, {
    required AppLocalizations l10n,
    required bool usePercentPrimaryAxis,
    required bool useMarkupAxisFormat,
    required Color barColor,
    double? heightOverride,
    bool fastChartAnimation = false,
    String? Function(TooltipArgs args)? tooltipBodyResolver,
  }) {
    final leftAxis = usePercentPrimaryAxis
        ? (useMarkupAxisFormat ? _markupAxisFormat : _percentFormat)
        : null;

    return AppComboChartStyle(
      height:
          heightOverride ??
          (tokens.chartStandardHeight + tokens.contentSpacing * 2),
      animationDuration: Duration(milliseconds: fastChartAnimation ? 150 : 350),
      tooltipBodyResolver: tooltipBodyResolver,
      leftAxisFormat: leftAxis ?? _compactCurrencyFormat,
      rightAxisFormat: _compactCurrencyFormat,
      chartPadding: EdgeInsets.only(bottom: tokens.gapSm),
      showRightYAxis: false,
      showLineSeries: false,
      showDataLabels: true,
      barDataLabelOffset: Offset(0, tokens.gapSm),
      horizontalScrollSemanticsHint:
          l10n.overviewComparisonBarHorizontalScrollHint,
      stickyPrimaryYAxisWhileScrolling: false,
      loadingLabel: l10n.overviewComparisonChartLoading,
      barColor: barColor,
    );
  }

  void _sortPoints(
    List<ResumoProdutoVendaLucratividadeRow> sortedPoints,
    _LucratividadeDisplay display,
    LucratividadePercentMetric percentMetric,
  ) {
    if (display == _LucratividadeDisplay.profitRevenue) {
      sortedPoints.sort((a, b) => b.lucro.compareTo(a.lucro));
    } else if (display == _LucratividadeDisplay.costRevenue) {
      sortedPoints.sort((a, b) => b.custoReposicao.compareTo(a.custoReposicao));
    } else if (display == _LucratividadeDisplay.percentMetrics) {
      sortedPoints.sort(
        (a, b) => compareLucratividadeRowsByPercentMetric(a, b, percentMetric),
      );
    } else {
      sortedPoints.sort((a, b) => b.valorTotalItem.compareTo(a.valorTotalItem));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = widget.l10n;
    final isPercent = _display == _LucratividadeDisplay.percentMetrics;
    final isCost = _display == _LucratividadeDisplay.costRevenue;
    final isProfit = _display == _LucratividadeDisplay.profitRevenue;

    final barColor = isCost ? tokens.warning : tokens.chartSeriesPrimary;

    final emptyMessage = widget.loadFailed
        ? overviewChartLoadFailureMessage(
            l10n: l10n,
            loadFailed: true,
            loadFailure: widget.loadFailure,
            legacyMessage: widget.loadFailureMessage,
            genericFallback: l10n.overviewMonthlyParcelsLoadFailed,
          )
        : widget.overviewApprovedAgentCount > 0
        ? l10n.overviewLucratividadeEmpty
        : l10n.overviewLucratividadeMultiAgentHint;

    num Function(ResumoProdutoVendaLucratividadeRow) barFn;
    num Function(ResumoProdutoVendaLucratividadeRow) lineFn;
    String Function(ResumoProdutoVendaLucratividadeRow, num) labelFn;

    if (isPercent) {
      barFn = (r) => r.metricBarValue(_percentMetric);
      lineFn = (r) => r.valorTotalItem;
      labelFn = _percentMetric == LucratividadePercentMetric.markupOverCost
          ? (row, v) => _barLabelMarkup(l10n, row, v)
          : _barLabelPercentScale;
    } else if (isCost) {
      barFn = _barByCost;
      lineFn = _lineByCost;
      labelFn = _barLabelCurrency;
    } else if (isProfit) {
      barFn = _barByProfit;
      lineFn = _lineByProfit;
      labelFn = _barLabelCurrency;
    } else {
      barFn = _barByRevenue;
      lineFn = _lineByRevenue;
      labelFn = _barLabelCurrency;
    }

    final sortedPoints = List<ResumoProdutoVendaLucratividadeRow>.of(
      widget.points,
    );
    _sortPoints(sortedPoints, _display, _percentMetric);

    final useMarkupAxis =
        isPercent &&
        _percentMetric == LucratividadePercentMetric.markupOverCost;

    final tooltipResolver = _lucratividadeMarkupTooltipBodyResolver(
      sortedPoints,
      _percentMetric,
      l10n,
    );

    final style = _buildStyle(
      tokens,
      l10n: l10n,
      usePercentPrimaryAxis: isPercent,
      useMarkupAxisFormat: useMarkupAxis,
      barColor: barColor,
      fastChartAnimation: isPercent,
      tooltipBodyResolver: tooltipResolver,
    );

    final mainModeControl = Semantics(
      sortKey: const OrdinalSortKey(1),
      child: AppSegmentedControl<_LucratividadeDisplay>(
        options: <AppSegmentedControlOption<_LucratividadeDisplay>>[
          AppSegmentedControlOption<_LucratividadeDisplay>(
            value: _LucratividadeDisplay.profitRevenue,
            label: l10n.overviewLucratividadeSwitchProfit,
          ),
          AppSegmentedControlOption<_LucratividadeDisplay>(
            value: _LucratividadeDisplay.revenueCost,
            label: l10n.overviewLucratividadeSwitchRevenue,
          ),
          AppSegmentedControlOption<_LucratividadeDisplay>(
            value: _LucratividadeDisplay.costRevenue,
            label: l10n.overviewLucratividadeSwitchCost,
          ),
          AppSegmentedControlOption<_LucratividadeDisplay>(
            value: _LucratividadeDisplay.percentMetrics,
            label: l10n.overviewLucratividadeSwitchMargin,
          ),
        ],
        value: _display,
        onChanged: (v) => setState(() {
          _display = v;
        }),
      ),
    );

    final belowSubtitle = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        mainModeControl,
        if (isPercent) ...<Widget>[
          SizedBox(height: tokens.gapSm),
          Semantics(
            sortKey: const OrdinalSortKey(2),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 380;
                return DashboardLucratividadePercentMetricSection(
                  l10n: l10n,
                  tokens: tokens,
                  metric: _percentMetric,
                  useDropdownLayout: narrow,
                  hasChartData: widget.points.isNotEmpty,
                  onMetricChanged: (v) => setState(() => _percentMetric = v),
                );
              },
            ),
          ),
        ],
      ],
    );

    final shareTitle = l10n.overviewLucratividadeTitle;
    final barSeriesLabel = isPercent
        ? lucratividadePercentBarSeriesLabel(l10n, _percentMetric)
        : isCost
        ? l10n.overviewLucratividadeCostSeriesLabel
        : isProfit
        ? l10n.overviewLucratividadeProfitSeriesLabel
        : l10n.overviewLucratividadeRevenueSeriesLabel;
    final lineSeriesLabel = isPercent || isCost || isProfit
        ? l10n.overviewLucratividadeRevenueSeriesLabel
        : l10n.overviewLucratividadeCostSeriesLabel;
    final metadata = buildOverviewLucratividadeChartShareMetadata(
      l10n: l10n,
      sortedPoints: sortedPoints,
      exportBaseStyle: style,
      series: OverviewLucratividadeComboShareSeries(
        barValueBuilder: barFn,
        lineValueBuilder: lineFn,
        barDataLabelBuilder: labelFn,
        barSeriesLabel: barSeriesLabel,
        lineSeriesLabel: lineSeriesLabel,
      ),
    );
    final shareActions = ChartShareActions(
      context: context,
      captureKey: _shareKey,
      metadata: metadata,
      onRequestShare: widget.onRequestShare,
      onRequestFullscreen: widget.onRequestFullscreen,
    );

    void openFullscreen() {
      final sortedPointsSnapshot = List<ResumoProdutoVendaLucratividadeRow>.of(
        sortedPoints,
        growable: false,
      );
      final fullscreenShareKey = GlobalKey();
      shareActions.openFullscreen(
        metadata.toFullscreenRequest(
          semanticsLabel: shareTitle,
          shareCaptureKey: fullscreenShareKey,
          chartBuilder: (fullscreenContext) {
              final fullscreenTokens = Theme.of(
                fullscreenContext,
              ).extension<AppThemeTokens>()!;
              var fullscreenDisplay = _display;
              var fullscreenPercentMetric = _percentMetric;
              return RepaintBoundary(
                key: fullscreenShareKey,
                child: StatefulBuilder(
                builder: (context, setFullscreenState) {
                  final fsPercent =
                      fullscreenDisplay == _LucratividadeDisplay.percentMetrics;
                  final fsMarkupAxis =
                      fsPercent &&
                      fullscreenPercentMetric ==
                          LucratividadePercentMetric.markupOverCost;

                  num Function(ResumoProdutoVendaLucratividadeRow) fsBarFn;
                  num Function(ResumoProdutoVendaLucratividadeRow) fsLineFn;
                  String Function(ResumoProdutoVendaLucratividadeRow, num)
                  fsLabelFn;

                  if (fsPercent) {
                    fsBarFn = (r) => r.metricBarValue(fullscreenPercentMetric);
                    fsLineFn = (r) => r.valorTotalItem;
                    fsLabelFn =
                        fullscreenPercentMetric ==
                            LucratividadePercentMetric.markupOverCost
                        ? (row, v) => _barLabelMarkup(l10n, row, v)
                        : _barLabelPercentScale;
                  } else if (fullscreenDisplay ==
                      _LucratividadeDisplay.costRevenue) {
                    fsBarFn = _barByCost;
                    fsLineFn = _lineByCost;
                    fsLabelFn = _barLabelCurrency;
                  } else if (fullscreenDisplay ==
                      _LucratividadeDisplay.profitRevenue) {
                    fsBarFn = _barByProfit;
                    fsLineFn = _lineByProfit;
                    fsLabelFn = _barLabelCurrency;
                  } else {
                    fsBarFn = _barByRevenue;
                    fsLineFn = _lineByRevenue;
                    fsLabelFn = _barLabelCurrency;
                  }

                  final fsBarLabel = fsPercent
                      ? lucratividadePercentBarSeriesLabel(
                          l10n,
                          fullscreenPercentMetric,
                        )
                      : fullscreenDisplay == _LucratividadeDisplay.costRevenue
                      ? l10n.overviewLucratividadeCostSeriesLabel
                      : fullscreenDisplay == _LucratividadeDisplay.profitRevenue
                      ? l10n.overviewLucratividadeProfitSeriesLabel
                      : l10n.overviewLucratividadeRevenueSeriesLabel;

                  final fsTooltipResolver =
                      _lucratividadeMarkupTooltipBodyResolver(
                        sortedPointsSnapshot,
                        fullscreenPercentMetric,
                        l10n,
                      );

                  final fsBelowMode = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Semantics(
                        sortKey: const OrdinalSortKey(1),
                        child: AppSegmentedControl<_LucratividadeDisplay>(
                          options:
                              <
                                AppSegmentedControlOption<_LucratividadeDisplay>
                              >[
                                AppSegmentedControlOption<
                                  _LucratividadeDisplay
                                >(
                                  value: _LucratividadeDisplay.profitRevenue,
                                  label: l10n.overviewLucratividadeSwitchProfit,
                                ),
                                AppSegmentedControlOption<
                                  _LucratividadeDisplay
                                >(
                                  value: _LucratividadeDisplay.revenueCost,
                                  label:
                                      l10n.overviewLucratividadeSwitchRevenue,
                                ),
                                AppSegmentedControlOption<
                                  _LucratividadeDisplay
                                >(
                                  value: _LucratividadeDisplay.costRevenue,
                                  label: l10n.overviewLucratividadeSwitchCost,
                                ),
                                AppSegmentedControlOption<
                                  _LucratividadeDisplay
                                >(
                                  value: _LucratividadeDisplay.percentMetrics,
                                  label: l10n.overviewLucratividadeSwitchMargin,
                                ),
                              ],
                          value: fullscreenDisplay,
                          onChanged: (v) => setFullscreenState(() {
                            fullscreenDisplay = v;
                          }),
                        ),
                      ),
                      if (fsPercent) ...<Widget>[
                        SizedBox(height: fullscreenTokens.gapSm),
                        Semantics(
                          sortKey: const OrdinalSortKey(2),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final narrow = constraints.maxWidth < 380;
                              return DashboardLucratividadePercentMetricSection(
                                l10n: l10n,
                                tokens: fullscreenTokens,
                                metric: fullscreenPercentMetric,
                                useDropdownLayout: narrow,
                                hasChartData: sortedPointsSnapshot.isNotEmpty,
                                onMetricChanged: (v) => setFullscreenState(() {
                                  fullscreenPercentMetric = v;
                                }),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  );

                  return buildSegmentedControlFullscreenBody(
                    tokens: fullscreenTokens,
                    control: fsBelowMode,
                    chartBuilder: (availableChartHeight) =>
                        AppComboChart<ResumoProdutoVendaLucratividadeRow>(
                              key: ValueKey<Object>(
                                Object.hash(
                                  sortedPointsSnapshot.length,
                                  fullscreenDisplay,
                                  fullscreenPercentMetric,
                                ),
                              ),
                              items: sortedPointsSnapshot,
                              xLabelBuilder: overviewLucratividadeAgentXLabel,
                              barValueBuilder: fsBarFn,
                              barSeriesLabel: fsBarLabel,
                              lineValueBuilder: fsLineFn,
                              lineSeriesLabel:
                                  fsPercent ||
                                      fullscreenDisplay ==
                                          _LucratividadeDisplay.costRevenue ||
                                      fullscreenDisplay ==
                                          _LucratividadeDisplay.profitRevenue
                                  ? l10n.overviewLucratividadeRevenueSeriesLabel
                                  : l10n.overviewLucratividadeCostSeriesLabel,
                              barDataLabelBuilder: fsLabelFn,
                              style: _buildStyle(
                                fullscreenTokens,
                                l10n: l10n,
                                usePercentPrimaryAxis: fsPercent,
                                useMarkupAxisFormat: fsMarkupAxis,
                                barColor:
                                    fullscreenDisplay ==
                                        _LucratividadeDisplay.costRevenue
                                    ? fullscreenTokens.warning
                                    : fullscreenTokens.chartSeriesPrimary,
                                heightOverride: availableChartHeight,
                                fastChartAnimation: fsPercent,
                                tooltipBodyResolver: fsTooltipResolver,
                              ),
                              emptyPlaceholder: sortedPointsSnapshot.isEmpty
                                  ? Center(
                                      child: Text(
                                        emptyMessage,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    )
                                  : null,
                        ),
                  );
                },
              ),
              );
          },
        ),
      );
    }

    return RepaintBoundary(
      key: _shareKey,
      child: AppComboChart<ResumoProdutoVendaLucratividadeRow>(
        key: ValueKey<Object>(
          Object.hash(
            identityHashCode(widget.points),
            _display,
            _percentMetric,
          ),
        ),
        title: shareTitle,
        onShare: shareActions.shareCallback(),
        shareProgressKey: _shareKey,
        onOpenFullscreen: shareActions.fullscreenCallback(openFullscreen),
        subtitle: l10n.overviewLucratividadeSubtitle,
        belowSubtitle: belowSubtitle,
        items: sortedPoints,
        xLabelBuilder: overviewLucratividadeAgentXLabel,
        barValueBuilder: barFn,
        barSeriesLabel: barSeriesLabel,
        lineValueBuilder: lineFn,
        lineSeriesLabel: isPercent || isCost || isProfit
            ? l10n.overviewLucratividadeRevenueSeriesLabel
            : l10n.overviewLucratividadeCostSeriesLabel,
        barDataLabelBuilder: labelFn,
        style: style,
        emptyPlaceholder: widget.points.isEmpty
            ? DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.bodyMedium,
                child: _emptyPlaceholder(tokens, emptyMessage),
              )
            : null,
      ),
    );
  }
}
