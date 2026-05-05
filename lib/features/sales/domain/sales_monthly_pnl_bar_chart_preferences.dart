import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_percent_metric.dart';
import 'package:flutter/foundation.dart';

// ignore_for_file: sort_constructors_first — factory follows fields + generative constructor by team layout.

/// Main display mode for the monthly P&L bar chart on the sales screen.
enum SalesMonthlyPnlBarDisplayMode {
  amounts,
  percent,
}

@immutable
class SalesMonthlyPnlBarChartPreferences {
  const SalesMonthlyPnlBarChartPreferences({
    required this.displayMode,
    required this.percentMetric,
  });

  final SalesMonthlyPnlBarDisplayMode displayMode;
  final LucratividadePercentMetric percentMetric;

  factory SalesMonthlyPnlBarChartPreferences.fromRaw(
    Map<String, Object?> raw,
  ) {
    final displayName = raw['display'] as String?;
    final metricName = raw['percent_metric'] as String?;

    final display = switch (displayName) {
      'percent' => SalesMonthlyPnlBarDisplayMode.percent,
      'amounts' => SalesMonthlyPnlBarDisplayMode.amounts,
      'values' => SalesMonthlyPnlBarDisplayMode.amounts,
      _ => SalesMonthlyPnlBarDisplayMode.amounts,
    };

    var metric = LucratividadePercentMetric.grossMargin;
    if (metricName != null && metricName.isNotEmpty) {
      try {
        metric = LucratividadePercentMetric.values.byName(metricName);
      } on Object catch (_) {
        metric = LucratividadePercentMetric.grossMargin;
      }
    }

    return SalesMonthlyPnlBarChartPreferences(
      displayMode: display,
      percentMetric: metric,
    );
  }

  static const SalesMonthlyPnlBarChartPreferences defaults =
      SalesMonthlyPnlBarChartPreferences(
    displayMode: SalesMonthlyPnlBarDisplayMode.amounts,
    percentMetric: LucratividadePercentMetric.grossMargin,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'display': displayMode.name,
    'percent_metric': percentMetric.name,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalesMonthlyPnlBarChartPreferences &&
          displayMode == other.displayMode &&
          percentMetric == other.percentMetric;

  @override
  int get hashCode => Object.hash(displayMode, percentMetric);
}
