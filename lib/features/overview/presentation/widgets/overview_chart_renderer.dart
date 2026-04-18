// NOT_RENDERED: only consumed by `OverviewSalesTrendCard`, which is itself
// not mounted in any page or route today. Kept for the upcoming overview
// revamp. See `lib/features/overview/presentation/widgets/README.md`.

import 'package:colmeia/features/overview/domain/entities/overview_chart_point.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_models.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_presets.dart';
import 'package:colmeia/shared/widgets/charts/app_time_series_chart.dart';
import 'package:flutter/material.dart';

class OverviewChartRenderer extends StatefulWidget {
  const OverviewChartRenderer({
    required this.title,
    required this.subtitle,
    required this.points,
    super.key,
    this.titleTrailing,
    this.belowSubtitle,
  });

  final String title;
  final String subtitle;
  final List<OverviewChartPoint> points;
  final Widget? titleTrailing;
  final Widget? belowSubtitle;

  @override
  State<OverviewChartRenderer> createState() => _OverviewChartRendererState();
}

class _OverviewChartRendererState extends State<OverviewChartRenderer> {
  List<OverviewChartPoint>? _pointsRef;
  List<AppChartPoint>? _chartPoints;

  void _rebuildChartPointsIfNeeded() {
    if (identical(_pointsRef, widget.points) && _chartPoints != null) {
      return;
    }
    _pointsRef = widget.points;
    _chartPoints = widget.points
        .map(
          (point) => AppChartPoint(
            label: point.label,
            value: point.value,
          ),
        )
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _rebuildChartPointsIfNeeded();
  }

  @override
  void didUpdateWidget(covariant OverviewChartRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rebuildChartPointsIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return AppTimeSeriesChart(
      title: widget.title,
      subtitle: widget.subtitle,
      titleTrailing: widget.titleTrailing,
      belowSubtitle: widget.belowSubtitle,
      points: _chartPoints!,
      preset: AppChartPreset.standard,
      style: const AppTimeSeriesChartStyle(
        animationDuration: Duration.zero,
      ),
    );
  }
}
