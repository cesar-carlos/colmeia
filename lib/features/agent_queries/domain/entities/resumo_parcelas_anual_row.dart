/// One row per company, branch, sale year, and payment method in the annual
/// parcel summary.
///
/// [qtdVendas] matches SQL `COUNT(DISTINCT Id)` (distinct sales in the group).
///
/// [valorParcela] matches SQL `SUM(ValorParcela - ValorTrocoParcela)` (net
/// parcel total after troco allocation), not a single installment line amount.
class ResumoParcelasAnualRow {
  const ResumoParcelasAnualRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.anoDataVenda,
    required this.codFormaPagamento,
    required this.descricaoFormaPagamento,
    required this.qtdVendas,
    required this.valorParcela,
  });

  final int codEmpresa;
  final int codFilial;
  final int anoDataVenda;
  final String codFormaPagamento;
  final String descricaoFormaPagamento;
  final int qtdVendas;
  final double valorParcela;
}
