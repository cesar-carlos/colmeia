/// Selected percent KPI for profitability charts (overview and sales monthly).
enum LucratividadePercentMetric {
  /// `custoReposicao / valorTotalItem × 100`
  costOverRevenue,

  /// `(lucro / valorTotalItem) × 100`
  grossMargin,

  /// `(lucro / custoReposicao) × 100`
  markupOverCost,
}
