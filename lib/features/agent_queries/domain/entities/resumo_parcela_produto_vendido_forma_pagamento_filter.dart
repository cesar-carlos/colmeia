class ResumoParcelaProdutoVendidoFormaPagamentoFilter {
  const ResumoParcelaProdutoVendidoFormaPagamentoFilter({
    required this.dataVendaInicio,
    required this.dataVendaFim,
    this.origem = 'FrenteLoja',
    this.geraFinanceiro = 'S',
    this.preVenda = 'N',
  });

  final DateTime dataVendaInicio;
  final DateTime dataVendaFim;
  final String origem;
  final String geraFinanceiro;
  final String preVenda;

  String get trimmedOrigem => origem.trim();
  String get trimmedGeraFinanceiro => geraFinanceiro.trim().toUpperCase();
  String get trimmedPreVenda => preVenda.trim().toUpperCase();

  String? validationError() {
    if (dataVendaFim.isBefore(dataVendaInicio)) {
      return 'dataVendaFim must be on or after dataVendaInicio';
    }
    if (trimmedOrigem.isEmpty) {
      return 'origem must not be empty';
    }
    if (!_isFlag(trimmedGeraFinanceiro)) {
      return 'geraFinanceiro must be S or N';
    }
    if (!_isFlag(trimmedPreVenda)) {
      return 'preVenda must be S or N';
    }
    return null;
  }

  bool _isFlag(String value) => value == 'S' || value == 'N';
}
