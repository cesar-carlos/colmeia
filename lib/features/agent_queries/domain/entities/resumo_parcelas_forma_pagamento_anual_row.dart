/// One row per calendar year and payment method in the annual parcel summary.
///
/// [quantidade] matches SQL `COUNT(*)` over filtered **parcel lines**, not
/// distinct sales.
class ResumoParcelasFormaPagamentoAnualRow {
  const ResumoParcelasFormaPagamentoAnualRow({
    required this.ano,
    required this.descricaoFormaPagamento,
    required this.quantidade,
    required this.valorTotal,
  });

  final int ano;
  final String descricaoFormaPagamento;
  final int quantidade;
  final double valorTotal;
}
