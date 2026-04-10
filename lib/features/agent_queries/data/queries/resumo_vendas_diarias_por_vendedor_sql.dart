abstract final class ResumoVendasDiariasPorVendedorSql {
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
    pv.PreVenda,
    tos.GeraFinanceiro,
    CAST(pv.DataVenda AS DATE) AS DataVenda,
    pv.CodVendedor,
    COALESCE(
      NULLIF(LTRIM(RTRIM(v.Nome)), ''),
      'Vendedor nao informado'
    ) AS NomeVendedor,
    pv.CodCliente,
    pv.NomeCliente,
    pv.CnpjCpf,
    pv.Bairro,
    m.Nome AS NomeMunicipio,
    m.UF AS UFMunicipio,
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
  LEFT JOIN Vendedor v ON
    v.CodVendedor = pv.CodVendedor
  LEFT JOIN Municipio m ON
    m.CodMunicipio = pv.CodMunicipio
) ResumoVendasDiario
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
