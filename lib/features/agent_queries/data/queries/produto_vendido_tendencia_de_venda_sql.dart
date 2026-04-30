// Product sales trend by quantity (`ProdutoVendidoTendenciaDeVenda`)
// in a single `sql.execute` round-trip.
//
// Compares two explicit periods (`ATUAL` and `ANTERIOR`) and returns one row
// per product with difference, percentage trend, and classification.
//
// ---
//
// ## Active joins and relationships
//
// | Alias | Table | Relationship / role |
// |---|---|---|
// | ipv | ItemProdutoVendido | Sale item line (`Quantidade`, `CodProduto`) |
// | pv | ProdutoVendido | `pv.CodEmpresa = ipv.CodEmpresa` and `pv.CodProdutoVendido = ipv.CodProdutoVendido`; provides `DataVenda`, `Origem`, `PreVenda`, `CodFilial` |
// | tos | TipoOperacaoSaida | `tos.CodEmpresa = pv.CodEmpresa`, `tos.CodFilial = pv.CodFilial`, `tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida`; validates financeiro rows |
// | p | Produto | `p.CodProduto = ipv.CodProduto`; provides product identity and `CodUnidadeMedida` |
// | gp | GrupoProduto | `gp.CodGrupoProduto = p.CodGrupoProduto` (optional metadata) |
// | m | Marca | `m.CodMarca = p.CodMarca` (optional metadata) |
//
// ## Tables intentionally removed from active SQL
//
// | Alias | Table | Why removed now | Notes for reintroduction |
// |---|---|---|---|
// | cp | CustoProduto | Not referenced by current select or filters | Re-add with `cp.CodEmpresa = pv.CodEmpresa`, `cp.CodFilial = pv.CodFilial`, `cp.CodProduto = ipv.CodProduto` when trend needs cost/profit dimensions |
//
// ---
//
// ## Query parameters
//
// Named params:
// - `:periodoAtualInicio`
// - `:periodoAtualFim`
// - `:periodoAnteriorInicio`
// - `:periodoAnteriorFim`
// - `:origem`
//
// Pagination bounds are inlined as validated integer literals to keep the query
// under bridge named-bind limits.
abstract final class ProdutoVendidoTendenciaDeVendaSql {
  static String pagedQuery({
    required int startRow,
    required int endRow,
    String? searchTerm,
    String? classificacao,
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
    final codGrupoProdutoLine = _whereIntEquals(
      columnSql: 'p.CodGrupoProduto',
      value: codGrupoProduto,
    );
    final codMarcaLine = _whereIntEquals(
      columnSql: 'p.CodMarca',
      value: codMarca,
    );
    final searchTermLine = _whereContainsProductDimensions(searchTerm);
    final classificacaoLine = _whereOptionalClassificacao(classificacao);
    return '''
    WITH Parametros AS (
      SELECT
        CAST(:periodoAtualInicio AS DATE) AS PeriodoAtualInicio,
        CAST(:periodoAtualFim AS DATE) AS PeriodoAtualFim,
        CAST(:periodoAnteriorInicio AS DATE) AS PeriodoAnteriorInicio,
        CAST(:periodoAnteriorFim AS DATE) AS PeriodoAnteriorFim
    ),
    BaseVendas AS (
      SELECT
        pv.CodEmpresa,
        pv.CodFilial,
        ipv.CodProduto,
        p.Nome AS NomeProduto,
        p.CodUnidadeMedida,
        gp.CodGrupoProduto,
        gp.Nome AS NomeGrupoProduto,
        m.CodMarca,
        m.Nome AS NomeMarca,
        CASE
          WHEN CAST(pv.DataVenda AS DATE)
            BETWEEN prm.PeriodoAtualInicio AND prm.PeriodoAtualFim
            THEN 'ATUAL'
          WHEN CAST(pv.DataVenda AS DATE)
            BETWEEN prm.PeriodoAnteriorInicio AND prm.PeriodoAnteriorFim
            THEN 'ANTERIOR'
        END AS Periodo,
        ipv.Quantidade
      FROM ItemProdutoVendido ipv
      INNER JOIN ProdutoVendido pv ON
        pv.CodEmpresa = ipv.CodEmpresa
        AND pv.CodProdutoVendido = ipv.CodProdutoVendido
      INNER JOIN TipoOperacaoSaida tos ON
        tos.CodEmpresa = pv.CodEmpresa
        AND tos.CodFilial = pv.CodFilial
        AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
      INNER JOIN Produto p ON
        p.CodProduto = ipv.CodProduto
      LEFT JOIN GrupoProduto gp ON
        gp.CodGrupoProduto = p.CodGrupoProduto
      LEFT JOIN Marca m ON
        m.CodMarca = p.CodMarca
      CROSS JOIN Parametros prm
      WHERE (
        CAST(pv.DataVenda AS DATE) BETWEEN prm.PeriodoAtualInicio AND prm.PeriodoAtualFim
        OR CAST(pv.DataVenda AS DATE)
          BETWEEN prm.PeriodoAnteriorInicio AND prm.PeriodoAnteriorFim
      )
        AND pv.Origem LIKE :origem
        AND COALESCE(tos.GeraFinanceiro, 'N') = 'S'
        AND pv.PreVenda = 'N'
$codGrupoProdutoLine
$codMarcaLine
$searchTermLine
    ),
    Vendas AS (
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
        Periodo,
        SUM(Quantidade) AS Quantidade
      FROM BaseVendas
      WHERE Periodo IS NOT NULL
      GROUP BY
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodUnidadeMedida,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca,
        Periodo
    ),
    Pivotado AS (
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
        SUM(CASE WHEN Periodo = 'ATUAL' THEN Quantidade ELSE 0 END) AS QtdAtual,
        SUM(CASE WHEN Periodo = 'ANTERIOR' THEN Quantidade ELSE 0 END) AS QtdAnterior
      FROM Vendas
      GROUP BY
        CodEmpresa,
        CodFilial,
        CodProduto,
        NomeProduto,
        CodUnidadeMedida,
        CodGrupoProduto,
        NomeGrupoProduto,
        CodMarca,
        NomeMarca
    ),
    Resultado AS (
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
        (QtdAtual - QtdAnterior) AS Diferenca,
        CASE
          WHEN QtdAnterior > 0
            THEN ((QtdAtual - QtdAnterior) * 100.0 / QtdAnterior)
          ELSE 0
        END AS PercentualTendencia,
        CASE
          WHEN QtdAtual = 0 AND QtdAnterior > 0 THEN 'PAROU DE VENDER'
          WHEN QtdAnterior = 0 AND QtdAtual > 0 THEN 'NOVO PRODUTO'
          WHEN ((QtdAtual - QtdAnterior) * 1.0 / NULLIF(QtdAnterior, 0)) > 0.2
            THEN 'CRESCENDO'
          WHEN ((QtdAtual - QtdAnterior) * 1.0 / NULLIF(QtdAnterior, 0)) < -0.2
            THEN 'CAINDO'
          ELSE 'ESTAVEL'
        END AS Classificacao
      FROM Pivotado
      WHERE (QtdAtual + QtdAnterior) >= 10
    ),
    Numbered AS (
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
      FROM Resultado
$classificacaoLine
    )
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
    FROM Numbered
    WHERE RowNum BETWEEN $startRow AND $endRow
    ORDER BY
      RowNum ASC
  ''';
  }

  static String _whereIntEquals({
    required String columnSql,
    required int? value,
  }) {
    if (value == null) {
      return '        AND (1 = 1)';
    }
    return '        AND $columnSql = $value';
  }

  static String _whereContainsProductDimensions(String? searchTerm) {
    final normalized = searchTerm?.trim();
    if (normalized == null || normalized.isEmpty) {
      return '        AND (1 = 1)';
    }
    final escaped = normalized.replaceAll("'", "''");
    final likeLiteral = "N'%$escaped%'";
    return '''
        AND (
          UPPER(p.Nome) LIKE UPPER($likeLiteral)
          OR UPPER(COALESCE(gp.Nome, '')) LIKE UPPER($likeLiteral)
          OR UPPER(COALESCE(m.Nome, '')) LIKE UPPER($likeLiteral)
        )''';
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
