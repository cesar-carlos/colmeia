import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_sql.dart';

/// Single-round-trip screen load for product sales trend.
///
/// Shares one filtered universe CTE through `Resultado`, then returns tagged
/// rows (`SUMMARY` / `PAGE` / `GAINER` / `LOSER`) via `UNION ALL`.
///
/// Page and summary may use different `classificacao` filters; search, grupo,
/// marca, and periods must be the same (enforced by the repository).
abstract final class ProdutoVendidoTendenciaDeVendaScreenSql {
  static const String rowKindSummary = 'SUMMARY';
  static const String rowKindPage = 'PAGE';
  static const String rowKindGainer = 'GAINER';
  static const String rowKindLoser = 'LOSER';

  static String query({
    required int startRow,
    required int endRow,
    String? searchTerm,
    String? pageClassificacao,
    String? summaryClassificacao,
    int? codGrupoProduto,
    int? codMarca,
  }) {
    if (startRow < 1) {
      throw ArgumentError.value(startRow, 'startRow', 'must be >= 1');
    }
    if (endRow < startRow) {
      throw ArgumentError.value(
        endRow,
        'endRow',
        'must be >= startRow',
      );
    }

    final filteredCtes = ProdutoVendidoTendenciaDeVendaSql.filteredUniverseCtes(
      searchTerm: searchTerm,
      codGrupoProduto: codGrupoProduto,
      codMarca: codMarca,
    );
    final pageClassLine = _whereOptionalClassificacao(pageClassificacao);
    final summaryClassLine = _whereOptionalClassificacao(summaryClassificacao);
    const topMovers = ProdutoVendidoTendenciaDeVendaSql.topMoversLimit;

    return '''
$filteredCtes,
    SummaryFiltrado AS (
      SELECT
        Diferenca,
        Classificacao
      FROM Resultado
$summaryClassLine
    ),
    SummaryAgg AS (
      SELECT
        Classificacao,
        COUNT(*) AS QuantidadeProdutos,
        SUM(Diferenca) AS ImpactoLiquido
      FROM SummaryFiltrado
      GROUP BY
        Classificacao
    ),
    PageFiltrado AS (
      SELECT
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodUnidadeMedida,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca,
        QtdAnterior,
        QtdAtual,
        Diferenca,
        PercentualTendencia,
        Classificacao
      FROM Resultado
$pageClassLine
    ),
    PageTot AS (
      SELECT COUNT(*) AS TotalCount FROM PageFiltrado
    ),
    PageNumbered AS (
      SELECT
        ROW_NUMBER() OVER (
          ORDER BY
            CodEmpresa ASC,
            CodFilial ASC,
            PercentualTendencia DESC
        ) AS RowNum,
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodUnidadeMedida,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca,
        QtdAnterior,
        QtdAtual,
        Diferenca,
        PercentualTendencia,
        Classificacao
      FROM PageFiltrado
    ),
    PageSlice AS (
      SELECT
        Tot.TotalCount,
        N.CodEmpresa,
        N.CodFilial,
        N.CodProduto,
        N.NomeProduto,
        N.CodUnidadeMedida,
        N.CodGrupoProduto,
        N.NomeGrupoProduto,
        N.CodMarca,
        N.NomeMarca,
        N.QtdAnterior,
        N.QtdAtual,
        N.Diferenca,
        N.PercentualTendencia,
        N.Classificacao,
        COALESCE(N.RowNum, 2147483647) AS PageOrder
      FROM PageTot Tot
      LEFT JOIN PageNumbered N ON N.RowNum BETWEEN $startRow AND $endRow
    ),
    GainerFiltrado AS (
      SELECT
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodUnidadeMedida,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca,
        QtdAnterior,
        QtdAtual,
        Diferenca,
        PercentualTendencia,
        Classificacao
      FROM Resultado
$pageClassLine
    ),
    GainerTop AS (
      SELECT TOP $topMovers
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodUnidadeMedida,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca,
        QtdAnterior,
        QtdAtual,
        Diferenca,
        PercentualTendencia,
        Classificacao
      FROM GainerFiltrado
      WHERE Diferenca > 0
      ORDER BY
        Diferenca DESC,
        PercentualTendencia DESC,
        CodEmpresa ASC,
        CodFilial ASC,
        NomeProduto ASC
    ),
    LoserFiltrado AS (
      SELECT
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodUnidadeMedida,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca,
        QtdAnterior,
        QtdAtual,
        Diferenca,
        PercentualTendencia,
        Classificacao
      FROM Resultado
$pageClassLine
    ),
    LoserTop AS (
      SELECT TOP $topMovers
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodUnidadeMedida,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca,
        QtdAnterior,
        QtdAtual,
        Diferenca,
        PercentualTendencia,
        Classificacao
      FROM LoserFiltrado
      WHERE Diferenca < 0
      ORDER BY
        Diferenca ASC,
        PercentualTendencia ASC,
        CodEmpresa ASC,
        CodFilial ASC,
        NomeProduto ASC
    )
    SELECT
      CAST('$rowKindSummary' AS VARCHAR(16)) AS RowKind,
      S.Classificacao,
      S.QuantidadeProdutos,
      CAST(S.ImpactoLiquido AS DOUBLE) AS ImpactoLiquido,
      CAST(NULL AS INTEGER) AS TotalCount,
      CAST(NULL AS INTEGER) AS CodEmpresa,
      CAST(NULL AS INTEGER) AS CodFilial,
      CAST(NULL AS INTEGER) AS CodProduto,
      CAST(NULL AS VARCHAR(200)) AS NomeProduto,
      CAST(NULL AS VARCHAR(50)) AS CodUnidadeMedida,
      CAST(NULL AS INTEGER) AS CodGrupoProduto,
      CAST(NULL AS VARCHAR(200)) AS NomeGrupoProduto,
      CAST(NULL AS INTEGER) AS CodMarca,
      CAST(NULL AS VARCHAR(200)) AS NomeMarca,
      CAST(NULL AS DOUBLE) AS QtdAnterior,
      CAST(NULL AS DOUBLE) AS QtdAtual,
      CAST(NULL AS DOUBLE) AS Diferenca,
      CAST(NULL AS DOUBLE) AS PercentualTendencia,
      CAST(0 AS INTEGER) AS SortOrder,
      CAST(0 AS INTEGER) AS PageOrder
    FROM SummaryAgg S
    UNION ALL
    SELECT
      CAST('$rowKindPage' AS VARCHAR(16)) AS RowKind,
      P.Classificacao,
      CAST(NULL AS INTEGER) AS QuantidadeProdutos,
      CAST(NULL AS DOUBLE) AS ImpactoLiquido,
      P.TotalCount,
      P.CodEmpresa,
      P.CodFilial,
      P.CodProduto,
      P.NomeProduto,
      P.CodUnidadeMedida,
      P.CodGrupoProduto,
      P.NomeGrupoProduto,
      P.CodMarca,
      P.NomeMarca,
      CAST(P.QtdAnterior AS DOUBLE) AS QtdAnterior,
      CAST(P.QtdAtual AS DOUBLE) AS QtdAtual,
      CAST(P.Diferenca AS DOUBLE) AS Diferenca,
      CAST(P.PercentualTendencia AS DOUBLE) AS PercentualTendencia,
      CAST(1 AS INTEGER) AS SortOrder,
      P.PageOrder
    FROM PageSlice P
    UNION ALL
    SELECT
      CAST('$rowKindGainer' AS VARCHAR(16)) AS RowKind,
      G.Classificacao,
      CAST(NULL AS INTEGER) AS QuantidadeProdutos,
      CAST(NULL AS DOUBLE) AS ImpactoLiquido,
      CAST(NULL AS INTEGER) AS TotalCount,
      G.CodEmpresa,
      G.CodFilial,
      G.CodProduto,
      G.NomeProduto,
      G.CodUnidadeMedida,
      G.CodGrupoProduto,
      G.NomeGrupoProduto,
      G.CodMarca,
      G.NomeMarca,
      CAST(G.QtdAnterior AS DOUBLE) AS QtdAnterior,
      CAST(G.QtdAtual AS DOUBLE) AS QtdAtual,
      CAST(G.Diferenca AS DOUBLE) AS Diferenca,
      CAST(G.PercentualTendencia AS DOUBLE) AS PercentualTendencia,
      CAST(2 AS INTEGER) AS SortOrder,
      CAST(0 AS INTEGER) AS PageOrder
    FROM GainerTop G
    UNION ALL
    SELECT
      CAST('$rowKindLoser' AS VARCHAR(16)) AS RowKind,
      L.Classificacao,
      CAST(NULL AS INTEGER) AS QuantidadeProdutos,
      CAST(NULL AS DOUBLE) AS ImpactoLiquido,
      CAST(NULL AS INTEGER) AS TotalCount,
      L.CodEmpresa,
      L.CodFilial,
      L.CodProduto,
      L.NomeProduto,
      L.CodUnidadeMedida,
      L.CodGrupoProduto,
      L.NomeGrupoProduto,
      L.CodMarca,
      L.NomeMarca,
      CAST(L.QtdAnterior AS DOUBLE) AS QtdAnterior,
      CAST(L.QtdAtual AS DOUBLE) AS QtdAtual,
      CAST(L.Diferenca AS DOUBLE) AS Diferenca,
      CAST(L.PercentualTendencia AS DOUBLE) AS PercentualTendencia,
      CAST(3 AS INTEGER) AS SortOrder,
      CAST(0 AS INTEGER) AS PageOrder
    FROM LoserTop L
    ORDER BY
      SortOrder ASC,
      PageOrder ASC,
      QuantidadeProdutos DESC,
      Classificacao ASC,
      Diferenca DESC,
      PercentualTendencia DESC,
      CodEmpresa ASC,
      CodFilial ASC,
      NomeProduto ASC
  ''';
}

  static String _whereOptionalClassificacao(String? classificacao) {
    final normalized = classificacao?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '      WHERE (1 = 1)';
    }
    final escaped = normalized.replaceAll("'", "''");
    return "      WHERE Classificacao = N'$escaped'";
  }
}
