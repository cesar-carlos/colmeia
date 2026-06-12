import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_percent_metric.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:syncfusion_flutter_charts/charts.dart' show TooltipArgs;

enum LucratividadeComboDisplay {
  profitRevenue,
  revenueCost,
  costRevenue,
  percentMetrics,
}

/// Localized copy for period vs monthly lucratividade combo charts.
class LucratividadeComboChartCopy {
  const LucratividadeComboChartCopy({
    required this.title,
    required this.subtitle,
    required this.switchProfit,
    required this.switchRevenue,
    required this.switchCost,
    required this.switchMargin,
    required this.profitSeriesLabel,
    required this.revenueSeriesLabel,
    required this.costSeriesLabel,
    required this.emptyMessage,
    required this.multiAgentHintMessage,
    required this.loadFailedFallback,
    required this.showChronologicalPercentHint,
    required this.useSmartCompactCurrencyLabels,
    this.chartPaddingBottom,
    this.minCategorySlotWidth,
  });

  final String title;
  final String subtitle;
  final String switchProfit;
  final String switchRevenue;
  final String switchCost;
  final String switchMargin;
  final String profitSeriesLabel;
  final String revenueSeriesLabel;
  final String costSeriesLabel;
  final String emptyMessage;
  final String multiAgentHintMessage;
  final String loadFailedFallback;
  final bool showChronologicalPercentHint;
  final bool useSmartCompactCurrencyLabels;
  final double? chartPaddingBottom;
  final double? minCategorySlotWidth;
}

/// Row accessors so one combo chart works for period and monthly row types.
class LucratividadeComboRowAccessors<T> {
  const LucratividadeComboRowAccessors({
    required this.lucro,
    required this.valorTotalItem,
    required this.custoReposicao,
    required this.metricBarValue,
    this.sortPoints,
  });

  final double Function(T row) lucro;
  final double Function(T row) valorTotalItem;
  final double Function(T row) custoReposicao;
  final num Function(T row, LucratividadePercentMetric metric) metricBarValue;
  final void Function(
    List<T> points,
    LucratividadeComboDisplay display,
    LucratividadePercentMetric percentMetric,
  )?
  sortPoints;
}

String? Function(TooltipArgs args)? lucratividadeMarkupTooltipBodyResolver<T>({
  required List<T> points,
  required LucratividadePercentMetric metric,
  required AppLocalizations l10n,
  required double Function(T row) custoReposicao,
}) {
  if (metric != LucratividadePercentMetric.markupOverCost) return null;
  return (TooltipArgs args) {
    final dynamic raw = args.pointIndex;
    final i = raw is int ? raw : (raw as num).toInt();
    if (i < 0 || i >= points.length) return null;
    if (custoReposicao(points[i]) > 0) return null;
    final base = args.text ?? '';
    final extra = l10n.overviewLucratividadeMarkupUndefinedTooltip;
    if (base.isEmpty) return extra;
    return '$base\n$extra';
  };
}
