/// One profitability bucket from the `ResumoProdutoVendaLucratividade`
/// aggregate query.
///
/// Grouped by `CodEmpresa` and `CodFilial` for the requested date range.
/// `percentualLucro` is computed in the app from `custoReposicao` and
/// `valorTotalItem` to avoid SQL compatibility issues with Sybase SQL Anywhere
/// and SQL Server when using aggregate expressions inside a CASE WHEN.
class ResumoProdutoVendaLucratividadeRow {
  const ResumoProdutoVendaLucratividadeRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.qtdVendas,
    required this.qtdItensVendido,
    required this.valorTotalCustoMedio,
    required this.custoReposicao,
    required this.pontoEquilibrio,
    required this.valorTotalItem,
    this.chartAxisLabel,
  });

  final int codEmpresa;
  final int codFilial;
  final int qtdVendas;
  final double qtdItensVendido;

  /// `SUM(qty × custo médio ponderado)` for the period.
  final double valorTotalCustoMedio;
  final double custoReposicao;
  final double pontoEquilibrio;
  final double valorTotalItem;

  /// When set (e.g. overview aggregates all branches for one agent), used as
  /// the chart category label instead of [filialLabel].
  final String? chartAxisLabel;

  /// Cost-to-revenue ratio in %: `(custoReposicao / valorTotalItem) × 100`.
  /// Computed from the raw aggregates returned by the query.
  double get percentualLucro {
    if (custoReposicao > 0 && valorTotalItem > 0) {
      return (custoReposicao / valorTotalItem) * 100;
    }
    return 0;
  }

  /// Absolute profit: `valorTotalItem - custoReposicao`.
  double get lucro => valorTotalItem - custoReposicao;

  /// Short label for chart X-axis: `"<empresa>-<filial>"`, or [chartAxisLabel].
  String get filialLabel => chartAxisLabel ?? '$codEmpresa-$codFilial';
}
