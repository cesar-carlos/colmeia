/// One grouped product line from the ResumoProdutoVenda aggregate query.
class ResumoProdutoVendaRow {
  const ResumoProdutoVendaRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.codProduto,
    required this.nomeProduto,
    required this.qtdVendas,
    required this.qtdItensVendido,
    required this.valorTotalCustoMedio,
    required this.custoReposicao,
    required this.pontoEquilibrio,
    required this.valorTotalItem,
    this.codGrupoProduto,
    this.nomeGrupoProduto,
    this.codMarca,
    this.nomeMarca,
    this.codTipoGrupoProduto,
    this.descricaoTipoGrupoProduto,
  });

  final int codEmpresa;
  final int codFilial;
  final int codProduto;
  final String nomeProduto;
  final int qtdVendas;
  final double qtdItensVendido;

  /// `SUM(Quantidade * CustoMedio)` no agrupamento (valor total, não unitário).
  final double valorTotalCustoMedio;
  final double custoReposicao;
  final double pontoEquilibrio;
  final double valorTotalItem;

  /// Cost as % of revenue: `(custoReposicao / valorTotalItem) × 100`.
  /// Computed from raw aggregates — removed from SQL to avoid Sybase SQL Anywhere
  /// SQLCODE -156 (invalid expression near 'SUM' inside CASE WHEN).
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
  double get markupSobreCustoPercent {
    if (custoReposicao > 0) {
      return (lucro / custoReposicao) * 100;
    }
    return 0;
  }

  /// Absolute profit: `valorTotalItem - custoReposicao`.
  double get lucro => valorTotalItem - custoReposicao;

  final int? codGrupoProduto;
  final String? nomeGrupoProduto;
  final int? codMarca;
  final String? nomeMarca;
  final int? codTipoGrupoProduto;
  final String? descricaoTipoGrupoProduto;
}
