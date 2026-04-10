/// One row per weekday bucket (`DiaSemanaNumero`) in the filtered period.
///
/// `quantidade` matches SQL `COUNT(*)` over filtered **parcel lines**, not
/// distinct sales.
class ResumoParcelasDiaSemanaRow {
  const ResumoParcelasDiaSemanaRow({
    required this.diaSemanaNumero,
    required this.diaSemana,
    required this.quantidade,
    required this.valorTotal,
  });

  final int diaSemanaNumero;
  final String diaSemana;
  final int quantidade;
  final double valorTotal;
}
