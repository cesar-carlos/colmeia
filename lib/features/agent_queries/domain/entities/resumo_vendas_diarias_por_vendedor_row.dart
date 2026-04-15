/// One row per company, branch, calendar day, month label, and seller
/// dimension.
///
/// The SQL may expose extra columns only inside nested subqueries (e.g. for
/// filters); this entity maps the outer result set only.
///
/// Measures come from parcel lines with troco allocation: distinct sale ids
/// and net value. codVendedor and nomeVendedor are null when the LEFT JOIN to
/// Vendedor has no matching row.
///
/// [valorTotalVenda] uses `double` like other agent SQL money fields; it
/// mirrors ERP/bridge numeric precision and is not a fixed decimal type.
class ResumoVendasDiariasPorVendedorRow {
  const ResumoVendasDiariasPorVendedorRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.dataVenda,
    required this.anoMesDataVenda,
    required this.qtdVendas,
    required this.valorTotalVenda,
    this.codVendedor,
    this.nomeVendedor,
  });

  final int codEmpresa;
  final int codFilial;
  final DateTime dataVenda;
  final String anoMesDataVenda;
  final int? codVendedor;
  final String? nomeVendedor;
  final int qtdVendas;
  final double valorTotalVenda;
}
