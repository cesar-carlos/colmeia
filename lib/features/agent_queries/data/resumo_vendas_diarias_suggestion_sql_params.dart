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

  /// SQL Server LIKE pattern with `%` wildcards.
  ///
  /// Escapes `%`, `_`, and `[` for LIKE.
  static String? buildSearchPattern(String? searchTerm) {
    if (searchTerm == null) {
      return null;
    }
    final trimmed = searchTerm.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final escaped = trimmed
        .replaceAll('[', '[[]')
        .replaceAll('%', '[%]')
        .replaceAll('_', '[_]');
    return '%$escaped%';
  }
}
