/// One row per company, branch, and calendar month in the monthly parcel
/// summary.
///
/// [qtdVendas] is `COUNT(DISTINCT Id)` over the filtered parcel lines (distinct
/// sales in the SQL sense). [valorParcela] is the sum of net parcel value after
/// troco allocation (`ValorParcela - ValorTrocoParcela` in SQL).
///
/// For chart rows built by `ResumoParcelasMensalCompletePeriod.fill`, field
/// `codEmpresa` and `codFilial` equal [aggregatedBranchSentinel] when values
/// were summed across branches for a single monthly series.
class ResumoParcelasMensalRow {
  const ResumoParcelasMensalRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.ano,
    required this.mes,
    required this.anoMes,
    required this.qtdVendas,
    required this.valorParcela,
  });

  /// Placeholder `codEmpresa` / `codFilial` for rows that are **not** tied to a
  /// real company or branch in the database.
  ///
  /// The SQL layer always returns concrete `CodEmpresa` and `CodFilial`. This
  /// value appears only after client-side aggregation (for example
  /// `ResumoParcelasMensalCompletePeriod.fill`), when monthly totals were
  /// summed across all branch keys for charting. It must not be sent back as
  /// a SQL filter or interpreted as branch id zero in the ERP.
  static const int aggregatedBranchSentinel = 0;

  final int codEmpresa;
  final int codFilial;
  final int ano;
  final int mes;
  final String anoMes;
  final int qtdVendas;
  final double valorParcela;
}
