/// One monthly profitability bucket from the
/// `ResumoProdutoVendaLucratividadeMensal` aggregate query.
///
/// Grouped by `CodEmpresa`, `CodFilial`, `Ano`, `Mes`. `PercentualLucro`
/// is `(Σ qty×custo reposição) / (Σ qty×valor líquido) × 100` when both
/// totals are positive; zero otherwise.
class ResumoProdutoVendaLucratividadeMensalRow {
  const ResumoProdutoVendaLucratividadeMensalRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.ano,
    required this.mes,
    required this.anoMes,
    required this.qtdVendas,
    required this.qtdItensVendido,
    required this.valorTotalCustoMedio,
    required this.custoReposicao,
    required this.pontoEquilibrio,
    required this.valorTotalItem,
    required this.percentualLucro,
  });

  final int codEmpresa;
  final int codFilial;
  final int ano;

  /// Calendar month (1–12).
  final int mes;

  /// Zero-padded `"YYYY/MM"` label suitable for display (e.g. `"2026/03"`).
  final String anoMes;

  final int qtdVendas;
  final double qtdItensVendido;

  /// `SUM(qty × custo médio ponderado)` for the month.
  final double valorTotalCustoMedio;
  final double custoReposicao;
  final double pontoEquilibrio;
  final double valorTotalItem;

  /// Cost-to-revenue ratio in %: `(Σ custo reposição / Σ valor líquido) × 100`.
  final double percentualLucro;
}
