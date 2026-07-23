/// One row per empresa/filial/product with calendar moving-average trend metrics.
class ProdutoVendidoTendenciaDeVendaMediaMovelRow {
  const ProdutoVendidoTendenciaDeVendaMediaMovelRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.codProduto,
    required this.nomeProduto,
    required this.codUnidadeMedida,
    required this.mediaAtual,
    required this.mediaAnterior,
    required this.diferenca,
    required this.tendenciaPercentual,
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
  final int? codGrupoProduto;
  final String? nomeGrupoProduto;
  final int? codMarca;
  final String? nomeMarca;
  final double mediaAtual;
  final double mediaAnterior;
  final double diferenca;
  final double tendenciaPercentual;
  final String classificacao;
}
