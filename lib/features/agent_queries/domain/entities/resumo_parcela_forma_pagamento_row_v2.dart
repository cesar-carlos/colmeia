class ResumoParcelaFormaPagamentoRowV2 {
  const ResumoParcelaFormaPagamentoRowV2({
    required this.codEmpresa,
    required this.codFilial,
    required this.codFormaPagamento,
    required this.descricaoFormaPagamento,
    required this.qtdVendas,
    required this.valorParcela,
  });

  final int codEmpresa;
  final int codFilial;
  final String codFormaPagamento;
  final String descricaoFormaPagamento;
  final int qtdVendas;
  final double valorParcela;
}
