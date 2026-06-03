import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';

/// Paged branch registration query with total count in one `sql.execute`.
///
/// Reads `Filial` and left-joins `Municipio` for municipality metadata.
/// Pagination is bound through named params `:startRow` and `:endRow`.
/// Company / branch predicates are validated in Dart and inlined into the SQL
/// to support exact multi-branch subsets without exhausting the bridge named
/// parameter budget.
///
/// Use [CadastroFilialSqlProjection.mapCatalog] for the live sales map catalog
/// (omits `CNPJ` and `CodMunicipio`; keeps address fields for geocoding).
abstract final class CadastroFilialSql {
  static String query({
    Iterable<CadastroFilialBranchRef> branches =
        const <CadastroFilialBranchRef>[],
    bool hasSelectedBranches = false,
    int? codEmpresa,
    int? codFilial,
    CadastroFilialSqlProjection projection = CadastroFilialSqlProjection.registration,
  }) {
    final branchPredicate = _branchPredicate(
      branches: branches,
      hasSelectedBranches: hasSelectedBranches,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
    );
    final baseColumns = projection == CadastroFilialSqlProjection.mapCatalog
        ? _baseColumnsMapCatalog
        : _baseColumnsRegistration;
    final outerColumns = projection == CadastroFilialSqlProjection.mapCatalog
        ? _outerColumnsMapCatalog
        : _outerColumnsRegistration;
    return '''
    WITH Base AS (
      SELECT
$baseColumns
      FROM Filial f
      LEFT JOIN Municipio m ON
        m.CodMunicipio = f.CodMunicipio
      WHERE 1 = 1
$branchPredicate
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
}
