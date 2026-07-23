import 'dart:math' as math;

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_chart_failure_placeholder_content.dart';
import 'package:colmeia/features/sales/domain/entities/sales_monthly_pnl_point.dart';
import 'package:colmeia/features/sales/presentation/sales_monthly_pnl_chart_keys.dart';
import 'package:colmeia/features/sales/presentation/share/sales_monthly_pnl_share.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/chart_horizontal_scroll_shell.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_actions.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_states.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

const double kSalesMonthlyPnlMinChartWidth = 560;
const double kSalesMonthlyPnlMonthSlotWidth = 72;
const double kSalesMonthlyPnlChartHorizontalPadding = 24;

String salesMonthlyPnlChartMonthShortLabel(
  SalesMonthlyPnlPoint point,
  String localeTag,
) {
  return DateFormat('MMM/yy', localeTag).format(
    DateTime(point.year, point.month),
  );
}

String salesMonthlyPnlChartMonthLongLabel(
  SalesMonthlyPnlPoint point,
  String localeTag,
) {
  return DateFormat.yMMM(localeTag).format(DateTime(point.year, point.month));
}

String salesMonthlyPnlLineChartTooltipSeriesLabel(
  AppLocalizations l10n,
  int seriesIndex,
) {
  return switch (seriesIndex) {
    1 => l10n.salesMonthlyPnlSeriesProfitLabel,
    2 => l10n.salesMonthlyPnlSeriesCostLabel,
    _ => l10n.salesMonthlyPnlSeriesSalesLabel,
  };
}

double salesMonthlyPnlLineChartTooltipSeriesValue(
  SalesMonthlyPnlPoint point,
  int seriesIndex,
) {
  return switch (seriesIndex) {
    1 => point.lucro,
    2 => point.custoMercadoria,
    _ => point.venda,
  };
}

double resolveSalesMonthlyPnlChartWidth({
  required double availableWidth,
  required int pointCount,
}) {
  final contentWidth =
      (pointCount * kSalesMonthlyPnlMonthSlotWidth) +
      kSalesMonthlyPnlChartHorizontalPadding;
  return math.max(
    availableWidth,
    math.max(kSalesMonthlyPnlMinChartWidth, contentWidth),
  );
}

class SalesMonthlyPnlLineChart extends StatefulWidget {
  const SalesMonthlyPnlLineChart({
    required this.l10n,
    required this.points,
    required this.loadFailed,
    required this.isLoading,
    super.key,
    this.loadFailure,
    this.loadFailureMessage,
    this.onOpenFullscreen,
    this.onRequestShare,
    this.exportHeaderContext,
    this.useChartShell = true,
    this.chartHeightOverride,
  });

  final AppLocalizations l10n;
  final ChartShareExportHeaderContext? exportHeaderContext;
  final List<SalesMonthlyPnlPoint> points;
  final bool loadFailed;
  final bool isLoading;
  final AppFailure? loadFailure;
  final String? loadFailureMessage;
  final VoidCallback? onOpenFullscreen;
  final AppChartShareRequestCallback? onRequestShare;
  final bool useChartShell;
  final double? chartHeightOverride;

  @override
  State<SalesMonthlyPnlLineChart> createState() =>
      _SalesMonthlyPnlLineChartState();
}

class _SalesMonthlyPnlLineChartState extends State<SalesMonthlyPnlLineChart> {
  final GlobalKey _shareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final colors = theme.appColors;
    final localeTag = l10n.localeName;
    final chartTheme = AppChartTheme.fromContext(
      context,
      preset: AppChartPreset.standard,
    );
    final yAxisFormat = AppBrFormatters.compactCurrencyFormatForLocale(
      localeTag,
    );
    final loadFailed = widget.loadFailed;
    final loadFailure = widget.loadFailure;
    final loadFailureMessage = widget.loadFailureMessage;
    final isLoading = widget.isLoading;
    final points = widget.points;
    final onOpenFullscreen = widget.onOpenFullscreen;
    final useChartShell = widget.useChartShell;
    final chartHeightOverride = widget.chartHeightOverride;

