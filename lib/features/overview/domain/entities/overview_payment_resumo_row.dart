/// Aggregated payment / user slice used to build overview KPIs.
///
/// Decouples overview from agent SQL row types such as
/// `ResumoParcelaFormaPagamentoRow`.
class OverviewPaymentResumoRow {
  const OverviewPaymentResumoRow({
    required this.nomeUsuario,
    required this.codFormaPagamento,
    required this.descricaoFormaPagamento,
    required this.qtdVendas,
    required this.valorParcela,
  });

  final String nomeUsuario;
  final String codFormaPagamento;
  final String descricaoFormaPagamento;
  final int qtdVendas;
  final double valorParcela;
}
