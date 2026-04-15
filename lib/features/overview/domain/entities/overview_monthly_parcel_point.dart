/// One month in the overview home last-12-months parcel trend chart.
class OverviewMonthlyParcelPoint {
  const OverviewMonthlyParcelPoint({
    required this.anoMes,
    required this.qtdVendas,
    required this.valorParcela,
  });

  final String anoMes;
  final int qtdVendas;
  final double valorParcela;
}
