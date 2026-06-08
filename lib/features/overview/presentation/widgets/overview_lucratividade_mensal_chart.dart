import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/dashboard_lucratividade_percent_metrics.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_chart_load_failure_helpers.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/metric_toggle_comparison_bar_fullscreen_body.dart'
    show buildSegmentedControlFullscreenBody, isLandscapeChartViewport;
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_export_capture.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

String _xLabel(ResumoProdutoVendaLucratividadeMensalRow r) => r.anoMes;

num _barByProfit(ResumoProdutoVendaLucratividadeMensalRow r) => r.lucro;
num _lineByProfit(ResumoProdutoVendaLucratividadeMensalRow r) =>
    r.valorTotalItem;

num _barByRevenue(ResumoProdutoVendaLucratividadeMensalRow r) =>
    r.valorTotalItem;
num _lineByRevenue(ResumoProdutoVendaLucratividadeMensalRow r) =>
    r.custoReposicao;

num _barByCost(ResumoProdutoVendaLucratividadeMensalRow r) => r.custoReposicao;
num _lineByCost(ResumoProdutoVendaLucratividadeMensalRow r) => r.valorTotalItem;

String? Function(TooltipArgs args)?
_lucratividadeMarkupTooltipBodyResolverMensal(
  List<ResumoProdutoVendaLucratividadeMensalRow> points,
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
  profitRevenue,
  revenueCost,
  costRevenue,
  percentMetrics,
}

/// Monthly product profitability chart (lucratividade mensal) using the same
/// `AppComboChart` pattern as `OverviewMonthlyParcelsComboChart`.
class OverviewLucratividadeMensalChart extends StatefulWidget {
  const OverviewLucratividadeMensalChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    required this.isSingleAgentSelected,
    this.loadFailure,
    this.loadFailureMessage,
    this.onViewAgentFailureDetails,
    this.onRequestFullscreen,
    this.onRequestShare,
    super.key,
  });

  final AppLocalizations l10n;
  final List<ResumoProdutoVendaLucratividadeMensalRow> points;
  final bool loadFailed;
  final AppFailure? loadFailure;
  final bool isSingleAgentSelected;
  final String? loadFailureMessage;
  final VoidCallback? onViewAgentFailureDetails;
  final AppChartFullscreenRequestCallback? onRequestFullscreen;
  final AppChartShareRequestCallback? onRequestShare;

  @override
  State<OverviewLucratividadeMensalChart> createState() =>
      _OverviewLucratividadeMensalChartState();
}

