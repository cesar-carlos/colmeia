/// Optional company, branch, and seller filters for parcel-summary SQL.
///
/// The Agent SQL bridge caps **named** parameter JSON size (see
/// `AgentSqlBridgeLimits.namedParamsJsonMaxUtf8Bytes`). Optional dimensions are
/// inlined as **integer literals** via [literalWhereLines] after
/// [validationError] passes — never from user-controlled strings.
///
/// [namedParams] is kept for tests; production SQL should use
/// [embedLiteralDimensionWhere] with [resumoParcelasWhereDimensionPlaceholder].
///
/// For **string** dimensions (e.g. neighbourhood filters elsewhere), use the
/// same idea: escape literals in Dart, never concatenate raw user input.
abstract final class ResumoParcelasSqlDimensionFilters {
  /// Marker in `*_sql.dart` tails; replaced by [embedLiteralDimensionWhere].
  static const String resumoParcelasWhereDimensionPlaceholder =
      '__RESUMO_PARCELAS_DIMENSION_WHERE__';

  static String? validationError({
    int? codEmpresa,
    int? codFilial,
    int? codVendedor,
  }) {
    if (codEmpresa != null && codEmpresa <= 0) {
      return 'codEmpresa must be positive when set';
    }
    if (codFilial != null && codFilial <= 0) {
      return 'codFilial must be positive when set';
    }
    if (codVendedor != null && codVendedor <= 0) {
      return 'codVendedor must be positive when set';
    }
    if (codFilial != null && codEmpresa == null) {
      return 'codEmpresa must be set when codFilial is set';
    }
    return null;
  }

  static Map<String, Object?> namedParams({
    int? codEmpresa,
    int? codFilial,
    int? codVendedor,
  }) {
    return <String, Object?>{
      'codEmpresa': codEmpresa,
      'codFilial': codFilial,
      'codVendedor': codVendedor,
    };
  }

  /// `AND CodEmpresa = …` lines for validated positive ints only; empty when all
  /// dimensions are unset.
  static String literalWhereLines({
    int? codEmpresa,
    int? codFilial,
    int? codVendedor,
  }) {
    final lines = <String>[];
    if (codEmpresa != null) {
      lines.add('      AND CodEmpresa = $codEmpresa');
    }
    if (codFilial != null) {
      lines.add('      AND CodFilial = $codFilial');
    }
    if (codVendedor != null) {
      lines.add('      AND CodVendedor = $codVendedor');
    }
    return lines.join('\n');
  }

  static String embedLiteralDimensionWhere(
    String queryTailContainingPlaceholder, {
    int? codEmpresa,
    int? codFilial,
    int? codVendedor,
  }) {
    return queryTailContainingPlaceholder.replaceFirst(
      resumoParcelasWhereDimensionPlaceholder,
      literalWhereLines(
        codEmpresa: codEmpresa,
        codFilial: codFilial,
        codVendedor: codVendedor,
      ),
    );
  }
}
