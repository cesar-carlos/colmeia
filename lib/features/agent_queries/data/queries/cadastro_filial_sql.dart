import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';

/// Paged branch registration query with total count in one `sql.execute`.
///
/// Reads `Filial`. Full and map-catalog projections left-join `Municipio`
/// for municipality metadata; [CadastroFilialSqlProjection.branchOptions]
/// skips that join.
/// Pagination is bound through named params `:startRow` and `:endRow`.
/// Company / branch predicates are validated in Dart and inlined into the SQL
/// to support exact multi-branch subsets without exhausting the bridge named
/// parameter budget.
///
/// Use [CadastroFilialSqlProjection.mapCatalog] for the live sales map catalog
/// (omits `CNPJ` and `CodMunicipio`; keeps address fields for geocoding).
/// Use [CadastroFilialSqlProjection.branchOptions] for pickers that only need
/// company/branch identity and names — no `Municipio` join or address columns.
abstract final class CadastroFilialSql {
  static String query({
    Iterable<CadastroFilialBranchRef> branches =
        const <CadastroFilialBranchRef>[],
    bool hasSelectedBranches = false,
    int? codEmpresa,
    int? codFilial,
    String? searchTerm,
    CadastroFilialSqlProjection projection =
        CadastroFilialSqlProjection.registration,
  }) {
    final branchPredicate = _branchPredicate(
      branches: branches,
      hasSelectedBranches: hasSelectedBranches,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
    );
    final searchPredicate = _searchPredicate(searchTerm);
    final baseColumns = switch (projection) {
      CadastroFilialSqlProjection.registration => _baseColumnsRegistration,
      CadastroFilialSqlProjection.mapCatalog => _baseColumnsMapCatalog,
      CadastroFilialSqlProjection.branchOptions => _baseColumnsBranchOptions,
    };
    final outerColumns = switch (projection) {
      CadastroFilialSqlProjection.registration => _outerColumnsRegistration,
      CadastroFilialSqlProjection.mapCatalog => _outerColumnsMapCatalog,
      CadastroFilialSqlProjection.branchOptions => _outerColumnsBranchOptions,
    };
    final municipioJoin =
        projection == CadastroFilialSqlProjection.branchOptions
        ? ''
        : '''
      LEFT JOIN Municipio m ON
        m.CodMunicipio = f.CodMunicipio
''';
    return '''
    WITH Base AS (
      SELECT
$baseColumns
      FROM Filial f
$municipioJoin      WHERE 1 = 1
$branchPredicate
$searchPredicate
    ),
    Tot AS (
      SELECT COUNT(*) AS TotalCount FROM Base
    ),
    Numbered AS (
      SELECT
        b.*,
        ROW_NUMBER() OVER (ORDER BY b.CodEmpresa, b.CodFilial) AS Rn
      FROM Base b
    )
    SELECT
      Tot.TotalCount,
$outerColumns
      N.Rn
    FROM Tot
    LEFT JOIN Numbered N ON N.Rn BETWEEN :startRow AND :endRow
    ORDER BY COALESCE(N.Rn, 2147483647)
  ''';
  }

  static CadastroFilialSqlProjection projectionFor(
    CadastroFilialFilter filter,
  ) {
    if (filter.branchOptionsProjection) {
      return CadastroFilialSqlProjection.branchOptions;
    }
    if (filter.mapCatalogProjection) {
      return CadastroFilialSqlProjection.mapCatalog;
    }
    return CadastroFilialSqlProjection.registration;
  }

