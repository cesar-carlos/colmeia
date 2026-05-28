/// Shared date range and parcel report flags for SQL-backed resumo queries.
class ResumoParcelasPeriodoFilter {
  const ResumoParcelasPeriodoFilter({
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
    final origemTrim = trimmedOrigem;
    if (origemTrim.isEmpty) {
      return 'origem must not be empty';
    }
    // Parcel resumo SQL binds `:origem` with an exact match (was `LIKE` —
    // kept the parameter name for backwards compatibility). Reject SQL LIKE
    // wildcards so a stray `%` does not silently widen the dataset and
    // diverge from sibling reports.
    if (origemTrim.contains('%') || origemTrim.contains('_')) {
      return 'origem must not contain SQL LIKE wildcards (% or _) '
          'for parcel resumo queries (exact match only)';
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
