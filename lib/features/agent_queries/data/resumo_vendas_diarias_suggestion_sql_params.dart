/// Shared rules for suggestion SQL named parameters on execute requests.
abstract final class ResumoVendasDiariasSuggestionSqlParams {
  static const int defaultLimit = 20;

  /// Upper bound for suggestion fetch size (`ROW_NUMBER` / `:limit`).
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

  /// Match-all `LIKE` pattern sent when the search box is empty.
  ///
  /// The JSON bind must stay a varchar string. SQL Server Native Client infers
  /// ODBC types from JSON; a `null` `searchPattern` next to integer `:limit`
  /// (especially `TOP (:limit)` + `LIKE COALESCE(:searchPattern, '%')`) binds
  /// the `'%'` literal into `TOP` and raises native error 245.
  static const String matchAllLikePattern = '%';

  /// Escapes `%`, `_`, and `[` for SQL Server / SAP SQL Anywhere `LIKE`.
  static String _escapeForLike(String trimmed) {
    return trimmed
        .replaceAll('[', '[[]')
        .replaceAll('%', '[%]')
        .replaceAll('_', '[_]');
  }

  /// SQL `LIKE` pattern with leading and trailing `%` (substring match).
  ///
  /// Always a [String] so the wire value is varchar, never JSON `null`.
  static String buildSearchPattern(String? searchTerm) {
    if (searchTerm == null) {
      return matchAllLikePattern;
    }
    final trimmed = searchTerm.trim();
    if (trimmed.isEmpty) {
      return matchAllLikePattern;
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
  /// substring matching is required (smaller option lists). Always a [String]
  /// so the wire value is varchar, never JSON `null`.
  static String buildPrefixSearchPattern(String? searchTerm) {
    if (searchTerm == null) {
      return matchAllLikePattern;
    }
    final trimmed = searchTerm.trim();
    if (trimmed.isEmpty) {
      return matchAllLikePattern;
    }
    final escaped = _escapeForLike(trimmed);
    return '$escaped%';
  }
}
