class ResumoParcelaProdutoVendidoFormaPagamentoRow {
  const ResumoParcelaProdutoVendidoFormaPagamentoRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeUsuario,
    required this.codFormaPagamento,
    required this.descricaoFormaPagamento,
    required this.qtdVendas,
    required this.valorParcela,
  });

  final int codEmpresa;
  final int codFilial;
  final String nomeUsuario;
  final String codFormaPagamento;
  final String descricaoFormaPagamento;
  final int qtdVendas;
  final double valorParcela;
}
