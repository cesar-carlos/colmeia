import 'package:colmeia/features/agent_queries/domain/entities/lucratividade_percent_metric.dart';
import 'package:colmeia/features/agent_queries/presentation/lucratividade_percent_metric_labels.dart';
import 'package:colmeia/features/overview/presentation/widgets/lucratividade_combo_chart_types.dart';
import 'package:colmeia/l10n/app_localizations.dart';

class LucratividadeComboDisplaySeries<T> {
  const LucratividadeComboDisplaySeries({
    required this.barFn,
    required this.lineFn,
    required this.labelFn,
    required this.barSeriesLabel,
    required this.lineSeriesLabel,
    required this.isPercent,
    required this.isCost,
  });

  final num Function(T) barFn;
  final num Function(T) lineFn;
  final String Function(T, num) labelFn;
  final String barSeriesLabel;
  final String lineSeriesLabel;
  final bool isPercent;
  final bool isCost;
}

LucratividadeComboDisplaySeries<T> resolveLucratividadeComboDisplaySeries<T>({
  required LucratividadeComboDisplay display,
  required LucratividadePercentMetric percentMetric,
  required LucratividadeComboChartCopy copy,
  required AppLocalizations l10n,
  required LucratividadeComboRowAccessors<T> accessors,
  required String Function(T, num) barLabelCurrency,
  required String Function(T, num) barLabelPercentScale,
  required String Function(T, num) barLabelMarkup,
}) {
  final isPercent = display == LucratividadeComboDisplay.percentMetrics;
  final isCost = display == LucratividadeComboDisplay.costRevenue;
  final isProfit = display == LucratividadeComboDisplay.profitRevenue;

  late final num Function(T) barFn;
  late final num Function(T) lineFn;
  late final String Function(T, num) labelFn;

  if (isPercent) {
    barFn = (r) => accessors.metricBarValue(r, percentMetric);
    lineFn = accessors.valorTotalItem;
    labelFn = percentMetric == LucratividadePercentMetric.markupOverCost
        ? barLabelMarkup
        : barLabelPercentScale;
  } else if (isCost) {
    barFn = accessors.custoReposicao;
    lineFn = accessors.valorTotalItem;
    labelFn = barLabelCurrency;
  } else if (isProfit) {
    barFn = accessors.lucro;
    lineFn = accessors.valorTotalItem;
    labelFn = barLabelCurrency;
  } else {
    barFn = accessors.valorTotalItem;
    lineFn = accessors.custoReposicao;
    labelFn = barLabelCurrency;
  }

  final barSeriesLabel = isPercent
      ? lucratividadePercentBarSeriesLabel(l10n, percentMetric)
      : isCost
      ? copy.costSeriesLabel
      : isProfit
      ? copy.profitSeriesLabel
      : copy.revenueSeriesLabel;
  final lineSeriesLabel = isPercent || isCost || isProfit
      ? copy.revenueSeriesLabel
      : copy.costSeriesLabel;

  return LucratividadeComboDisplaySeries<T>(
    barFn: barFn,
    lineFn: lineFn,
    labelFn: labelFn,
    barSeriesLabel: barSeriesLabel,
    lineSeriesLabel: lineSeriesLabel,
    isPercent: isPercent,
    isCost: isCost,
  );
}
