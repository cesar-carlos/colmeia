import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_fullscreen_request.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_share_request.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_actions.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/metric_toggle_comparison_bar_fullscreen_body.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:flutter/material.dart';

enum MetricToggleComparisonBarMetric { count, amount }

Widget buildMetricToggleComparisonBarSegmentedControl({
  required MetricToggleComparisonBarMetric value,
  required ValueChanged<MetricToggleComparisonBarMetric> onChanged,
  required String countMetricLabel,
  required String amountMetricLabel,
}) {
  return AppSegmentedControl<MetricToggleComparisonBarMetric>(
    options: <AppSegmentedControlOption<MetricToggleComparisonBarMetric>>[
      AppSegmentedControlOption<MetricToggleComparisonBarMetric>(
        value: MetricToggleComparisonBarMetric.count,
        label: countMetricLabel,
      ),
      AppSegmentedControlOption<MetricToggleComparisonBarMetric>(
        value: MetricToggleComparisonBarMetric.amount,
        label: amountMetricLabel,
      ),
    ],
    value: value,
    onChanged: onChanged,
  );
}

typedef MetricToggleComparisonBarStyleBuilder =
    AppComparisonBarChartStyle Function(
      BuildContext context,
      MetricToggleComparisonBarMetric metric, {
      double? heightOverride,
    });

/// Comparison bar card with count/amount metric toggle, share, and fullscreen.
class MetricToggleComparisonBarCard<T> extends StatefulWidget {
  const MetricToggleComparisonBarCard({
    required this.items,
    required this.countMetricLabel,
    required this.amountMetricLabel,
    required this.filterItems,
    required this.titleForMetric,
    required this.subtitle,
    required this.semanticsLabelForMetric,
    required this.labelBuilder,
    required this.valueBuilder,
    required this.tooltipLabelBuilder,
    required this.dataLabelBuilder,
    required this.styleBuilder,
    required this.shareMetadataBuilder,
    required this.plotFloorAccessibilityNotice,
    required this.extremeSpreadAccessibilityNotice,
    super.key,
    this.semanticsHint,
    this.semanticsValue,
    this.semanticsValueBuilder,
    this.emptyPlaceholder,
    this.isLoading = false,
    this.onRequestFullscreen,
    this.onRequestShare,
    this.shareEnabled = true,
    this.fullscreenSemanticsLabelBuilder,
    this.landscapeStyleOverride,
  });

  final List<T> items;
  final String countMetricLabel;
  final String amountMetricLabel;
  final List<T> Function(
    List<T> items,
    MetricToggleComparisonBarMetric metric,
  )
  filterItems;
  final String Function(MetricToggleComparisonBarMetric metric) titleForMetric;
  final String subtitle;
  final String Function(MetricToggleComparisonBarMetric metric)
  semanticsLabelForMetric;
  final String? semanticsHint;
  final String? semanticsValue;
  final String Function(MetricToggleComparisonBarMetric metric)?
  semanticsValueBuilder;
  final String Function(T item) labelBuilder;
  final num Function(T item, MetricToggleComparisonBarMetric metric)
  valueBuilder;
  final String Function(
    T item,
    num value,
    MetricToggleComparisonBarMetric metric,
  )
  tooltipLabelBuilder;
  final String Function(
    T item,
    num value,
    MetricToggleComparisonBarMetric metric,
  )
  dataLabelBuilder;
  final MetricToggleComparisonBarStyleBuilder styleBuilder;
  final ChartShareMetadata Function(MetricToggleComparisonBarMetric metric)
  shareMetadataBuilder;
  final String plotFloorAccessibilityNotice;
  final String extremeSpreadAccessibilityNotice;
  final Widget? emptyPlaceholder;
  final bool isLoading;
  final AppChartFullscreenRequestCallback? onRequestFullscreen;
  final AppChartShareRequestCallback? onRequestShare;
  final bool shareEnabled;
  final String Function(MetricToggleComparisonBarMetric metric)?
  fullscreenSemanticsLabelBuilder;
  final AppComparisonBarChartStyle Function(
    AppComparisonBarChartStyle base,
    double height,
  )?
  landscapeStyleOverride;

  @override
  State<MetricToggleComparisonBarCard<T>> createState() =>
      _MetricToggleComparisonBarCardState<T>();
}

