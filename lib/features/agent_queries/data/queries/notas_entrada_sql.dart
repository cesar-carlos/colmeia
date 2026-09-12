import 'package:colmeia/features/agent_queries/data/queries/agent_queries_sql_accent_fold.dart';

/// Paged entrada-note catalog from `Compra.Compra` with total count.
///
/// ## Tables read
///
/// | Alias | Table | Role |
/// | --- | --- | --- |
/// | `cc` | `Compra.Compra` | purchase, launch date, branch, supplier and total |
/// | `dem` | `Compra.DadosEntradaMercadoria` | document number, issue and entry dates |
/// | `toc` | `Compra.TipoOperacaoCompra` | purchase-operation description |
/// | `f` | `Fornecedor` | supplier identity |
/// | `fl` | `Filial` | branch names |
///
/// ## Parameters and pagination
///
/// `:codEmpresa`, `:codFilial`, `:nomeFornecedorPattern`, `:startRow`, and
/// `:endRow` occur once. Optional date parameters also occur once,
/// materialized in `Parametros` so SQL Anywhere ODBC does not duplicate
/// positional binds.
///
/// `:nomeFornecedorPattern` is a contains literal (e.g. `%mel%`) from
/// `ResumoVendasDiariasSuggestionSqlParams.buildSearchPattern`, or `NULL`
/// to skip the supplier filter. The `LIKE` runs in `Base` before `Tot` and
/// `ROW_NUMBER`, so `totalCount` and page windows share the same filtered
/// catalog. Supplier names are accent-folded and uppercased
/// (`AgentQueriesSqlAccentFold`); code and tax id use a case-insensitive
/// contains match.
///
/// Date predicates are included only when their corresponding value exists.
/// The final selected calendar day is inclusive. Page windows use
/// `ROW_NUMBER` over `DataLancamento DESC`, then `CompraId DESC`.
abstract final class NotasEntradaSql {
  static String pagedQuery({
    required bool hasDataLancamentoInicio,
    required bool hasDataLancamentoFim,
  }) {
    final parametrosDates = StringBuffer();
    if (hasDataLancamentoInicio) {
      parametrosDates.write(
        ',\n        CAST(:dataLancamentoInicio AS DATE) AS DataLancamentoInicio',
      );
    }
    if (hasDataLancamentoFim) {
      parametrosDates.write(
        ',\n        CAST(:dataLancamentoFim AS DATE) AS DataLancamentoFim',
      );
    }
    final dataLancamentoInicioFilter = hasDataLancamentoInicio
        ? '''
    AND cc.DataInclusao >= prm.DataLancamentoInicio'''
        : '';
    final dataLancamentoFimFilter = hasDataLancamentoFim
        ? '''
    AND cc.DataInclusao < DATEADD(day, 1, prm.DataLancamentoFim)'''
        : '';
    final razaoFolded = AgentQueriesSqlAccentFold.foldUpper(
      'TRIM(f.RazaoSocial)',
    );
    final fantasiaFolded = AgentQueriesSqlAccentFold.foldUpper(
      "COALESCE(TRIM(f.NomeFantasia), '')",
    );
    final patternFolded = AgentQueriesSqlAccentFold.foldUpper(
      'prm.NomeFornecedorPattern',
    );

    return '''
WITH Parametros AS (
  SELECT
    CAST(:codEmpresa AS INTEGER) AS CodEmpresa,
    CAST(:codFilial AS INTEGER) AS CodFilial,
    CAST(:nomeFornecedorPattern AS VARCHAR(255)) AS NomeFornecedorPattern$parametrosDates
),
Base AS (
  SELECT
    cc.Id AS CompraId,
    cc.CodEmpresa,
    cc.CodFilial,
    fl.Nome AS NomeFilial,
    fl.NomeFantasia AS NomeFantasiaFilial,
    cc.CodTipoOperacaoCompra,
    toc.Descricao AS DescricaoTipoOperacaoCompra,
    dem.NumeroDocumento,
    dem.DataEmissao,
    dem.DataEntrada,
    cc.DataInclusao AS DataLancamento,
    f.CodFornecedor,
    f.RazaoSocial AS NomeFornecedor,
    f.NomeFantasia AS NomeFantasiaFornecedor,
    f.cnpj_cpf AS CnpjCpfFornecedor,
    cc.ValorTotalCompra
  FROM Compra.Compra cc
  CROSS JOIN Parametros prm
  INNER JOIN Compra.DadosEntradaMercadoria dem ON dem.CompraID = cc.Id
  INNER JOIN Compra.TipoOperacaoCompra toc ON
    toc.CodEmpresa = cc.CodEmpresa
    AND toc.CodTipoOperacaoCompra = cc.CodTipoOperacaoCompra
  INNER JOIN Fornecedor f ON f.CodFornecedor = cc.CodFornecedor
  INNER JOIN Filial fl ON
    fl.CodEmpresa = cc.CodEmpresa
    AND fl.CodFilial = cc.CodFilial
  WHERE cc.Cancelada = 'N'
    AND cc.CodEmpresa = prm.CodEmpresa
    AND cc.CodFilial = prm.CodFilial$dataLancamentoInicioFilter$dataLancamentoFimFilter
    AND (
      prm.NomeFornecedorPattern IS NULL
      OR $razaoFolded LIKE $patternFolded
      OR $fantasiaFolded LIKE $patternFolded
      OR CAST(f.CodFornecedor AS VARCHAR(20)) LIKE prm.NomeFornecedorPattern
      OR UPPER(COALESCE(f.cnpj_cpf, '')) LIKE UPPER(prm.NomeFornecedorPattern)
    )
),
Tot AS (
  SELECT COUNT(*) AS TotalCount FROM Base
),
Numbered AS (
  SELECT
    b.*,
    ROW_NUMBER() OVER (
      ORDER BY
        b.DataLancamento DESC,
        b.CompraId DESC
    ) AS Rn
  FROM Base b
)
SELECT
  Tot.TotalCount,
  N.CompraId,
  N.CodEmpresa,
  N.CodFilial,
  N.NomeFilial,
  N.NomeFantasiaFilial,
  N.CodTipoOperacaoCompra,
  N.DescricaoTipoOperacaoCompra,
  N.NumeroDocumento,
  N.DataEmissao,
  N.DataEntrada,
  N.DataLancamento,
  N.CodFornecedor,
  N.NomeFornecedor,
  N.NomeFantasiaFornecedor,
  N.CnpjCpfFornecedor,
  N.ValorTotalCompra
FROM Tot
LEFT JOIN Numbered N ON N.Rn BETWEEN :startRow AND :endRow
ORDER BY COALESCE(N.Rn, 2147483647)
''';
  }
}
