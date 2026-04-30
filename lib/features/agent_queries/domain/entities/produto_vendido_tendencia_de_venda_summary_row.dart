/// Aggregated trend summary row grouped by classification.
class ProdutoVendidoTendenciaDeVendaSummaryRow {
  const ProdutoVendidoTendenciaDeVendaSummaryRow({
    required this.classificacao,
    required this.quantidadeProdutos,
    required this.impactoLiquido,
  });

  final String classificacao;
  final int quantidadeProdutos;
  final double impactoLiquido;
}
