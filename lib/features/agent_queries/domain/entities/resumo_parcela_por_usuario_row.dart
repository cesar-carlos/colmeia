class ResumoParcelaPorUsuarioRow {
  const ResumoParcelaPorUsuarioRow({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeUsuario,
    required this.qtdVendas,
    required this.valorParcela,
  });

  final int codEmpresa;
  final int codFilial;
  final String nomeUsuario;
  final int qtdVendas;
  final double valorParcela;
}
