class ResumoVendasDiariasPorVendedorFilter {
  const ResumoVendasDiariasPorVendedorFilter({
    required this.dataVendaInicio,
    required this.dataVendaFim,
    this.codVendedor,
    this.bairro,
    this.municipio,
    this.origem = 'FrenteLoja',
    this.geraFinanceiro = 'S',
    this.preVenda = 'N',
  });

  final DateTime dataVendaInicio;
  final DateTime dataVendaFim;
  final int? codVendedor;
  final String? bairro;
  final String? municipio;

  /// Defaults match `ResumoParcelasPeriodoFilter` for parcel-line resumos.
  final String origem;
  final String geraFinanceiro;
  final String preVenda;

  String get trimmedOrigem => origem.trim();

  String get trimmedGeraFinanceiro => geraFinanceiro.trim().toUpperCase();

  String get trimmedPreVenda => preVenda.trim().toUpperCase();

  int? get sqlCodVendedor {
    final value = codVendedor;
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  String? get sqlBairro {
    final trimmed = bairro?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String? get sqlMunicipio {
    final trimmed = municipio?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String? validationError() {
    if (dataVendaFim.isBefore(dataVendaInicio)) {
      return 'dataVendaFim must be on or after dataVendaInicio';
    }
    final cod = codVendedor;
    if (cod != null && cod <= 0) {
      return 'codVendedor must be greater than zero when provided';
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