  /// Non-CTE query used when the paged CTE comes back as an empty payload
  /// (missing `TotalCount` sentinel). Some SQL Anywhere agents drop the
  /// `Tot LEFT JOIN Numbered` shape even with unary + `preferDbStreaming:
  /// false`; a `SELECT TOP` still reads `Filial`.
  ///
  /// [maxRows] and [startRow] are inlined; the caller must pass a validated
  /// page size and 1-based start index.
  static String simpleQuery({
    Iterable<CadastroFilialBranchRef> branches =
        const <CadastroFilialBranchRef>[],
    bool hasSelectedBranches = false,
    int? codEmpresa,
    int? codFilial,
    String? searchTerm,
    int maxRows = CadastroFilialFilter.maxPageSize,
    int startRow = 1,
    CadastroFilialSqlProjection projection =
        CadastroFilialSqlProjection.registration,
  }) {
    final branchPredicate = _branchPredicate(
      branches: branches,
      hasSelectedBranches: hasSelectedBranches,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
    );
    final searchPredicate = _searchPredicate(searchTerm);
    final baseColumns = switch (projection) {
      CadastroFilialSqlProjection.registration => _baseColumnsRegistration,
      CadastroFilialSqlProjection.mapCatalog => _baseColumnsMapCatalog,
      CadastroFilialSqlProjection.branchOptions => _baseColumnsBranchOptions,
    };
    final municipioJoin =
        projection == CadastroFilialSqlProjection.branchOptions
        ? ''
        : '''
      LEFT JOIN Municipio m ON
        m.CodMunicipio = f.CodMunicipio
''';
    final topClause = startRow > 1
        ? 'SELECT TOP $maxRows START AT $startRow'
        : 'SELECT TOP $maxRows';
    return '''
    $topClause
      (SELECT COUNT(*) FROM Filial f WHERE 1 = 1
$branchPredicate
$searchPredicate) AS TotalCount,
$baseColumns
      FROM Filial f
$municipioJoin      WHERE 1 = 1
$branchPredicate
$searchPredicate
    ORDER BY f.CodEmpresa, f.CodFilial
  ''';
  }

  /// Picker-only alias of [simpleQuery] with
  /// [CadastroFilialSqlProjection.branchOptions].
  static String branchOptionsSimpleQuery({
    Iterable<CadastroFilialBranchRef> branches =
        const <CadastroFilialBranchRef>[],
    bool hasSelectedBranches = false,
    int? codEmpresa,
    int? codFilial,
    String? searchTerm,
    int maxRows = CadastroFilialFilter.maxPageSize,
  }) {
    return simpleQuery(
      branches: branches,
      hasSelectedBranches: hasSelectedBranches,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      searchTerm: searchTerm,
      maxRows: maxRows,
      projection: CadastroFilialSqlProjection.branchOptions,
    );
  }

  static const String _baseColumnsRegistration = '''
        f.CodEmpresa,
        f.CodFilial,
        f.Nome AS NomeFilial,
        f.NomeFantasia AS NomeFantasia,
        f.CNPJ,
        f.Logradouro AS Endereco,
        f.NumeroLogradouro AS NumeroEndereco,
        f.Bairro,
        REPLACE(REPLACE(REPLACE(TRIM(f.CEP), '.', ''), '-', ''), ' ', '') AS CEP,
        f.CodMunicipio,
        TRIM(m.Nome) AS NomeMunicipio,
        m.CodigoIBGE AS CodigoIBGE,
        TRIM(m.UF) AS UFMunicipio
''';

  static const String _baseColumnsMapCatalog = '''
        f.CodEmpresa,
        f.CodFilial,
        f.Nome AS NomeFilial,
        f.NomeFantasia AS NomeFantasia,
        f.Logradouro AS Endereco,
        f.NumeroLogradouro AS NumeroEndereco,
        f.Bairro,
        REPLACE(REPLACE(REPLACE(TRIM(f.CEP), '.', ''), '-', ''), ' ', '') AS CEP,
        TRIM(m.Nome) AS NomeMunicipio,
        m.CodigoIBGE AS CodigoIBGE,
        TRIM(m.UF) AS UFMunicipio
''';

