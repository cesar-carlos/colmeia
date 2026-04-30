/// One row per sold product with trend metrics between two periods.
class ProdutoVendidoTendenciaDeVendaRow {
  const ProdutoVendidoTendenciaDeVendaRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.codProduto,
    required this.nomeProduto,
    required this.codUnidadeMedida,
    required this.qtdAnterior,
    required this.qtdAtual,
    required this.diferenca,
    required this.percentualTendencia,
    required this.classificacao,
    this.codGrupoProduto,
    this.nomeGrupoProduto,
    this.codMarca,
    this.nomeMarca,
  });

  final int codEmpresa;
  final int codFilial;
  final int codProduto;
  final String nomeProduto;
  final String codUnidadeMedida;

  /// Null when the product has no grupo row (LEFT JOIN).
  final int? codGrupoProduto;
  final String? nomeGrupoProduto;

  /// Null when the product has no marca row (LEFT JOIN).
  final int? codMarca;
  final String? nomeMarca;

  final double qtdAnterior;
  final double qtdAtual;
  final double diferenca;
  final double percentualTendencia;
  final String classificacao;
}
