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
    required this.percentualLucro,
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

  /// Margem bruta aproximada: `(ValorTotalItem - CustoReposicao agregado) / ValorTotalItem * 100`.
  final double percentualLucro;
  final int? codGrupoProduto;
  final String? nomeGrupoProduto;
  final int? codMarca;
  final String? nomeMarca;
  final int? codTipoGrupoProduto;
  final String? descricaoTipoGrupoProduto;
}