  static const String _baseColumnsBranchOptions = '''
        f.CodEmpresa,
        f.CodFilial,
        f.Nome AS NomeFilial,
        f.NomeFantasia AS NomeFantasia
''';

  static const String _outerColumnsRegistration = '''
      N.CodEmpresa,
      N.CodFilial,
      N.NomeFilial,
      N.NomeFantasia,
      N.CNPJ,
      N.Endereco,
      N.NumeroEndereco,
      N.Bairro,
      N.CEP,
      N.CodMunicipio,
      N.NomeMunicipio,
      N.CodigoIBGE,
      N.UFMunicipio,
''';

  static const String _outerColumnsMapCatalog = '''
      N.CodEmpresa,
      N.CodFilial,
      N.NomeFilial,
      N.NomeFantasia,
      N.Endereco,
      N.NumeroEndereco,
      N.Bairro,
      N.CEP,
      N.NomeMunicipio,
      N.CodigoIBGE,
      N.UFMunicipio,
''';

  static const String _outerColumnsBranchOptions = '''
      N.CodEmpresa,
      N.CodFilial,
      N.NomeFilial,
      N.NomeFantasia,
''';

  static String _searchPredicate(String? searchTerm) {
    final normalized = searchTerm?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '';
    }
    final escaped = normalized.replaceAll("'", "''");
    final likeLiteral = "N'%$escaped%'";
    return '''
        AND (
          UPPER(f.Nome) LIKE UPPER($likeLiteral)
          OR UPPER(COALESCE(f.NomeFantasia, '')) LIKE UPPER($likeLiteral)
          OR CAST(f.CodFilial AS VARCHAR(20)) LIKE $likeLiteral
        )''';
  }

  static String _branchPredicate({
    required Iterable<CadastroFilialBranchRef> branches,
    required bool hasSelectedBranches,
    required int? codEmpresa,
    required int? codFilial,
  }) {
    final byKey = <String, CadastroFilialBranchRef>{};
    for (final branch in branches) {
      byKey['${branch.codEmpresa}:${branch.codFilial}'] = branch;
    }
    final uniqueBranches = byKey.values.toList(growable: false)
      ..sort((left, right) {
        final company = left.codEmpresa.compareTo(right.codEmpresa);
        if (company != 0) {
          return company;
        }
        return left.codFilial.compareTo(right.codFilial);
      });

    if (uniqueBranches.isEmpty) {
      if (hasSelectedBranches) {
        return '        AND 1 = 0';
      }
      final clauses = <String>[];
      if (codEmpresa != null) {
        clauses.add('f.CodEmpresa = $codEmpresa');
      }
      if (codFilial != null) {
        clauses.add('f.CodFilial = $codFilial');
      }
      if (clauses.isEmpty) {
        return '';
      }
      return '        AND ${clauses.join(' AND ')}';
    }

    final branchesByCompany = <int, List<int>>{};
    for (final branch in uniqueBranches) {
      branchesByCompany
          .putIfAbsent(branch.codEmpresa, () => <int>[])
          .add(branch.codFilial);
    }

    final clauses = branchesByCompany.entries
        .map((entry) {
          final filiais = entry.value;
          if (filiais.length == 1) {
            return '(f.CodEmpresa = ${entry.key} AND f.CodFilial = ${filiais.single})';
          }
          return '(f.CodEmpresa = ${entry.key} '
              'AND f.CodFilial IN (${filiais.join(', ')}))';
        })
        .join(' OR ');
    return '        AND ($clauses)';
  }
}

/// Column projection for [CadastroFilialSql.query].
enum CadastroFilialSqlProjection {
  /// Full branch registration (CNPJ, CodMunicipio, all address fields).
  registration,

  /// Live sales map catalog: omits CNPJ and CodMunicipio; keeps address for geocoding.
  mapCatalog,

  /// Picker / filter options: company, branch, and names only. No `Municipio`
  /// join and no address columns — those extras fail on some agent schemas.
  branchOptions,
}
