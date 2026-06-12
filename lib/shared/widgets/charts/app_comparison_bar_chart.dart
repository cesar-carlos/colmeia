import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_shell.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart_style.dart';
import 'package:colmeia/shared/widgets/charts/comparison_bar_chart_point_mapper.dart';
import 'package:colmeia/shared/widgets/charts/comparison_bar_plot_floor.dart';
import 'package:colmeia/shared/widgets/charts/engines/syncfusion_comparison_bar_chart.dart';
import 'package:flutter/material.dart';

export 'app_comparison_bar_chart_style.dart';
export 'comparison_bar_x_axis_label.dart'
    show
        formatComparisonBarXAxisLabelCollapsed,
        formatComparisonBarXAxisLabelTwoLines,
        formatComparisonBarXAxisLabelWrapped;

class AppComparisonBarPointTapEvent<T> {
  const AppComparisonBarPointTapEvent({
    required this.item,
    required this.index,
    required this.label,
    required this.value,
  });

  final T item;
  final int index;
  final String label;
  final num value;
}

/// Generic vertical bar chart for discrete comparisons between labelled items.
///
/// [valueBuilder] supplies the true metric; optional minimum-height lifts for
/// readability are stored on [AppChartPoint.plottedValue] only for drawing.
///
/// Usage:
/// ```dart
/// AppComparisonBarChart<ReportResultRow>(
///   title: 'Faturamento por vendedor',
///   subtitle: 'Recorte atual.',
///   items: detail.rows,
///   labelBuilder: (row) => row.seller,
///   valueBuilder: (row) => row.revenue,
///   style: AppComparisonBarChartStyle(
///     yAxisFormat: AppBrFormatters.compactCurrencyFormat,
///   ),
/// )
/// ```
///
/// Pass [colorBuilder] to assign a different color to each bar. Pass
/// [title] to wrap the chart inside a shell card automatically.
class AppComparisonBarChart<T> extends StatelessWidget {
  const AppComparisonBarChart({
    required this.items,
    required this.labelBuilder,
    required this.valueBuilder,
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.titleTrailing,
    this.onShare,
    this.shareProgressKey,
    this.shareEnabled = true,
    this.openShareTooltip,
    this.openShareSemanticLabel,
    this.onOpenFullscreen,
    this.openFullscreenTooltip,
    this.openFullscreenSemanticLabel,
    this.belowSubtitle,
    this.colorBuilder,
    this.dataLabelBuilder,
    this.tooltipLabelBuilder,
    this.onPointTap,
    this.onPointTapEvent,
    this.style = const AppComparisonBarChartStyle(),
    this.preset = AppChartPreset.standard,
    this.isLoading = false,
    this.emptyPlaceholder,
    this.plotFloorAccessibilityNotice,
    this.extremeSpreadAccessibilityNotice,
  });

  /// Height the engine will reserve for the chart body when `style.height` is
  /// not set. Useful for callers that render their own staged-mounting
  /// placeholder and need to keep the same vertical footprint between the
  /// placeholder and the eventual real card (avoids layout shift).
  ///
  /// When [styleHeight] is non-null it is returned verbatim — mirrors the
  /// engine resolution (`style.height ?? chartTheme.height`).
  static double loadingBlockHeight(
    AppThemeTokens tokens, {
    AppChartPreset preset = AppChartPreset.standard,
    double? styleHeight,
  }) {
    if (styleHeight != null) {
      return styleHeight;
    }
    return switch (preset) {
      AppChartPreset.compact => tokens.chartCompactHeight,
      AppChartPreset.standard => tokens.chartStandardHeight,
      AppChartPreset.explorable => tokens.chartStandardHeight,
    };
  }

  /// Data items to plot.
  final List<T> items;

  /// Returns the X-axis label for an item.
  final String Function(T item) labelBuilder;

  /// Returns the numeric Y value for an item.
  final num Function(T item) valueBuilder;

  /// Optional chart title string. When provided (and [titleWidget] is null)
  /// the chart is wrapped in [AppChartShell] with a plain text header.
  final String? title;

  /// Optional rich-content widget used as the chart title header.
  ///
  /// When set, it replaces the plain [Text] rendered from [title] inside
  /// [AppChartShell]. [subtitle], [titleTrailing] and [belowSubtitle] still
  /// apply alongside it. Setting [titleWidget] without [title] is supported —
  /// pass an empty string for [title] or omit it entirely.
  final Widget? titleWidget;

  /// Optional subtitle shown below [title] / [titleWidget] inside [AppChartShell].
  final String? subtitle;

  /// Widget aligned to the trailing edge of the header row.
  final Widget? titleTrailing;

  /// Optional callback that enables sharing the chart from the chart header.
  final VoidCallback? onShare;

  /// When set with [onShare], reflects in-progress state on the share button.
  final Object? shareProgressKey;

  /// When false, the share action is disabled (e.g. while chart data loads).
  final bool shareEnabled;

  /// Optional tooltip for the share action button.
  final String? openShareTooltip;

  /// Optional semantics label for the share action button.
  final String? openShareSemanticLabel;

  /// Optional callback that enables fullscreen expansion from the chart header.
  final VoidCallback? onOpenFullscreen;

  /// Optional tooltip for the fullscreen action button.
  final String? openFullscreenTooltip;

  /// Optional semantics label for the fullscreen action button.
  final String? openFullscreenSemanticLabel;

  /// Widget rendered between the subtitle and the chart (e.g. period picker).
  final Widget? belowSubtitle;

  /// Returns an optional per-item bar color. When null the style bar color
  /// (or the theme default) is used uniformly.
  final Color? Function(T item)? colorBuilder;

