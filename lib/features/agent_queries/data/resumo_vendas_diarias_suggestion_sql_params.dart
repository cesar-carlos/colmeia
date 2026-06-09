/// Shared rules for suggestion SQL named parameters on execute requests.
abstract final class ResumoVendasDiariasSuggestionSqlParams {
  static const int defaultLimit = 20;

  /// Upper bound for `TOP (:limit)` on suggestion queries.
  ///
  /// Applies to single-agent calls and per-agent fetches in merge flows.
  static const int maxSuggestionFetchLimit = 100;

  static String? validateDateRange({
    required DateTime dataVendaInicio,
    required DateTime dataVendaFim,
  }) {
    if (dataVendaFim.isBefore(dataVendaInicio)) {
      return 'dataVendaFim must be on or after dataVendaInicio';
    }
    return null;
  }

  static int clampLimit(int limit) {
    if (limit < 1) {
      return 1;
    }
    if (limit > maxSuggestionFetchLimit) {
      return maxSuggestionFetchLimit;
    }
    return limit;
  }

  /// Rows to request per agent before cross-agent merge and dedupe.
  ///
  /// [mergeResultLimit] is the UI cap after merge (already [clampLimit]'d).
  ///
  /// Each agent runs `TOP` independently; scaling by target count reduces
  /// missing globally relevant rows, still capped by [maxSuggestionFetchLimit].
  static int perAgentSuggestionFetchLimit({
    required int mergeResultLimit,
    required int plannedTargetCount,
  }) {
    final mergedCap = clampLimit(mergeResultLimit);
    final n = plannedTargetCount < 1 ? 1 : plannedTargetCount;
    final multiplied = mergedCap * n;
    if (multiplied > maxSuggestionFetchLimit) {
      return maxSuggestionFetchLimit;
    }
    return multiplied;
  }

  /// Escapes `%`, `_`, and `[` for SQL Server / SAP SQL Anywhere `LIKE`.
  static String _escapeForLike(String trimmed) {
    return trimmed
        .replaceAll('[', '[[]')
        .replaceAll('%', '[%]')
        .replaceAll('_', '[_]');
  }

  /// SQL `LIKE` pattern with leading and trailing `%` (substring match).
  static String? buildSearchPattern(String? searchTerm) {
    if (searchTerm == null) {
      return null;
    }
    final trimmed = searchTerm.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final escaped = _escapeForLike(trimmed);
    return '%$escaped%';
  }

  /// Whether [searchTerm] is non-empty and contains only ASCII digits.
  static bool isDigitsOnlySearchTerm(String? searchTerm) {
    if (searchTerm == null) {
      return false;
    }
    final trimmed = searchTerm.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    return RegExp(r'^\d+$').hasMatch(trimmed);
  }

  /// `LIKE` pattern for IBGE code lookup when the user typed digits only.
  static String? buildDigitsOnlySearchPattern(String? searchTerm) {
    if (!isDigitsOnlySearchTerm(searchTerm)) {
      return null;
    }
    return buildSearchPattern(searchTerm!.trim());
  }

  /// Prefix `LIKE` pattern (`term%`) for large catalogs (e.g. municipio list).
  ///
  /// Favors index seeks on `Nome`-like columns; use [buildSearchPattern] when
  /// substring matching is required (smaller option lists).
  static String? buildPrefixSearchPattern(String? searchTerm) {
    if (searchTerm == null) {
      return null;
    }
    final trimmed = searchTerm.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final escaped = _escapeForLike(trimmed);
    return '$escaped%';
  }
}
