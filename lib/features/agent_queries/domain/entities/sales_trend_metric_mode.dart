/// Active metric for product sales trend reports (period and moving-average).
enum SalesTrendMetricMode {
  /// Sum of sold units (`ipv.Quantidade`).
  quantity,

  /// Sum of `ipv.Quantidade * ipv.ValorUnitarioLiquido` (net line revenue).
  revenue,
}

extension SalesTrendMetricModeSql on SalesTrendMetricMode {
  /// SQL expression evaluated per sale line before period aggregation.
  String get lineMetricSql => switch (this) {
    SalesTrendMetricMode.quantity => 'ipv.Quantidade',
    SalesTrendMetricMode.revenue =>
      '(ipv.Quantidade * ipv.ValorUnitarioLiquido)',
  };
}
