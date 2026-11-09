/// Canonical persisted inputs matching the defaults of the report adapters.
Map<String, Object?> normalizeCacheRefreshFilters(
  String report,
  Map<String, Object?> filters,
) {
  final defaults = <String, Object?>{
    if (const {
      'productSales',
      'productMargin',
      'purchaseNotes',
      'purchaseSuppliers',
      'movingAverage',
      'productTrend',
    }.contains(report)) ...{
      'page': 1,
      'pageSize': report == 'purchaseNotes' || report == 'purchaseSuppliers'
          ? 50
          : 20,
    },
    if (report == 'productSales') 'origem': 'FrenteLoja',
    if (report == 'purchaseNotes' || report == 'purchaseSuppliers') ...{
      'codEmpresa': 1,
      'codFilial': 1,
    },
  };
  final result = <String, Object?>{};
  for (final entry in filters.entries) {
    final value = entry.value is String
        ? (entry.value! as String).trim()
        : entry.value;
    if (value == null ||
        value == '' ||
        (defaults.containsKey(entry.key) && defaults[entry.key] == value)) {
      continue;
    }
    result[entry.key] = value;
  }
  return Map.unmodifiable(result);
}
