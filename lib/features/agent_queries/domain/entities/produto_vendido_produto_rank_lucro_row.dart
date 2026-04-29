/// One row per product in the bounded top ranking for profitability metrics.
///
/// Column names mirror the outer SELECT of the rank query template.
class ProdutoVendidoProdutoRankLucroRow {
  const ProdutoVendidoProdutoRankLucroRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.codProduto,
    required this.nomeProduto,
    required this.qtdItensVendido,
    required this.valorTotal,
    required this.custoTotal,
    required this.lucroUnitario,
    required this.totalValorLucro,
    this.codGrupoProduto,
    this.nomeGrupoProduto,
    this.codMarca,
    this.nomeMarca,
  });

  final int codEmpresa;
  final int codFilial;
  final int codProduto;
  final String nomeProduto;
  final double qtdItensVendido;
  final double valorTotal;
  final double custoTotal;
  final double lucroUnitario;
  final double totalValorLucro;

  /// Null when the product has no grupo row (LEFT JOIN).
  final int? codGrupoProduto;

  final String? nomeGrupoProduto;

  /// Null when the product has no marca row (LEFT JOIN).
  final int? codMarca;

  final String? nomeMarca;
}
