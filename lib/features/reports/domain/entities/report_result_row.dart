class ReportResultRow {
  const ReportResultRow({
    required this.seller,
    required this.store,
    required this.revenue,
    required this.orders,
  });

  final String seller;
  final String store;
  final double revenue;
  final int orders;
}