class _MetricToggleComparisonBarCardState<T>
    extends State<MetricToggleComparisonBarCard<T>> {
  final GlobalKey _shareKey = GlobalKey();
  MetricToggleComparisonBarMetric _metric =
      MetricToggleComparisonBarMetric.count;

  List<T> _chartItems() => widget.filterItems(widget.items, _metric);

  Widget _metricToggle({
    required MetricToggleComparisonBarMetric value,
    required ValueChanged<MetricToggleComparisonBarMetric> onChanged,
  }) {
    return buildMetricToggleComparisonBarSegmentedControl(
      value: value,
      onChanged: onChanged,
      countMetricLabel: widget.countMetricLabel,
      amountMetricLabel: widget.amountMetricLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chartItems = _chartItems();
    final showEmptyPlaceholder = widget.items.isEmpty || chartItems.isEmpty;
    final shareActions = ChartShareActions(
      context: context,
      captureKey: _shareKey,
      metadata: widget.shareMetadataBuilder(_metric),
      onRequestShare: widget.onRequestShare,
      onRequestFullscreen: widget.onRequestFullscreen,
      shareEnabled: widget.shareEnabled && !widget.isLoading,
    );

    void openFullscreen() {
      final chartItemsSnapshot = List<T>.of(chartItems, growable: false);
      final metricSnapshot = _metric;
      final isLoadingSnapshot = widget.isLoading;
      final fullscreenShareKey = GlobalKey();
      final metadata = widget.shareMetadataBuilder(metricSnapshot);
      final semanticsLabel =
          widget.fullscreenSemanticsLabelBuilder?.call(metricSnapshot) ??
          widget.semanticsLabelForMetric(metricSnapshot);
      shareActions.openFullscreen(
        metadata.toFullscreenRequest(
          semanticsLabel: semanticsLabel,
          shareCaptureKey: fullscreenShareKey,
          chartBuilder: (fullscreenContext) {
            final fullscreenTokens = Theme.of(
              fullscreenContext,
            ).extension<AppThemeTokens>()!;
            var fullscreenMetric = metricSnapshot;
            return RepaintBoundary(
              key: fullscreenShareKey,
              child: StatefulBuilder(
                builder: (context, setFullscreenState) {
                  return buildMetricToggleComparisonBarFullscreenBody(
                    tokens: fullscreenTokens,
                    metricToggle: _metricToggle(
                      value: fullscreenMetric,
                      onChanged: (value) => setFullscreenState(
                        () => fullscreenMetric = value,
                      ),
                    ),
                    chartBuilder: (availableChartHeight) {
                      var style = widget.styleBuilder(
                        context,
                        fullscreenMetric,
                        heightOverride: availableChartHeight,
                      );
                      final landscapeOverride = widget.landscapeStyleOverride;
                      if (landscapeOverride != null &&
                          isLandscapeChartViewport(context)) {
                        style = landscapeOverride(
                          style,
                          availableChartHeight,
                        );
                      }
                      return AppComparisonBarChart<T>(
                        items: chartItemsSnapshot,
                        isLoading: isLoadingSnapshot,
                        plotFloorAccessibilityNotice:
                            widget.plotFloorAccessibilityNotice,
                        extremeSpreadAccessibilityNotice:
                            widget.extremeSpreadAccessibilityNotice,
                        labelBuilder: widget.labelBuilder,
                        valueBuilder: (item) =>
                            widget.valueBuilder(item, fullscreenMetric),
                        tooltipLabelBuilder: (item, value) =>
                            widget.tooltipLabelBuilder(
                              item,
                              value,
                              fullscreenMetric,
                            ),
                        dataLabelBuilder: (item, value) =>
                            widget.dataLabelBuilder(
                              item,
                              value,
                              fullscreenMetric,
                            ),
                        style: style,
                        emptyPlaceholder: showEmptyPlaceholder
                            ? widget.emptyPlaceholder
                            : null,
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      );
    }

    final semanticsChild = RepaintBoundary(
      key: _shareKey,
      child: AppComparisonBarChart<T>(
        title: widget.titleForMetric(_metric),
        subtitle: widget.subtitle,
        onShare: shareActions.shareCallback(),
        shareProgressKey: _shareKey,
        shareEnabled: widget.shareEnabled && !widget.isLoading,
        onOpenFullscreen: shareActions.fullscreenCallback(openFullscreen),
        belowSubtitle: _metricToggle(
          value: _metric,
          onChanged: (value) => setState(() => _metric = value),
        ),
        items: chartItems,
        isLoading: widget.isLoading,
        plotFloorAccessibilityNotice: widget.plotFloorAccessibilityNotice,
        extremeSpreadAccessibilityNotice:
            widget.extremeSpreadAccessibilityNotice,
        labelBuilder: widget.labelBuilder,
        valueBuilder: (item) => widget.valueBuilder(item, _metric),
        tooltipLabelBuilder: (item, value) =>
            widget.tooltipLabelBuilder(item, value, _metric),
        dataLabelBuilder: (item, value) =>
            widget.dataLabelBuilder(item, value, _metric),
        style: widget.styleBuilder(context, _metric),
        emptyPlaceholder: showEmptyPlaceholder ? widget.emptyPlaceholder : null,
      ),
    );

    return Semantics(
      label: widget.semanticsLabelForMetric(_metric),
      hint: widget.semanticsHint,
      value:
          widget.semanticsValue ?? widget.semanticsValueBuilder?.call(_metric),
      child: semanticsChild,
    );
  }
}
