/// One entrada note from the branch-scoped purchase catalog.
class NotaEntradaRow {
  const NotaEntradaRow({
    required this.compraId,
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeFilial,
    required this.codTipoOperacaoCompra,
    required this.descricaoTipoOperacaoCompra,
    required this.numeroDocumento,
    required this.dataLancamento,
    required this.codFornecedor,
    required this.nomeFornecedor,
    required this.valorTotalCompra,
    this.nomeFantasiaFilial,
    this.dataEmissao,
    this.dataEntrada,
    this.nomeFantasiaFornecedor,
    this.cnpjCpfFornecedor,
  });

  /// `Compra.Compra.Id`, exposed for a stable list key and keyset cursor.
  final int compraId;
  final int codEmpresa;
  final int codFilial;
  final String nomeFilial;
  final String? nomeFantasiaFilial;
  final int codTipoOperacaoCompra;
  final String descricaoTipoOperacaoCompra;
  final String numeroDocumento;
  final DateTime? dataEmissao;
  final DateTime? dataEntrada;
  final DateTime dataLancamento;
  final int codFornecedor;
  final String nomeFornecedor;
  final String? nomeFantasiaFornecedor;
  final String? cnpjCpfFornecedor;
  final double valorTotalCompra;
}