  /// Returns an optional label rendered above each bar.
  final String? Function(T item, num value)? dataLabelBuilder;

  /// Returns an optional tooltip string for each bar.
  final String? Function(T item, num value)? tooltipLabelBuilder;

  /// Called when the user taps a bar.
  final void Function(T item, int index)? onPointTap;

  /// Called when the user taps a bar with a structured event payload.
  final ValueChanged<AppComparisonBarPointTapEvent<T>>? onPointTapEvent;

  /// Visual overrides applied on top of the [preset]-driven defaults.
  final AppComparisonBarChartStyle style;

  /// Base visual preset (compact / standard / explorable).
  final AppChartPreset preset;

  /// Shows an indeterminate loading indicator at chart height.
  final bool isLoading;

  /// Widget rendered when [items] is empty (and not loading).
  final Widget? emptyPlaceholder;

  /// Shown as a header info tooltip and in chart [Semantics] when any bar uses
  /// a minimum plotted height ([AppChartPoint.plottedValue]).
  final String? plotFloorAccessibilityNotice;

  /// Appended to chart [Semantics] when values span an extreme ratio (e.g.
  /// orders of magnitude); use for screen-reader context about possible unit mix-ups.
  final String? extremeSpreadAccessibilityNotice;

  @override
  Widget build(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final n = items.length;
    final values = List<num>.generate(n, (i) => valueBuilder(items[i]));
    debugLogSuspiciousComparisonBarSpread(values);

    final mapped = mapComparisonBarChartPoints<T>(
      items: items,
      values: values,
      labelBuilder: labelBuilder,
      style: style,
      colorBuilder: colorBuilder,
      dataLabelBuilder: dataLabelBuilder,
      tooltipLabelBuilder: tooltipLabelBuilder,
    );
    final points = mapped.points;
    final hasPlotFloor = mapped.hasPlotFloor;
    final hasExtremeSpread = mapped.hasExtremeSpread;

    final semanticsParts = <String>[];
    final floorNotice = plotFloorAccessibilityNotice?.trim();
    if (hasPlotFloor && floorNotice != null && floorNotice.isNotEmpty) {
      semanticsParts.add(floorNotice);
    }
    final spreadNotice = extremeSpreadAccessibilityNotice?.trim();
    if (hasExtremeSpread && spreadNotice != null && spreadNotice.isNotEmpty) {
      semanticsParts.add(spreadNotice);
    }
    final coordinatorExtra = style.chartSemanticsCoordinatorNotice?.trim();
    if (coordinatorExtra != null && coordinatorExtra.isNotEmpty) {
      semanticsParts.add(coordinatorExtra);
    }
    final semanticsCoordinatorLabel = semanticsParts.isEmpty
        ? null
        : semanticsParts.join(' ');

    Widget? floorNoticeTrailing;
    if (hasPlotFloor && floorNotice != null && floorNotice.isNotEmpty) {
      floorNoticeTrailing = Tooltip(
        message: floorNotice,
        child: Icon(
          Icons.info_outline,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    final mergedTitleTrailing = _mergeComparisonTitleTrailing(
      titleTrailing,
      floorNoticeTrailing,
      gap: tokens.gapSm,
    );

    final resolvedLoadingLabel =
        style.loadingLabel ?? l10n?.chartComparisonLoadingDefault;
    final resolvedEmptyMessage =
        style.emptyMessage ?? l10n?.chartComparisonEmptyDefault;

    void handlePointTap(int index) {
      if (index < 0 || index >= items.length || index >= points.length) {
        return;
      }

      final item = items[index];
      final event = AppComparisonBarPointTapEvent<T>(
        item: item,
        index: index,
        label: points[index].label,
        value: points[index].value,
      );
      onPointTap?.call(item, index);
      onPointTapEvent?.call(event);
    }

    Widget innerChart = SyncfusionComparisonBarChart(
      points: points,
      preset: preset,
      style: style,
      pointColors: mapped.pointColors,
      dataLabels: mapped.dataLabels,
      tooltipLabels: mapped.tooltipLabels,
      onPointTap: (onPointTap == null && onPointTapEvent == null)
          ? null
          : handlePointTap,
      isLoading: isLoading,
      emptyPlaceholder: emptyPlaceholder,
      resolvedLoadingLabel: resolvedLoadingLabel,
      resolvedEmptyMessage: resolvedEmptyMessage,
    );

    if (semanticsCoordinatorLabel != null &&
        semanticsCoordinatorLabel.isNotEmpty) {
      innerChart = Semantics(
        label: semanticsCoordinatorLabel,
        excludeSemantics: true,
        child: innerChart,
      );
    }

    if (title == null && titleWidget == null) {
      return innerChart;
    }

    return AppChartShell(
      title: title ?? '',
      titleWidget: titleWidget,
      subtitle: subtitle,
      titleTrailing: mergedTitleTrailing,
      onShare: onShare,
      shareProgressKey: shareProgressKey,
      shareEnabled: shareEnabled && !isLoading,
      openShareTooltip: openShareTooltip,
      openShareSemanticLabel: openShareSemanticLabel,
      onOpenFullscreen: onOpenFullscreen,
      openFullscreenTooltip: openFullscreenTooltip,
      openFullscreenSemanticLabel: openFullscreenSemanticLabel,
      belowSubtitle: belowSubtitle,
      child: innerChart,
    );
  }
}

Widget? _mergeComparisonTitleTrailing(
  Widget? primary,
  Widget? secondary, {
  required double gap,
}) {
  if (primary == null) {
    return secondary;
  }
  if (secondary == null) {
    return primary;
  }
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      primary,
      SizedBox(width: gap),
      secondary,
    ],
  );
}
