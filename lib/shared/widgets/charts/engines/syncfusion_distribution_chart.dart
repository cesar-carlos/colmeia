import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:colmeia/shared/widgets/charts/app_distribution_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class SyncfusionDistributionChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final chartTheme = AppChartTheme.fromContext(
      context,
      preset: preset,
    );
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final resolvedHeight = style.height ?? chartTheme.height;
    final visiblePoints = points
        .where(_hasRenderableValue)
        .toList(growable: false);

    if (isLoading) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child: Semantics(
            container: true,
            liveRegion: true,
            label: 'Carregando distribuicao...',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(color: chartTheme.primaryColor),
                const SizedBox(height: 12),
                Text(
                  'Carregando distribuicao...',
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

    if (visiblePoints.isEmpty) {
      return SizedBox(
        height: resolvedHeight,
        child: Center(
          child:
              emptyPlaceholder ??
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
        margin: style.chartPadding ?? EdgeInsets.zero,
        palette: chartTheme.palette,
        legend: Legend(isVisible: style.showLegend),
        tooltipBehavior: TooltipBehavior(enable: style.showTooltip),
        series: <CircularSeries<AppChartPoint, String>>[
          DoughnutSeries<AppChartPoint, String>(
            dataSource: visiblePoints,
            xValueMapper: (point, _) => point.label,
            yValueMapper: (point, _) => point.value,
            onPointTap: onSegmentTap == null
                ? null
                : (args) {
                    final index = args.pointIndex;
                    if (index == null ||
                        index < 0 ||
                        index >= visiblePoints.length) {
                      return;
                    }
                    onSegmentTap!(visiblePoints[index], index);
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
