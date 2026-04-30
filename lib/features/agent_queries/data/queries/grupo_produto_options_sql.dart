/// Product-group catalog options used by product filter UIs.
///
/// Named params: none.
abstract final class GrupoProdutoOptionsSql {
  static const String query = '''
    SELECT
      CodGrupoProduto,
      Nome AS NomeGrupoProduto
    FROM GrupoProduto
    ORDER BY
      Nome
  ''';
}
