/// One row per company, branch, and sale calendar year in the annual parcel
/// summary (no payment-method dimension).
///
/// [qtdVendas] matches SQL `COUNT(DISTINCT Id)` (distinct sales in the group).
///
/// [valorTotalVenda] matches SQL `SUM(ValorParcela - ValorTrocoParcela)` (net
/// total after troco allocation on parcel lines).
///
/// Uses `double` like other agent SQL money aggregates; it mirrors ERP or
/// bridge numeric precision and is not a fixed decimal type.
class ResumoParcelasAnualRow {
  const ResumoParcelasAnualRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.anoDataVenda,
    required this.qtdVendas,
    required this.valorTotalVenda,
  });

  final int codEmpresa;
  final int codFilial;
  final int anoDataVenda;
  final int qtdVendas;
  final double valorTotalVenda;
}
