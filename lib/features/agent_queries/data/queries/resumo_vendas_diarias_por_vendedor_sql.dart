abstract final class ResumoVendasDiariasPorVendedorSql {
  /// Inner slice follows the ERP `ResumoVendasDiarioVendedor` report: `Cliente`
  /// and `Municipio` are required joins. Lookups on `GrupoCliente` / `Regiao`
  /// stay out of this text so agents without read access to those resources
  /// can still run the query.
  static const String query = '''
SELECT
  CodEmpresa,
  CodFilial,
  DataVenda,
  CodVendedor,
  NomeVendedor,
  SUM(QtdeItens) AS QtdeItens,
  SUM(ValorAcrescimo) AS ValorAcrescimo,
  SUM(ValorDesconto) AS ValorDesconto,
  SUM(ValorBruto) AS ValorBruto,
  SUM(ValorLiquido) AS ValorLiquido
FROM (
  SELECT
    pv.CodEmpresa,
    pv.CodFilial,
    pv.Origem,
    pv.CodOrigem,
    pv.CodTipoOperacaoSaida,
    tos.Descricao AS DescricaoTipoOperacaoSaida,
    tos.GeraFinanceiro,
    pv.PreVenda,
    pv.CodVendedor,
    COALESCE(
      NULLIF(LTRIM(RTRIM(v.Nome)), ''),
      'Vendedor nao informado'
    ) AS NomeVendedor,
    pv.CodCliente,
    pv.NomeCliente,
    pv.CnpjCpf AS CnpjCpfCliente,
    c.CodGrupoCliente,
    pv.Bairro AS Bairro,
    pv.CodMunicipio,
    m.Nome AS NomeMunicipio,
    m.UF AS UFMunicipio,
    c.CodRegiao,
    CAST(pv.DataVenda AS DATE) AS DataVenda,
    pv.QtdeItens,
    pv.PercentualAcrescimo,
    pv.ValorAcrescimo,
    pv.PercentualDesconto,
    pv.ValorDesconto,
    pv.ValorBruto,
    pv.ValorLiquido
  FROM ProdutoVendido pv
  INNER JOIN TipoOperacaoSaida tos ON
    tos.CodEmpresa = pv.CodEmpresa
    AND tos.CodTipoOperacaoSaida = pv.CodTipoOperacaoSaida
  INNER JOIN Cliente c ON
    c.CodCliente = pv.CodCliente
  INNER JOIN Municipio m ON
    m.CodMunicipio = pv.CodMunicipio
  LEFT JOIN Vendedor v ON
    v.CodVendedor = pv.CodVendedor
) ResumoVendasDiarioVendedor
WHERE DataVenda BETWEEN :dataVendaInicio AND :dataVendaFim
  AND Origem LIKE 'FrenteLoja'
  AND GeraFinanceiro = 'S'
  AND PreVenda = 'N'
  AND (:codVendedor IS NULL OR CodVendedor = :codVendedor)
  AND (:bairro IS NULL OR Bairro = :bairro)
  AND (:municipio IS NULL OR NomeMunicipio = :municipio)
GROUP BY
  CodEmpresa,
  CodFilial,
  DataVenda,
  CodVendedor,
  NomeVendedor
''';
}
