/// One row per company, branch, and weekday bucket (`DiaSemanaNumero`) in the
/// filtered period.
///
/// `qtdVendas` is `COUNT(DISTINCT Id)` over the filtered parcel lines (distinct
/// sales in the SQL sense). `valorParcela` is the sum of net parcel value after
/// troco allocation (`ValorParcela - ValorTrocoParcela` in SQL).
///
/// For chart rows built by client-side week fill, field `codEmpresa` and
/// `codFilial` equal `aggregatedBranchSentinel` when values were summed across
/// branches for a single weekly series.
class ResumoParcelasDiaSemanaRow {
  const ResumoParcelasDiaSemanaRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.diaSemanaNumero,
    required this.diaSemana,
    required this.qtdVendas,
    required this.valorParcela,
  });

  /// Placeholder `codEmpresa` / `codFilial` for rows that are **not** tied to a
  /// real company or branch in the database.
  ///
  /// The SQL layer returns concrete `CodEmpresa` and `CodFilial`. This value
  /// appears only after client-side aggregation (for example
  /// `ResumoParcelasDiaSemanaCompleteWeek.fill`), when weekday totals were
  /// summed across all branch keys for charting. It must not be sent back as
  /// a SQL filter or interpreted as branch id zero in the ERP.
  static const int aggregatedBranchSentinel = 0;

  final int codEmpresa;
  final int codFilial;
  final int diaSemanaNumero;
  final String diaSemana;
  final int qtdVendas;
  final double valorParcela;
}
