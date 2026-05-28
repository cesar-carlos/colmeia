/// Filters for the monthly product profitability summary `sql.execute` query.
///
/// Only `dataVendaInicio` and `dataVendaFim` are required. The date part is
/// what matters: the repository sends `yyyy-MM-dd` strings and the SQL applies
/// `CAST(pv.DataVenda AS DATE) BETWEEN :dataVendaInicio AND :dataVendaFim`.
///
/// The result is bounded by month buckets — at most
/// `(months in range) × (filiais)` rows — so no pagination is needed.
class ResumoProdutoVendaLucratividadeMensalFilter {
  const ResumoProdutoVendaLucratividadeMensalFilter({
    required this.dataVendaInicio,
    required this.dataVendaFim,
    this.origem = 'FrenteLoja',
  });

  /// Allows slightly over one year so year-over-year comparisons fit in a
  /// single request.
  static const int maxDateRangeDays = 400;

  final DateTime dataVendaInicio;
  final DateTime dataVendaFim;

  /// Bound to `pv.Origem = :origem` (exact match; wildcards rejected by
  /// [validationError]).
  final String origem;

  String get trimmedOrigem => origem.trim();

  String? validationError() {
    final origemTrim = trimmedOrigem;
    if (origemTrim.isEmpty) {
      return 'origem must not be empty';
    }
    if (origemTrim.contains('%') || origemTrim.contains('_')) {
      return 'origem must not contain SQL LIKE wildcards (% or _) '
          'for ProdutoVendido resumo queries (exact match only)';
    }
    final start = DateTime(
      dataVendaInicio.year,
      dataVendaInicio.month,
      dataVendaInicio.day,
    );
    final end = DateTime(
      dataVendaFim.year,
      dataVendaFim.month,
      dataVendaFim.day,
    );
    if (end.isBefore(start)) {
      return 'dataVendaFim must be on or after dataVendaInicio';
    }
    final inclusiveDays = end.difference(start).inDays + 1;
    if (inclusiveDays > maxDateRangeDays) {
      return 'date range must be at most $maxDateRangeDays inclusive days';
    }
    return null;
  }
}
