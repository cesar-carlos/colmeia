/// One row per company and branch, with branch municipality, for a sale period.
///
/// `qtdVendas` is `COUNT(*)` in SQL. `totalVenda`
/// sums `ValorLiquido` lines across the whole filtered period.
class ResumoTotalVendasMunicipioFilialPeriodoRow {
  const ResumoTotalVendasMunicipioFilialPeriodoRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeFilial,
    required this.qtdVendas,
    required this.totalVenda,
    this.codMunicipioFilial,
    this.nomeMunicipioFilial,
    this.ufMunicipioFilial,
    this.nomeFantasiaFilial,
    this.cepFilial,
    this.codigoIbgeMunicipioFilial,
  });

  final int codEmpresa;
  final int codFilial;
  final String nomeFilial;
  final int? codMunicipioFilial;
  final String? nomeMunicipioFilial;
  final String? ufMunicipioFilial;
  final int qtdVendas;
  final double totalVenda;
  final String? nomeFantasiaFilial;
  final String? cepFilial;
  final String? codigoIbgeMunicipioFilial;
}
