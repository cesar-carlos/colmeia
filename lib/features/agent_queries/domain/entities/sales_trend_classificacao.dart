/// Unified wire values for product sales trend classification (period + MA).
abstract final class SalesTrendClassificacao {
  static const String novo = 'NOVO';
  static const String parou = 'PAROU';
  static const String crescendo = 'CRESCENDO';
  static const String caindo = 'CAINDO';
  static const String estavel = 'ESTAVEL';

  static const Set<String> allowed = <String>{
    novo,
    parou,
    crescendo,
    caindo,
    estavel,
  };

  /// Display order for KPI strips and charts.
  static const List<String> displayOrder = <String>[
    crescendo,
    caindo,
    novo,
    parou,
    estavel,
  ];

  /// Normalizes persisted/UI values including legacy period-report labels.
  static String? normalize(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final upper = trimmed.toUpperCase();
    return switch (upper) {
      'NOVO PRODUTO' => novo,
      'PAROU DE VENDER' => parou,
      _ when allowed.contains(upper) => upper,
      _ => null,
    };
  }
}

/// How top-mover lists are ranked.
enum SalesTrendTopMoversSortBy {
  diferenca,
  percentual,
}
