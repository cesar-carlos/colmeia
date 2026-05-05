/// One monthly profitability bucket from the
/// `ResumoProdutoVendaLucratividadeMensal` aggregate query.
///
/// Grouped by `CodEmpresa`, `CodFilial`, `Ano`, `Mes`. Percent metrics are
/// computed in the app from `custoReposicao` and `valorTotalItem` to avoid
/// SQL compatibility issues with Sybase SQL Anywhere and SQL Server when using
/// aggregate expressions inside a CASE WHEN.
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

  /// Cost as % of revenue: `(custoReposicao / valorTotalItem) × 100`.
  double get percentualCustoSobreVenda {
    if (custoReposicao > 0 && valorTotalItem > 0) {
      return (custoReposicao / valorTotalItem) * 100;
    }
    return 0;
  }

  /// Gross margin %: `(lucro / valorTotalItem) × 100`.
  double get margemLucroBrutoPercent {
    if (valorTotalItem > 0) {
      return (lucro / valorTotalItem) * 100;
    }
    return 0;
  }

  /// Markup on replacement cost: `(lucro / custoReposicao) × 100`.
  /// Returns `0` when [custoReposicao] is not positive (undefined markup).
  double get markupSobreCustoPercent {
    if (custoReposicao > 0) {
      return (lucro / custoReposicao) * 100;
    }
    return 0;
  }

  /// Absolute profit: `valorTotalItem - custoReposicao`.
  double get lucro => valorTotalItem - custoReposicao;
}
