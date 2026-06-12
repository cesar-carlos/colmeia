import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_percent_metric.dart';
import 'package:colmeia/features/overview/presentation/widgets/lucratividade_combo_chart_controls.dart';
import 'package:colmeia/features/overview/presentation/widgets/lucratividade_combo_chart_display_series.dart';
import 'package:colmeia/features/overview/presentation/widgets/lucratividade_combo_chart_types.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/charts/metric_toggle_comparison_bar_fullscreen_body.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_combo_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart' show TooltipArgs;

typedef LucratividadeComboStyleBuilder =
    AppComboChartStyle Function(
      AppThemeTokens tokens, {
      required AppLocalizations l10n,
      required bool usePercentPrimaryAxis,
      required bool useMarkupAxisFormat,
      required Color barColor,
      double? heightOverride,
      bool fastChartAnimation,
      String? Function(TooltipArgs args)? tooltipBodyResolver,
    });

/// Offscreen fullscreen surface with independent display/metric state.
Widget buildLucratividadeComboFullscreenBody<T>({
  required GlobalKey shareCaptureKey,
  required List<T> snapshot,
  required LucratividadeComboDisplay initialDisplay,
  required LucratividadePercentMetric initialPercentMetric,
  required LucratividadeComboChartCopy copy,
  required AppLocalizations l10n,
  required String emptyMessage,
  required LucratividadeComboRowAccessors<T> accessors,
  required String Function(T row) xLabelBuilder,
  required LucratividadeComboStyleBuilder styleBuilder,
  required AppComboChartStyle Function(AppComboChartStyle base, double height)?
  landscapeStyleOverride,
  required String Function(T, num) barLabelCurrency,
  required String Function(T, num) barLabelPercentScale,
  required String Function(T, num) barLabelMarkup,
}) {
  var display = initialDisplay;
  var percentMetric = initialPercentMetric;

  return RepaintBoundary(
    key: shareCaptureKey,
    child: StatefulBuilder(
      builder: (context, setFullscreenState) {
        final fullscreenTokens = Theme.of(
          context,
        ).extension<AppThemeTokens>()!;
        final series = resolveLucratividadeComboDisplaySeries<T>(
          display: display,
          percentMetric: percentMetric,
          copy: copy,
          l10n: l10n,
          accessors: accessors,
          barLabelCurrency: barLabelCurrency,
          barLabelPercentScale: barLabelPercentScale,
          barLabelMarkup: barLabelMarkup,
        );
        final tooltipResolver = lucratividadeMarkupTooltipBodyResolver<T>(
          points: snapshot,
          metric: percentMetric,
          l10n: l10n,
          custoReposicao: accessors.custoReposicao,
        );
        final useMarkupAxis =
            series.isPercent &&
            percentMetric == LucratividadePercentMetric.markupOverCost;

        return buildSegmentedControlFullscreenBody(
          tokens: fullscreenTokens,
          control: LucratividadeComboChartControls(
            l10n: l10n,
            copy: copy,
            tokens: fullscreenTokens,
            display: display,
            percentMetric: percentMetric,
            hasChartData: snapshot.isNotEmpty,
            onDisplayChanged: (v) => setFullscreenState(() => display = v),
            onPercentMetricChanged: (v) =>
                setFullscreenState(() => percentMetric = v),
          ),
          chartBuilder: (availableChartHeight) {
            var built = styleBuilder(
              fullscreenTokens,
              l10n: l10n,
              usePercentPrimaryAxis: series.isPercent,
              useMarkupAxisFormat: useMarkupAxis,
              barColor: display == LucratividadeComboDisplay.costRevenue
                  ? fullscreenTokens.warning
                  : fullscreenTokens.chartSeriesPrimary,
              heightOverride: availableChartHeight,
              fastChartAnimation: series.isPercent,
              tooltipBodyResolver: tooltipResolver,
            );
            final landscapeOverride = landscapeStyleOverride;
            if (landscapeOverride != null && isLandscapeChartViewport(context)) {
              built = landscapeOverride(built, availableChartHeight);
            }
            return AppComboChart<T>(
              key: ValueKey<Object>(
                Object.hash(snapshot.length, display, percentMetric),
              ),
              items: snapshot,
              xLabelBuilder: xLabelBuilder,
              barValueBuilder: series.barFn,
              barSeriesLabel: series.barSeriesLabel,
              lineValueBuilder: series.lineFn,
              lineSeriesLabel: series.lineSeriesLabel,
              barDataLabelBuilder: series.labelFn,
              style: built,
              emptyPlaceholder: snapshot.isEmpty
                  ? Center(
                      child: Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : null,
            );
          },
        );
      },
    ),
  );
}
