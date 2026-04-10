/// One row per calendar month in the monthly parcel summary.
///
/// [quantidade] matches SQL `COUNT(*)` over filtered **parcel lines**, not
/// distinct sales.
class ResumoParcelasMensalRow {
  const ResumoParcelasMensalRow({
    required this.ano,
    required this.mes,
    required this.anoMes,
    required this.quantidade,
    required this.valorTotal,
  });

  final int ano;
  final int mes;
  final String anoMes;
  final int quantidade;
  final double valorTotal;
}
