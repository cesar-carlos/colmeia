/// Aggregated moving-average trend summary row grouped by classification.
class ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow {
  const ProdutoVendidoTendenciaDeVendaMediaMovelSummaryRow({
    required this.classificacao,
    required this.quantidadeProdutos,
    required this.impactoLiquido,
  });

  final String classificacao;
  final int quantidadeProdutos;
  final double impactoLiquido;
}
