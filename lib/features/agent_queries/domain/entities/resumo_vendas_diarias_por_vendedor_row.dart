class ResumoVendasDiariasPorVendedorRow {
  const ResumoVendasDiariasPorVendedorRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.dataVenda,
    required this.codVendedor,
    required this.nomeVendedor,
    required this.qtdeItens,
    required this.valorAcrescimo,
    required this.valorDesconto,
    required this.valorBruto,
    required this.valorLiquido,
  });

  final int codEmpresa;
  final int codFilial;
  final DateTime dataVenda;
  final int? codVendedor;
  final String nomeVendedor;
  final double qtdeItens;
  final double valorAcrescimo;
  final double valorDesconto;
  final double valorBruto;
  final double valorLiquido;
}
