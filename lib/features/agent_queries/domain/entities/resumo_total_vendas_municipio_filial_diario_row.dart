/// One row per company, branch (with municipality), and calendar sale day from
/// `ResumoTotalVendasMunicipioFilialDiario`.
///
/// `qtdVendas` is `COUNT(DISTINCT CodProdutoVendido)` in SQL. `totalVenda` sums
/// `ValorLiquido` lines.
class ResumoTotalVendasMunicipioFilialDiarioRow {
  const ResumoTotalVendasMunicipioFilialDiarioRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeFilial,
    required this.codMunicipioFilial,
    required this.nomeMunicipioFilial,
    required this.ufMunicipioFilial,
    required this.dataVenda,
    required this.qtdVendas,
    required this.totalVenda,
    this.nomeFantasiaFilial,
    this.cepFilial,
    this.codigoIbgeMunicipioFilial,
  });

  final int codEmpresa;
  final int codFilial;
  final String nomeFilial;
  final int codMunicipioFilial;
  final String nomeMunicipioFilial;
  final String ufMunicipioFilial;
  final DateTime dataVenda;
  final int qtdVendas;
  final double totalVenda;
  final String? nomeFantasiaFilial;
  final String? cepFilial;
  final String? codigoIbgeMunicipioFilial;
}
