import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_media_movel_filter.dart';

// Product sales trend by moving average (`ProdutoVendidoTendenciaDeVendaMediaMovel`)
// in a single `sql.execute` round-trip.
//
// Compares the latest moving-average window against the immediately previous
// window of the same size and returns one row per product with the current
// average, previous average, delta, percentage trend, and classification.
//
// ---
//
// ## Active joins and relationships
//
// | Alias | Table | Relationship / role |
// |---|---|---|
// | ipv | ItemProdutoVendido | Sale item line (`Quantidade`, `CodProduto`) |
// | pv | ProdutoVendido | `pv.CodEmpresa = ipv.CodEmpresa` and `pv.CodProdutoVendido = ipv.CodProdutoVendido`; provides `DataVenda`, `Origem`, `PreVenda`, `CodFilial` |
// | tos | TipoOperacaoSaida | `tos.CodEmpresa = pv.CodEmpresa`, `tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida`; validates financeiro rows |
// | p | Produto | `p.CodProduto = ipv.CodProduto`; provides product identity and `CodUnidadeMedida` |
// | gp | GrupoProduto | `gp.CodGrupoProduto = p.CodGrupoProduto` (optional metadata) |
// | m | Marca | `m.CodMarca = p.CodMarca` (optional metadata) |
//
// ## Query parameters
//
// Named params:
// - `:startRow`
// - `:endRow`
//
// `quantidadeDias` and optional detail filters are inlined as validated SQL
// literals because SQL Server window-frame offsets must remain integer
// literals in `ROWS BETWEEN ... PRECEDING`.
abstract final class ProdutoVendidoTendenciaDeVendaMediaMovelSql {
  static String filteredUniverseCtes({
    required int quantidadeDias,
    String? searchTerm,
    String? classificacao,
    int? codGrupoProduto,
    int? codMarca,
  }) {
    if (quantidadeDias < 1) {
      throw ArgumentError.value(
        quantidadeDias,
        'quantidadeDias',
        'must be >= 1',
      );
    }

    final currentWindowRows = quantidadeDias - 1;
    final previousWindowStart = (quantidadeDias * 2) - 1;
    final previousWindowEnd = quantidadeDias;
    final lookbackDays = previousWindowStart;
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
    WITH Diario AS (
      SELECT
        pv.CodEmpresa,
        pv.CodFilial,
        CAST(pv.DataVenda AS DATE) AS DataVenda,
        ipv.CodProduto,
        p.Nome AS NomeProduto,
        p.CodUnidadeMedida,
        gp.CodGrupoProduto,
        gp.Nome AS NomeGrupoProduto,
        m.CodMarca,
        m.Nome AS NomeMarca,
        SUM(ipv.Quantidade) AS QtdDia
      FROM ItemProdutoVendido ipv
      INNER JOIN ProdutoVendido pv ON
        pv.CodEmpresa = ipv.CodEmpresa
        AND pv.CodProdutoVendido = ipv.CodProdutoVendido
      INNER JOIN Produto p ON
        p.CodProduto = ipv.CodProduto
      LEFT JOIN GrupoProduto gp ON
        gp.CodGrupoProduto = p.CodGrupoProduto
      LEFT JOIN Marca m ON
        m.CodMarca = p.CodMarca
      INNER JOIN TipoOperacaoSaida tos ON
        tos.CodEmpresa = pv.CodEmpresa
        AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
      WHERE pv.DataVenda >= DATEADD(DAY, -$lookbackDays, CAST(GETDATE() AS DATE))
        AND pv.DataVenda < DATEADD(day, 1, CAST(GETDATE() AS DATE))
        AND pv.Origem = 'FrenteLoja'
        AND COALESCE(tos.GeraFinanceiro, 'N') = 'S'
        AND pv.PreVenda = 'N'
$codGrupoProdutoLine
$codMarcaLine
$searchTermLine
      GROUP BY
        pv.CodEmpresa,
        pv.CodFilial,
        CAST(pv.DataVenda AS DATE),
        ipv.CodProduto,
        p.Nome,
        p.CodUnidadeMedida,
        gp.CodGrupoProduto,
        gp.Nome,
        m.CodMarca,
        m.Nome
    ),
    Movel AS (
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
        DataVenda,
        AVG(QtdDia * 1.0) OVER (
          PARTITION BY CodProduto
          ORDER BY DataVenda
          ROWS BETWEEN $currentWindowRows PRECEDING AND CURRENT ROW
        ) AS MediaAtual,
        AVG(QtdDia * 1.0) OVER (
          PARTITION BY CodProduto
          ORDER BY DataVenda
          ROWS BETWEEN $previousWindowStart PRECEDING AND $previousWindowEnd PRECEDING
        ) AS MediaAnterior
      FROM Diario
    ),
    UltimaLinha AS (
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
        MediaAtual,
        MediaAnterior,
        ROW_NUMBER() OVER (
          PARTITION BY CodProduto
          ORDER BY DataVenda DESC
        ) AS Linha
      FROM Movel
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
        COALESCE(MediaAtual, 0) AS MediaAtual,
        COALESCE(MediaAnterior, 0) AS MediaAnterior,
        COALESCE(MediaAtual, 0) - COALESCE(MediaAnterior, 0) AS Diferenca,
        CASE
          WHEN COALESCE(MediaAnterior, 0) > 0
            THEN (
              (COALESCE(MediaAtual, 0) - COALESCE(MediaAnterior, 0))
              * 100.0
              / MediaAnterior
            )
          ELSE 0
        END AS TendenciaPercentual,
        CASE
          WHEN COALESCE(MediaAnterior, 0) = 0
            AND COALESCE(MediaAtual, 0) > 0 THEN 'NOVO'
          WHEN COALESCE(MediaAtual, 0) = 0 THEN 'PAROU'
          WHEN (
            (COALESCE(MediaAtual, 0) - COALESCE(MediaAnterior, 0))
            / NULLIF(MediaAnterior, 0)
          ) > 0.2 THEN 'CRESCENDO'
          WHEN (
            (COALESCE(MediaAtual, 0) - COALESCE(MediaAnterior, 0))
            / NULLIF(MediaAnterior, 0)
          ) < -0.2 THEN 'CAINDO'
          ELSE 'ESTAVEL'
        END AS Classificacao
      FROM UltimaLinha
      WHERE Linha = 1
    ),
    Filtrado AS (
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
        MediaAtual,
        MediaAnterior,
        Diferenca,
        TendenciaPercentual,
        Classificacao
      FROM Resultado
$classificacaoLine
    )''';
  }

  static String pagedQuery({
    required int quantidadeDias,
    String? searchTerm,
    String? classificacao,
    int? codGrupoProduto,
    int? codMarca,
    ProdutoVendidoTendenciaDeVendaMediaMovelSortBy sortBy =
        ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.tendenciaPercentualDesc,
  }) {
    final filteredCtes = filteredUniverseCtes(
      quantidadeDias: quantidadeDias,
      searchTerm: searchTerm,
      classificacao: classificacao,
      codGrupoProduto: codGrupoProduto,
      codMarca: codMarca,
    );

    return '''
$filteredCtes,
    Tot AS (
      SELECT COUNT(*) AS TotalCount FROM Filtrado
    ),
    Numbered AS (
      SELECT
        f.*,
        ROW_NUMBER() OVER (
          ORDER BY ${_numberedOrderByClause(sortBy)}
        ) AS Rn
      FROM Filtrado f
    )
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
      N.MediaAtual,
      N.MediaAnterior,
      N.Diferenca,
      N.TendenciaPercentual,
      N.Classificacao
    FROM Tot
    LEFT JOIN Numbered N ON N.Rn BETWEEN :startRow AND :endRow
    ORDER BY COALESCE(N.Rn, 2147483647)
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

  static String _numberedOrderByClause(
    ProdutoVendidoTendenciaDeVendaMediaMovelSortBy sortBy,
  ) {
    return switch (sortBy) {
      ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.tendenciaPercentualDesc =>
        '''
            f.CodEmpresa ASC,
            f.CodFilial ASC,
            f.TendenciaPercentual DESC,
            f.Diferenca DESC,
            f.NomeProduto ASC''',
      ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.diferencaDesc =>
        '''
            f.CodEmpresa ASC,
            f.CodFilial ASC,
            f.Diferenca DESC,
            f.TendenciaPercentual DESC,
            f.NomeProduto ASC''',
      ProdutoVendidoTendenciaDeVendaMediaMovelSortBy.nomeProdutoAsc =>
        '''
            f.CodEmpresa ASC,
            f.CodFilial ASC,
            f.NomeProduto ASC,
            f.TendenciaPercentual DESC''',
    };
  }
}