    final emptyMessage = loadFailed
        ? (loadFailureMessage ?? l10n.salesMonthlyPnlLoadFailed)
        : l10n.salesMonthlyPnlEmpty;
    final semanticsLabel = l10n.salesMonthlyPnlChartSemantics;
    final resolvedHeight = chartHeightOverride ?? chartTheme.height;
    final gridLineColor = colors.outlineVariant.withValues(alpha: 0.35);
    final animationDuration = resolveChartAnimationDurationMs(
      context: context,
      styleDuration: const Duration(milliseconds: 350),
      defaultMs: AppChartEngineAnimationDefaults.cartesianSeriesMs,
    );
    final showZerosOnly =
        points.isNotEmpty &&
        !loadFailed &&
        points.every(
          (point) =>
              point.venda == 0 &&
              point.lucro == 0 &&
              point.custoMercadoria == 0,
        );

    final chartBody = isLoading
        ? buildChartLoadingState(
            context: context,
            height: resolvedHeight,
            indicatorColor: chartTheme.primaryColor,
            label: l10n.overviewComparisonChartLoading,
            variant: ChartLoadingPlaceholderVariant.timeSeries,
          )
        : points.isEmpty
        ? buildChartEmptyState(
            context: context,
            height: resolvedHeight,
            message: emptyMessage,
            placeholder: AgentQueryChartFailurePlaceholderContent(
              emptyMessage: emptyMessage,
              textStyle: theme.textTheme.bodyMedium,
              verticalPadding: tokens.contentSpacing,
              loadFailure: loadFailed ? loadFailure : null,
            ),
          )
        : showZerosOnly
        ? buildChartEmptyState(
            context: context,
            height: resolvedHeight,
            message: l10n.salesMonthlyPnlBarZerosOnlyMessage,
            placeholder: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.contentSpacing),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.outline,
                    ),
                    SizedBox(width: tokens.gapSm),
                    Expanded(
                      child: Text(
                        l10n.salesMonthlyPnlBarZerosOnlyMessage,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              final minChartWidth = resolveSalesMonthlyPnlChartWidth(
                availableWidth: constraints.maxWidth,
                pointCount: points.length,
              );
              return SizedBox(
                height: resolvedHeight,
                child: ChartHorizontalScrollShell(
                  SizedBox(
                    width: minChartWidth,
                    height: resolvedHeight,
                    child: SfCartesianChart(
                      margin: EdgeInsets.zero,
                      plotAreaBorderWidth: 0,
                      onTooltipRender: buildSanitizingTooltipRenderer(),
                      tooltipBehavior: buildChartTooltipBehavior(
                        context,
                        enable: true,
                        builder: (data, point, series, pointIndex, seriesIndex) {
                          if (pointIndex < 0 || pointIndex >= points.length) {
                            return const SizedBox.shrink();
                          }
                          final item = points[pointIndex];
                          final label =
                              salesMonthlyPnlLineChartTooltipSeriesLabel(
                                l10n,
                                seriesIndex,
                              );
                          final value =
                              salesMonthlyPnlLineChartTooltipSeriesValue(
                                item,
                                seriesIndex,
                              );
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  salesMonthlyPnlChartMonthLongLabel(
                                    item,
                                    localeTag,
                                  ),
                                  style: TextStyle(
                                    color: theme.colorScheme.onInverseSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$label: ${AppBrFormatters.smartCompactCurrencyForLocale(value, localeTag)}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onInverseSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      legend: const Legend(
                        isVisible: true,
                        position: LegendPosition.bottom,
                        overflowMode: LegendItemOverflowMode.wrap,
                      ),
                      primaryXAxis: const CategoryAxis(
                        majorGridLines: MajorGridLines(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                        numberFormat: yAxisFormat,
                        axisLine: const AxisLine(width: 0),
                        majorGridLines: MajorGridLines(
                          color: gridLineColor,
                          width: 1,
                        ),
                      ),
                      zoomPanBehavior: ZoomPanBehavior(
                        enablePinching: chartTheme.enableSelectionZooming,
                        enablePanning: chartTheme.enableSelectionZooming,
                        enableSelectionZooming:
                            chartTheme.enableSelectionZooming,
                      ),
                      series: <CartesianSeries<SalesMonthlyPnlPoint, String>>[
                        LineSeries<SalesMonthlyPnlPoint, String>(
                          dataSource: points,
                          xValueMapper: (point, _) =>
                              salesMonthlyPnlChartMonthShortLabel(
                                point,
                                localeTag,
                              ),
                          yValueMapper: (point, _) => point.venda,
                          name: l10n.salesMonthlyPnlSeriesSalesLabel,
                          color: chartTheme.primaryColor,
                          width: 3,
                          animationDuration: animationDuration,
                          markerSettings: MarkerSettings(
                            isVisible: true,
                            height: 6,
                            width: 6,
                            color: chartTheme.primaryColor,
                            borderColor: theme.colorScheme.surface,
                          ),
                        ),
                        LineSeries<SalesMonthlyPnlPoint, String>(
                          dataSource: points,
                          xValueMapper: (point, _) =>
                              salesMonthlyPnlChartMonthShortLabel(
                                point,
                                localeTag,
                              ),
                          yValueMapper: (point, _) => point.lucro,
                          name: l10n.salesMonthlyPnlSeriesProfitLabel,
                          color: chartTheme.paletteColor(1),
                          width: 3,
                          animationDuration: animationDuration,
                          markerSettings: MarkerSettings(
                            isVisible: true,
                            height: 6,
                            width: 6,
                            color: chartTheme.paletteColor(1),
                            borderColor: theme.colorScheme.surface,
                          ),
                        ),
                        LineSeries<SalesMonthlyPnlPoint, String>(
                          dataSource: points,
                          xValueMapper: (point, _) =>
                              salesMonthlyPnlChartMonthShortLabel(
                                point,
                                localeTag,
                              ),
                          yValueMapper: (point, _) => point.custoMercadoria,
                          name: l10n.salesMonthlyPnlSeriesCostLabel,
                          color: chartTheme.paletteColor(2),
                          width: 3,
                          animationDuration: animationDuration,
                          markerSettings: MarkerSettings(
                            isVisible: true,
                            height: 6,
                            width: 6,
                            color: chartTheme.paletteColor(2),
                            borderColor: theme.colorScheme.surface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  semanticsHint: l10n.overviewComparisonBarHorizontalScrollHint,
                  key: SalesMonthlyPnlChartKeys.lineHorizontalScrollShell,
                ),
              );
            },
          );

    final shareTitle = l10n.salesMonthlyPnlChartTitle;
    final shareActions = ChartShareActions(
      context: context,
      captureKey: _shareKey,
      metadata: buildSalesMonthlyPnlLineChartShareMetadata(
        l10n: l10n,
        points: points,
        exportHeaderContext: widget.exportHeaderContext,
      ),
      onRequestShare: widget.onRequestShare,
      shareEnabled: !isLoading,
    );
    final chartSurface = useChartShell
        ? AppChartShell(
            title: shareTitle,
            subtitle: l10n.salesMonthlyPnlChartSubtitle,
            onShare: shareActions.shareCallback(),
            shareProgressKey: _shareKey,
            onOpenFullscreen: onOpenFullscreen,
            child: chartBody,
          )
        : chartBody;

    return Semantics(
      label: semanticsLabel,
      child: RepaintBoundary(
        key: _shareKey,
        child: chartSurface,
      ),
    );
  }
}
