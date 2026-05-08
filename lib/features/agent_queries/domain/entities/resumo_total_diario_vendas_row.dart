/// One row per company, branch, and calendar sale day from
/// `ResumoTotalDiarioVendas`.
///
/// `qtdVendas` is `COUNT(DISTINCT CodProdutoVendido)` in SQL (distinct sale
/// headers per branch/day). `valorTotalDiarioVenda` sums `ValorLiquido` lines.
///
/// Chart rows from period fill (`ResumoTotalDiarioVendasCompletePeriod.fill`)
/// use `aggregatedBranchSentinel` for company and branch when collapsed across
/// branches for a single daily series.
class ResumoTotalDiarioVendasRow {
  const ResumoTotalDiarioVendasRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.dataVenda,
    required this.qtdVendas,
    required this.valorTotalDiarioVenda,
  });

  /// Same sentinel as `ResumoParcelasMensalRow.aggregatedBranchSentinel`.
  static const int aggregatedBranchSentinel = 0;

  final int codEmpresa;
  final int codFilial;
  final DateTime dataVenda;
  final int qtdVendas;
  final double valorTotalDiarioVenda;
}
