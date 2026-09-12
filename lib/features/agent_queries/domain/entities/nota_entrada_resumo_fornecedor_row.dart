/// One supplier total from the branch-scoped entrada-note catalog.
class NotaEntradaResumoFornecedorRow {
  const NotaEntradaResumoFornecedorRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeFilial,
    required this.codFornecedor,
    required this.nomeFornecedor,
    required this.qtdNotas,
    required this.ticketMedio,
    required this.valorTotalCompra,
    this.nomeFantasiaFilial,
    this.nomeFantasiaFornecedor,
    this.cnpjCpfFornecedor,
  });

  final int codEmpresa;
  final int codFilial;
  final String nomeFilial;
  final String? nomeFantasiaFilial;
  final int codFornecedor;
  final String nomeFornecedor;
  final String? nomeFantasiaFornecedor;
  final String? cnpjCpfFornecedor;
  final int qtdNotas;
  final double ticketMedio;
  final double valorTotalCompra;
}
