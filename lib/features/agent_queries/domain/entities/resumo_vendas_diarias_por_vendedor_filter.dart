class ResumoVendasDiariasPorVendedorFilter {
  const ResumoVendasDiariasPorVendedorFilter({
    required this.dataVendaInicio,
    required this.dataVendaFim,
    this.codVendedor,
    this.bairro,
    this.municipio,
  });

  final DateTime dataVendaInicio;
  final DateTime dataVendaFim;
  final int? codVendedor;
  final String? bairro;
  final String? municipio;

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
    return null;
  }
}
