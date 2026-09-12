/// Supplier-search helpers for the entrada-notes catalog.
abstract final class SalesNotasEntradaSearch {
  static const String persistSearchTermKey = 'searchTerm';

  /// Agent SQL is too expensive to run per keystroke.
  static const Duration debounce = Duration(milliseconds: 400);

  static String? normalize(Object? raw) {
    if (raw is! String) {
      return null;
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
