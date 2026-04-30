/// Product-brand catalog options used by product filter UIs.
///
/// Named params: none.
abstract final class MarcaProdutoOptionsSql {
  static const String query = '''
    SELECT
      CodMarca,
      Nome AS NomeMarca
    FROM Marca
    ORDER BY
      Nome
  ''';
}
