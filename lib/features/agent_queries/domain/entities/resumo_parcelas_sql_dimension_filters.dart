/// Optional company, branch, and seller filters for parcel-summary SQL.
///
/// Bound as named parameters (`codEmpresa`, `codFilial`, `codVendedor`). The
/// SQL uses `(:name IS NULL OR column = :name)` so the bridge must send
/// explicit nulls for unused dimensions (not omit keys), or the predicate may
/// not behave as intended.
abstract final class ResumoParcelasSqlDimensionFilters {
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
}
