import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_percent_metric.dart';
import 'package:colmeia/l10n/app_localizations.dart';

String lucratividadePercentMetricExplanation(
  AppLocalizations l10n,
  LucratividadePercentMetric metric,
) {
  switch (metric) {
    case LucratividadePercentMetric.costOverRevenue:
      return l10n.overviewLucratividadePercentHelpCostBody;
    case LucratividadePercentMetric.grossMargin:
      return l10n.overviewLucratividadePercentHelpGrossBody;
    case LucratividadePercentMetric.markupOverCost:
      return l10n.overviewLucratividadePercentHelpMarkupBody;
  }
}

String lucratividadePercentBarSeriesLabel(
  AppLocalizations l10n,
  LucratividadePercentMetric metric,
) {
  switch (metric) {
    case LucratividadePercentMetric.costOverRevenue:
      return l10n.overviewLucratividadePercentSeriesCostLabel;
    case LucratividadePercentMetric.grossMargin:
      return l10n.overviewLucratividadePercentSeriesGrossLabel;
    case LucratividadePercentMetric.markupOverCost:
      return l10n.overviewLucratividadePercentSeriesMarkupLabel;
  }
}

/// Semantics-friendly summary for the active percent metric (formula + hint).
String lucratividadePercentMetricSemanticsLabel(
  AppLocalizations l10n,
  LucratividadePercentMetric metric,
) {
  switch (metric) {
    case LucratividadePercentMetric.costOverRevenue:
      return l10n.overviewLucratividadePercentSemanticsCost;
    case LucratividadePercentMetric.grossMargin:
      return l10n.overviewLucratividadePercentSemanticsGross;
    case LucratividadePercentMetric.markupOverCost:
      return l10n.overviewLucratividadePercentSemanticsMarkup;
  }
}

String lucratividadePercentMetricSegmentTooltip(
  AppLocalizations l10n,
  LucratividadePercentMetric metric,
) {
  switch (metric) {
    case LucratividadePercentMetric.costOverRevenue:
      return l10n.overviewLucratividadePercentMetricCostTooltip;
    case LucratividadePercentMetric.grossMargin:
      return l10n.overviewLucratividadePercentMetricGrossTooltip;
    case LucratividadePercentMetric.markupOverCost:
      return l10n.overviewLucratividadePercentMetricMarkupTooltip;
  }
}
