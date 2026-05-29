import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_distribution_chart.dart';
import 'package:colmeia/shared/widgets/charts/engines/chart_engine_defaults.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionDistributionChart extends StatefulWidget {
  const SyncfusionDistributionChart({
    required this.points,
    required this.preset,
    required this.style,
    super.key,
    this.isLoading = false,
    this.emptyPlaceholder,
    this.onSegmentTap,
  });

  final List<AppChartPoint> points;
  final AppChartPreset preset;
  final AppDistributionChartStyle style;
  final bool isLoading;
  final Widget? emptyPlaceholder;
  final void Function(AppChartPoint point, int index)? onSegmentTap;

  @override
  State<SyncfusionDistributionChart> createState() =>
      _SyncfusionDistributionChartState();
}

class _SyncfusionDistributionChartState
    extends State<SyncfusionDistributionChart> {
  List<AppChartPoint>? _pointsRef;
  List<AppChartPoint> _visiblePoints = const <AppChartPoint>[];

  void _recomputeVisibleIfNeeded() {
    if (identical(_pointsRef, widget.points)) {
      return;
    }
    _pointsRef = widget.points;
    _visiblePoints = widget.points
        .where(_hasRenderableValue)
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _recomputeVisibleIfNeeded();
  }

  @override
  void didUpdateWidget(covariant SyncfusionDistributionChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recomputeVisibleIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(
      context,
      preset: widget.preset,
    );
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final resolvedHeight = widget.style.height ?? chartTheme.height;

    if (widget.isLoading) {
      final loadingLabel = AppLocalizations.of(context).chartLoadingGeneric;
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child: Semantics(
            container: true,
            liveRegion: true,
            label: loadingLabel,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(color: chartTheme.primaryColor),
                const SizedBox(height: 12),
                Text(
                  loadingLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_visiblePoints.isEmpty) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child:
              widget.emptyPlaceholder ??
              Text(
                'Sem distribuicao disponivel para este recorte.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
        ),
      );
    }

    return SizedBox(
      height: resolvedHeight,
      child: SfCircularChart(
        margin: widget.style.chartPadding ?? EdgeInsets.zero,
        palette: chartTheme.palette,
        legend: Legend(isVisible: widget.style.showLegend),
        onTooltipRender: buildSanitizingTooltipRenderer(),
        tooltipBehavior: buildChartTooltipBehavior(
          context,
          enable: widget.style.showTooltip,
        ),
        series: <CircularSeries<AppChartPoint, String>>[
          DoughnutSeries<AppChartPoint, String>(
            dataSource: _visiblePoints,
            animationDuration: resolveChartAnimationDurationMs(
              context: context,
              styleDuration: null,
              defaultMs: AppChartEngineAnimationDefaults.circularSeriesMs,
            ),
            xValueMapper: (point, _) => point.label,
            yValueMapper: (point, _) => point.value,
            onPointTap: widget.onSegmentTap == null
                ? null
                : (args) {
                    final index = args.pointIndex;
                    if (index == null ||
                        index < 0 ||
                        index >= _visiblePoints.length) {
                      return;
                    }
                    widget.onSegmentTap!(_visiblePoints[index], index);
                  },
          ),
        ],
      ),
    );
  }

  bool _hasRenderableValue(AppChartPoint point) {
    final resolvedValue = point.value.toDouble();
    return resolvedValue.isFinite && resolvedValue > 0;
  }
}
