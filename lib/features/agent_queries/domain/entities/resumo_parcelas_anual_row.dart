/// One row per calendar year in the annual parcel summary.
///
/// [quantidade] matches SQL `COUNT(*)` over filtered **parcel lines**, not
/// distinct sales.
class ResumoParcelasAnualRow {
  const ResumoParcelasAnualRow({
    required this.ano,
    required this.quantidade,
    required this.valorTotal,
  });

  final int ano;
  final int quantidade;
  final double valorTotal;
}
