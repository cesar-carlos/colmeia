/// One row per company, branch, user, sale year/month (`YYYY/MM`), and payment
/// method in the parcel summary.
///
/// [qtdVendas] matches SQL `COUNT(DISTINCT Id)` (distinct sales in the group).
///
/// [valorParcela] matches SQL `SUM(ValorParcela - ValorTrocoParcela)` (net
/// parcel total after troco allocation), not a single installment line amount.
class ResumoParcelasFormaPagamentoPorMesRow {
  const ResumoParcelasFormaPagamentoPorMesRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeUsuario,
    required this.anoMesDataVenda,
    required this.codFormaPagamento,
    required this.descricaoFormaPagamento,
    required this.qtdVendas,
    required this.valorParcela,
  });

  final int codEmpresa;
  final int codFilial;
  final String nomeUsuario;
  final String anoMesDataVenda;
  final String codFormaPagamento;
  final String descricaoFormaPagamento;
  final int qtdVendas;
  final double valorParcela;
}
