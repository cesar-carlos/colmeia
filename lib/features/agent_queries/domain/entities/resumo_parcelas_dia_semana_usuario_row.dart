/// One row per company, branch, sale user name, and weekday bucket
/// (`DiaSemanaNumero`) in the filtered period.
///
/// `qtdVendas` is `COUNT(DISTINCT Id)` over the filtered parcel lines (distinct
/// sales in the SQL sense). `valorParcela` is the sum of net parcel value after
/// troco allocation (`ValorParcela - ValorTrocoParcela` in SQL).
class ResumoParcelasDiaSemanaUsuarioRow {
  const ResumoParcelasDiaSemanaUsuarioRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeUsuario,
    required this.diaSemanaNumero,
    required this.diaSemana,
    required this.qtdVendas,
    required this.valorParcela,
  });

  final int codEmpresa;
  final int codFilial;
  final String nomeUsuario;
  final int diaSemanaNumero;
  final String diaSemana;
  final int qtdVendas;
  final double valorParcela;
}
