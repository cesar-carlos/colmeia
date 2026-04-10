/// One row per calendar sale day and payment method.
///
/// [quantidade] matches SQL `COUNT(*)` over filtered **parcel lines**, not
/// distinct sales.
class ResumoParcelaFormaPagamentoDiarioRow {
  const ResumoParcelaFormaPagamentoDiarioRow({
    required this.dataVenda,
    required this.descricaoFormaPagamento,
    required this.quantidade,
    required this.valorTotal,
  });

  final DateTime dataVenda;
  final String descricaoFormaPagamento;
  final int quantidade;
  final double valorTotal;
}
