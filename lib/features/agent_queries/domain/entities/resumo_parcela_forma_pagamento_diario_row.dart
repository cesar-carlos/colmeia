/// One row per sold product line (codProdutoVendido) in the filtered period.
///
/// The SQL may expose extra columns only inside nested subqueries; this entity
/// maps the outer result set only.
///
/// Grain matches SQL `GROUP BY` on company, branch, sold product, origin,
/// sale date, month label, user, and seller dimensions. Measures are distinct
/// sale count and net value after troco allocation on parcel lines.
///
/// codVendedor and nomeVendedor are null when the LEFT JOIN to Vendedor has no
/// matching row.
class ResumoVendaProdutoDiarioRow {
  const ResumoVendaProdutoDiarioRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.codProdutoVendido,
    required this.origem,
    required this.codOrigem,
    required this.dataVenda,
    required this.anoMesDataVenda,
    required this.nomeUsuario,
    required this.qtdVendas,
    required this.valorTotalVenda,
    this.codVendedor,
    this.nomeVendedor,
  });

  final int codEmpresa;
  final int codFilial;
  final int codProdutoVendido;
  final String origem;
  final int codOrigem;
  final DateTime dataVenda;
  final String anoMesDataVenda;
  final String nomeUsuario;
  final int? codVendedor;
  final String? nomeVendedor;
  final int qtdVendas;
  final double valorTotalVenda;
}
