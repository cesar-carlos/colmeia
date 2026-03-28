import 'package:colmeia/features/dashboards/domain/entities/dashboard_summary_metric.dart';
import 'package:colmeia/features/dashboards/presentation/widgets/dashboard_summary_metric_icon_material.dart';
import 'package:colmeia/shared/widgets/metrics/app_metric_stat_card.dart';
import 'package:flutter/material.dart';

enum DashboardSummaryCardEmphasis { standard, accent }

class DashboardSummaryCard extends StatelessWidget {
  const DashboardSummaryCard({
    required this.title,
    required this.value,
    required this.deltaLabel,
    super.key,
    this.icon,
    this.leading,
    this.emphasis = DashboardSummaryCardEmphasis.standard,
    this.trendPlacement = AppMetricStatTrendPlacement.end,
  }) : assert(
         leading != null || icon != null,
         'DashboardSummaryCard requires icon or leading.',
       );

  final String title;
  final String value;
  final String deltaLabel;
  final DashboardSummaryMetricIcon? icon;
  final Widget? leading;
  final DashboardSummaryCardEmphasis emphasis;
  final AppMetricStatTrendPlacement trendPlacement;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedLeading =
        leading ??
        Icon(
          icon!.materialIconData,
          size: 22,
          color: cs.primary,
        );
    return AppMetricStatCard(
      leading: resolvedLeading,
      trendLabel: deltaLabel,
      label: title,
      value: value,
      emphasis: switch (emphasis) {
        DashboardSummaryCardEmphasis.accent => AppMetricStatCardEmphasis.accent,
        DashboardSummaryCardEmphasis.standard =>
          AppMetricStatCardEmphasis.standard,
      },
      trendPlacement: trendPlacement,
    );
  }
}
