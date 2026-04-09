class DashboardFilialRanking {
  const DashboardFilialRanking({
    required this.codEmpresa,
    required this.codFilial,
    required this.totalSalesCount,
    required this.totalAmount,
  });

  final int codEmpresa;
  final int codFilial;
  final int totalSalesCount;
  final double totalAmount;

  String get label => 'Empresa $codEmpresa · Filial $codFilial';
}