class _OverviewLucratividadeMensalChartState
    extends State<OverviewLucratividadeMensalChart> {
  final GlobalKey _shareKey = GlobalKey();

  _LucratividadeDisplay _display = _LucratividadeDisplay.profitRevenue;
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
  void didUpdateWidget(covariant OverviewLucratividadeMensalChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.l10n.localeName != oldWidget.l10n.localeName) {
      _formatsLocaleTag = widget.l10n.localeName;
      _initFormats(widget.l10n.localeName);
      _emptyMessageCache = null;
      _emptyPlaceholderCache = null;
    } else if (!identical(widget.points, oldWidget.points)) {
      _emptyMessageCache = null;
      _emptyPlaceholderCache = null;
    }
  }

  String _barLabelCurrency(ResumoProdutoVendaLucratividadeMensalRow _, num v) =>
      _compactCurrencyFormat.format(v);

  String _barLabelPercentScale(
    ResumoProdutoVendaLucratividadeMensalRow _,
    num v,
  ) => _percentFormat.format(v / 100);

  String _barLabelMarkup(
    AppLocalizations l10n,
    ResumoProdutoVendaLucratividadeMensalRow row,
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
        : widget.isSingleAgentSelected
        ? l10n.overviewLucratividadeMensalEmpty
        : l10n.overviewLucratividadeMensalMultiAgentHint;

    num Function(ResumoProdutoVendaLucratividadeMensalRow) barFn;
    num Function(ResumoProdutoVendaLucratividadeMensalRow) lineFn;
    String Function(ResumoProdutoVendaLucratividadeMensalRow, num) labelFn;

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

    final sortedPoints = List<ResumoProdutoVendaLucratividadeMensalRow>.of(
      widget.points,
    );

    final useMarkupAxis =
        isPercent &&
        _percentMetric == LucratividadePercentMetric.markupOverCost;

    final tooltipResolver = _lucratividadeMarkupTooltipBodyResolverMensal(
      sortedPoints,
      _percentMetric,
      l10n,
    );

    AppComboChartStyle buildStyle(
      AppThemeTokens themeTokens, {
      required bool fsPercent,
      required bool fsMarkupAxis,
      double? heightOverride,
      String? Function(TooltipArgs args)? tooltipBodyResolver,
    }) {
      return AppComboChartStyle(
        height:
            heightOverride ??
            (themeTokens.chartStandardHeight + themeTokens.contentSpacing * 2),
        animationDuration: Duration(
          milliseconds: fsPercent ? 150 : 350,
        ),
        tooltipBodyResolver: tooltipBodyResolver,
        leftAxisFormat: fsPercent
            ? (fsMarkupAxis ? _markupAxisFormat : _percentFormat)
            : _compactCurrencyFormat,
        rightAxisFormat: _compactCurrencyFormat,
        chartPadding: EdgeInsets.zero,
        showRightYAxis: false,
        showLineSeries: false,
        showDataLabels: true,
        barDataLabelOffset: Offset(0, themeTokens.gapSm),
        minCategorySlotWidth:
            themeTokens.chartOverviewMonthlyCategoryMinSlotWidth,
        categoryLabelIntersectAction: AxisLabelIntersectAction.none,
        horizontalScrollSemanticsHint:
            l10n.overviewComparisonBarHorizontalScrollHint,
        stickyPrimaryYAxisWhileScrolling: false,
        loadingLabel: l10n.overviewComparisonChartLoading,
        barColor: barColor,
      );
    }

    final shareTitle = l10n.overviewLucratividadeMensalTitle;
    final inlineStyle = buildStyle(
      tokens,
      fsPercent: isPercent,
      fsMarkupAxis: useMarkupAxis,
      tooltipBodyResolver: tooltipResolver,
    );
    final shareMetadata = ChartShareMetadata(
      title: shareTitle,
      subtitle: l10n.overviewLucratividadeMensalSubtitle,
      tableData: ChartShareTableData(
        headers: <String>[
          l10n.chartSharePdfColumnMonth,
          l10n.chartSharePdfColumnRevenue,
          l10n.chartSharePdfColumnCost,
          l10n.chartSharePdfColumnProfit,
        ],
        rows: <List<String>>[
          for (final row in sortedPoints)
            <String>[
              row.anoMes,
              AppBrFormatters.currency(row.valorTotalItem),
              AppBrFormatters.currency(row.custoReposicao),
              AppBrFormatters.currency(row.lucro),
            ],
        ],
      ),
      chartExportBuilder: sortedPoints.isEmpty
          ? null
          : (exportContext) {
              final exportStyle = inlineStyle.forPdfExport();
              final exportBarLabel = isPercent
                  ? lucratividadePercentBarSeriesLabel(l10n, _percentMetric)
                  : isCost
                  ? l10n.overviewLucratividadeMensalCostSeriesLabel
                  : isProfit
                  ? l10n.overviewLucratividadeMensalProfitSeriesLabel
                  : l10n.overviewLucratividadeMensalRevenueSeriesLabel;
              return wrapCartesianChartForPdfExport(
                context: exportContext,
                itemCount: sortedPoints.length,
                minSlotWidth: exportStyle.minCategorySlotWidth,
                height: exportStyle.height,
                chart: AppComboChart<ResumoProdutoVendaLucratividadeMensalRow>(
                  items: sortedPoints,
                  xLabelBuilder: _xLabel,
                  barValueBuilder: barFn,
                  barSeriesLabel: exportBarLabel,
                  lineValueBuilder: lineFn,
                  lineSeriesLabel: isPercent || isCost || isProfit
                      ? l10n.overviewLucratividadeMensalRevenueSeriesLabel
                      : l10n.overviewLucratividadeMensalCostSeriesLabel,
                  barDataLabelBuilder: labelFn,
                  style: exportStyle,
                ),
              );
            },
    );

    void openFullscreen() {
      final emit = widget.onRequestFullscreen;
      if (emit == null) {
        return;
      }
      final snapshot = List<ResumoProdutoVendaLucratividadeMensalRow>.of(
        sortedPoints,
        growable: false,
      );
      final fullscreenShareKey = GlobalKey();
      emit(
        context,
        shareMetadata.toFullscreenRequest(
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

                  num Function(ResumoProdutoVendaLucratividadeMensalRow)
                  fsBarFn;
                  num Function(ResumoProdutoVendaLucratividadeMensalRow)
                  fsLineFn;
                  String Function(ResumoProdutoVendaLucratividadeMensalRow, num)
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
                      ? l10n.overviewLucratividadeMensalCostSeriesLabel
                      : fullscreenDisplay == _LucratividadeDisplay.profitRevenue
                      ? l10n.overviewLucratividadeMensalProfitSeriesLabel
                      : l10n.overviewLucratividadeMensalRevenueSeriesLabel;

                  final fsTooltipResolver =
                      _lucratividadeMarkupTooltipBodyResolverMensal(
                        snapshot,
                        fullscreenPercentMetric,
                        l10n,
                      );

                  final fsBelow = Column(
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
                                  label: l10n
                                      .overviewLucratividadeMensalSwitchProfit,
                                ),
                                AppSegmentedControlOption<
                                  _LucratividadeDisplay
                                >(
                                  value: _LucratividadeDisplay.revenueCost,
                                  label: l10n
                                      .overviewLucratividadeMensalSwitchRevenue,
                                ),
                                AppSegmentedControlOption<
                                  _LucratividadeDisplay
                                >(
                                  value: _LucratividadeDisplay.costRevenue,
                                  label: l10n
                                      .overviewLucratividadeMensalSwitchCost,
                                ),
                                AppSegmentedControlOption<
                                  _LucratividadeDisplay
                                >(
                                  value: _LucratividadeDisplay.percentMetrics,
                                  label: l10n
                                      .overviewLucratividadeMensalSwitchMargin,
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
                                hasChartData: snapshot.isNotEmpty,
                                showChronologicalHint: true,
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
                    control: fsBelow,
                    chartBuilder: (availableChartHeight) =>
                        AppComboChart<ResumoProdutoVendaLucratividadeMensalRow>(
                          key: ValueKey<Object>(
                            Object.hash(
                              snapshot.length,
                              fullscreenDisplay,
                              fullscreenPercentMetric,
                            ),
                          ),
                          items: snapshot,
                          xLabelBuilder: _xLabel,
                          barValueBuilder: fsBarFn,
                          barSeriesLabel: fsBarLabel,
                          lineValueBuilder: fsLineFn,
                          lineSeriesLabel:
                              fsPercent ||
                                  fullscreenDisplay ==
                                      _LucratividadeDisplay.costRevenue ||
                                  fullscreenDisplay ==
                                      _LucratividadeDisplay.profitRevenue
                              ? l10n.overviewLucratividadeMensalRevenueSeriesLabel
                              : l10n.overviewLucratividadeMensalCostSeriesLabel,
                          barDataLabelBuilder: fsLabelFn,
                          style: () {
                            final built = buildStyle(
                              fullscreenTokens,
                              fsPercent: fsPercent,
                              fsMarkupAxis: fsMarkupAxis,
                              heightOverride: availableChartHeight,
                              tooltipBodyResolver: fsTooltipResolver,
                            );
                            if (isLandscapeChartViewport(context)) {
                              return built.forLandscapeFullscreen(
                                height: availableChartHeight,
                              );
                            }
                            return built;
                          }(),
                          emptyPlaceholder: snapshot.isEmpty
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

    void openShare() {
      final emit = widget.onRequestShare;
      if (emit == null) {
        return;
      }
      emit(context, shareMetadata.toShareRequest(_shareKey));
    }

    final barSeriesLabel = isPercent
        ? lucratividadePercentBarSeriesLabel(l10n, _percentMetric)
        : isCost
        ? l10n.overviewLucratividadeMensalCostSeriesLabel
        : isProfit
        ? l10n.overviewLucratividadeMensalProfitSeriesLabel
        : l10n.overviewLucratividadeMensalRevenueSeriesLabel;

    final belowSubtitle = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          sortKey: const OrdinalSortKey(1),
          child: AppSegmentedControl<_LucratividadeDisplay>(
            options: <AppSegmentedControlOption<_LucratividadeDisplay>>[
              AppSegmentedControlOption<_LucratividadeDisplay>(
                value: _LucratividadeDisplay.profitRevenue,
                label: l10n.overviewLucratividadeMensalSwitchProfit,
              ),
              AppSegmentedControlOption<_LucratividadeDisplay>(
                value: _LucratividadeDisplay.revenueCost,
                label: l10n.overviewLucratividadeMensalSwitchRevenue,
              ),
              AppSegmentedControlOption<_LucratividadeDisplay>(
                value: _LucratividadeDisplay.costRevenue,
                label: l10n.overviewLucratividadeMensalSwitchCost,
              ),
              AppSegmentedControlOption<_LucratividadeDisplay>(
                value: _LucratividadeDisplay.percentMetrics,
                label: l10n.overviewLucratividadeMensalSwitchMargin,
              ),
            ],
            value: _display,
            onChanged: (v) => setState(() => _display = v),
          ),
        ),
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
                  showChronologicalHint: true,
                  onMetricChanged: (v) => setState(() => _percentMetric = v),
                );
              },
            ),
          ),
        ],
      ],
    );

    return RepaintBoundary(
      key: _shareKey,
      child: AppComboChart<ResumoProdutoVendaLucratividadeMensalRow>(
        key: ValueKey<Object>(
          Object.hash(
            identityHashCode(widget.points),
            _display,
            _percentMetric,
          ),
        ),
        title: shareTitle,
        subtitle: l10n.overviewLucratividadeMensalSubtitle,
        onShare: widget.onRequestShare == null ? null : openShare,
        shareProgressKey: _shareKey,
        onOpenFullscreen:
            widget.onRequestFullscreen == null ? null : openFullscreen,
        belowSubtitle: belowSubtitle,
        items: sortedPoints,
        xLabelBuilder: _xLabel,
        barValueBuilder: barFn,
        barSeriesLabel: barSeriesLabel,
        lineValueBuilder: lineFn,
        lineSeriesLabel: isPercent || isCost || isProfit
            ? l10n.overviewLucratividadeMensalRevenueSeriesLabel
            : l10n.overviewLucratividadeMensalCostSeriesLabel,
        barDataLabelBuilder: labelFn,
        style: inlineStyle,
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
